// SPDX-License-Identifier: MIT
// Portable reproduction harness. Numerical targets remain in the Modelica assertions.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const options={};
for(let i=2;i<process.argv.length;i+=2){const k=process.argv[i],v=process.argv[i+1];if(!k?.startsWith('--')||v===undefined)throw Error('Arguments must be --key value');options[k.slice(2)]=v;}
const repo=path.resolve(options.repo||path.join(path.dirname(fileURLToPath(import.meta.url)),'..'));
const omc=options.omc||process.env.OMC||'omc',storage=options.storage||'source',suite=options.suite||'release';
if(!['source','tree'].includes(storage)||!['release','tutorial'].includes(suite))throw Error('Invalid storage or suite');
if(!options.out)throw Error('Usage: node scripts/run_verification.mjs --out NEW_DIRECTORY [--storage source|tree] [--suite release|tutorial] [--omc EXECUTABLE]');
const out=path.resolve(options.out),source=path.join(repo,'src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo');
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const expected='2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b';
if(sha(source)!==expected)throw Error('Immutable source hash mismatch. Clone with core.autocrlf=false.');
if(storage==='tree'){const r=spawnSync(process.execPath,[path.join(repo,'scripts/package_tree.mjs'),'--check'],{encoding:'utf8'});if(r.status!==0)throw Error('Package-tree integrity failed: '+r.stderr);}
const mp=path.join(repo,suite==='release'?'tests/v010_test_manifest.json':'tests/tutorial_manifest.json');
const manifest=JSON.parse(fs.readFileSync(mp,'utf8'));
if(manifest.source_sha256!==expected)throw Error('Manifest source hash mismatch');
if(suite==='release'&&(manifest.cases.length!==50||manifest.cases.filter(c=>c.kind==='sim').length!==45))throw Error('Release case inventory changed');
if(new Set(manifest.cases.map(c=>c.name)).size!==manifest.cases.length)throw Error('Duplicate case names');
if(fs.existsSync(out))throw Error('Refusing to overwrite an existing run directory');
const v=spawnSync(omc,['--version'],{encoding:'utf8',timeout:15000});
if(v.status!==0||!v.stdout.includes('1.27.1'))throw Error('OpenModelica 1.27.1 required: '+(v.stderr||v.error||v.stdout));
const compiler=omc.includes(path.sep)||omc.includes('/')?path.resolve(omc):omc;
const env={...process.env};if(path.isAbsolute(compiler))env.PATH=path.dirname(compiler)+path.delimiter+(env.PATH||'');
fs.mkdirSync(out,{recursive:true});fs.copyFileSync(mp,path.join(out,'manifest.json'));
const started=new Date().toISOString(),records=[];
const revision=spawnSync('git',['-C',repo,'rev-parse','HEAD'],{encoding:'utf8'}).stdout?.trim()||null;
const summary=status=>{const x={status,suite,storage,source_sha256:expected,manifest_sha256:sha(mp),runner_sha256:sha(fileURLToPath(import.meta.url)),git_commit:revision,compiler:v.stdout.trim(),platform:process.platform,architecture:process.arch,started_utc:started,updated_utc:new Date().toISOString(),expected_cases:manifest.cases.length,completed_cases:records.length,passed_cases:records.filter(c=>c.status==='PASS').length,results:records};fs.writeFileSync(path.join(out,'summary.json'),JSON.stringify(x,null,2));return x;};
const fatal=/(?:\b(?:error|fatal)\s*:|LOG_ASSERT\s*\|\s*error|division by zero|assertion[^\n]*failed|assertion has been violated)/im;
const esc=s=>s.replaceAll('\\','/').replaceAll('"','\\"');
const load=storage==='source'?source:path.join(repo,'ModelicaHumanBodyPArts/package.mo');
function completion(file,c){
 const lines=fs.readFileSync(file,'utf8').trim().split(/\r?\n/);
 const headers=(lines.shift().match(/"(?:[^"]|"")*"|[^,]+/g)||[]).map(x=>x.replaceAll('"','').trim());
 const ti=headers.indexOf('time'),ci=headers.indexOf('checksPassed');if(ti<0||ci<0)throw Error('Missing completion channels');
 const rows=lines.map(l=>l.split(',').map(Number));if(!rows.length||rows.some(r=>!Number.isFinite(r[ti])||!Number.isFinite(r[ci])))throw Error('Invalid completion data');
 if(rows.some((r,i)=>i&&r[ti]<rows[i-1][ti]-1e-12))throw Error('Nonmonotone times');
 const last=rows.at(-1);if(Math.abs(rows[0][ti])>1e-8||Math.abs(last[ti]-c.stop)>1e-7||last[ci]<1)throw Error('Incomplete run or assertion stages');
 return {rows:rows.length,final_time:last[ti],checksPassed:last[ci]};
}
summary('RUNNING');
for(const c of manifest.cases){
 const d=path.join(out,c.name);fs.mkdirSync(d);const rec={...c,status:'FAIL',started_utc:new Date().toISOString()};
 try{
  const extra=suite==='tutorial'?['examples/Article1ContactTutorial.mo','examples/Article1RegionalRedistribution.mo','examples/Article1ParallelSupport.mo'].map((f,i)=>`ok:=loadFile("${esc(path.join(repo,f))}");if not ok then print(getErrorString());exit(${12+i});end if;\n`).join(''):'';
  const script=`ok:=loadModel(Modelica,{"4.1.0"},requireExactVersion=true);if not ok then print(getErrorString());exit(10);end if;\nok:=loadFile("${esc(load)}",requireExactVersion=true);if not ok then print(getErrorString());exit(11);end if;\n${extra}print("MSL="+getVersion(Modelica)+"\\n");print("LIB="+getVersion(ModelicaHumanBodyPArts)+"\\n");\nb:=buildModel(${c.model},startTime=0,stopTime=${c.stop},numberOfIntervals=${c.intervals},tolerance=1e-8,method="dassl",outputFormat="csv",fileNamePrefix="model");print(getErrorString());print("EXEC="+b[1]+"\\n");`;
  fs.writeFileSync(path.join(d,'build.mos'),script);
  const b=spawnSync(compiler,['build.mos'],{cwd:d,env,encoding:'utf8',timeout:600000,maxBuffer:50000000});
  const blog=(b.stdout||'')+'\n'+(b.stderr||'');fs.writeFileSync(path.join(d,'build.log'),blog);
  const exe=path.join(d,process.platform==='win32'?'model.exe':'model');
  if(b.error||b.status!==0||fatal.test(blog)||!fs.existsSync(exe)||!fs.existsSync(path.join(d,'model_init.xml')))throw Error('Build failed: '+(b.error?.message||b.status));
  if(!blog.includes('MSL=4.1.0')||!blog.includes('LIB=0.10.0'))throw Error('Dependency version mismatch');
  if(c.kind==='sim'){
   const r=spawnSync(exe,['-r=result.csv'],{cwd:d,env,encoding:'utf8',timeout:600000,maxBuffer:50000000});
   const log=(r.stdout||'')+'\n'+(r.stderr||'');fs.writeFileSync(path.join(d,'runtime.log'),log);
   if(r.error||r.status!==0||fatal.test(log))throw Error('Runtime failed: '+(r.error?.message||r.status));
   rec.completion=completion(path.join(d,'result.csv'),c);
  }
  rec.status='PASS';
 }catch(e){rec.reason=e.message;}
 rec.finished_utc=new Date().toISOString();rec.hashes={};
 for(const f of fs.readdirSync(d)){if(/\.(csv|log|xml|mos)$/.test(f))rec.hashes[f]=sha(path.join(d,f));}
 fs.writeFileSync(path.join(d,'result_status.json'),JSON.stringify(rec,null,2));records.push(rec);
 summary(rec.status==='PASS'?'RUNNING':'FAIL');console.log(`${records.length}/${manifest.cases.length} ${c.name}: ${rec.status}${rec.reason?' - '+rec.reason:''}`);
 if(rec.status!=='PASS')process.exit(2);
}
summary(records.length===manifest.cases.length?'PASS':'INCOMPLETE');
console.log('PASS '+suite+' / '+storage+' / '+records.length+' cases');