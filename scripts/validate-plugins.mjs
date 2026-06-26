#!/usr/bin/env node
//
// Validate plugin manifests, catalogs, MCP configs and skill files.
//
// Run locally with `node scripts/validate-plugins.mjs` to reproduce CI failures.
// The Claude plugin contract itself is checked separately by `claude plugin
// validate`; this script covers the shape and cross-file rules that tool does
// not know about (cursor manifests, catalog consistency, logos, frontmatter).
//
import { readFileSync, existsSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";

const KEBAB_CASE = /^[a-z0-9]+(-[a-z0-9]+)*$/;

const errors = [];

/** Record a failure against a file, printed in GitHub Actions error format. */
function fail(file, message) {
  errors.push({ file, message });
  console.error(`::error file=${file}::${message}`);
}

/** Parse JSON, recording a failure (and returning null) on syntax errors. */
function readJson(file) {
  try {
    return JSON.parse(readFileSync(file, "utf8"));
  } catch (e) {
    fail(file, `Invalid JSON: ${e.message}`);
    return null;
  }
}

/** Directories under plugins/, e.g. ["plugins/contentsquare", ...]. */
function pluginDirs() {
  return readdirSync("plugins", { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => join("plugins", d.name));
}

/** SKILL.md paths under plugins/<plugin>/skills/<skill>/SKILL.md. */
function skillFiles() {
  const files = [];
  for (const dir of pluginDirs()) {
    const skillsDir = join(dir, "skills");
    if (!existsSync(skillsDir)) continue;
    for (const skill of readdirSync(skillsDir, { withFileTypes: true })) {
      if (!skill.isDirectory()) continue;
      const file = join(skillsDir, skill.name, "SKILL.md");
      if (existsSync(file)) files.push(file);
    }
  }
  return files;
}

/** Every plugin manifest that exists, across both plugin systems. */
function manifestFiles() {
  const files = [];
  for (const dir of pluginDirs()) {
    for (const rel of [".claude-plugin/plugin.json", ".cursor-plugin/plugin.json"]) {
      const file = join(dir, rel);
      if (existsSync(file)) files.push(file);
    }
  }
  return files;
}

// --- Checks -----------------------------------------------------------------

/** Manifests and catalogs are valid JSON with a kebab-case `name`. */
function validateManifestNames() {
  const catalogs = [".claude-plugin/marketplace.json", ".cursor-plugin/marketplace.json"];
  for (const file of [...catalogs, ...manifestFiles()]) {
    const json = readJson(file);
    if (!json) continue;
    if (!json.name) fail(file, "missing name");
    else if (!KEBAB_CASE.test(json.name)) fail(file, `name must be kebab-case: "${json.name}"`);
  }
}

/** .mcp.json files declare at least one server with a url or command. */
function validateMcpConfigs() {
  for (const dir of pluginDirs()) {
    const file = join(dir, ".mcp.json");
    if (!existsSync(file)) continue;
    const json = readJson(file);
    if (!json) continue;
    if (!json.mcpServers || typeof json.mcpServers !== "object") {
      fail(file, "missing or invalid mcpServers object");
      continue;
    }
    const servers = Object.entries(json.mcpServers);
    if (servers.length === 0) {
      fail(file, "mcpServers must have at least one entry");
      continue;
    }
    for (const [name, cfg] of servers) {
      if (!cfg.url && !cfg.command) fail(file, `server "${name}" must have url or command`);
    }
  }
}

/** Each SKILL.md opens with closed YAML frontmatter containing a description. */
function validateSkillFrontmatter() {
  for (const file of skillFiles()) {
    const content = readFileSync(file, "utf8");
    if (!content.startsWith("---")) {
      fail(file, "missing YAML frontmatter (must start with ---)");
      continue;
    }
    const end = content.indexOf("---", 3);
    if (end === -1) {
      fail(file, "unclosed YAML frontmatter");
      continue;
    }
    if (!/^description\s*:/m.test(content.slice(3, end))) {
      fail(file, "missing required description field in frontmatter");
    }
  }
}

/** Catalog entries point at real plugin directories with the right manifest. */
function validateCatalogConsistency() {
  const catalogs = {
    ".claude-plugin/marketplace.json": ".claude-plugin/plugin.json",
    ".cursor-plugin/marketplace.json": ".cursor-plugin/plugin.json",
  };
  for (const [catalog, manifestRel] of Object.entries(catalogs)) {
    const json = readJson(catalog);
    if (!json) continue;
    for (const plugin of json.plugins ?? []) {
      const src = plugin.source.replace(/^\.\//, "");
      if (!existsSync(src)) {
        fail(catalog, `plugin "${plugin.name}" source path does not exist: ${src}`);
        continue;
      }
      if (!existsSync(join(src, manifestRel))) {
        fail(catalog, `plugin "${plugin.name}" missing ${manifestRel}`);
      }
    }
  }
}

/** A plugin's claude and cursor manifests agree on name and version. */
function validateCrossManifestConsistency() {
  for (const dir of pluginDirs()) {
    const claudeFile = join(dir, ".claude-plugin/plugin.json");
    const cursorFile = join(dir, ".cursor-plugin/plugin.json");
    if (!existsSync(claudeFile) || !existsSync(cursorFile)) continue;
    const claude = readJson(claudeFile);
    const cursor = readJson(cursorFile);
    if (!claude || !cursor) continue;
    if (claude.name !== cursor.name) {
      fail(claudeFile, `name mismatch: .claude-plugin "${claude.name}" vs .cursor-plugin "${cursor.name}"`);
    }
    if (claude.version && cursor.version && claude.version !== cursor.version) {
      fail(claudeFile, `version mismatch: .claude-plugin "${claude.version}" vs .cursor-plugin "${cursor.version}"`);
    }
  }
}

/** Any logo referenced by a cursor manifest exists on disk. */
function validateLogoAssets() {
  for (const dir of pluginDirs()) {
    const file = join(dir, ".cursor-plugin/plugin.json");
    if (!existsSync(file)) continue;
    const json = readJson(file);
    if (!json?.logo) continue;
    const logoPath = join(dir, json.logo);
    if (!existsSync(logoPath)) fail(file, `logo file not found: ${logoPath}`);
  }
}

// --- Run --------------------------------------------------------------------

validateManifestNames();
validateMcpConfigs();
validateSkillFrontmatter();
validateCatalogConsistency();
validateCrossManifestConsistency();
validateLogoAssets();

if (errors.length > 0) {
  console.error(`\n${errors.length} validation error(s) found.`);
  process.exit(1);
}
console.log("OK - all plugin manifests, catalogs, MCP configs and skills are valid.");
