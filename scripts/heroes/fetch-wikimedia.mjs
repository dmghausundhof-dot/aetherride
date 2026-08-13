#!/usr/bin/env node
/**
 * Fetch CC-licensed place photos from Wikimedia Commons into
 * mobile/assets/seeds/heroes/ and write ATTRIBUTION.md
 *
 *   node scripts/heroes/fetch-wikimedia.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(__dirname, "../../mobile/assets/seeds/heroes");
const UA = "AetherRide/1.0 (https://aetherride.vercel.app; tour heroes)";

const PLACES = [
  { file: "wm-heidelberg.jpg", q: "Heidelberg Neckar Altstadt" },
  { file: "wm-mannheim.jpg", q: "Mannheim Schloss" },
  { file: "wm-koenigstuhl.jpg", q: "Heidelberg Königstuhl" },
  { file: "wm-tempelhofer.jpg", q: "Tempelhofer Feld Berlin" },
  { file: "wm-spree.jpg", q: "Berlin Spree" },
  { file: "wm-grunewald.jpg", q: "Grunewald Berlin Wald" },
  { file: "wm-karlsruhe.jpg", q: "Karlsruhe Schloss" },
  { file: "wm-freiburg.jpg", q: "Freiburg im Breisgau" },
  { file: "wm-muenchen.jpg", q: "München Englischer Garten" },
  { file: "wm-koeln.jpg", q: "Köln Rhein Dom" },
  { file: "wm-stuttgart.jpg", q: "Stuttgart" },
  { file: "wm-bodensee.jpg", q: "Bodensee Lindau" },
  { file: "wm-innsbruck.jpg", q: "Innsbruck" },
  { file: "wm-salzburg.jpg", q: "Salzburg Festung" },
  { file: "wm-wien.jpg", q: "Wien Donaukanal" },
  { file: "wm-hamburg.jpg", q: "Hamburg Binnenalster" },
];

const OK_LICENSE = /cc0|cc.?by|public domain|pd-|gfdl/i;

async function search(q) {
  const url =
    "https://commons.wikimedia.org/w/api.php?" +
    new URLSearchParams({
      action: "query",
      generator: "search",
      gsrsearch: `filetype:bitmap ${q}`,
      gsrnamespace: "6",
      gsrlimit: "8",
      prop: "imageinfo",
      iiprop: "url|extmetadata|size|mime",
      iiurlwidth: "1600",
      format: "json",
      origin: "*",
    });
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`commons ${res.status}`);
  const data = await res.json();
  const pages = Object.values(data.query?.pages || {});
  for (const p of pages) {
    const info = p.imageinfo?.[0];
    if (!info) continue;
    const mime = String(info.mime || "");
    if (!mime.includes("jpeg") && !mime.includes("jpg")) continue;
    const lic = String(
      info.extmetadata?.LicenseShortName?.value ||
        info.extmetadata?.License?.value ||
        ""
    );
    if (!OK_LICENSE.test(lic) && !/public domain/i.test(lic)) continue;
    const artist = String(info.extmetadata?.Artist?.value || "Wikimedia")
      .replace(/<[^>]+>/g, "")
      .trim();
    const thumb = info.thumburl || info.url;
    if (!thumb) continue;
    return {
      url: thumb,
      title: p.title,
      license: lic,
      artist,
      page: info.descriptionshorturl || info.descriptionurl,
    };
  }
  return null;
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });
  const lines = [
    "# Hero photo attribution (Wikimedia Commons)",
    "",
    "Downloaded thumbs (max 1600px). See each Commons file for the full license.",
    "",
  ];
  for (const place of PLACES) {
    process.stderr.write(`… ${place.file} (${place.q})\n`);
    try {
      const hit = await search(place.q);
      if (!hit) {
        process.stderr.write(`  skip (no CC hit)\n`);
        continue;
      }
      const img = await fetch(hit.url, { headers: { "User-Agent": UA } });
      if (!img.ok) continue;
      const buf = Buffer.from(await img.arrayBuffer());
      fs.writeFileSync(path.join(outDir, place.file), buf);
      lines.push(
        `- \`${place.file}\` — ${hit.title} — ${hit.artist} — ${hit.license} — ${hit.page}`
      );
      process.stderr.write(`  ok ${Math.round(buf.length / 1024)}K ${hit.license}\n`);
    } catch (e) {
      process.stderr.write(`  fail ${e.message}\n`);
    }
    await new Promise((r) => setTimeout(r, 400));
  }
  fs.writeFileSync(path.join(outDir, "ATTRIBUTION.md"), lines.join("\n") + "\n");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
