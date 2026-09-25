import fs from 'node:fs'; import {spawnSync} from 'node:child_process';
const root='C:/Users/toufi/LynkorrContactDevelopment_20260923_135626';
const out=root+'/A2_V010_REPRO_20260924';
const runner=out+'/run_article2_v010_case.mjs';
const inv=0.115275665089173, summary=[];
for(const side of ['R','L'])for(const arch of [1,2,3]){
  const id=`nominal_${side}_A${arch}_v010`, spec={id,modifiers:`rightStance=${side==='R'},architecture=${arch},ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,${inv}}`,stop:1.5,intervals:750,maxStep:0.004,family:'A2_V010_NOMINAL'};
  const sp=out+'/'+id+'.json'; if(!fs.existsSync(out+'/'+id+'/result.json')){fs.writeFileSync(sp,JSON.stringify(spec,null,2)); console.log('START '+id); spawnSync(process.execPath,[runner,sp],{encoding:'utf8',timeout:900000,maxBuffer:50e6});}
  const f=out+'/'+id+'/result.json',j=fs.existsSync(f)?JSON.parse(fs.readFileSync(f,'utf8')):{id,status:'NO_RESULT'},d=j.diagnostics||{};
  summary.push({id,status:j.status,pelvis:d.pelvisYaw,lumbar:d.lumbarYaw,thorax:d.thoraxYaw,heel:d.heelShare,broad:d.broadSupport,axis:d.stanceAxis,freeX:d['freeDeltaHip[1]'],Fx:d['groundForce[1]'],Mz:d['groundMoment[3]'],energy:d.energyResidual,lumbarM:d['body.cutMomentsWorld[7,3]']});
  fs.writeFileSync(out+'/nominal_summary_v010.json',JSON.stringify(summary,null,2)); console.log(id+' '+j.status);
}
console.log('DONE '+summary.length);