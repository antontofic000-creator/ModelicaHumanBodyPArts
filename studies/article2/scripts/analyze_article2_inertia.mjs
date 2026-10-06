import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const orig=path.resolve(process.argv[2]||path.join(root,'results/robustness'));
const upper=path.resolve(process.argv[3]||path.join(root,'results/upper_body_inertia/robustness'));
const output=path.resolve(process.argv[4]||path.join(root,'robustness_compare_analysis.json'));
const casePath=(folder,tag)=>{const candidates=[path.join(folder,tag+'.csv'),path.join(folder,'rob_'+tag,'model_res.csv'),path.join(folder,'robustness','rob_'+tag,'model_res.csv')];const p=candidates.find(fs.existsSync);if(!p)throw Error('Missing condition '+tag+' in '+folder);return p;};
const conditions=[];
for(const a of [10,15,20]) for(const h of [0.5,1,1.5]) conditions.push(`drive_a${a}_h${String(h).replace('.','p')}`);
conditions.push('fric_0p45','fric_0p75','kn_100000','kn_400000','posture_am0p02','posture_a0');
const outputs=[
  ['pelvisYaw','Pelvis yaw'],
  ['thoraxYaw','Thorax yaw'],
  ['freeDeltaHip[1]','Free-side x'],
  ['heelShare','Heel share'],
  ['stanceAxis','Stance-axis angle'],
  ['groundForce[1]','Horizontal ground force'],
  ['groundMoment[3]','Ground yaw moment'],
  ['body.cutMomentsWorld[7,3]','Axial lumbar cut moment']
];

function parseCSV(file){
  const lines=fs.readFileSync(file,'utf8').trim().split(/\r?\n/);
  const header=(lines.shift().match(/"(?:[^"]|"")*"|[^,]+/g)||[]).map(x=>x.replaceAll('"','').trim());
  const idx=new Map(header.map((x,i)=>[x,i]));
  const rows=lines.map(line=>line.split(',').map(Number));
  return {idx,rows};
}
function series(D,name){
  const ti=D.idx.get('time'), j=D.idx.get(name); if(j===undefined) throw Error('missing '+name);
  const a=[];
  for(const r of D.rows){
    const t=r[ti], y=r[j];
    if(t>1.500000001) continue;
    if(a.length && Math.abs(a.at(-1)[0]-t)<1e-12) a[a.length-1]=[t,y]; else a.push([t,y]);
  }
  return a;
}
function interp(s,t){
  let lo=0,hi=s.length-1;
  if(t<=s[0][0])return s[0][1];
  if(t>=s[hi][0])return s[hi][1];
  while(hi-lo>1){const m=(lo+hi)>>1;if(s[m][0]<=t)lo=m;else hi=m;}
  const [t0,y0]=s[lo],[t1,y1]=s[hi];
  if(Math.abs(t1-t0)<1e-15)return y1;
  return y0+(y1-y0)*(t-t0)/(t1-t0);
}
function med(a){const b=[...a].sort((x,y)=>x-y),n=b.length;return n%2?b[(n-1)/2]:(b[n/2-1]+b[n/2])/2;}
function analyze(folder){
  const per=[];
  const grid=Array.from({length:751},(_,i)=>i*0.002);
  for(const c of conditions){
    const D={};
    for(const arch of [1,2,3]) D[arch]=parseCSV(casePath(folder,`${c}_A${arch}`));
    const row={condition:c,outputs:{}};
    for(const [name,label] of outputs){
      const S={};for(const arch of [1,2,3]){const s=series(D[arch],name);S[arch]=grid.map(t=>interp(s,t));}
      let EA=0,EB=0,tEA=0,tEB=0;
      for(let i=0;i<grid.length;i++){
        const a=Math.abs(S[1][i]-S[3][i]),b=Math.abs(S[2][i]-S[3][i]);
        if(a>EA){EA=a;tEA=grid[i];} if(b>EB){EB=b;tEB=grid[i];}
      }
      row.outputs[name]={label,EA,EB,eta:100*EB/Math.max(EA,1e-15),tEA,tEB};
    }
    per.push(row);
  }
  const summary={};
  for(const [name,label] of outputs){
    const vals=per.map(x=>x.outputs[name]);
    summary[name]={
      label,
      pass5:vals.filter(x=>x.eta<=5).length,
      pass10:vals.filter(x=>x.eta<=10).length,
      pass20:vals.filter(x=>x.eta<=20).length,
      medianEta:med(vals.map(x=>x.eta)),
      maxEta:Math.max(...vals.map(x=>x.eta)),
      medianEB:med(vals.map(x=>x.EB)),
      maxEB:Math.max(...vals.map(x=>x.EB)),
      fail10:per.filter(x=>x.outputs[name].eta>10).map(x=>({condition:x.condition,eta:x.outputs[name].eta,EB:x.outputs[name].EB}))
    };
  }
  return {conditions:per,summary};
}
const result={original:analyze(orig),upperBody:analyze(upper)};
for(const name of Object.keys(result.original.summary)){
  const a=result.original.summary[name],b=result.upperBody.summary[name];
  b.changePass10=b.pass10-a.pass10;
  b.originalPass10=a.pass10;
}
fs.mkdirSync(path.dirname(output),{recursive:true});
fs.writeFileSync(output,JSON.stringify(result,null,2)+'\n');
console.log('ORIGINAL');
for(const [n,s] of Object.entries(result.original.summary))console.log(n,s);
console.log('\nUPPER BODY');
for(const [n,s] of Object.entries(result.upperBody.summary))console.log(n,s);