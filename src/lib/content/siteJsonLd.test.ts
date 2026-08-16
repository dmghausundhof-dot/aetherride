/**
 * Run: npx tsx src/lib/content/siteJsonLd.test.ts
 */
import assert from "node:assert/strict";
import {
  breadcrumbJsonLd,
  editorialPersonJsonLd,
  guideArticleJsonLd,
  siteOrigin,
  websiteJsonLd,
} from "./siteJsonLd";

function testWebsiteGraph() {
  const json = websiteJsonLd("https://example.test");
  const types = json["@graph"].map((n) => n["@type"]);
  assert.ok(types.includes("WebSite"));
  assert.ok(types.includes("Organization"));
  assert.ok(!JSON.stringify(json).includes("Musterstraße"));
}

function testBreadcrumb() {
  const json = breadcrumbJsonLd("https://example.test", [
    { name: "Regionen", path: "/regions" },
    { name: "Bodensee", path: "/regions/bodensee" },
  ]);
  assert.equal(json.itemListElement.length, 2);
  assert.equal(
    json.itemListElement[1].item,
    "https://example.test/regions/bodensee",
  );
}

function testGuideAndPerson() {
  const article = guideArticleJsonLd("https://example.test", {
    slug: "teilen-per-link",
    title: "Teilen",
    teaser: "Link statt Feed.",
  });
  assert.equal(article["@type"], "Article");
  const person = editorialPersonJsonLd("https://example.test", {
    handle: "mara_road",
    displayName: "Mara",
    bio: "Editorial",
    sports: ["road"],
  });
  assert.equal(person.url, "https://example.test/u/mara_road");
}

function testOriginHasNoTrailingSlash() {
  assert.equal(siteOrigin().endsWith("/"), false);
}

testWebsiteGraph();
testBreadcrumb();
testGuideAndPerson();
testOriginHasNoTrailingSlash();
console.log("siteJsonLd.test.ts OK");
