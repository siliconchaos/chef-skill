---
name: chef-automate
version: 1.0.0
description: >
  Use this skill whenever the user wants to interact with Chef Automate or Chef
  Infra Server using the knife CLI. Covers configuration, node management,
  cookbook management, roles, environments, data bags, search, bootstrapping,
  SSH/WinRM execution, and troubleshooting. Trigger on any mention of knife,
  chef-client, Chef Automate, Chef Infra, cookbooks, nodes, environments, data
  bags, bootstrap, or managing infrastructure with Chef.
---

# Chef Automate — knife CLI Skill

## Overview

This skill helps you interact with **Chef Automate** and **Chef Infra Server** via the `knife` CLI. Whether you're uploading cookbooks, querying nodes, bootstrapping machines, or debugging convergence failures, knife is the primary workstation tool for all of it.

The architecture is: **knife → Chef Infra Server → Chef Automate** (Automate automatically collects run data when configured).

---

## Quick Start: Verify Your Setup

Before anything else, confirm knife is configured correctly:

```bash
knife config get client_name          # Who you're authenticated as
knife config get chef_server_url      # Which server you're hitting
knife ssl check                       # Verify SSL is trusted
knife client list                     # Smoke test — proves connectivity
```

If `ssl check` fails: run `knife ssl fetch` to download and trust the server's certificate.

---

## Configuration

Knife reads configuration from two sources (modern approach uses both):

### `~/.chef/credentials` (recommended, profile-based)

```toml
[default]
client_name     = "admin"
client_key      = "~/.chef/admin.pem"
chef_server_url = "https://chef-automate.example.com/organizations/myorg"

[staging]
client_name     = "deploy-user"
client_key      = "~/.chef/deploy-user.pem"
chef_server_url = "https://chef-automate.example.com/organizations/staging"
```

Switch profiles with `--profile staging` on any knife command.

### `.chef/config.rb` (project-level)

```ruby
current_dir = File.dirname(__FILE__)
node_name                "admin"
client_key               "#{current_dir}/admin.pem"
chef_server_url          "https://chef-automate.example.com/organizations/myorg"
cookbook_path            ["#{current_dir}/../cookbooks"]
```

**Common config problems:**
- Wrong `chef_server_url` (missing `/organizations/ORGNAME`)
- Key file path typo or wrong permissions (`chmod 600 ~/.chef/*.pem`)
- Clock skew > 15 minutes between workstation and server (causes 401s)

---

## Node Management

```bash
# List all nodes
knife node list

# Show full details for a node
knife node show web-01

# Show a specific attribute
knife node show web-01 -a kernel.machine

# Edit a node's run-list or attributes
knife node edit web-01

# Set run-list directly
knife node run_list set web-01 "recipe[nginx],role[base]"
knife node run_list add web-01 "recipe[monitoring]"
knife node run_list remove web-01 "recipe[old-recipe]"

# Delete a node (also delete its client: knife client delete web-01)
knife node delete web-01

# Delete both node and client in one go
knife node delete web-01 && knife client delete web-01
```

---

## Cookbook Management

```bash
# Upload a single cookbook
knife cookbook upload nginx

# Upload all cookbooks in the cookbook path
knife cookbook upload --all

# List cookbooks on the server
knife cookbook list

# Show versions
knife cookbook show nginx

# Download a cookbook from the server
knife cookbook download nginx --dir /tmp/downloaded-cookbooks

# Delete a specific version
knife cookbook delete nginx 1.2.3

# Delete all versions
knife cookbook delete nginx --all

# Check dependencies before upload
knife deps cookbooks/nginx/metadata.rb
```

Cookbooks are referenced by nodes through their **run-list**. Changes only take effect on a node's next `chef-client` run.

---

## Roles

Roles group run-lists and attributes that apply to multiple nodes.

```bash
# List roles
knife role list

# Show a role
knife role show base

# Upload role from a JSON file
knife role from file roles/base.json

# Edit a role interactively
knife role edit base

# Delete a role
knife role delete base
```

**Example role file (`roles/base.json`):**
```json
{
  "name": "base",
  "description": "Base configuration for all nodes",
  "run_list": ["recipe[ntp]", "recipe[users]", "recipe[monitoring]"],
  "default_attributes": { "ntp": { "servers": ["pool.ntp.org"] } },
  "override_attributes": {}
}
```

---

