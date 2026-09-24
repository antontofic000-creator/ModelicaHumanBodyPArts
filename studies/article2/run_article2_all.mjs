import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '..', '..');
const manifest = JSON.parse(fs.readFileSync(path.join(here, 'article2_manifest.json'), 'utf8'));
const lib = path.resolve(here, manifest.software.path);
const study = path.resolve(here, manifest.experiment_source.path);
const outRoot = path.join(here, 'article2_results');
const omc = process.env.OMC_PATH ||
  (process.platform === 'win32' && fs.existsSync('C:/Program Files/OpenModelica1.27.1-64bit/bin/omc.exe')
    ? 'C:/Program Files/OpenModelica1.27.1-64bit/bin/omc.exe'
    : 'omc');
const requested = process.argv[2] || 'all';
const filter = 'time|checksPassed|pelvisYaw|lumbarYaw|thoraxYaw|heelShare|broadSupport|stanceAxis|freeDeltaHip.*|groundForce.*|groundMoment.*|energyResidual|minimumROMMargin|body.cutMomentsWorld.*|body.cutForcesWorld.*';
const sha256 = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');

function assertSource(pathname, expected, label) {
  const got = sha256(pathname);
  if (got !== expected) throw new Error(`${label} SHA-256 mismatch: expected ${expected}, got ${got}`);
}

function parseCsv(csv) {
  const lines = fs.readFileSync(csv, 'utf8').trim().split(/\r?\n/);
  const header = (lines.shift().match(/"(?:[^"]|"")*"|[^,]+/g) || []).map(x => x.replaceAll('"','').trim());
  const rows = lines.map(line => line.split(',').map(Number));
  return { header, rows };
}

function runCase(campaign, c) {
  const d = path.join(outRoot, campaign, c.id);
  fs.mkdirSync(d, { recursive: true });
  const modelName = 'Article2Case';
  const mos = [
    'setCommandLineOptions("--maxSizeLinearTearing=300");',
    'loadModel(Modelica,{"4.1.0"},requireExactVersion=true);',
    `loadFile("${lib.replaceAll('\\','/')}");`,
    `loadFile("${study.replaceAll('\\','/')}");`,
    `loadString("model ${modelName} extends ModelicaHumanBodyPArtsArticle2.DistributedSupport(${c.modifiers},endTime=${c.stop}); end ${modelName};");`,
    'print(getErrorString());',
    `simulate(${modelName},stopTime=${c.stop},numberOfIntervals=${c.intervals},tolerance=${c.tolerance},method="dassl",outputFormat="csv",fileNamePrefix="model",variableFilter="${filter}",simflags="-lv=LOG_STATS -maxStepSize=${c.maxStep}");`,
    'print(getErrorString());'
  ].join('\n');
  fs.writeFileSync(path.join(d, 'run.mos'), mos);
  const p = spawnSync(omc, ['run.mos'], { cwd:d, encoding:'utf8', timeout:900000, maxBuffer:50e6 });
  const log = (p.stdout || '') + '\n' + (p.stderr || '');
  fs.writeFileSync(path.join(d, 'run.log'), log);
  const csv = path.join(d, 'model_res.csv');
  let status = 'FAIL', finalTime = null, checksPassed = null;
  if (p.status === 0 && fs.existsSync(csv)) {
    const {header, rows} = parseCsv(csv);
    const ti = header.indexOf('time'), ci = header.indexOf('checksPassed');
    finalTime = rows.at(-1)?.[ti];
    checksPassed = rows.at(-1)?.[ci];
    if (Math.abs(finalTime - c.stop) < 1e-8 && checksPassed >= 1 && !/LOG_ASSERT\s*\|\s*(error|debug)|Error:/i.test(log)) status='PASS';
  }
  const result = { campaign, id:c.id, status, finalTime, checksPassed, settings:c, software_sha256:sha256(lib), study_source_sha256:sha256(study) };
  fs.writeFileSync(path.join(d,'result.json'), JSON.stringify(result,null,2));
  console.log(`${campaign} ${c.id}: ${status}`);
  return result;
}

function runBenchmark() {
  const b = manifest.analytical_benchmark;
  const d = path.join(outRoot, 'benchmark');
  fs.mkdirSync(d,{recursive:true});
  const src = path.join(here,b.source);
  const mos = [
    'loadModel(Modelica,{"4.1.0"},requireExactVersion=true);',
    `loadFile("${src.replaceAll('\\','/')}");`,
    `simulate(${b.model},startTime=0,stopTime=${b.stop},numberOfIntervals=${b.intervals},tolerance=${b.tolerance},method="dassl",outputFormat="csv",fileNamePrefix="benchmark");`,
    'print(getErrorString());'
  ].join('\n');
  fs.writeFileSync(path.join(d,'run.mos'),mos);
  const p=spawnSync(omc,['run.mos'],{cwd:d,encoding:'utf8',timeout:900000,maxBuffer:50e6});
  fs.writeFileSync(path.join(d,'run.log'),(p.stdout||'')+'\n'+(p.stderr||''));
  const csv=path.join(d,'benchmark_res.csv');
  let maxDeltaError=null,status='FAIL';
  if(p.status===0&&fs.existsSync(csv)){
    const {header,rows}=parseCsv(csv), j=header.indexOf('deltaError');
    maxDeltaError=Math.max(...rows.map(r=>Math.abs(r[j])));
    status=maxDeltaError<2e-6?'PASS':'FAIL';
  }
  const result={status,maxDeltaError,reference_max_error:b.verified_max_delta_error_rad};
  fs.writeFileSync(path.join(d,'result.json'),JSON.stringify(result,null,2));
  console.log(`benchmark: ${status}, max delta error=${maxDeltaError}`);
  return result;
}

fs.mkdirSync(outRoot,{recursive:true});
assertSource(lib, manifest.software.sha256, 'ModelicaHumanBodyPArts v0.10.0 RC1');
if (manifest.experiment_source.github_sha256) assertSource(study, manifest.experiment_source.github_sha256, 'Article 2 experiment source');

const selected = requested === 'all' ? ['nominal','robustness','sensitivity','refinement','benchmark'] : [requested];
const allResults=[];
for (const campaign of selected) {
  if (campaign === 'benchmark') allResults.push({campaign,result:runBenchmark()});
  else {
    if (!manifest.campaigns[campaign]) throw new Error('Unknown campaign: '+campaign);
    for (const c of manifest.campaigns[campaign]) allResults.push(runCase(campaign,c));
  }
}
fs.writeFileSync(path.join(outRoot,'campaign_summary.json'),JSON.stringify(allResults,null,2));
const failed=allResults.filter(r=>(r.status||r.result?.status)!=='PASS');
if(failed.length){console.error(`FAILED: ${failed.length} case(s)`);process.exitCode=1;}
else console.log(`PASS: ${allResults.length} executed case(s)`);
