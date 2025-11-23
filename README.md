<div align="center">
  <img src="logo.png" alt="Twin Logo" width="200">
</div>

# Twin - Painlessly pair directories across machines

> Have you ever wanted to painlessly pair up one directory on two machines? Twin is a lightweight convenience tool for pairing directories across remote hosts via rsync and git. It's a one-off command to pair-up folders.

## Quick Start

```bash
# 1. Pair your local directory with a remote path
twin myserver /var/www/myapp

# 2. Make changes locally, then sync
twin myserver

# 3. Pull changes from remote
twin -p myserver
```

That's it. Twin remembers the pairing and your preferences.

## What is Twin?

Twin solves a common developer problem: keeping directories synchronized across machines without the overhead of version control or cloud services. You run one command to pair a local directory with a remote path, and Twin remembers everything - the remote path, your rsync preferences, even git remote setup if both directories are repositories.

Unlike raw rsync, you don't re-type paths and flags every time. Unlike git alone, large binary files sync efficiently. Twin gives you the best of both worlds.

## Installation

```bash
make install              # Install to /usr/local/bin
make install PREFIX=~/bin # Install to custom location
```

Requirements: bash, rsync, python3, SSH access to remote hosts

## How It Works

**Pairing**: The first time you sync to a remote, Twin saves the pairing:
```bash
twin myserver /var/www/myapp  # Creates .twin.myserver.json
```

**Persistence**: Future syncs use the saved path and flags:
```bash
twin myserver  # Syncs to /var/www/myapp automatically
```

**Git Integration**: If both directories are git repos, Twin offers to set them up as git remotes bidirectionally. You can sync files with rsync and commits with git.

## Basic Usage

### Sync Modes

```bash
twin myserver              # Push: local → remote
twin -p myserver           # Push then pull: bidirectional sync
twin -P myserver           # Pull only: remote → local
```

### First-Time Pairing

```bash
cd ~/my-project
twin myserver /remote/path  # Sets up pairing, syncs files
```

### Custom Rsync Flags

```bash
# Flags are saved for future syncs
twin -e "-av --delete" myserver           # Delete extra files on remote
twin -e "-avu --progress" myserver        # Show detailed progress
```

### Common Exclusions

```bash
twin -e '--exclude=node_modules/ --exclude=.venv/' myserver
twin -e '--exclude=*.pyc --exclude=__pycache__/' myserver
```

### Git Repository Pairing

When both directories are git repos, Twin prompts to link them:

```bash
twin myserver /remote/project
# Twin detects git repos and offers to set up remotes
# After setup: git push target main, git pull target main
```

Use `-g` to force git setup, `-G` to skip it.

## Command Reference

| Flag | Description |
|------|-------------|
| `-p` | Bidirectional sync (push then pull) |
| `-P` | Pull only (remote to local) |
| `-e FLAGS` | Custom rsync flags (saved for future use) |
| `-g` | Force git remote setup |
| `-G` | Skip git remote setup |
| `--git-local-name NAME` | Custom git remote name on local machine |
| `--git-remote-name NAME` | Custom git remote name on remote machine |
| `--git-ssh-config` | Use SSH config hostnames for git remotes |
| `-h` | Show help |

## Configuration

Twin stores pairings in `.twin.{remote}.json` files in each directory:

```json
{
  "remote_path": "/var/www/myapp",
  "rsync_flags": "-avu --progress",
  "last_sync": "2025-11-23T10:30:00",
  "git_integration": {
    "local_remote_name": "target",
    "remote_remote_name": "source",
    "setup_complete": true
  }
}
```

Config files are automatically git-ignored.

## SSH Setup

Twin uses SSH host aliases from `~/.ssh/config`:

```
Host myserver
    HostName example.com
    User deploy
    IdentityFile ~/.ssh/id_rsa
```

Then use: `twin myserver`

See [docs/ssh-setup.md](docs/ssh-setup.md) for detailed SSH configuration.

## Documentation

- **[Advanced Usage](docs/advanced-usage.md)** - Complex rsync patterns, multiple remotes, workflow examples
- **[Git Integration Guide](docs/git-integration.md)** - Complete git integration documentation
- **[SSH Setup](docs/ssh-setup.md)** - SSH configuration, key management, troubleshooting
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Contributing](CONTRIBUTING.md)** - Development setup, running tests

## Common Workflows

**Development on local, deploy to server:**
```bash
# Initial setup
twin prod /var/www/myapp

# Daily workflow
# ... make changes ...
twin prod              # Deploy to production
```

**Working across laptop and desktop:**
```bash
# On laptop
twin desktop ~/projects/myapp

# On desktop (after laptop sync)
twin -P laptop  # Pull changes from laptop
```

**Managing binary assets with git code:**
```bash
twin -e '--exclude=*.git/' myserver  # Sync everything except .git
# Then use git push/pull for code history
```

## Uninstallation

```bash
make uninstall
```

## License

MIT
