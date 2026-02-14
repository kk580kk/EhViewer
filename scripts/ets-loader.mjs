/**
 * Custom Node.js loader that treats .ets files as TypeScript modules.
 * Usage: node --import ./scripts/ets-loader.mjs <script>
 *
 * Uses the register() API (Node.js v20.6+) to install module hooks.
 */
import { register } from 'node:module';

register('./ets-hooks.mjs', import.meta.url);
