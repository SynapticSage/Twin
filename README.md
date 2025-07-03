# Twin - Simple rsync wrapper

A lightweight tool for syncing directories to remote hosts using rsync.

## Installation

```bash
make install              # Install to /usr/local/bin
make install PREFIX=~/bin # Install to custom location
```

## Usage

```bash
# Basic sync (push only)
twin ssh-remote-name
twin ssh-remote-name /path/to/directory

# Bidirectional sync (push then pull)
twin -p ssh-remote-name

# Custom rsync flags
twin -e "-av --delete" ssh-remote-name

# Show help
twin -h
```

## Testing

The project includes two test suites:

### Unit Tests
```bash
make test
```

Tests basic functionality including:
- Installation/uninstallation
- Argument parsing
- Error handling
- Flag combinations

### Integration Tests
```bash
make test-integration
```

Requires SSH access to localhost. Tests real rsync operations:
- Basic file synchronization
- Directory sync
- Pull-back functionality
- Custom rsync flags

To enable SSH to localhost for testing:
```bash
ssh-keygen  # If you don't have SSH keys
ssh-copy-id localhost
```

## Requirements

- bash
- rsync
- SSH access to remote hosts
- Remote hosts must have the same directory structure

## Uninstallation

```bash
make uninstall
```