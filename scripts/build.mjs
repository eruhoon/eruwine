import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const DIST_DIR = path.join(ROOT_DIR, 'dist');
const TEMPLATE_DIR = path.join(ROOT_DIR, 'template');
const PORTS_DIR = path.join(ROOT_DIR, 'ports');

function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();
  if (isDirectory) {
    fs.mkdirSync(dest, { recursive: true });
    fs.readdirSync(src).forEach((childItemName) => {
      copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName));
    });
  } else {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }
}

console.log('==================================================================');
console.log('Building Eruwine Universal Framework Dist Artifacts');
console.log('==================================================================');

// Clean dist directory
if (fs.existsSync(DIST_DIR)) {
  console.log('[1/4] Cleaning existing dist directory...');
  fs.rmSync(DIST_DIR, { recursive: true, force: true });
}
fs.mkdirSync(DIST_DIR, { recursive: true });

// Copy master template files
console.log('[2/4] Assembling port template distribution package...');
const distTemplateFolder = path.join(DIST_DIR, 'eruwine');
const distTemplateScript = path.join(DIST_DIR, 'eruwine.sh');

copyRecursiveSync(path.join(TEMPLATE_DIR, 'eruwine'), distTemplateFolder);
copyRecursiveSync(path.join(TEMPLATE_DIR, 'eruwine.sh'), distTemplateScript);
fs.chmodSync(distTemplateScript, 0o755);

// Copy sample ports if present
if (fs.existsSync(PORTS_DIR) && fs.readdirSync(PORTS_DIR).length > 0) {
  console.log('[3/4] Packaging reference ports...');
  const distPortsFolder = path.join(DIST_DIR, 'ports');
  copyRecursiveSync(PORTS_DIR, distPortsFolder);
}

// Copy Documentation into dist
console.log('[4/4] Copying documentation into dist...');
if (fs.existsSync(path.join(ROOT_DIR, 'HOW_TO_USE.md'))) {
  fs.copyFileSync(path.join(ROOT_DIR, 'HOW_TO_USE.md'), path.join(DIST_DIR, 'HOW_TO_USE.md'));
}

console.log('\n[SUCCESS] Eruwine Framework build completed successfully!');
console.log(`Dist output directory: ${DIST_DIR}`);
