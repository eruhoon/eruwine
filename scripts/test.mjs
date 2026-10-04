import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const TEMPLATE_DIR = path.join(ROOT_DIR, 'template');

let failures = 0;

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ [FAIL] ${message}`);
    failures++;
  } else {
    console.log(`✅ [PASS] ${message}`);
  }
}

console.log('==================================================================');
console.log('Running Eruwine Framework Automated Validation Tests');
console.log('==================================================================');

// Test 1: Template Launcher Script Exists
assert(fs.existsSync(path.join(TEMPLATE_DIR, 'eruwine.sh')), 'Master launcher script template (eruwine.sh) exists');

// Test 2: Template Folder Exists
assert(fs.existsSync(path.join(TEMPLATE_DIR, 'eruwine')), 'Port directory template folder (eruwine) exists');

// Test 3: Check port.conf inside template
const confPath = path.join(TEMPLATE_DIR, 'eruwine', 'port.conf');
assert(fs.existsSync(confPath), 'port.conf exists in template folder');

if (fs.existsSync(confPath)) {
  const confContent = fs.readFileSync(confPath, 'utf8');
  assert(confContent.includes('GAME_NAME='), 'port.conf contains GAME_NAME');
  assert(confContent.includes('WINE_RENDERER='), 'port.conf contains WINE_RENDERER');
}

// Test 4: keymap.gptk Template Exists
assert(fs.existsSync(path.join(TEMPLATE_DIR, 'eruwine', 'keymap.gptk')), 'keymap.gptk template file exists');

console.log('------------------------------------------------------------------');
if (failures > 0) {
  console.error(`Test run failed with ${failures} error(s).`);
  process.exit(1);
} else {
  console.log('All framework validation tests passed!');
  process.exit(0);
}
