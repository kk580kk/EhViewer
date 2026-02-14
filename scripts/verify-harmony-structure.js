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

// 检查 HarmonyOS SDK 路径配置 (local.properties)
const localProps = path.join(ROOT, 'local.properties');
if (fs.existsSync(localProps)) {
  const content = fs.readFileSync(localProps, 'utf8');
  const match = content.match(/hwsdk\.dir\s*=\s*(.+)/);
  if (!match || !match[1].trim()) {
    console.error('local.properties 中请设置 hwsdk.dir 为你的 OpenHarmony/HarmonyOS SDK 目录，例如：');
    console.error('  hwsdk.dir=/Volumes/Brave 2T/OpenHarmony/Sdk');
    failed++;
  }
} else {
  console.error('缺少 local.properties，请创建并设置 hwsdk.dir（SDK 路径）');
  failed++;
}

if (failed > 0) {
  process.exit(1);
}
console.log('HarmonyOS project structure OK');
