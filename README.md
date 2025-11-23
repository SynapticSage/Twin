<div align="center">
  <img src="logo.png" alt="Twin Logo" width="200">
</div>

# Twin - Simple rsync wrapper

A lightweight convenience tool for pairing directories across remote hosts via rsync.


## Installation

```bash
make install              # Install to /usr/local/bin
make install PREFIX=~/bin # Install to custom location
```

## Usage

```bash
# Initial pairing (sets remote target path)
twin myserver /var/www/myapp      # Pairs current dir to remote:/var/www/myapp

# Subsequent syncs (uses saved pairing)
twin myserver                      # Syncs to saved remote path (push only)
twin -p myserver                   # Bidirectional sync (push then pull)
twin -P myserver                   # Pull only - sync from remote to local

# Custom rsync flags (saved for future use)
twin -e "-av --dry-run" myserver   # Test what would happen
twin -e "-av --delete" myserver    # CAUTION: Deletes files not in source

# Exclude patterns (use = syntax to avoid quoting issues)
twin -e '-avu --exclude=.venv/' myserver                    # Exclude .venv directory
twin -e '-avu --exclude=*.pyc --exclude=__pycache__/' myserver  # Exclude Python cache
twin -e '-avu --progress --exclude=node_modules/' myserver  # Show progress, exclude node_modules
twin -e '-avu --exclude=venv_py311/ --exclude=.venv/' myserver  # Multiple excludes

# First time usage (no pairing)
twin myserver                      # Syncs to same path on remote (default)

# Show help
twin -h
```

### Configuration Files

Twin saves your directory pairings in `.twin.{remote}.json` files:
- Remote path is remembered after first use
- Custom rsync flags are saved when using `-e`
- Each directory can have different pairings for different remotes
- Config files are git-ignored by default

Example: After running `twin prod /var/www/site` in `/Users/me/project`:
- Creates `.twin.prod.json` with the pairing
- Future `twin prod` commands will sync to `/var/www/site`

## Testing

### Test Configuration

Before running tests, configure your test environment:

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set your test remote:
   ```bash
   # SSH remote name for running tests (must be configured in ~/.ssh/config)
   TWIN_TEST_REMOTE=your-test-server
   ```

   Alternatively, set the environment variable directly:
   ```bash
   export TWIN_TEST_REMOTE=your-test-server
   ```

3. Ensure you have SSH access to the test remote:
   ```bash
   ssh your-test-server exit  # Should connect without password
   ```

### Test Suites

The project includes two test suites:

#### Unit Tests
```bash
make test
```

Tests basic functionality including:
- Installation/uninstallation
- Argument parsing
- Error handling
- Flag combinations

#### Integration Tests
```bash
make test-integration
```

Requires SSH access to the configured test remote. Tests real rsync operations:
- Basic file synchronization
- Directory sync
- Pull-back functionality
- Custom rsync flags
- Remote directory creation

#### Configuration Tests
```bash
./test_config.sh
```

Tests configuration file functionality:
- Config file creation
- Saved paths and flags
- Multiple directory pairings

#### Git Integration Tests
```bash
./test_git.sh
```

Tests git integration functionality:
- Git repository detection
- Remote setup and configuration
- Conflict handling
- SSH config parsing
- Non-git directory handling
- Config persistence


## Features

- **Smart Pairing**: Remember remote paths for each directory
- **Configuration Memory**: Save custom rsync flags per remote
- **Bidirectional Sync**: Push and pull with `-p` flag
- **Auto Directory Creation**: Creates remote directories as needed
- **Per-Directory Settings**: Each directory can sync to different remote paths
- **Git Integration**: Automatically link git repositories as remotes

## Git Integration

Twin can automatically set up git remotes between your local and remote directories when both are git repositories. This makes it easy to sync files with rsync while also being able to push/pull git commits between the machines.

### How It Works

When you pair a local git repository with a remote git repository (during initial pairing), Twin will:

1. Detect that both directories are git repositories
2. Prompt you for remote names (or use defaults)
3. Add each repository as a git remote on the other machine
4. Save the configuration for future syncs

