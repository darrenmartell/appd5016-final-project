import js from '@eslint/js'
import globals from 'globals'
// import pluginReact from "eslint-plugin-react";
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{js,jsx}'],
    extends: [
      js.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
      parserOptions: {
        ecmaVersion: 'latest',
        ecmaFeatures: { jsx: true },
        sourceType: 'module',
      },
    },
    rules: {
      'no-unused-vars': ['error', { varsIgnorePattern: '^[A-Z_]' }],
    },
  },
])

// export default defineConfig([
//   {
//     files: ["**/*.{js,mjs,cjs,jsx}"],
//     plugins: {
//       react: pluginReact
//     },
//     languageOptions: {
//       globals: globals.browser,
//       parserOptions: {
//         ecmaFeatures: {
//           jsx: true
//         }
//       }
//     },
//     extends: [
//       js.configs.recommended,
//       pluginReact.configs.flat.recommended
//     ],
//     rules: {
//       "react/react-in-scope": "off", 
//       "react/jsx-uses-react": "off"
//     }
//   },
// ]);
