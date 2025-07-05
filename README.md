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
twin myserver                      # Syncs to saved remote path
twin -p myserver                   # Bidirectional sync with saved path

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


## Features

- **Smart Pairing**: Remember remote paths for each directory
- **Configuration Memory**: Save custom rsync flags per remote
- **Bidirectional Sync**: Push and pull with `-p` flag
- **Auto Directory Creation**: Creates remote directories as needed
- **Per-Directory Settings**: Each directory can sync to different remote paths

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
