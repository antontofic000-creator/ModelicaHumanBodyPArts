import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2] || '.');
const output = process.argv[3] ? path.resolve(process.argv[3]) : path.join(root, 'generated', 'smoke');
const cases = ['UpperBodyKnownAnswer', 'PrimaryLocked', 'PrimaryYawOnly', 'PrimaryFull3D', 'UpperBodyLocked', 'UpperBodyYawOnly', 'UpperBodyFull3D'];
const results = [];
for (const id of cases) {
  const known = id === 'UpperBodyKnownAnswer';
  const row = { id, status: 'FAIL', expected_final_time: known ? 0.5 : 1.5 };
  try {
    const file = path.join(output, id + '_res.csv');
    const lines = fs.readFileSync(file, 'utf8').trim().split(/\r?\n/);
    const header = (lines.shift().match(/"(?:[^"]|"")*"|[^,]+/g) || []).map(x => x.replaceAll('"', '').trim());
    const data = lines.filter(Boolean).map(x => x.split(',').map(Number));
    if (!data.length) throw Error('Empty result file');
    const channel = name => {
      const j = header.indexOf(name);
      if (j < 0) throw Error('Missing channel: ' + name);
      const values = data.map(x => x[j]);
      if (!values.every(Number.isFinite)) throw Error('Non-finite channel: ' + name);
      return values;
    };
    const times = channel('time'), checks = channel('checksPassed');
    row.final_time = times.at(-1); row.checks_passed = checks.at(-1);
    if (Math.abs(times[0]) > 1e-9 || row.final_time < row.expected_final_time - 0.001 || row.final_time > row.expected_final_time + 0.005) throw Error('Incomplete or unexpected final time');
    if (row.checks_passed < 1) throw Error('Internal model assertions did not complete');
    const log = fs.readFileSync(path.join(output, id + '.log'), 'utf8');
    if (!/The simulation finished successfully/.test(log)) throw Error('No successful completion in log');
    if (/LOG_ASSERT\s*\|\s*(?:error|debug)|simulation terminated|assertion has been violated|Execution failed!/i.test(log)) throw Error('Fatal assertion in log');
    if (known) {
      const expected = channel('expectedTorque'), measured = channel('measuredTorque');
      row.max_torque_error_Nm = Math.max(...expected.map((v, i) => Math.abs(Math.abs(v) - Math.abs(measured[i]))));
      row.max_mass_error_kg = Math.max(...channel('add.addedMass').map(v => Math.abs(v - 12.615)));
      row.max_yaw_inertia_error_kg_m2 = Math.max(...channel('add.yawInertiaAboutBase').map(v => Math.abs(v - 0.34314807897)));
      if (row.max_torque_error_Nm >= 1e-8 || row.max_mass_error_kg >= 1e-9 || row.max_yaw_inertia_error_kg_m2 >= 1e-10) throw Error('Known-answer inertia gate failed');
    } else {
      row.max_abs_energy_residual_J = Math.max(...channel('energyResidual').map(Math.abs));
      if (row.max_abs_energy_residual_J >= 0.01) throw Error('Archived energy gate failed');
    }
    row.status = 'PASS';
  } catch (e) { row.reason = e.message; }
  results.push(row);
  console.log(id + ': ' + row.status + (row.reason ? ' (' + row.reason + ')' : ''));
}
let environment = {};
try { environment = JSON.parse(fs.readFileSync(path.join(root, 'test_environment.json'), 'utf8')); } catch (e) { environment.error = e.message; }
const pass = results.every(x => x.status === 'PASS') && environment.modelica === '4.1.0';
fs.writeFileSync(path.join(root, 'test_summary.json'), JSON.stringify({ schema_version: 1, status: pass ? 'PASS' : 'FAIL', environment, energy_gate_J: 0.01, cases: results }, null, 2) + '\n');
if (!pass) process.exitCode = 1;
