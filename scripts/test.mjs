import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseVersionTag, evaluateVersionBump } from './check-version.mjs';

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

// Test 5: GEMINI.md Project Rules Exist
const geminiMdPath = path.join(ROOT_DIR, 'GEMINI.md');
assert(fs.existsSync(geminiMdPath), 'GEMINI.md project rules file exists');
if (fs.existsSync(geminiMdPath)) {
  const geminiContent = fs.readFileSync(geminiMdPath, 'utf8');
  assert(geminiContent.includes('Major.Minor.Patch.Revision'), 'GEMINI.md defines 4-part version rule');
  assert(geminiContent.includes('pnpm'), 'GEMINI.md defines pnpm package manager rule');
}

// Test 6: package.json follows 4-part semantic versioning
const pkgPath = path.join(ROOT_DIR, 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const versionParts = pkg.version.split('.');
assert(versionParts.length === 4, `package.json version (${pkg.version}) uses 4-part Major.Minor.Patch.Revision format`);

// Test 7: Version Checker Unit Tests (evaluateVersionBump)
console.log('--- Version Bump Qualification Tests ---');

// Case A: Minor bump (patch=0, revision=0)
const resMinor = evaluateVersionBump('v0.2.0.0', []);
assert(resMinor.shouldBuild === true, 'Minor bump (v0.2.0.0) qualifies for build');

// Case B: Major bump (minor=0, patch=0, revision=0)
const resMajor = evaluateVersionBump('v1.0.0.0', []);
assert(resMajor.shouldBuild === true, 'Major bump (v1.0.0.0) qualifies for build');

// Case C: Patch bump (patch=1, revision=0)
const resPatch = evaluateVersionBump('v0.2.1.0', []);
assert(resPatch.shouldBuild === false, 'Patch bump (v0.2.1.0) is correctly skipped');

// Case D: Revision bump (patch=0, revision=1)
const resRev = evaluateVersionBump('v0.2.0.1', []);
assert(resRev.shouldBuild === false, 'Revision bump (v0.2.0.1) is correctly skipped');

// Case E: Compare with historical tags
const resHigher = evaluateVersionBump('v0.3.0.0', ['v0.2.0.0', 'v0.1.0.0']);
assert(resHigher.shouldBuild === true, 'v0.3.0.0 is higher than v0.2.0.0 and qualifies');

const resLower = evaluateVersionBump('v0.2.0.0', ['v0.3.0.0']);
assert(resLower.shouldBuild === false, 'v0.2.0.0 is lower than v0.3.0.0 and is rejected');

console.log('------------------------------------------------------------------');
if (failures > 0) {
  console.error(`Test run failed with ${failures} error(s).`);
  process.exit(1);
} else {
  console.log('All framework validation tests passed!');
  process.exit(0);
}
