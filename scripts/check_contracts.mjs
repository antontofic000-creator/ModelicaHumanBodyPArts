// SPDX-License-Identifier: MIT
// External checks of retained CSV output, including fail-closed data-corruption tests.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const args={};for(let i=2;i<process.argv.length;i+=2)args[process.argv[i].replace(/^--/,'')]=process.argv[i+1];
if(!args.release||!args.tutorial||!args.out)throw Error('Usage: node scripts/check_contracts.mjs --release RUN --tutorial RUN --out NEW_JSON');
if(fs.existsSync(args.out))throw Error('Output already exists; refusing to overwrite an audit');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
function read(root,name){const file=path.join(root,name,'result.csv');const ls=fs.readFileSync(file,'utf8').trim().split(/\r?\n/);const h=(ls.shift().match(/"(?:[^"]|"")*"|[^,]+/g)||[]).map(x=>x.replaceAll('"','').trim());return {h,r:ls.map(x=>x.replace(/,$/,'').split(',').map(Number)),file,sha256:hash(file)};}
function col(d,k){const j=d.h.indexOf(k);if(j<0)throw Error('Missing '+k);const x=d.r.map(r=>r[j]);if(!x.length||x.some(v=>!Number.isFinite(v)))throw Error('Nonfinite '+k);return x;}
const last=x=>x[x.length-1],maxabs=x=>x.reduce((a,b)=>Math.max(a,Math.abs(b)),0);
function near(x,y,t,msg){if(!Number.isFinite(x)||Math.abs(x-y)>t)throw Error(msg);}
function bounded(x,t,msg){if(maxabs(x)>t)throw Error(msg);}
function completion(d,stop){const t=col(d,'time'),c=col(d,'checksPassed');near(t[0],0,1e-8,'Start time');near(last(t),stop,1e-7,'End time');if(t.some((v,i)=>i&&v<t[i-1]-1e-12)||last(c)<1)throw Error('Completion stages');}
function known(d){completion(d,.01);near(last(col(d,'totalNormal')),98.1,1e-6,'Known normal load');for(const k of ['heelLoad','midfootLoad','forefootLoad'])near(last(col(d,'contact.'+k)),32.7,1e-6,k);near(last(col(d,'contact.heelShare')),1/3,1e-10,'Heel share');bounded(col(d,'contact.identityResidual'),1e-8,'Contact identity');return {total_normal_N:last(col(d,'totalNormal'))};}
function heel(d){completion(d,.01);near(last(col(d,'contact.heelLoad')),0,1e-9,'Unloaded heel');for(const k of ['midfootLoad','forefootLoad'])near(last(col(d,'contact.'+k)),40,1e-6,k);near(last(col(d,'contact.broadSupport')),0,1e-12,'Broad support should be false');return {heel_load_N:last(col(d,'contact.heelLoad'))};}
function impedance(d){completion(d,.5);bounded(col(d,'energyResidual'),1e-4,'Aggregate impedance energy');near(last(col(d,'body.actualStiffness[1]')),600,1e-7,'Actual stiffness');near(last(col(d,'body.actualDamping[1]')),36,1e-7,'Actual damping');if(Math.min(...col(d,'body.dissipationPower'))< -1e-9)throw Error('Negative dissipation');return {max_energy_residual_J:maxabs(col(d,'energyResidual'))};}
function guided(d){completion(d,.75);const m=col(d,'body.representedMass'),f=col(d,'normalLoad'),a=col(d,'body.representedCOMAcceleration[3]'),g=col(d,'guideVerticalForce'),e=col(d,'totalEnergy'),loss=col(d,'dissipated');
 const force=f.map((v,i)=>v-m[i]*9.81-m[i]*a[i]),energy=e.map((v,i)=>v-e[0]+loss[i]-loss[0]);
 bounded(g,1e-7,'Vertical guide bypass');bounded(force,1e-3,'Independent vertical force balance');bounded(energy,1e-6,'Independent total energy balance');bounded(col(d,'contact.identityResidual'),1e-6,'Contact power identity');
 const zones=Array.from({length:6},(_,i)=>col(d,`contact.zoneNormalForce[${i+1}]`));
 if(zones.some(z=>z.some(v=>v< -1e-9)))throw Error('Tensile contact');
 bounded(f.map((v,i)=>v-zones.reduce((s,z)=>s+z[i],0)),1e-6,'Zone sum mismatch');
 near(last(f),last(m)*9.81,.01*last(m)*9.81,'Final weight support');
 for(let i=1;i<=3;i++)near(last(col(d,`regionalShares[${i}]`)),1/3,1e-8,'Regional symmetry');
 return {represented_mass_kg:last(m),normal_load_min_N:Math.min(...f),normal_load_max_N:Math.max(...f),final_normal_load_N:last(f),weight_N:last(m)*9.81,max_guide_vertical_force_N:maxabs(g),max_force_residual_N:maxabs(force),max_energy_residual_J:maxabs(energy),max_reported_energy_residual_J:maxabs(col(d,'energyResidual')),final_dissipation_J:last(loss),final_regional_shares:[1,2,3].map(i=>last(col(d,`regionalShares[${i}]`)))};
}
function bypass(d){completion(d,.75);near(last(col(d,'bypassObserved')),1,1e-12,'Bypass not detected');const m=last(col(d,'body.representedMass')),f=last(col(d,'groundForce[3]')),z=['heelLoad','midfootLoad','forefootLoad'].reduce((s,k)=>s+last(col(d,'contact.'+k)),0);if(z>=.01*m*9.81||f<=.99*m*9.81)throw Error('Bypass numerical conditions');return {plantar_load_N:z,ideal_support_N:f};}
function pitch(d){completion(d,.75);const m=col(d,'body.representedMass'),f=col(d,'normalLoad'),a=col(d,'body.representedCOMAcceleration[3]'),g=col(d,'guideVerticalForce'),e=col(d,'totalEnergy'),loss=col(d,'dissipated'),work=col(d,'actuatorWork');
 const force=f.map((v,i)=>v-m[i]*9.81-m[i]*a[i]),energy=e.map((v,i)=>v-e[0]+loss[i]-loss[0]-work[i]+work[0]);
 bounded(g,1e-7,'Pitch-case vertical guide reaction');bounded(force,1e-3,'Pitch-case vertical force balance');bounded(energy,1e-6,'Pitch-case actuator-inclusive energy balance');
 if(maxabs(col(d,'heelShareChange'))<=.01)throw Error('Regional redistribution too small');
 if(maxabs(col(d,'guidePitch'))<=1e-5)throw Error('Pitch degree did not move');
 return {max_heel_share_change:maxabs(col(d,'heelShareChange')),max_pitch_rad:maxabs(col(d,'guidePitch')),max_force_residual_N:maxabs(force),max_energy_residual_J:maxabs(energy),final_heel_share:last(col(d,'contact.heelShare'))};
}
function parallel(d){completion(d,.75);const m=col(d,'body.representedMass'),p=col(d,'normalLoad'),b=col(d,'bypassLoad'),t=col(d,'totalSupport'),a=col(d,'body.representedCOMAcceleration[3]'),g=col(d,'guideVerticalForce');
 const force=t.map((v,i)=>v-m[i]*9.81-m[i]*a[i]);bounded(g,1e-7,'Parallel-case vertical guide reaction');bounded(force,1e-3,'Parallel-case force balance');
 const frac=last(p)/last(t),bf=last(b)/last(t);if(!(frac>.80&&frac<.90&&bf>.10&&bf<.20))throw Error('Parallel support shares not detected');
 return {plantar_fraction:frac,bypass_fraction:bf,final_total_support_N:last(t),weight_N:last(m)*9.81,max_force_residual_N:maxabs(force)};
}
const specs=[['release','AuditedPlantarKnownLoadTest',known],['release','AuditedPlantarHeelUnloadTest',heel],['release','LoadedSupportVariableImpedanceEnergyTest',impedance],['tutorial','GuidedStandingContact',guided],['tutorial','GuidedStandingPerturbation',guided],['tutorial','SupportBypassNegativeControl',bypass],['tutorial','GuidedPitchRedistribution',pitch],['tutorial','ParallelSupportNegativeControl',parallel]];
const results=[],data={};for(const [root,name,fn] of specs){try{const d=read(args[root],name);data[name]=d;const metrics=fn(d);results.push({name,status:'PASS',csv_sha256:d.sha256,metrics});}catch(e){results.push({name,status:'FAIL',error:e.message});}}
const negatives=[];const original=data.AuditedPlantarKnownLoadTest;
if(original){for(const kind of ['wrong_value','missing_channel','nonfinite','truncated_time']){const d=structuredClone(original);const j=d.h.indexOf('totalNormal');if(kind==='wrong_value')d.r.at(-1)[j]+=1;if(kind==='missing_channel')d.h[j]='REMOVED';if(kind==='nonfinite')d.r.at(-1)[j]=NaN;if(kind==='truncated_time')d.r=d.r.slice(0,Math.floor(d.r.length/2));let rejected=false;try{known(d);}catch{rejected=true;}negatives.push({kind,rejected});}}
const status=results.length===8&&results.every(r=>r.status==='PASS')&&negatives.length===4&&negatives.every(x=>x.rejected)?'PASS':'FAIL';
const out={status,checker_sha256:hash(fileURLToPath(import.meta.url)),created_utc:new Date().toISOString(),scope:'External numerical checks of eight selected contracts; not human validation or independent authorship',results,negative_data_controls:negatives};
fs.mkdirSync(path.dirname(path.resolve(args.out)),{recursive:true});fs.writeFileSync(args.out,JSON.stringify(out,null,2)+'\n');console.log(JSON.stringify(out,null,2));if(status!=='PASS')process.exit(2);