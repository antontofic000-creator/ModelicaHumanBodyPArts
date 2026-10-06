import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root=path.dirname(fileURLToPath(import.meta.url));
const manifest=JSON.parse(fs.readFileSync(path.join(root,'article2_manifest.json'),'utf8').replace(/^\uFEFF/,''));
const supplementary=manifest.supplementary_upper_body_inertia;
if(!supplementary) throw Error('Supplementary block missing from manifest');
const out=path.join(root,'generated','upper_body_'+new Date().toISOString().replace(/[^0-9TZ]/g,''));
fs.mkdirSync(out,{recursive:true});
const locate=(spec,fallback)=>[spec.path,spec.repository_path,fallback].filter(Boolean).map(p=>path.resolve(root,p)).find(fs.existsSync);
const lib=locate(manifest.software,'../../src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo')?.replaceAll('\\','/');
const exp=locate(supplementary.source,'ModelicaHumanBodyPArtsArticle2_UpperBody.mo')?.replaceAll('\\','/');
const omc=process.env.OMC||process.env.OMC_PATH||(process.platform==='win32'?'C:/Program Files/OpenModelica1.27.1-64bit/bin/omc.exe':'omc');
const filter='time|checksPassed|pelvisYaw|lumbarYaw|thoraxYaw|heelShare|broadSupport|stanceAxis|freeDeltaHip.*|groundForce.*|groundMoment.*|energyResidual|forceResidual.*|minimumROMMargin|body.cutMomentsWorld.*|body.cutForcesWorld.*|representedMassTotal|addedUpperBodyMass|addedUpperBodyYawInertia';
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
for(const [p,expected] of [[lib,manifest.software.sha256],[exp,supplementary.source.sha256]]) if(!p||sha(p)!==expected) throw Error('Source hash mismatch: '+p);
fs.writeFileSync(out+'/source_hashes.json',JSON.stringify({
  library_v010_rc1:sha(lib),
  article2_upperbody_experiment_package:sha(exp)
},null,2));

function parseCsv(csv){
  const l=fs.readFileSync(csv,'utf8').trim().split(/\r?\n/);
  const h=(l.shift().match(/"(?:[^"]|"")*"|[^,]+/g)||[]).map(x=>x.replaceAll('"','').trim());
  const R=l.map(x=>x.split(',').map(Number));
  return {h,R};
}
function metrics(csv){
  const {h,R}=parseCsv(csv), o={rows:R.length,finalTime:R.at(-1)[h.indexOf('time')]};
  for(const k of ['checksPassed','pelvisYaw','lumbarYaw','thoraxYaw','heelShare','broadSupport','stanceAxis','freeDeltaHip[1]','groundForce[1]','groundMoment[3]','energyResidual','minimumROMMargin','body.cutMomentsWorld[7,3]','representedMassTotal','addedUpperBodyMass','addedUpperBodyYawInertia']){
    const j=h.indexOf(k); if(j>=0){const a=R.map(r=>r[j]);o[k]={initial:a[0],final:a.at(-1),min:Math.min(...a),max:Math.max(...a),maxAbs:Math.max(...a.map(Math.abs))};}
  }
  return o;
}
function build(arch){
  const dir=out+'/build_A'+arch; fs.mkdirSync(dir,{recursive:true});
  const exe=dir+(process.platform==='win32'?'/model.exe':'/model');
  if(fs.existsSync(exe)) return dir;
  const name='A2UpperBodyRobustA'+arch;
  const mos=[
    'setCommandLineOptions("--maxSizeLinearTearing=300");',
    'loadModel(Modelica,{"4.1.0"},requireExactVersion=true);',
    'loadFile("'+lib+'");',
    'loadFile("'+exp+'");',
    'loadString("model '+name+' extends ModelicaHumanBodyPArtsArticle2UpperBody.UpperBodyRobustnessCase(studyArchitecture='+arch+'); end '+name+';");',
    'print(getErrorString());',
    'b:=buildModel('+name+',startTime=0,stopTime=1.5,numberOfIntervals=750,tolerance=1e-8,method="dassl",outputFormat="csv",fileNamePrefix="model",variableFilter="'+filter+'");',
    'print(getErrorString());'
  ].join('\n');
  fs.writeFileSync(dir+'/build.mos',mos);
  const q=spawnSync(omc,['build.mos'],{cwd:dir,encoding:'utf8',timeout:900000,maxBuffer:50e6});
  fs.writeFileSync(dir+'/build.log',(q.stdout||'')+'\n'+(q.stderr||''));
  if(q.status!==0||!fs.existsSync(exe)) throw Error('build A'+arch+' failed; see '+dir+'/build.log');
  return dir;
}

