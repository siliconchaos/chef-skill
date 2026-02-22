# CLAUDE.md — Contributor Guide

> **For end users:** See [README.md](README.md) for installation and usage.
>
> **This file** is for contributors and maintainers working on the skill itself.

## What This Is

A **Claude Code skill** that gives Claude expertise in Chef Automate and Chef Infra Server operations via the `knife` CLI. Think of it as version-controlled domain knowledge — prompt engineering checked into git.

## Repository Structure

```
chef-skill/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace metadata and plugin registration
├── .github/
│   └── workflows/
│       ├── automated-release.yml # Conventional commits → version bump → GitHub Release
│       └── validate.yml          # PR/push validation for SKILL.md and marketplace.json
├── chef-automate/
│   ├── SKILL.md                  # Core skill file loaded by Claude
│   └── references/
│       └── knife-commands.md     # Full knife command reference (loaded on demand)
│   └── scripts/
│       └── check_setup.sh        # Diagnostic script for knife configuration
├── chef-automate.skill           # Packaged distributable (zip of chef-automate/)
├── CHANGELOG.md                  # Managed by automated-release workflow
├── LICENSE                       # MIT — Robert Wallace
└── README.md                     # For GitHub and marketplace users
```

### File Roles

| File | Loaded by | Purpose |
|------|-----------|---------|
| `.claude-plugin/marketplace.json` | Claude Code | Marketplace registration and plugin metadata |
| `chef-automate/SKILL.md` | Claude Code | Core skill — node ops, cookbook management, search, diagnostics |
| `chef-automate/references/knife-commands.md` | Claude Code (on demand) | Full flag reference for every knife subcommand |
| `chef-automate/scripts/check_setup.sh` | User | Local diagnostic for validating knife setup |
| `chef-automate.skill` | Claude Code marketplace | Packaged distributable |

## How the Skill Works

```
User: "Which nodes are running the nginx cookbook?"
       ↓
Claude reads SKILL.md frontmatter (~50 tokens)
       ↓
Activation triggers match ("knife", "cookbook", "nodes")
       ↓
Full SKILL.md loads (~3,500 tokens)
       ↓
Claude responds with accurate knife search commands
```

Skills only load when relevant — keeping token usage low for unrelated tasks.

## Content Philosophy

### What Belongs in SKILL.md

✅ **Include:**
- Knife command patterns with real, copy-pasteable examples
- Decision guidance (when to use `recipes:nginx` vs `run_list:*nginx*`)
- Workflow sequences (before/after diff, bootstrap steps, failure diagnosis)
- Common pitfalls and their fixes (401s, SSL errors, stale search index)
- Output formatting options and `jq` pipelines for scripting

✅ **Format:**
- Tables for comparisons
- Code blocks with comments for non-obvious flags
- Imperative voice: "Run X", not "You might want to consider running X"
- Section headers that let Claude scan quickly

❌ **Exclude:**
- Chef concepts covered adequately in official docs (resource DSL, cookbook authoring)
- Provider or cloud-specific resource details
- Generic shell or Linux advice unrelated to Chef/knife
- Long prose where a table or code block would do

### What Goes in `references/knife-commands.md`

Full flag listings, less-common subcommands, and exhaustive option tables that would bloat SKILL.md. SKILL.md links here; Claude loads it when a user needs depth.

## Releases (Automated)

Releases are driven entirely by [conventional commits](https://www.conventionalcommits.org/). Push to `main` and the workflow handles the rest.

| Commit prefix | Example | Version bump |
|---------------|---------|-------------|
| `feat!:` / `BREAKING CHANGE:` | `feat!: restructure frontmatter` | Major (1.x.x → 2.0.0) |
| `feat:` | `feat: add knife vault commands` | Minor (1.0.x → 1.1.0) |
| `fix:` / other | `fix: correct bootstrap SSH flag` | Patch (1.0.0 → 1.0.1) |

The workflow automatically:
1. Bumps `version` in `.claude-plugin/marketplace.json` (both root and `plugins[0]`)
2. Bumps `version` in `chef-automate/SKILL.md` frontmatter
3. Prepends an entry to `CHANGELOG.md`
4. Creates a git tag and GitHub Release

**Do not** manually edit `CHANGELOG.md` or version fields — the workflow owns those.

## Validation

The `validate.yml` workflow checks on every PR and push to `main`:

- `chef-automate/SKILL.md` has valid frontmatter (`name`, `description` required; `version` for release sync)
- `description` is under 1,024 characters
- `.claude-plugin/marketplace.json` has all required fields and a valid semver `version`
- Markdown linting passes (non-blocking warning)

Run locally before pushing:

```bash
# Check frontmatter
python3 -c "
import yaml, sys
content = open('chef-automate/SKILL.md').read()
fm = yaml.safe_load(content.split('---')[1])
print('name:', fm['name'])
print('description length:', len(fm['description']))
"

# Validate marketplace.json
python3 -c "
import json
m = json.load(open('.claude-plugin/marketplace.json'))
print('version:', m['version'])
print('plugins:', len(m['plugins']))
"
```

## Contributing

### Making Changes

1. Fork the repo and create a branch
2. Edit `chef-automate/SKILL.md` (and `references/knife-commands.md` if needed)
3. Test by loading the skill locally (see below)
4. Commit with a conventional commit message
5. Open a PR — validation runs automatically

### Testing Locally

```bash
# Clone into Claude skills directory
git clone https://github.com/siliconchaos/chef-skill ~/.claude/skills/chef-skill

# After editing, reload Claude Code to pick up changes
# Then test with real queries:
# "Show me all nodes that haven't converged in the last hour"
# "Bootstrap a new Ubuntu node into the production environment"
# "Find every role that uses the base cookbook"
```

There is no build step — the skill is the Markdown file. The test is whether Claude applies the guidance correctly.

### When to Contribute

✅ Good candidates for updates:
- Chef Workstation or knife gains new subcommands or flags
- A common workflow has no coverage (e.g., knife-vault, knife-supermarket)
- An existing example has a bug or uses a deprecated flag
- A new troubleshooting pattern emerges from real-world use

❌ Not great candidates:
- Adding generic shell scripting advice
- Duplicating what `knife --help` already covers
- Personal style preferences without broader applicability

## Quality Checklist

Before opening a PR:

- [ ] Examples are copy-pasteable and accurate
- [ ] No deprecated flags or removed subcommands
- [ ] New sections follow the existing imperative, scannable style
- [ ] Conventional commit message used (for correct version bump)
- [ ] Validation workflow passes

## Questions and Issues

[GitHub Issues](https://github.com/siliconchaos/chef-skill/issues)