## Environments

Environments let you pin cookbook versions and set environment-specific attributes.

```bash
knife environment list
knife environment show production
knife environment from file environments/production.json
knife environment edit production
```

**Example environment file:**
```json
{
  "name": "production",
  "description": "Production environment",
  "cookbook_versions": { "nginx": "= 3.0.0", "base": ">= 2.0.0" },
  "default_attributes": {},
  "override_attributes": { "app": { "debug": false } }
}
```

---

## Data Bags

Data bags store arbitrary JSON data accessible to all nodes during converge.

```bash
# List data bags
knife data bag list

# List items in a data bag
knife data bag show users

# Show a specific item
knife data bag show users alice

# Create a data bag
knife data bag create users

# Create/edit an item from file
knife data bag from file users alice.json

# Edit an item interactively
knife data bag edit users alice

# Delete an item
knife data bag delete users alice

# Encrypted data bags (requires secret key)
knife data bag show secrets api-keys --secret-file ~/.chef/encrypted_data_bag_secret
knife data bag from file secrets api-keys.json --secret-file ~/.chef/encrypted_data_bag_secret
```

---

## Search

Search queries the Solr index on Chef Infra Server. Supports full Solr query syntax.

```bash
# All nodes
knife search node "*:*"

# Nodes by platform
knife search node "platform:ubuntu"

# Nodes in an environment
knife search node "chef_environment:production"

# Nodes with a specific role
knife search node "role:webserver"

# Combine conditions
knife search node "role:webserver AND chef_environment:production"

# Search with attribute output
knife search node "platform:centos" -a ipaddress -a kernel.machine

# Output as JSON (useful for scripting)
knife search node "platform:ubuntu" -F json

# Search other indexes: node, client, role, environment, data_bag_name
knife search role "*:*"
knife search environment "*:*"
```

---

## Finding What Uses a Cookbook or Recipe

Useful for auditing before you rename, delete, or change a cookbook's behavior.

```bash
# Nodes where the cookbook has actually run (from expanded run list in Solr)
knife search node "recipes:nginx"

# Nodes with a specific recipe
knife search node "recipes:nginx::install"

# Nodes where it's in the declared run_list (may not have converged yet)
knife search node "run_list:*nginx*"

# Roles that include the cookbook — dump all and filter with jq
knife search role "*:*" -F json | \
  jq -r '.rows[] | select(.run_list | any(. | test("nginx"))) | .name'

# Environments that pin a cookbook version
knife search environment "*:*" -F json | \
  jq -r '.rows[] | select(.cookbook_versions | has("nginx")) | .name'
```

`recipes:nginx` is more reliable than `run_list:*nginx*` — it reflects the expanded run list after roles are resolved.

---

## Safe Attribute Updates (with Before/After)

Saving a before snapshot lets you diff changes, audit history, and roll back if needed.

```bash
# Node attributes
knife node show web-01 -F json > web-01-before.json
cp web-01-before.json web-01-after.json
$EDITOR web-01-after.json
knife node from file web-01-after.json
diff web-01-before.json web-01-after.json

# Role attributes
knife role show base -F json > base-before.json
cp base-before.json base-after.json
$EDITOR base-after.json
knife role from file base-after.json
diff base-before.json base-after.json

# Environment attributes or cookbook version pins
knife environment show production -F json > production-before.json
cp production-before.json production-after.json
$EDITOR production-after.json
knife environment from file production-after.json
diff production-before.json production-after.json
```

**Note:** The JSON from `knife node show -F json` includes `automatic` (Ohai) attributes. Edit `default_attributes` / `override_attributes` freely — Ohai data is overwritten on the next `chef-client` run regardless.

---

## Bootstrapping New Nodes

Bootstrap installs `chef-client` on a target machine and registers it with the server.

### Linux (SSH)

```bash
# Basic bootstrap
knife bootstrap 192.168.1.10 \
  --ssh-user ec2-user \
  --sudo \
  --identity-file ~/.ssh/id_rsa \
  --node-name web-01 \
  --run-list "role[base],recipe[nginx]" \
  --environment production

# With password auth
knife bootstrap 192.168.1.10 \
  --ssh-user admin \
  --ssh-password 'secret' \
  --sudo \
  --node-name web-01
```

### Windows (WinRM)

