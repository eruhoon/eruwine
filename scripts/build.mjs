import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const DIST_DIR = path.join(ROOT_DIR, 'dist');
const TEMPLATE_DIR = path.join(ROOT_DIR, 'template');
const PORTS_DIR = path.join(ROOT_DIR, 'ports');

const pkgPath = path.join(ROOT_DIR, 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

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
console.log(`Building Eruwine Universal Framework Dist Artifacts (v${pkg.version})`);
console.log('==================================================================');

// 1. Clean dist directory
if (fs.existsSync(DIST_DIR)) {
  console.log('[1/5] Cleaning existing dist directory...');
  fs.rmSync(DIST_DIR, { recursive: true, force: true });
}
fs.mkdirSync(DIST_DIR, { recursive: true });

// 2. Copy master template files
console.log('[2/5] Assembling port template distribution package...');
const distTemplateFolder = path.join(DIST_DIR, 'eruwine');
const distTemplateScript = path.join(DIST_DIR, 'eruwine.sh');

copyRecursiveSync(path.join(TEMPLATE_DIR, 'eruwine'), distTemplateFolder);
copyRecursiveSync(path.join(TEMPLATE_DIR, 'eruwine.sh'), distTemplateScript);
fs.chmodSync(distTemplateScript, 0o755);

// 3. Copy sample ports if present
if (fs.existsSync(PORTS_DIR) && fs.readdirSync(PORTS_DIR).length > 0) {
  console.log('[3/5] Packaging reference ports...');
  const distPortsFolder = path.join(DIST_DIR, 'ports');
  copyRecursiveSync(PORTS_DIR, distPortsFolder);
}

// 4. Copy Documentation into dist
console.log('[4/5] Copying documentation into dist...');
if (fs.existsSync(path.join(ROOT_DIR, 'HOW_TO_USE.md'))) {
  fs.copyFileSync(path.join(ROOT_DIR, 'HOW_TO_USE.md'), path.join(DIST_DIR, 'HOW_TO_USE.md'));
}
if (fs.existsSync(path.join(ROOT_DIR, 'README.md'))) {
  fs.copyFileSync(path.join(ROOT_DIR, 'README.md'), path.join(DIST_DIR, 'README.md'));
}

// 5. Create Release Zip Archives
console.log('[5/5] Creating release distribution zip archives...');
const zipFilesToInclude = ['eruwine.sh', 'eruwine'];
if (fs.existsSync(path.join(DIST_DIR, 'HOW_TO_USE.md'))) zipFilesToInclude.push('HOW_TO_USE.md');
if (fs.existsSync(path.join(DIST_DIR, 'README.md'))) zipFilesToInclude.push('README.md');
if (fs.existsSync(path.join(DIST_DIR, 'ports'))) zipFilesToInclude.push('ports');

const releaseZipName = `eruwine-v${pkg.version}.zip`;
const genericZipName = 'eruwine.zip';
const releaseZipPath = path.join(DIST_DIR, releaseZipName);
const genericZipPath = path.join(DIST_DIR, genericZipName);

try {
  // Try using system zip utility
  const zipCmd = `zip -r -q "${releaseZipName}" ${zipFilesToInclude.join(' ')}`;
  execSync(zipCmd, { cwd: DIST_DIR, stdio: 'inherit' });
  fs.copyFileSync(releaseZipPath, genericZipPath);

  const stats = fs.statSync(releaseZipPath);
  console.log(`  • Created ${releaseZipName} (${(stats.size / 1024).toFixed(1)} KB)`);
  console.log(`  • Created ${genericZipName} (${(stats.size / 1024).toFixed(1)} KB)`);
} catch (err) {
  console.warn(`[WARN] System zip utility unavailable or failed: ${err.message}. Release zip skipped.`);
}

console.log('\n[SUCCESS] Eruwine Framework build completed successfully!');
console.log(`Dist output directory: ${DIST_DIR}`);
