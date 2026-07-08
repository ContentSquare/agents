# Contentsquare for AI coding agents

Official Contentsquare artifacts for AI coding assistants (GitHub Copilot, Cursor, Claude Code, or any compatible tool). This repository is the home for Contentsquare's AI-related deliverables — plugins, MCP server configs, and standalone skills — that let your agent handle Contentsquare configuration, analysis, and more, right from your editor.

It ships as:

- **Plugin marketplaces** for Claude Code, GitHub Copilot, and Cursor.
- **Plugins** that bundle skills and/or MCP servers.
- **Standalone skills** distributed through the open [skills.sh](https://skills.sh) ecosystem.

> [!WARNING]
> These artifacts guide your AI coding agent through Contentsquare configuration and analysis. The agent you use (Cursor, Claude Code, Copilot) is your own tool and operates under your settings and permissions. Contentsquare is not responsible for how your agent interprets or applies the instructions contained in these files.

## What's included

This repository currently ships the following plugins:

| Plugin                      | Type  | Description                                                                                                                      |
| --------------------------- | ----- | -------------------------------------------------------------------------------------------------------------------------------- |
| `contentsquare-web`         | Skill | Install & verify the Contentsquare tracking tag in any web project (Next.js, React, Vue, Angular, SvelteKit, Nuxt, static HTML). |
| `contentsquare`             | MCP   | Query your Contentsquare analytics data — journeys, funnels, error impact, page performance — in natural language.               |
| `contentsquare-android`     | Skill | Integrate & manage the Contentsquare SDK in Android applications.                                                                |
| `contentsquare-ios`         | Skill | Integrate & manage the Contentsquare SDK in iOS applications.                                                                    |
| `contentsquare-reactnative` | Skill | Integrate & manage the Contentsquare SDK in React Native applications.                                                           |
| `contentsquare-flutter`     | Skill | Integrate & manage the Contentsquare SDK in Flutter applications.                                                                |

## What you can do

**Install and verify the Contentsquare tag** — let your agent add the tag to your website and confirm it loads correctly:

```
Add contentsquare to my website using tag ID `81c677ba742d7`
```

**Query your analytics** — ask questions about your data without leaving your editor:

```
What are the top pages by sessions with errors on my main project?
```

## Installation

### As a plugin (Claude Code & GitHub Copilot CLI)

Add the marketplace, then install **only the plugin(s) that match your project's stack**. You do not need to install all of them.

**Claude Code:**

```shell
/plugin marketplace add ContentSquare/agents

# 1. Choose the skill that matches your platform:
/plugin install contentsquare-web@contentsquare
# /plugin install contentsquare-android@contentsquare
# /plugin install contentsquare-ios@contentsquare
# /plugin install contentsquare-reactnative@contentsquare
# /plugin install contentsquare-flutter@contentsquare

# 2. (Optional) Install the MCP server for analytics querying:
/plugin install contentsquare@contentsquare
```

**GitHub Copilot CLI:**

```shell
copilot plugin marketplace add ContentSquare/agents

# 1. Choose the skill that matches your platform:
copilot plugin install contentsquare-web@contentsquare
# copilot plugin install contentsquare-android@contentsquare
# copilot plugin install contentsquare-ios@contentsquare
# copilot plugin install contentsquare-reactnative@contentsquare
# copilot plugin install contentsquare-flutter@contentsquare

# 2. (Optional) Install the MCP server for analytics querying:
copilot plugin install contentsquare@contentsquare
```

Then, in natural language: "Install Contentsquare, tag ID `81c677ba742d7`" — the agent loads the right skill automatically.

### Cursor

Install from the [Cursor marketplace](https://cursor.com/marketplace) by searching for **contentsquare**, or add this repository directly. Cursor reads the `.cursor-plugin/` catalog.

### Standalone skills (skills.sh)

For agents supporting the open [skills.sh](https://skills.sh) ecosystem:

```bash
npx skills add contentsquare/agents
```

Works with Claude Code, Cursor, GitHub Copilot, and other compatible agents.

### Manual installation

Copy the skills from this repository's `./skills` folder into the location your AI assistant uses for context discovery:

| Assistant      | Recommended location                   |
| -------------- | -------------------------------------- |
| GitHub Copilot | `.github/skills/` or `.agents/skills/` |
| Cursor         | `.cursor/rules/` or project root       |
| Claude Code    | `.claude/skills/` or project root      |
| Any (generic)  | `.agents/skills/`                      |

You can verify a skill is discoverable by prompting your agent: "Which skills are available for you to use?".

For the MCP server, point your agent's MCP configuration at `https://api.contentsquare.com/mcp`. Your agent handles the OAuth flow on first use.

## Repository layout (for maintainers)

The marketplaces reuse single authored sources; the rest are generated copies kept in sync by CI.

| Path                                                 | Role                                                                  |
| ---------------------------------------------------- | --------------------------------------------------------------------- |
| `skills/<skill-name>/SKILL.md`                       | **Authored** source of each standalone skill                          |
| `plugins/<plugin-name>/`                             | **Authored** plugin (manifest, and bundled skills and/or `.mcp.json`) |
| `plugins/<plugin-name>/skills/<skill-name>/SKILL.md` | Generated copy of a skill — do not edit                               |
| `.claude-plugin/marketplace.json`                    | **Authored** marketplace catalog (Claude Code & Copilot)              |
| `.cursor-plugin/marketplace.json`                    | **Authored** marketplace catalog (Cursor)                             |

After editing an authored source, run `./scripts/sync-plugin.sh` and commit the result. CI fails if the generated copies drift.
