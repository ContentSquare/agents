# Contentsquare MCP

Query your Contentsquare analytics data directly from your AI coding agent using natural language. Ask questions about user journeys, conversion funnels, error impact, and page performance without leaving your editor.

## Prerequisites

- A Contentsquare account with admin access
- An AI coding agent with MCP support (Cursor, Claude Code, or compatible)

## Installation

Install this plugin from the [Cursor marketplace](https://cursor.com/marketplace) by searching for **contentsquare**, or add it directly from this repository URL. For Claude Code, use the `.claude-plugin` marketplace entry.

Once installed, your agent will prompt you to authenticate with your Contentsquare account via OAuth. No manual token management required.

## Authentication

This plugin connects to the Contentsquare MCP server at `https://api.contentsquare.com/mcp` using OAuth 2.1 with PKCE. Your agent handles the authentication flow automatically when you first invoke a tool.

You will need:
- A Contentsquare account
- Admin-level access to at least one project

## Available tools

The Contentsquare MCP server exposes two experiences. When authenticating, you select which one to use - this determines which set of tools is available.

### CSQ XP

A unified experience combining Contentsquare and Heap analytics into a single entry point.

| Tool | Description |
|------|-------------|
| `listHierarchy` | List available master projects, environments, and data sources |
| `runAnalysis` | Run any analysis - journey, funnel, impact, page comparison, or metrics |
| `getDefinedEvents` | List custom interaction events defined in your project |
| `getTransactionEvent` | Retrieve the built-in transaction event for e-commerce analysis |

### Legacy

The original experience with dedicated tools per analysis type.

| Tool | Description |
|------|-------------|
| `listProjects` | List accessible Contentsquare projects |
| `computeJourney` | Analyze user navigation paths through your site |
| `computeFunnel` | Compute conversion funnel metrics step by step |
| `computeImpact` | Measure the revenue and conversion impact of page issues |
| `computePageComparison` | Compare metrics across multiple page groups side by side |
| `computeSiteMetrics` | Retrieve overall site-level metrics |
| `computePageGroupMetrics` | Retrieve metrics for a specific page group |
| `getTopErrorsBySessionsWithErrors` | Find pages with the most user sessions containing errors |
| `getTopErrorsByImpactOnGoal` | Find errors with the highest impact on conversion goals |
| `getTopErrorsByMissedOpportunity` | Find errors causing the most missed revenue opportunity |
| `getTopPageGroupsByLostConversions` | Identify page groups with the most lost conversions |
| `getTopPagesBySessionsWithErrors` | List pages ranked by error session count |
| `searchGoals` | Search for conversion goals by name |
| `recommendGoals` | Get goal recommendations based on your recent activity |

### Both experiences

These tools are available regardless of which experience you select.

| Tool | Description |
|------|-------------|
| `searchMappings` | Search for URL mappings by name or keyword |
| `recommendMappings` | Get mapping recommendations based on your recent activity |
| `searchSegments` | Search for audience segments by name |
| `recommendSegments` | Get segment recommendations based on your recent activity |
| `getPageGroupsForMapping` | List all page groups for a given mapping |
| `recommendPageGroups` | Get page group recommendations based on your recent activity |
| `submitMcpFeedback` | Submit feedback about the MCP experience |

## Example prompts

- "Show me the top 5 pages where users are dropping off in my checkout funnel"
- "What errors are causing the most missed revenue on the product page?"
- "Compare conversion rates between the old and new homepage designs"
- "Analyze the journey users take after landing on the pricing page"
- "Which page groups have the highest frustration score this week?"

## Documentation

Full documentation is available at [support.contentsquare.com](https://support.contentsquare.com/hc/en-us/articles/41563169756945-Model-Context-Protocol-MCP).

## Support

- Documentation: [Model Context Protocol (MCP)](https://support.contentsquare.com/hc/en-us/articles/41563169756945-Model-Context-Protocol-MCP)
- Support: [engineering@contentsquare.com](mailto:engineering@contentsquare.com)
