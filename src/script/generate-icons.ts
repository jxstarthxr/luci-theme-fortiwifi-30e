import fs from "node:fs";
import path from "node:path";

import sharp from "sharp";

// Use relative paths from the repository root
const svgPath = "./package/luci-theme-fluent/htdocs/luci-static/fluent/img/fortinet-logomark-red.svg";
const iconDir = "./package/luci-theme-fluent/htdocs/luci-static/fluent/icon";
const themeDir = "./package/luci-theme-fluent/htdocs/luci-static/fluent";

interface Target {
  file: string;
  size: number;
}

const targets: Target[] = [
  { file: "fortinet-logomark-red-192.png", size: 192 },
  { file: "fortinet-logomark-red-32.png", size: 32 },
];

const keepFiles = new Set<string>(["manifest.json", "favicon.ico", ...targets.map(({ file }) => file)]);

function wrapPngAsIco(png: Buffer, size: number): Buffer {
  const header = Buffer.alloc(22);
  header.writeUInt16LE(0, 0); // Reserved
  header.writeUInt16LE(1, 2); // ICO image
  header.writeUInt16LE(1, 4); // One image
  header.writeUInt8(size >= 256 ? 0 : size, 6);
  header.writeUInt8(size >= 256 ? 0 : size, 7);
  header.writeUInt8(0, 8); // No palette
  header.writeUInt8(0, 9); // Reserved
  header.writeUInt16LE(1, 10); // Color planes
  header.writeUInt16LE(32, 12); // Bits per pixel
  header.writeUInt32LE(png.length, 14);
  header.writeUInt32LE(header.length, 18);
  return Buffer.concat([header, png]);
}

async function generate(): Promise<void> {
  // Check if source SVG exists
  if (!fs.existsSync(svgPath)) {
    console.error(`Source SVG not found at: ${svgPath}`);
    process.exit(1);
  }

  const svgBuffer = fs.readFileSync(svgPath);

  // Ensure icon directory exists
  if (!fs.existsSync(iconDir)) {
    fs.mkdirSync(iconDir, { recursive: true });
  }

  // Generate optimized PNGs
  for (const target of targets) {
    const dest = path.join(iconDir, target.file);
    console.log(`Generating ${target.file} (${target.size}x${target.size})...`);
    await sharp(svgBuffer)
      .resize(target.size, target.size, {
        fit: "contain",
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .png({
        palette: true,
        compressionLevel: 9,
        quality: 85,
        effort: 10,
      })
      .toFile(dest);
  }

  // Generate a real ICO container containing an optimized 32x32 PNG.
  const faviconPng = await sharp(svgBuffer)
    .resize(32, 32, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png({
      palette: true,
      compressionLevel: 9,
      quality: 85,
      effort: 10,
    })
    .toBuffer();
  const faviconIco = wrapPngAsIco(faviconPng, 32);

  console.log("Generating favicon.ico in root...");
  fs.writeFileSync(path.join(themeDir, "favicon.ico"), faviconIco);

  console.log("Generating favicon.ico in icon directory...");
  fs.writeFileSync(path.join(iconDir, "favicon.ico"), faviconIco);

  // Clean up all other files in the icon directory
  const files = fs.readdirSync(iconDir);
  for (const file of files) {
    if (!keepFiles.has(file)) {
      console.log(`Deleting file: ${file}`);
      fs.unlinkSync(path.join(iconDir, file));
    }
  }

  console.log("All icons generated, minimized, and optimized successfully!");
}

generate().catch((err: unknown) => {
  console.error("Error generating icons:", err);
  process.exit(1);
});
