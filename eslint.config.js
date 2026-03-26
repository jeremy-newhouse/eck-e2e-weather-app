"use strict";

const globals = require("globals");

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  // Node.js / CommonJS files (server, routes, data, tests)
  {
    files: ["**/*.js"],
    ignores: ["public/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        ...globals.node,
        ...globals.commonjs,
      },
    },
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "error",
    },
  },
  // Browser scripts in public/
  {
    files: ["public/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "script",
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "error",
    },
  },
];
