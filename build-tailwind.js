#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import postcss from "postcss";
import tailwindPostcss from "@tailwindcss/postcss";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function buildTailwind() {
  console.log("Building Tailwind CSS for Blazor...");

  try {
    const srcCss = path.join(__dirname, "src", "index.css");
    const outCss = path.join(__dirname, "blazor-migration", "wwwroot", "tailwind.css");

    // Read the source CSS
    const css = fs.readFileSync(srcCss, "utf8");

    // Process with PostCSS and Tailwind
    const result = await postcss([tailwindPostcss]).process(css, {
      from: srcCss,
      to: outCss,
    });

    // Write output
    fs.writeFileSync(outCss, result.css);

    console.log(`✓ Tailwind CSS generated: ${outCss}`);
    console.log(`  Size: ${(result.css.length / 1024).toFixed(2)} KB`);
  } catch (error) {
    console.error("✗ Build failed:", error.message);
    process.exit(1);
  }
}

buildTailwind();

