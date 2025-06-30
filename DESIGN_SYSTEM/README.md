# CBPump Design System

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
