# Git Integration Guide

Twin can automatically set up git remotes between your local and remote directories when both are git repositories. This makes it easy to sync files with rsync while also being able to push/pull git commits between machines.

## Table of Contents

- [How It Works](#how-it-works)
- [Quick Start](#quick-start)
- [Command-Line Flags](#command-line-flags)
- [Interactive Prompts](#interactive-prompts)
- [Remote Naming](#remote-naming)
- [Conflict Resolution](#conflict-resolution)
- [Configuration](#configuration)
- [Working with Git After Setup](#working-with-git-after-setup)
- [Examples](#examples)

## How It Works

When you pair a local git repository with a remote git repository during initial pairing, Twin will:

1. **Detect** that both directories are git repositories
2. **Prompt** you for remote names (or use defaults/flags)
3. **Add** each repository as a git remote on the other machine bidirectionally
4. **Save** the configuration for future syncs

The git remote setup only runs once during initial pairing unless you force it with `-g`.

## Quick Start

```bash
# Both directories are git repos
cd ~/my-project
twin myserver /remote/project

# Twin prompts:
# Git repositories detected! Setting up git remotes.
#
# Choose how to name the remote on the local machine:
#   1) Use default name: target
#   2) Enter custom name
#   3) Use SSH config hostname: server.example.com
#
# Choice (1-3) [1]:

# After selecting option 1 for both prompts:
# Local repo now has remote 'target' -> myserver:/remote/project
# Remote repo now has remote 'source' -> youruser@yourmachine:~/my-project

# Now you can use git commands:
git fetch target
git pull target main
git push target main
```

## Command-Line Flags

Control git integration behavior with these flags:

### Skip or Force Setup

```bash
twin -g myserver           # Force git remote setup (even if already paired)
twin -G myserver           # Skip git remote setup entirely
```

### Custom Remote Names

```bash
twin --git-local-name laptop myserver
# Local machine will have remote named 'laptop' instead of 'target'

twin --git-remote-name desktop myserver
# Remote machine will have remote named 'desktop' instead of 'source'

# Combine both:
twin --git-local-name dev --git-remote-name prod myserver
```

### SSH Config Hostname

```bash
twin --git-ssh-config myserver
# Uses hostname from ~/.ssh/config as remote name
# If SSH config has 'HostName server.example.com', uses that name
```

### Combined Example

```bash
twin -g --git-local-name laptop --git-remote-name server myserver
# Forces setup with custom names on both sides
```

## Interactive Prompts

If you don't provide remote names via flags, Twin asks interactively:

```
Git repositories detected! Setting up git remotes.

Choose how to name the remote on the local machine:
  1) Use default name: target
  2) Enter custom name
  3) Use SSH config hostname: 192.168.0.75

Choice (1-3) [1]:
```

### Option 1: Default Name

Uses "target" for local machine, "source" for remote machine.

### Option 2: Custom Name

```
Choice (1-3) [1]: 2
Enter custom remote name: production

# Remote will be named 'production'
```

### Option 3: SSH Config Hostname

Uses the hostname from your SSH config. If the SSH config has:

```
Host myserver
    HostName server.example.com
```

Twin will suggest "server.example.com" as the remote name.

## Remote Naming

### Default Names

Without custom names:
- **Local machine** gets remote named: `target`
- **Remote machine** gets remote named: `source`

Rationale: You're on the source machine targeting a remote.

### Custom Names

Provide specific names for clarity:

```bash
# Development workflow
twin --git-local-name staging myserver

# Multi-machine setup
twin --git-local-name laptop desktop
twin --git-local-name desktop laptop
```

### SSH Config Names

Use actual hostnames for meaningful remote names:

```bash
twin --git-ssh-config prod-server
# If SSH config has HostName: production.example.com
# Remote will be named: production.example.com
```

## Conflict Resolution

If a git remote with the chosen name already exists, Twin handles it gracefully:

```
Warning: Git remote 'target' already exists on local machine.
Enter alternate name (or press Enter to skip git remote setup):
```

**Options:**

1. **Enter alternate name**: `target2`, `myserver`, etc.
2. **Press Enter**: Skip git remote setup entirely
3. **Use `-g` flag later**: Force git setup after resolving conflicts manually

### Checking Existing Remotes

```bash
cd ~/my-project
git remote -v
# origin  https://github.com/user/repo.git (fetch)
# origin  https://github.com/user/repo.git (push)
# target  myserver:/remote/project (fetch)
# target  myserver:/remote/project (push)
```

## Configuration

Git integration settings are stored in `.twin.{remote}.json`:

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

### Fields

- `local_remote_name`: Name of remote on local machine
- `remote_remote_name`: Name of remote on remote machine
- `setup_complete`: Whether git setup has been completed

## Working with Git After Setup

### On Local Machine

```bash
# Fetch from remote
git fetch target

# Pull changes from remote
git pull target main

# Push to remote
git push target main

# View all remotes
git remote -v
```

### On Remote Machine

SSH to the remote and use the reverse remote:

```bash
ssh myserver
cd /remote/project

# Fetch from your local machine
git fetch source

# Pull changes from your local machine
git pull source main

# Push to your local machine
git push source main
```

### Common Workflow

```bash
# On local machine
git add .
git commit -m "Add feature"
git push target main

# On remote machine (via SSH)
ssh myserver
cd /remote/project
git pull source main
```

## Examples

### Example 1: Accept Defaults

```bash
cd ~/my-project
twin myserver /remote/project
# Choose option 1 for both prompts
# Result:
# - Local: remote 'target' -> myserver:/remote/project
# - Remote: remote 'source' -> you@yourmachine:~/my-project
```

### Example 2: Custom Names

```bash
twin --git-local-name laptop --git-remote-name server myserver /remote/project
# No prompts, uses custom names
# Result:
# - Local: remote 'laptop' -> myserver:/remote/project
# - Remote: remote 'server' -> you@yourmachine:~/my-project
```

### Example 3: SSH Config Hostnames

```bash
# ~/.ssh/config has:
# Host prod
#   HostName production.example.com

twin --git-ssh-config prod /var/www/app
# Result:
# - Local: remote 'production.example.com'
# - Remote: remote 'yourhostname'
```

### Example 4: Skip Git Integration

```bash
twin -G myserver /remote/project
# Sets up file sync only, no git remotes
```

### Example 5: Force Setup After Initial Pairing

```bash
# Already paired, but want to set up git remotes now
twin -g myserver
# Runs git setup even though directory is already paired
```

### Example 6: Handle Conflict

```bash
twin myserver /remote/project
# Git repositories detected! Setting up git remotes.
#
# Choose how to name the remote on the local machine:
#   1) Use default name: target
#   2) Enter custom name
#   3) Use SSH config hostname: 192.168.0.75
#
# Choice (1-3) [1]: 1
#
# Warning: Git remote 'target' already exists on local machine.
# Enter alternate name (or press Enter to skip git remote setup): staging
#
# Remote added: staging -> myserver:/remote/project
```

## URL Formats

Twin intelligently chooses the git remote URL format:

### SSH URLs (Default)

For remote machines:
```
myserver:/path/to/repo
user@host:/path/to/repo
```

### File Paths

For same machine (rare, but supported):
```
/path/to/repo
```

## Non-Git Directories

Twin gracefully handles non-git directories:

- **Neither is a git repo**: Syncs files normally, no git setup attempted
- **Only one is a git repo**: Syncs files normally, no git setup attempted
- **No errors or warnings**: Git integration is silent when not applicable

## Troubleshooting

### Remote Already Exists

**Problem**: "Warning: Git remote 'target' already exists"

**Solutions**:
1. Enter alternate name when prompted
2. Remove existing remote: `git remote remove target`
3. Use custom name: `twin --git-local-name other-name myserver`

### Can't Reach Remote Git Repo

**Problem**: Git commands fail after setup

**Check**:
1. SSH connection works: `ssh myserver`
2. Remote directory is a git repo: `ssh myserver "cd /path && git status"`
3. Remote URL is correct: `git remote -v`

### Want to Change Remote Names

**Solution**:
1. Remove existing remotes: `git remote remove target`
2. Force re-setup: `twin -g --git-local-name newname myserver`

### Setup Didn't Run

**Possible reasons**:
- Not initial pairing (already paired) - use `-g` to force
- Used `-G` flag to skip
- One or both directories aren't git repos
- Setup already completed (check `.twin.{remote}.json`)

---

[Back to main README](../README.md)
