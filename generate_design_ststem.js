#!/usr/bin/env node
/**
 * generate_design_system.js
 *
 * Auto-generates the DESIGN_SYSTEM folder and files at your project root.
 * - Finds project root by locating package.json in parent dirs.
 * - Creates DESIGN_SYSTEM/ with:
 *    • GLOBAL_DESIGN_SYSTEM.md
 *    • tailwind.config.js
 *    • README.md
 * - Creates src/styles/design-system.css
 * - Optionally injects import into src/index.css
 *
 * Usage:
 *   node generate_design_system.js
 *   # Or add to package.json scripts:
 *   # "scripts": {
 *   #   "generate:ds": "node ./scripts/generate_design_system.js",
 *   #   "build": "npm run generate:ds && next build"
 *   # }
 */

const fs = require('fs');
const path = require('path');

// Recursively find project root by locating package.json
function findProjectRoot(dir) {
  if (fs.existsSync(path.join(dir, 'package.json'))) return dir;
  const parent = path.resolve(dir, '..');
  if (parent === dir) throw new Error('Could not find project root (package.json).');
  return findProjectRoot(parent);
}

// Write file utility
function writeFile(dir, filename, content) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, filename), content, 'utf8');
  console.log(`✔️  ${path.relative(root, path.join(dir, filename))}`);
}

// Entry point
const root = findProjectRoot(process.cwd());
console.log(`📂 Project root detected: ${root}`);

// 1. DESIGN_SYSTEM folder
const DS = path.join(root, 'DESIGN_SYSTEM');
writeFile(DS, 'GLOBAL_DESIGN_SYSTEM.md', `# Global CBPump Design System

## 1. Foundations
- **Voice:** Precise, data-driven, a touch cold.
- **Mood:** Dark-mode first, neon accents, minimal.

## 2. Tokens
... (full spec here) ...
`);
writeFile(DS, 'tailwind.config.js', `module.exports = {
  theme: { extend: { /* tokens here */ } },
  plugins: [],
};
`);
writeFile(DS, 'README.md', `# DESIGN_SYSTEM

1. Install Tailwind: npm install -D tailwindcss postcss autoprefixer  
2. Init: npx tailwindcss init -p  
3. Merge tokens: replace root tailwind.config.js with:
\`\`\`js
const ds = require('./DESIGN_SYSTEM/tailwind.config.js');
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx,html}'],
  theme: { extend: ds.theme.extend },
  plugins: [],
};
\`\`\`
4. Import CSS variables:
   @import './styles/design-system.css';
`);

// 2. CSS variables in src/styles
const stylesDir = path.join(root, 'src', 'styles');
writeFile(stylesDir, 'design-system.css', `:root {
  /* Colors & tokens... */
}
`);

// 3. Inject into src/index.css
const idxCss = path.join(root, 'src', 'index.css');
if (fs.existsSync(idxCss)) {
  let content = fs.readFileSync(idxCss, 'utf8');
  const importLine = `@import './styles/design-system.css';`;
  if (!content.includes(importLine)) {
    writeFile(path.dirname(idxCss), 'index.css', importLine + '\n' + content);
    console.log(`✅ Injected CSS import into src/index.css`);
  }
}

console.log('🎉 DESIGN_SYSTEM generation complete!');
