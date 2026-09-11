import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const out='outputs/recaudaciones';
const w=await SpreadsheetFile.importXlsx(await FileBlob.load('EXCEL UTILITARIOS/Formato Libro Recaudaciones.xlsx'));
const f=w.worksheets.getItem('Formato'), d=w.worksheets.getItem('Datos');
await fs.writeFile(`${out}/before.png`,new Uint8Array(await (await w.render({sheetName:'Formato',range:'A1:H3',scale:1})).arrayBuffer()));
if(process.argv.includes('--inspect')) {console.log(w.help('table.resize',{maxChars:1800}).ndjson);process.exit(0);}
const dh=d.getRange('A1:CI1').values[0], fh=f.getRange('A1:CH1').values[0];
f.tables.items[0].rows.add(null,Array.from({length:12},()=>Array(16384).fill(null)));
const col=n=>{let s='';for(n++;n;n=Math.floor((n-1)/26))s=String.fromCharCode(65+(n-1)%26)+s;return s;};
for(let j=0;j<86;j++){
 const k=dh.findIndex(h=>h.toLowerCase()===fh[j].toLowerCase());
 if(k<0) throw Error(fh[j]);
 f.getRange(`${col(j)}2:${col(j)}14`).formulas=Array.from({length:13},(_,i)=>[`=IF('Datos'!${col(k)}${i+2}="","",'Datos'!${col(k)}${i+2})`]);
 if(fh[j].startsWith('Fecha'))f.getRange(`${col(j)}2:${col(j)}14`).setNumberFormat(fh[j]==='FechaContabilizacion'?'dd/mm/yyyy hh:mm:ss':'dd/mm/yyyy');
}
f.getRange('A1:CH14').format.autofitColumns();
w.recalculate();
console.log((await w.inspect({kind:'table',range:'Formato!A1:H4',tableMaxCols:8,tableMaxRows:4,maxChars:2500})).ndjson);
console.log((await w.inspect({kind:'match',range:'Formato!A2:CH14',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!',options:{useRegex:true,maxResults:10},maxChars:1000})).ndjson);
await fs.writeFile(`${out}/after.png`,new Uint8Array(await (await w.render({sheetName:'Formato',range:'A1:H5',scale:1})).arrayBuffer()));
await (await SpreadsheetFile.exportXlsx(w)).save(`${out}/Formato Libro Recaudaciones.xlsx`);
process.exit(0);
