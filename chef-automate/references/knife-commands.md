# knife Command Reference

Full flag reference for common knife commands. Use this when you need specific
flags or options not covered in SKILL.md.

## Table of Contents

1. [Global Options](#global-options)
2. [knife bootstrap](#knife-bootstrap)
3. [knife node](#knife-node)
4. [knife cookbook](#knife-cookbook)
5. [knife role](#knife-role)
6. [knife environment](#knife-environment)
7. [knife data bag](#knife-data-bag)
8. [knife search](#knife-search)
9. [knife ssh](#knife-ssh)
10. [knife winrm](#knife-winrm)
11. [knife status](#knife-status)
12. [knife client](#knife-client)
13. [knife ssl](#knife-ssl)
14. [knife config](#knife-config)
15. [knife supermarket](#knife-supermarket)

---

## Global Options

These work on every knife subcommand:

| Flag | Description |
|------|-------------|
| `-c CONFIG` | Specify config file path |
| `--profile PROFILE` | Use a named profile from `~/.chef/credentials` |
| `-F FORMAT` | Output format: `summary`, `json`, `text`, `yaml`, `pp` |
| `-u USERNAME` | Override client name |
| `-k KEY_FILE` | Override client key path |
| `-s SERVER_URL` | Override chef server URL |
| `--no-color` | Disable color output |
| `-V` / `--verbose` | More verbose output |
| `-D` / `--disable-editing` | Skip EDITOR for commands that open one |
| `-z` / `--local-mode` | Use Chef Zero (local server) |

---

## knife bootstrap

Install chef-client on a target and register with Chef Infra Server.

### Linux/SSH

```bash
knife bootstrap FQDN_OR_IP [options]
```

| Flag | Description |
|------|-------------|
| `--ssh-user USER` | SSH username |
| `--ssh-password PASSWORD` | SSH password |
| `-i IDENTITY_FILE` | Path to SSH identity file (private key) |
| `--ssh-port PORT` | SSH port (default: 22) |
| `--sudo` | Execute with sudo |
| `--use-sudo-password` | Sudo with the SSH password |
| `-N NAME` / `--node-name NAME` | Name to assign the node on Chef server |
| `-r RUN_LIST` / `--run-list RUN_LIST` | Initial run-list |
| `-E ENVIRONMENT` / `--environment ENVIRONMENT` | Chef environment to assign |
| `--bootstrap-version VERSION` | Chef Infra Client version to install |
| `--channel CHANNEL` | Install channel: `stable`, `current` |
| `--json-attributes JSON` | Node attributes as JSON string |
| `--json-attribute-file FILE` | Node attributes from JSON file |
| `--secret-file FILE` | Path to encrypted data bag secret |
| `--bootstrap-url URL` | Custom bootstrap script URL |
| `--bootstrap-no-proxy` | Bypass proxy for bootstrap |
| `--hint HINT_NAME[=PATH]` | Set Ohai hints |

### Windows/WinRM

Same flags plus:

| Flag | Description |
|------|-------------|
| `--winrm-user USER` | WinRM username |
| `--winrm-password PASSWORD` | WinRM password |
| `--winrm-port PORT` | WinRM port (default: 5985 HTTP, 5986 HTTPS) |
| `--winrm-transport TRANSPORT` | `plaintext` or `ssl` |
| `--winrm-shell SHELL` | `cmd` (default) or `powershell` or `elevated` |
| `--winrm-ssl-verify-mode MODE` | `verify_none` or `verify_peer` |
| `--ca-trust-file FILE` | Path to CA certificate for WinRM SSL |

---

## knife node

Manage nodes registered with Chef Infra Server.

```bash
knife node list [options]
knife node show NODE [options]
knife node edit NODE [options]
knife node delete NODE [options]
knife node run_list add NODE ITEMS [options]
knife node run_list remove NODE ITEMS [options]
knife node run_list set NODE ITEMS [options]
knife node environment set NODE ENVIRONMENT
knife node from file FILE [FILE ...]
knife node bulk delete REGEX
```

| Flag | Description |
|------|-------------|
| `-a ATTR` / `--attribute ATTR` | Show only this attribute (can repeat) |
| `-r` / `--run-list` | Show only run-list |
| `-m` / `--medium` | More detail than default |
| `-l` / `--long` | Full detail |
| `-F json` | JSON output (pipe to `jq` for filtering) |

**Examples:**
```bash
# Show all nodes with their IPs
knife node list -F json | jq -r '.[].name'
knife search node "*:*" -a ipaddress -F json

# Bulk delete nodes matching a regex
knife node bulk delete "^web-"

# Set environment for a node
knife node environment set web-01 production
```

---

## knife cookbook

Manage cookbooks on Chef Infra Server.

```bash
knife cookbook list [options]
knife cookbook show COOKBOOK [VERSION] [PART] [FILENAME]
knife cookbook upload [COOKBOOK ...] [options]
knife cookbook download COOKBOOK [VERSION] [options]
knife cookbook delete COOKBOOK [VERSION] [options]
knife cookbook metadata COOKBOOK
knife cookbook test [COOKBOOK ...]
```

| Flag | Description |
|------|-------------|
| `--all` | Apply to all cookbooks |
| `-a` / `--all-versions` | Show/delete all versions |
| `-d DIR` / `--dir DIR` | Directory for download |
| `--freeze` | Freeze cookbook (prevent overwrites) |
| `--force` | Overwrite frozen cookbook |
| `--include-dependencies` | Upload cookbook dependencies too |
| `-o COOKBOOK_PATH` | Override cookbook path |
| `-E ENVIRONMENT` | Limit to cookbooks in this environment |

**Examples:**
```bash
# Upload everything in your repo's cookbooks/ dir
knife cookbook upload --all

# Upload and freeze for production
knife cookbook upload nginx --freeze

# Force-overwrite a frozen cookbook
knife cookbook upload nginx --force

# List cookbook versions in JSON
knife cookbook list -F json | jq 'to_entries[] | {name: .key, versions: .value}'
```

---

## knife role

Manage roles.

```bash
knife role list
knife role show ROLE
knife role create ROLE
knife role edit ROLE
knife role delete ROLE
knife role from file FILE [FILE ...]
knife role bulk delete REGEX
```

Roles are typically managed from JSON files in a `roles/` directory and uploaded with `knife role from file`.

---

## knife environment

Manage environments.

```bash
knife environment list
knife environment show ENVIRONMENT
knife environment create ENVIRONMENT
knife environment edit ENVIRONMENT
knife environment delete ENVIRONMENT
knife environment from file FILE [FILE ...]
```

---

## knife data bag

Manage data bags and items.

```bash
knife data bag list
knife data bag show BAG [ITEM]
knife data bag create BAG [ITEM]
knife data bag edit BAG ITEM
knife data bag delete BAG [ITEM]
knife data bag from file BAG FILE [FILE ...]
```

| Flag | Description |
|------|-------------|
| `--secret SECRET` | Encryption secret string |
| `--secret-file FILE` | Path to encryption secret file |

**Encrypted data bag workflow:**
```bash
# Generate a secret key
openssl rand -base64 512 > ~/.chef/encrypted_data_bag_secret

# Create an encrypted item
knife data bag create secrets
knife data bag from file secrets db_creds.json \
  --secret-file ~/.chef/encrypted_data_bag_secret

# Read it back
knife data bag show secrets db_creds \
  --secret-file ~/.chef/encrypted_data_bag_secret -F json
```

---

## knife search

Query the Chef Infra Server's Solr index.

```bash
knife search INDEX QUERY [options]
```

**Indexes:** `node`, `client`, `role`, `environment`, or any data bag name.

**Query syntax (Solr):**
```
platform:ubuntu                    # exact match
platform:ubun*                     # wildcard
role:web*                          # wildcard role
platform:ubuntu AND role:webserver # AND
platform:ubuntu OR platform:centos # OR
NOT platform:windows               # NOT
ipaddress:[10.0.0.0 TO 10.0.1.0]  # range
```

| Flag | Description |
|------|-------------|
| `-a ATTR` | Return only this attribute (can repeat) |
| `-i` | ID-only output (node names) |
| `-r` | Run-list only |
| `-F json` | JSON output |
| `-R INT` | Rows per page (default 1000) |
| `--start INT` | Start row offset |

**Examples:**
```bash
# Find all nodes running a specific recipe
knife search node "recipes:nginx"

# Nodes with a specific FQDN pattern
knife search node "fqdn:web*.example.com"

# Get just IPs of production web nodes
knife search node "role:webserver AND chef_environment:production" \
  -a ipaddress -F json | jq -r '.rows[].ipaddress'
```

---

## knife ssh

Execute commands in parallel on nodes via SSH.

```bash
knife ssh QUERY COMMAND [options]
```

| Flag | Description |
|------|-------------|
| `--ssh-user USER` | SSH username |
| `--ssh-password PASSWORD` | SSH password |
| `-i IDENTITY_FILE` | SSH private key |
| `--ssh-port PORT` | SSH port |
| `--sudo` | Use sudo |
| `-a ATTR` | Attribute to use for host address (default: `ipaddress`) |
| `--concurrency N` | Max parallel connections (default: 10) |
| `--no-host-key-verify` | Skip host key verification |
| `--tmux` | Use tmux for interactive sessions |
| `--screen` | Use screen for interactive sessions |

**Examples:**
```bash
# Rolling chef-client run
knife ssh "chef_environment:production" "sudo chef-client" \
  --ssh-user ec2-user -i ~/.ssh/deploy-key.pem \
  --concurrency 5

# Use FQDN instead of IP
knife ssh "role:webserver" "uptime" \
  --ssh-user admin \
  -a fqdn

# Interactive SSH to a node
knife ssh "name:web-01" "bash" --ssh-user admin
```

---

## knife winrm

Execute commands in parallel on Windows nodes.

```bash
knife winrm QUERY COMMAND [options]
```

| Flag | Description |
|------|-------------|
| `--winrm-user USER` | WinRM username |
| `--winrm-password PASSWORD` | WinRM password |
| `--winrm-port PORT` | Port (5985 HTTP, 5986 HTTPS) |
| `--winrm-transport TRANSPORT` | `plaintext` or `ssl` |
| `--winrm-shell SHELL` | `cmd` or `powershell` (default: `cmd`) |
| `-a ATTR` | Attribute for host address |
| `--concurrency N` | Max parallel connections |

---

## knife status

Quick view of node convergence times.

```bash
knife status [QUERY]
```

| Flag | Description |
|------|-------------|
| `--hide-by-mins MINS` | Hide nodes that converged within N minutes |
| `-r` | Show run-list |
| `-F json` | JSON output |

---

## knife client

Manage API clients (authentication identities).

```bash
knife client list
knife client show CLIENT
knife client create CLIENT
knife client delete CLIENT
knife client reregister CLIENT    # Generate new private key
```

Clients are the authentication identity used by both nodes (chef-client) and workstations (knife). Each node gets its own client object.

---

## knife ssl

Manage SSL certificate trust.

```bash
knife ssl check [URL]             # Verify server cert chain
knife ssl fetch [URL]             # Download and trust server cert
```

Fetched certs are stored in `~/.chef/trusted_certs/`. These are automatically trusted by future knife and chef-client runs.

---

## knife config

Inspect and manage knife configuration.

```bash
knife config get [KEY]            # Show config value(s)
knife config get-profile          # Show current profile
knife config list-profiles        # List all profiles
knife config use-profile PROFILE  # Set default profile
```

**Useful during troubleshooting:**
```bash
knife config get client_name
knife config get client_key
knife config get chef_server_url
knife config get node_name
```

---

## knife supermarket

Interact with Chef Supermarket (community cookbooks).

```bash
knife supermarket list
knife supermarket search QUERY
knife supermarket show COOKBOOK
knife supermarket download COOKBOOK [VERSION]
knife supermarket install COOKBOOK [VERSION]   # Download + add to Berksfile
knife supermarket share COOKBOOK               # Publish your cookbook
```

| Flag | Description |
|------|-------------|
| `-m URL` | Supermarket URL (default: supermarket.chef.io) |
| `--ssl-verify-mode` | `verify_none` or `verify_peer` |

---

## Quick Diagnostic Checklist

When something's wrong, run these in order:

```bash
1. knife config get client_name         # Auth identity
2. knife config get chef_server_url     # Server URL
3. ls -la ~/.chef/*.pem                 # Keys exist and are readable
4. knife ssl check                      # TLS trust
5. knife client list                    # Basic connectivity
6. date && ssh SERVER date              # Clock skew check
```
