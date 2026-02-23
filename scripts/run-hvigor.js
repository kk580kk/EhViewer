#!/usr/bin/env node
/**
 * HarmonyOS 构建入口：通过 ohpm 安装的插件或 DevEco 自带 hvigor 执行构建。
 * 使用方式: node scripts/run-hvigor.js assembleHap --mode module -p product=default
 *
 * 若设置环境变量 DEVECO_STUDIO_APP 为本机 DevEco Studio.app 路径（见 docs/编译环境说明.md），
 * 将优先使用其 ohpm 与 hvigor，无需先执行 ohpm install。
 */
const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const args = process.argv.slice(2);

// 本机 DevEco 路径（与 docs/编译环境说明.md 一致），可通过环境变量覆盖
const DEVECO_APP = process.env.DEVECO_STUDIO_APP || '/Volumes/Brave 2T/Applications/DevEco-Studio.app';
const OHPM_BIN = path.join(DEVECO_APP, 'Contents', 'tools', 'ohpm', 'bin');
const HVIGOR_JS = path.join(DEVECO_APP, 'Contents', 'tools', 'hvigor', 'hvigor', 'bin', 'hvigor.js');

function run(cmd, a, opts = {}) {
  const r = spawnSync(cmd, a, { stdio: 'inherit', cwd: ROOT, ...opts });
  if (r.status !== 0) process.exit(r.status != null ? r.status : 1);
}

function hasOhpm() {
  return spawnSync('ohpm', ['--version'], { cwd: ROOT, encoding: 'utf8' }).status === 0;
}

// 若未安装依赖，先尝试用 DevEco 的 ohpm 安装
if (!fs.existsSync(path.join(ROOT, 'oh_modules'))) {
  const envPath = process.env.PATH || '';
  if (fs.existsSync(path.join(OHPM_BIN, 'ohpm'))) {
    process.env.PATH = OHPM_BIN + path.delimiter + envPath;
  }
  if (!hasOhpm()) {
    console.error('');
    console.error('未检测到 ohpm。HarmonyOS 构建需使用 DevEco Studio 自带的 ohpm：');
    console.error('  1. 安装 DevEco Studio：https://developer.harmonyos.com/cn/develop/deveco-studio');
    console.error('  2. 用 DevEco Studio 打开本工程根目录，按提示完成「项目结构/配置升级」');
    console.error('  3. 在 IDE 内：Build > Build Hap(s)/APP(s) > Build Hap(s)');
    console.error('  或设置 DEVECO_STUDIO_APP 指向 DevEco-Studio.app 后执行：npm run build');
    console.error('');
    process.exit(1);
  }
  console.log('Running ohpm install...');
  run('ohpm', ['install'], { stdio: 'inherit' });
}

// 优先使用 DevEco 自带的 hvigor（需已用 IDE 打开工程并完成迁移）
if (fs.existsSync(HVIGOR_JS)) {
  const nodePath = path.join(ROOT, 'node_modules');
  if (fs.existsSync(nodePath)) {
    const env = { ...process.env, NODE_PATH: nodePath };
    run('node', [HVIGOR_JS, ...args], { env });
    return;
  }
}

// 否则从 oh_modules / node_modules 执行 hvigor
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
console.error('  1. Open this project in DevEco Studio, complete project upgrade, then Build > Build Hap(s), or');
console.error('  2. Ensure DEVECO_STUDIO_APP points to DevEco-Studio.app and node_modules has @ohos links (see docs/编译环境说明.md)');
process.exit(1);