const cond=supplementary.campaigns.robustness.filter(c=>c.architecture===1).map(c=>({tag:c.condition,ankle:c.overrides.studyAnkleAmplitude,hip:c.overrides.studyHipAmplitude,mu:c.overrides.studyFriction,kn:c.overrides.studyNormalStiffness,q:c.overrides.studyFreeAnkle}));
if(cond.length!==15||supplementary.campaigns.robustness.length!==45) throw Error('Expected 15 conditions x 3 architectures');
const knownDir=path.join(out,'known_answer');fs.mkdirSync(knownDir,{recursive:true});
const knownMOS=['if not loadModel(Modelica,{"4.1.0"},requireExactVersion=true) then exit(1); end if;','loadFile("'+lib.replaceAll('\\','/')+'");','loadFile("'+exp.replaceAll('\\','/')+'");','simulate(ModelicaHumanBodyPArtsArticle2UpperBody.UpperBodyInertiaKnownAnswer,stopTime=0.5,numberOfIntervals=1000,tolerance=1e-10,method="dassl",outputFormat="csv",fileNamePrefix="known",variableFilter="time|checksPassed|expectedTorque|measuredTorque|add.addedMass|add.yawInertiaAboutBase",simflags="-maxStepSize=0.0005");','print(getErrorString());'].join('\n');
fs.writeFileSync(path.join(knownDir,'run.mos'),knownMOS);
const knownRun=spawnSync(omc,['run.mos'],{cwd:knownDir,encoding:'utf8',timeout:300000,maxBuffer:20e6});
const knownLog=(knownRun.stdout||'')+'\n'+(knownRun.stderr||'');fs.writeFileSync(path.join(knownDir,'run.log'),knownLog);
if(knownRun.status!==0||!fs.existsSync(path.join(knownDir,'known_res.csv'))||!/The simulation finished successfully/.test(knownLog)) throw Error('Upper-body known-answer failed');
const kd=parseCsv(path.join(knownDir,'known_res.csv')); const kc=name=>{const j=kd.h.indexOf(name);if(j<0) throw Error('Known-answer missing '+name);return kd.R.map(r=>r[j]);};
const ke=kc('expectedTorque'),km=kc('measuredTorque');const kt=Math.max(...ke.map((v,i)=>Math.abs(Math.abs(v)-Math.abs(km[i]))));
const ksummary={status:'PASS',torqueError:kt,checksPassed:kc('checksPassed').at(-1),finalTime:kc('time').at(-1),massError:Math.max(...kc('add.addedMass').map(v=>Math.abs(v-12.615))),inertiaError:Math.max(...kc('add.yawInertiaAboutBase').map(v=>Math.abs(v-0.34314807897)))};
if(!Number.isFinite(kt)||kt>=1e-8||ksummary.checksPassed<1||ksummary.finalTime<0.499||ksummary.finalTime>0.505||ksummary.massError>=1e-9||ksummary.inertiaError>=1e-10) throw Error('Upper-body analytical inertia gate failed');
fs.writeFileSync(path.join(knownDir,'summary.json'),JSON.stringify(ksummary,null,2));

const builds={};
for(const a of [1,2,3]){console.log('BUILD A'+a); builds[a]=build(a);}

const res=[];
for(const c of cond){
  for(const arch of [1,2,3]){
    const tag=`${c.tag}_A${arch}`;
    const csv=out+'/'+tag+'.csv', log=out+'/'+tag+'.log';
    if(!fs.existsSync(csv)){
      const exe=builds[arch]+(process.platform==='win32'?'/model.exe':'/model');
      const ov=`studyAnkleAmplitude=${c.ankle},studyHipAmplitude=${c.hip},studyFriction=${c.mu},studyNormalStiffness=${c.kn},studyFreeAnkle=${c.q}`;
      const q=spawnSync(exe,['-r='+csv,'-override='+ov,'-lv=LOG_STATS','-maxStepSize=0.004'],{
        cwd:builds[arch],encoding:'utf8',timeout:300000,maxBuffer:30e6,
        env:{...process.env,PATH:path.dirname(omc)+path.delimiter+(process.env.PATH||'')}
      });
      fs.writeFileSync(log,(q.stdout||'')+'\n'+(q.stderr||''));
    }
    let status='FAIL',m={},error=null;
    try{
      if(!fs.existsSync(csv))throw Error('no csv');
      m=metrics(csv);
      if(!m.checksPassed||m.checksPassed.final<1||!Number.isFinite(m.finalTime)||m.finalTime<1.499||m.finalTime>1.505)throw Error('runtime gate');
      const runLog=fs.readFileSync(log,'utf8');
      if(!/The simulation finished successfully/.test(runLog)||/LOG_ASSERT\s*\|\s*(error|debug)|simulation terminated|assertion has been violated|Execution failed!/i.test(runLog))throw Error('completion log gate');
      if(!m.energyResidual||!Number.isFinite(m.energyResidual.maxAbs)||m.energyResidual.maxAbs>=0.01)throw Error('energy residual');
      status='PASS';
    }catch(e){error=String(e);}
    res.push({condition:c.tag,settings:c,arch,status,error,metrics:m});
    fs.writeFileSync(out+'/robustness_summary.json',JSON.stringify(res,null,2));
    console.log(tag+' '+status);
  }
}
fs.writeFileSync(out+'/robustness_summary.json',JSON.stringify(res,null,2));
console.log('DONE '+res.length+' cases; '+res.filter(x=>x.status==='PASS').length+' PASS');

if(res.some(x=>x.status!=='PASS'))process.exitCode=1;
