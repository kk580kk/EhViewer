/**
 * Module loader hooks that treat .ets files as TypeScript modules.
 * Registered by ets-loader.mjs via register().
 */
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export async function resolve(specifier, context, nextResolve) {
  // If specifier is a relative path without a recognized extension,
  // try appending .ets (ArkTS convention omits .ets in import paths).
  if (specifier.startsWith('.') && !specifier.match(/\.\w+$/)) {
    const parentUrl = context.parentURL;
    if (parentUrl) {
      const candidate = new URL(specifier + '.ets', parentUrl);
      if (existsSync(fileURLToPath(candidate))) {
        return nextResolve(specifier + '.ets', context);
      }
    }
  }
  return nextResolve(specifier, context);
}

export async function load(url, context, nextLoad) {
  if (url.endsWith('.ets')) {
    return nextLoad(url, { ...context, format: 'module-typescript' });
  }
  return nextLoad(url, context);
}
