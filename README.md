# Chef Skill for Claude

[![Claude Skill](https://img.shields.io/badge/Claude-Skill-5865F2)](https://docs.claude.ai/docs/agent-skills)
[![Chef](https://img.shields.io/badge/Chef-Automate-F18B21)](https://www.chef.io/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Chef Automate and Chef Infra Server knife CLI skill for Claude Code. Get instant, accurate guidance on node management, cookbook operations, bootstrapping, remote execution, monitoring, and failure diagnostics — without leaving your terminal.

## What This Skill Provides

**Node Management**
- List, inspect, edit run-lists, and delete nodes
- Set and modify attributes safely with before/after diff workflow

**Cookbook Operations**
- Upload single or all cookbooks, manage versions, check dependencies
- Find all nodes/roles/environments that consume a given cookbook

**Roles & Environments**
- Create and update from JSON files, pin cookbook versions per environment

**Data Bags**
- Plain and encrypted data bag operations with secret key support

**Search**
- Full Solr query syntax — filter by platform, role, environment, or any attribute
- JSON output piped to `jq` for scripting

**Bootstrapping**
- Linux via SSH, Windows via WinRM
- Run-list and environment assignment at bootstrap time

**Remote Execution**
- `knife ssh` and `knife winrm` for parallel command execution across node sets

**Monitoring & Diagnostics**
- `knife status` with stale-node filtering
- `ohai_time` timestamp conversion
- Node failure diagnosis — Chef Automate UI, SSH log tailing, stacktrace location, why-run mode

## Installation

### Claude Code (Recommended)

```bash
/plugin marketplace add siliconchaos/chef-skill
/plugin install chef-automate@siliconchaos
```

### Manual

```bash
git clone https://github.com/siliconchaos/chef-skill ~/.claude/skills/chef-skill
```

### Verify

After installation, try:
```
"Show me all production nodes that haven't converged in the last hour"
```

Claude will automatically use the skill when working with Chef/knife.

## Quick Start Examples

**Check your knife setup:**
> "Verify my knife configuration is correct"

**Find cookbook consumers:**
> "Which nodes are using the nginx cookbook?"

**Safe attribute edit:**
> "Update the `app.debug` attribute on web-01 with a before/after diff"

**Bootstrap a new node:**
> "Bootstrap 10.0.1.50 as web-03 in the production environment with the base role"

**Diagnose a silent node:**
> "web-07 hasn't converged in 3 hours, help me diagnose it"

## What's Included

```
chef-automate/
├── SKILL.md                        # Full skill prompt loaded by Claude
└── references/
│   └── knife-commands.md           # Comprehensive knife command reference
└── scripts/
    └── check_setup.sh              # Knife configuration diagnostic script
```

## Requirements

- **Claude Code** or another Claude environment that supports skills
- **Chef Workstation** (includes `knife`) installed locally
- A configured `~/.chef/credentials` or `.chef/config.rb` pointing at your Chef Infra Server
- Network access to your Chef Infra Server / Chef Automate instance

## Contributing

Issues and pull requests are welcome at [github.com/siliconchaos/chef-skill](https://github.com/siliconchaos/chef-skill).

For significant changes, open an issue first to discuss the approach.

## Related Resources

- [Chef Docs — knife](https://docs.chef.io/workstation/knife/) — official knife reference
- [Chef Workstation](https://docs.chef.io/workstation/) — installation and setup
- [Chef Automate](https://docs.chef.io/automate/) — UI and pipeline documentation
- [knife search syntax](https://docs.chef.io/workstation/knife_search/) — Solr query reference

## Attribution

Skill structure and release automation inspired by [terraform-skill](https://github.com/antonbabenko/terraform-skill) by [Anton Babenko](https://github.com/antonbabenko).

## License

[MIT](LICENSE)
