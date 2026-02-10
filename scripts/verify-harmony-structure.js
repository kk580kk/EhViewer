#!/usr/bin/env node
/**
 * Verify HarmonyOS project structure and config files.
 * Run with: node scripts/verify-harmony-structure.js
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

const requiredFiles = [
  'oh-package.json5',
  'build-profile.json5',
  'hvigorfile.ts',
  'hvigor-config.json5',
  'entry/oh-package.json5',
  'entry/build-profile.json5',
  'entry/hvigorfile.ts',
  'entry/src/main/module.json5',
  'entry/src/main/ets/entryability/EntryAbility.ets',
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/resources/base/profile/main_pages.json',
  'entry/src/main/resources/base/element/string.json',
  'entry/src/main/resources/base/element/color.json',
  'entry/src/main/resources/base/media/icon.png',
];

let failed = 0;

requiredFiles.forEach((rel) => {
  const full = path.join(ROOT, rel);
  if (!fs.existsSync(full)) {
    console.error('Missing:', rel);
    failed++;
  }
});

const buildProfile = path.join(ROOT, 'build-profile.json5');
if (fs.existsSync(buildProfile)) {
  const content = fs.readFileSync(buildProfile, 'utf8');
  if (!content.includes('entry') || !content.includes('subProjects')) {
    console.error('build-profile.json5 must have subProjects containing "entry"');
    failed++;
  }
}

const moduleJson = path.join(ROOT, 'entry/src/main/module.json5');
if (fs.existsSync(moduleJson)) {
  const content = fs.readFileSync(moduleJson, 'utf8');
  if (!content.includes('EntryAbility') || !content.includes('abilities')) {
    console.error('module.json5 must define abilities and EntryAbility');
    failed++;
  }
}

if (failed > 0) {
  process.exit(1);
}
console.log('HarmonyOS project structure OK');
