/**
 * Node.js loader hook that lets `import … from '*.ets'` work
 * by treating .ets files as TypeScript (type-stripped ESM).
 *
 * Usage:  node --import ./scripts/ets-loader.mjs --test …
 */
import { registerHooks } from 'node:module';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

registerHooks({
  load(url, context, nextLoad) {
    if (url.endsWith('.ets')) {
      const source = readFileSync(fileURLToPath(url), 'utf-8');
      return { format: 'module-typescript', source, shortCircuit: true };
    }
    return nextLoad(url, context);
  },
});
