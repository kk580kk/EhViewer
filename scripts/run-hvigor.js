#!/usr/bin/env node
/**
 * HarmonyOS 构建入口：通过 ohpm 安装的插件执行构建。
 * 使用方式: node scripts/run-hvigor.js assembleHap --mode module -p product=default
 */
const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const args = process.argv.slice(2);

function run(cmd, a, opts = {}) {
  const r = spawnSync(cmd, a, { stdio: 'inherit', cwd: ROOT, ...opts });
  if (r.status !== 0) process.exit(r.status != null ? r.status : 1);
}

// 若未安装依赖，先执行 ohpm install
if (!fs.existsSync(path.join(ROOT, 'oh_modules'))) {
  console.log('Running ohpm install...');
  run('ohpm', ['install'], { stdio: 'inherit' });
}

// 尝试从 oh_modules 或 node_modules 执行 hvigor
const candidates = [
  path.join(ROOT, 'oh_modules', '.bin', 'hvigorw'),
  path.join(ROOT, 'oh_modules', '.bin', 'hvigor'),
  path.join(ROOT, 'node_modules', '.bin', 'hvigorw'),
  path.join(ROOT, 'node_modules', '.bin', 'hvigor'),
];
for (const bin of candidates) {
  if (fs.existsSync(bin)) {
    run('node', [bin, ...args]);
    return;
  }
}

console.error('Could not find hvigor. Please either:');
console.error('  1. Open this project in DevEco Studio and build from the IDE, or');
console.error('  2. Run: ohpm install (then ensure @ohos/hvigor-ohos-plugin provides hvigorw in oh_modules/.bin)');
process.exit(1);
