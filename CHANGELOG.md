# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Releases are automated from conventional commits:

| Commit prefix | Version bump |
|---------------|-------------|
| `feat!:` / `BREAKING CHANGE:` | Major |
| `feat:` | Minor |
| `fix:` / other | Patch |

## [1.0.0] - 2026-02-21

### Added

- Initial release of the `chef-automate` knife CLI skill
- Configuration guide (`~/.chef/credentials` and `.chef/config.rb`)
- Node management — list, show, edit, run-list, delete
- Cookbook management — upload, list, download, delete, dependency check
- Roles and environments — show, from file, edit, delete
- Data bags — list, show, create, from file, encrypted data bags
- Search — full Solr query syntax, attribute output, JSON formatting
- Finding cookbook/recipe consumers — nodes, roles, environments
- Safe attribute updates — before/after diff workflow for nodes, roles, environments
- Bootstrapping — Linux (SSH) and Windows (WinRM)
- `knife ssh` and `knife winrm` remote execution
- Status and monitoring — `knife status`, `ohai_time` timestamp conversion
- Node failure diagnostics — Chef Automate UI, SSH log tailing, stacktrace location, why-run
- Troubleshooting common issues (401 errors, SSL, search, cookbook upload)
- Output formatting reference
- `references/knife-commands.md` — comprehensive command reference
- `scripts/check_setup.sh` — diagnostic script for validating knife configuration