### Basic Usage

```bash
# Initial pairing with git repos - Twin will detect and offer to link them
cd ~/my-project  # Local git repo
twin myserver /remote/project  # Remote is also a git repo
# Twin prompts you to set up git remotes

# Subsequent syncs - git remotes already configured
twin myserver  # Just syncs files, git remotes stay configured
```

### Git Flags

```bash
# Force git remote setup (even if already paired)
twin -g myserver

# Skip git remote setup
twin -G myserver

# Custom remote names
twin --git-local-name laptop myserver
twin --git-remote-name desktop myserver

# Use SSH config hostnames for remote names
twin --git-ssh-config myserver

# Combine flags
twin -g --git-local-name dev-laptop --git-remote-name prod-server myserver
```

### Interactive Prompts

If you don't provide remote names via flags, Twin will interactively ask you how to name the remotes:

```
Git repositories detected! Setting up git remotes.

Choose how to name the remote on the local machine:
  1) Use default name: target
  2) Enter custom name
  3) Use SSH config hostname: myserver.example.com

Choice (1-3) [1]:
```

### Remote Name Conflicts

If a git remote with the chosen name already exists, Twin will:
1. Detect the conflict
2. Ask you for an alternate name
3. Skip git setup if you press Enter without providing a name

```
Warning: Git remote 'target' already exists on local machine.
Enter alternate name (or press Enter to skip git remote setup):
```

### URL Formats

Twin intelligently chooses the git remote URL format:
- **SSH URLs** for remote machines: `myserver:/path/to/repo`
- **File paths** for same machine: `/path/to/repo`

### Default Remote Names

If you don't specify custom names:
- **Local machine** gets remote named: `target`
- **Remote machine** gets remote named: `source`

This means:
```bash
cd ~/my-project
twin myserver /remote/project

# Local repo now has remote 'target' -> myserver:/remote/project
# Remote repo now has remote 'source' -> youruser@yourmachine:~/my-project
```

### Using SSH Config Hostnames

With the `--git-ssh-config` flag, Twin will parse your `~/.ssh/config` to use meaningful names:

```bash
# In ~/.ssh/config:
# Host prod-server
#   HostName server.example.com

twin --git-ssh-config prod-server

# Local remote named: prod-server
# Remote remote named: yourhostname
```

### Working with Git After Setup

Once git remotes are configured:

```bash
# On local machine
git fetch target           # Fetch from remote
git pull target main       # Pull remote changes
git push target main       # Push to remote

# On remote machine (via SSH)
ssh myserver
cd /remote/project
git fetch source          # Fetch from your local machine
git pull source main      # Pull local changes
git push source main      # Push to your local machine
```

### Configuration Storage

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

### Non-Git Directories

Twin gracefully handles non-git directories:
- If neither directory is a git repo: Syncs files normally, no git setup attempted
- If only one is a git repo: Syncs files normally, no git setup attempted
- No errors or warnings if git is not relevant

### Examples

```bash
# Example 1: Accept defaults
twin myserver /remote/project
# Choose option 1 for both prompts -> uses 'target' and 'source'

# Example 2: Custom names
twin --git-local-name laptop --git-remote-name server myserver /remote/project
# No prompts, uses your custom names

# Example 3: Use SSH config
twin --git-ssh-config prod /remote/project
# Uses hostname from ~/.ssh/config

# Example 4: Skip git integration
twin -G myserver /remote/project
# Sets up file sync only, no git remotes

# Example 5: Force git setup later
twin -g myserver  # Runs git setup even though already paired
```

## Requirements

- bash
- rsync
- python3 (for configuration management)
- SSH access to remote hosts

## SSH Configuration

Twin uses SSH host aliases from your `~/.ssh/config` file. Example configuration:

```
Host myserver
    HostName example.com
    User myusername
    Port 22
    IdentityFile ~/.ssh/id_rsa

Host X
    HostName X.example.com
    User deploy
    Port 2222
```

Then use: `twin myserver` or `twin X`

## Uninstallation

```bash
make uninstall
```