```bash
knife bootstrap 192.168.1.20 \
  --winrm-user Administrator \
  --winrm-password 'Secret123!' \
  --winrm-shell powershell \
  --node-name win-01 \
  --run-list "role[windows-base]"
```

**Bootstrap requires:**
1. SSH/WinRM access to the target
2. `ORGANIZATION-validator.pem` in `~/.chef/` (for initial node registration)
3. Target can reach Chef Infra Server

---

## Running Commands on Nodes

### `knife ssh` — parallel command execution on Linux nodes

```bash
# Run chef-client on all production nodes
knife ssh "chef_environment:production" "sudo chef-client" \
  --ssh-user ec2-user \
  --identity-file ~/.ssh/id_rsa

# On a specific role
knife ssh "role:webserver" "sudo systemctl restart nginx" \
  --ssh-user admin

# Check disk usage across all nodes
knife ssh "*:*" "df -h" --ssh-user ec2-user
```

### `knife winrm` — parallel execution on Windows nodes

```bash
knife winrm "platform:windows" "chef-client" \
  --winrm-user Administrator \
  --winrm-password 'Secret!'
```

---

## Status and Monitoring

```bash
# Show all nodes and when they last converged
knife status

# Narrow to a subset
knife status "role:webserver"
knife status "chef_environment:production"

# Flag nodes that haven't checked in recently
knife status --hide-by-mins 60    # only show nodes silent for >60 min
```

### When did a specific node last talk to Chef?

`ohai_time` is the Unix timestamp of the last successful `chef-client` run:

```bash
knife node show web-01 -a ohai_time

# Human-readable
knife node show web-01 -F json | \
  python3 -c "import json,sys,datetime; d=json.load(sys.stdin); \
  print(datetime.datetime.fromtimestamp(d['ohai_time']).strftime('%Y-%m-%d %H:%M:%S'))"
```

---

## Diagnosing Node Failures

For run history and failure details, **Chef Automate UI → Infrastructure → Client Runs** is the most complete view. For a quick check, `knife status "name:web-01"` shows when it last converged — silence for hours is a red flag.

### Dig deeper via SSH

```bash
# Tail the chef-client log directly
knife ssh "name:web-01" "sudo tail -100 /var/log/chef/client.log" \
  --ssh-user ec2-user -i ~/.ssh/id_rsa

# systemd journal (if chef-client runs as a service)
knife ssh "name:web-01" "sudo journalctl -u chef-client -n 100 --no-pager" \
  --ssh-user ec2-user

# Panic stacktrace (written when chef-client crashes hard)
knife ssh "name:web-01" "sudo cat /var/chef/cache/chef-stacktrace.out 2>/dev/null || echo 'no stacktrace'" \
  --ssh-user ec2-user
```

### Trigger a run

```bash
# Dry-run (why-run): shows what chef would change without actually doing it
knife ssh "name:web-01" "sudo chef-client --why-run" --ssh-user ec2-user

# Real run with live output
knife ssh "name:web-01" "sudo chef-client" --ssh-user ec2-user
```

---

## Troubleshooting Common Issues

**401 Unauthorized**
- Clock skew: sync clocks on workstation and server
- Wrong key: check `knife config get client_name` matches your `.pem` filename
- Expired/regenerated key: re-download `.pem` from Chef Automate UI

**SSL errors**
```bash
knife ssl check     # Shows what's wrong
knife ssl fetch     # Downloads and trusts the server cert
```

**Node not converging after bootstrap**
```bash
knife node show NODE_NAME    # Verify run-list was set
knife client show NODE_NAME  # Verify client registered
# Check logs on the node: /var/log/chef/client.log
```

**Can't upload cookbook — dependency missing**
```bash
knife cookbook upload nginx --include-dependencies
# Or upload the dependency first
knife cookbook upload base && knife cookbook upload nginx
```

**Search returns no results**
- Index may be stale — wait a minute and retry
- Check query syntax: use simple `role:webserver` not `role:"webserver"` for single values
- Verify the attribute exists: `knife node show NODE_NAME -a ATTRIBUTE`

---

## Output Formatting

All knife commands accept `-F FORMAT`:

```bash
knife node list -F json
knife search node "*:*" -F json | jq '.rows[].name'
knife role show base -F json > roles/base.json
```

Formats: `summary` (default), `json`, `text`, `yaml`, `pp`

---

## Reference

For full command flags and options, see `references/knife-commands.md`.
