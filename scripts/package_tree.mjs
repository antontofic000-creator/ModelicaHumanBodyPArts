// SPDX-License-Identifier: MIT
// Lossless storage-only conversion of the immutable v0.10.0 source.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const src=path.join(repo,'src/ModelicaHumanBodyPArts_v0_10_0_RC1.mo');
const dest=path.join(repo,'ModelicaHumanBodyPArts');
const expected='2fda3b797ef9304529776d0610a3a8608e233c92531924579cb2eafe6665de4b';
const hash=s=>crypto.createHash('sha256').update(s).digest('hex');
const text=fs.readFileSync(src,'utf8');
if(hash(text)!==expected)throw Error('Source bytes differ from v0.10.0; use core.autocrlf=false.');
const matches=[...text.matchAll(/^  package (\w+)[^\n]*\n/gm)];
if(matches.length!==19)throw Error(`Unexpected top-level package count: ${matches.length}`);
const lastEnd=text.lastIndexOf('end ModelicaHumanBodyPArts;');
const prefix=text.slice(0,matches[0].index), suffix=text.slice(lastEnd);
const generated=new Map([['package.mo',prefix+suffix],['package.order',matches.map(x=>x[1]).join('\n')+'\n']]);
for(let i=0;i<matches.length;i++){
 const m=matches[i], end=i+1<matches.length?matches[i+1].index:lastEnd;
 const block=text.slice(m.index,end);
 if(!new RegExp('^  end '+m[1]+';','m').test(block))throw Error('Unclosed package '+m[1]);
 generated.set(m[1]+'/package.mo','within ModelicaHumanBodyPArts;\n'+block);
}
const check=process.argv.includes('--check');
for(const [p,s] of generated){const f=path.join(dest,p);if(check){if(!fs.existsSync(f)||fs.readFileSync(f,'utf8')!==s)throw Error('Generated tree differs: '+p);}else{fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,s);}}
const reconstructed=prefix+matches.map(m=>fs.readFileSync(path.join(dest,m[1],'package.mo'),'utf8').replace(/^within ModelicaHumanBodyPArts;\n/,'')).join('')+suffix;
if(hash(reconstructed)!==expected)throw Error('Round-trip failed');
console.log(JSON.stringify({status:'PASS',storage_only:true,packages:matches.map(m=>m[1]),source_sha256:expected,reconstructed_sha256:hash(reconstructed),generated_files:generated.size},null,2));
