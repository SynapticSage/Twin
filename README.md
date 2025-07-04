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
# Basic sync (push only)
twin ssh-remote-name              # Syncs current dir to same path on remote
twin ssh-remote-name /path/to/dir # Syncs to remote:/path/to/dir

# Bidirectional sync (push then pull)
twin -p ssh-remote-name

# Custom rsync flags
twin -e "-av --delete" ssh-remote-name

# Show help
twin -h
```

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


## Requirements

- bash
- rsync
- SSH access to remote hosts
- Remote hosts must have the same directory structure

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
