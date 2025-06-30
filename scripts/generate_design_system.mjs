#!/usr/bin/env node
// scripts/generate_design_system.js

import fs from 'fs';
import path from 'path';

function write(dir, name, content) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, name), content, 'utf8');
  console.log(`✔️  Created ${path.join(dir, name)}`);
}

const root      = process.cwd();
const DS        = path.join(root, 'DESIGN_SYSTEM');
const stylesDir = path.join(root, 'src', 'styles');
const idxCss    = path.join(root, 'src', 'index.css');

// 1. Scaffold DESIGN_SYSTEM folder
write(DS, 'GLOBAL_CBUMP_DesignSystem.md', `# Global CBPump Design System

## 1. Foundations
- Voice: Precise, data-driven, a touch cold.
- Mood: Dark-mode first, neon accents, minimal.

## 2. Tokens
…paste your full spec here…
`);

write(DS, 'tailwind.config.js', `module.exports = {
  theme: {
    extend: {
      backgroundImage: {
        'bhabit-dark': 'linear-gradient(to bottom, #000000, #0B0B0F, #101014)',
      },
      fontFamily: {
        heading: ['Prosto One','sans-serif'],
        sans:    ['Raleway','sans-serif'],
        mono:    ['Fragment Mono','monospace'],
      },
      colors: {
        primary: '#FF5E00',
        accent:  '#8B00FF',
        success: '#00CFFF',
        danger:  '#FF3B30',
        neutral: '#E0E0E0',
      },
      spacing: { xs:'8px', sm:'16px', md:'24px', lg:'32px', xl:'48px' },
      borderRadius: { sm:'4px', md:'8px', lg:'16px' },
    },
  },
  plugins: [],
};
`);

write(DS, 'README.md', `# CBPump Design System

1. Install Tailwind:
   npm install -D tailwindcss postcss autoprefixer  
   npx tailwindcss init -p

2. Merge tokens in root tailwind.config.js:
   const ds = require('./DESIGN_SYSTEM/tailwind.config.js');
   module.exports = {
     content: ['./src/**/*.{js,jsx,ts,tsx,html}'],
     theme: { extend: ds.theme.extend },
     plugins: [],
   };

3. Import CSS vars via src/styles/design-system.css  
4. See GLOBAL_DESIGN_SYSTEM.md for full spec.
`);

// 2. Create CSS variables file
write(stylesDir, 'design-system.css', `:root {
  /* Colors & tokens… */
}
`);

// 3. Inject into src/index.css (if it exists)
if (fs.existsSync(idxCss)) {
  let content = fs.readFileSync(idxCss, 'utf8');
  const imp = "@import './styles/design-system.css';";
  if (!content.includes(imp)) {
    content = imp + '\n' + content;
    fs.writeFileSync(idxCss, content, 'utf8');
    console.log(`✔️  Injected import into src/index.css`);
  }
}

console.log('🎉 DESIGN_SYSTEM generation complete!');