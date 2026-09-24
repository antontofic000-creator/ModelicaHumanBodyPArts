import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const root='C:/Users/toufi/LynkorrContactDevelopment_20260923_135626';
const source=root+'/ModelicaHumanBodyPArts_v0_10_0_RC1.mo';
const manifest=JSON.parse(fs.readFileSync(root+'/v010_test_manifest.json','utf8'));
const omc='C:/Program Files/OpenModelica1.27.1-64bit/bin/omc.exe';
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
if(sha(source)!==manifest.source_sha256) throw Error('hash mismatch '+sha(source));
const stamp=new Date().toISOString().replace(/[-:.TZ]/g,'');
const run=root+'/v010_native_run_'+stamp;fs.mkdirSync(run);
fs.copyFileSync(source,run+'/source_snapshot.mo');fs.copyFileSync(root+'/v010_test_manifest.json',run+'/test_manifest.json');
const results=[];const fatal=/(?:\b(?:error|fatal)\s*:|LOG_ASSERT\s*\|\s*error|division by zero|assertion[^\n]*failed)/im;
function parseCSV(p,c){const lines=fs.readFileSync(p,'utf8').trim().split(/\r?\n/);const h=(lines.shift().match(/"(?:[^"]|"")*"|[^,]+/g)||[]).map(x=>x.replaceAll('"','').trim());const ti=h.indexOf('time'),ci=h.indexOf('checksPassed');if(ti<0||ci<0)throw Error('missing time/checks');const rows=lines.map(l=>l.split(',').map(Number));const last=rows.at(-1),first=rows[0];if(Math.abs(last[ti]-c.stop)>1e-7||Math.abs(first[ti])>1e-7||last[ci]<1)throw Error('completion gate failed');return {rows:rows.length,final_time:last[ti],checksPassed:last[ci]};}
for(let ix=0;ix<manifest.cases.length;ix++){const c=manifest.cases[ix],d=run+'/'+c.name;fs.mkdirSync(d);const rec={...c,status:'FAIL'};try{
 const mos=`ok:=loadModel(Modelica,{"4.1.0"},requireExactVersion=true); if not ok then print(getErrorString());exit(10);end if;
ok:=loadFile("${source.replaceAll('\\','/')}",requireExactVersion=true); if not ok then print(getErrorString());exit(11);end if;
print("MSL="+getVersion(Modelica)+"\\n"); print("LIB="+getVersion(ModelicaHumanBodyPArts)+"\\n");
b:=buildModel(${c.model},startTime=0,stopTime=${c.stop},numberOfIntervals=${c.intervals},tolerance=1e-8,method="dassl",outputFormat="csv",fileNamePrefix="model"); print(getErrorString()); print("EXEC="+b[1]+"\\n");`;
 fs.writeFileSync(d+'/build.mos',mos);const b=spawnSync(omc,['build.mos'],{cwd:d,encoding:'utf8',timeout:600000,maxBuffer:50e6});const blog=(b.stdout||'')+'\n'+(b.stderr||'');fs.writeFileSync(d+'/build.log',blog);const exe=d+'/model.exe';if(b.status!==0||fatal.test(blog)||!fs.existsSync(exe)||!fs.existsSync(d+'/model_init.xml'))throw Error('build gate failed');if(!blog.includes('LIB='+manifest.release)||!blog.includes('MSL=4.1.0'))throw Error('version gate failed');
 if(c.kind==='sim'){const rr=spawnSync(exe,['-r=result.csv'],{cwd:d,encoding:'utf8',timeout:600000,maxBuffer:50e6,env:{...process.env,PATH:path.dirname(omc)+';'+(process.env.PATH||'')}});const log=(rr.stdout||'')+'\n'+(rr.stderr||'');fs.writeFileSync(d+'/runtime.log',log);if(rr.status!==0||fatal.test(log))throw Error('runtime gate failed');rec.completion=parseCSV(d+'/result.csv',c);}
 rec.status='PASS';
}catch(e){rec.reason=String(e.message||e);}
rec.hashes={};for(const f of fs.readdirSync(d)){if(/\.(csv|log|xml|exe|mos)$/.test(f))rec.hashes[f]=sha(d+'/'+f);}fs.writeFileSync(d+'/result_status.json',JSON.stringify(rec,null,2));results.push(rec);console.log((ix+1)+'/'+manifest.cases.length+' '+c.name+': '+rec.status+(rec.reason?' - '+rec.reason:''));
}
const summary={status:results.length&&results.every(x=>x.status==='PASS')?'PASS':'FAIL',compiler:spawnSync(omc,['--version'],{encoding:'utf8'}).stdout.trim(),source_sha256:sha(source),release:manifest.release,results,human_validation:'NOT_PERFORMED',dymola:'NOT_RUN'};
fs.writeFileSync(run+'/summary.json',JSON.stringify(summary,null,2));fs.writeFileSync(root+'/v010_latest_native_run.txt',run);console.log('SUMMARY '+summary.status+' '+run);