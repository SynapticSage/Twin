# Contributing to Twin

Thank you for your interest in contributing to Twin! This guide covers development setup, testing, and contribution guidelines.

## Table of Contents

- [Development Setup](#development-setup)
- [Testing](#testing)
- [Code Structure](#code-structure)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)

## Development Setup

### Prerequisites

- bash
- rsync
- python3
- git
- make
- SSH access to a test remote (for integration tests)

### Clone Repository

```bash
git clone https://github.com/your-username/twin.git
cd twin
```

### Local Development

You can test Twin without installing it system-wide:

```bash
# Run from source
./twin -h

# Test with local remote (same machine)
./twin localhost ~/test-target
```

## Testing

Twin includes multiple test suites to ensure reliability.

### Test Configuration

Before running tests, configure your test environment:

#### Option 1: Environment File

```bash
# Copy example environment file
cp .env.example .env

# Edit .env and set your test remote
nano .env
```

Set the following variable:
```bash
TWIN_TEST_REMOTE=your-test-server
```

#### Option 2: Environment Variable

```bash
export TWIN_TEST_REMOTE=your-test-server
```

### SSH Test Setup

Ensure you have SSH access to the test remote:

```bash
# Should connect without password
ssh your-test-server exit

# Configure in ~/.ssh/config if needed
Host your-test-server
    HostName example.com
    User testuser
    IdentityFile ~/.ssh/id_ed25519
```

### Unit Tests

Tests basic functionality without requiring remote access:

```bash
make test
```

Tests include:
- Installation/uninstallation
- Argument parsing
- Error handling
- Flag combinations
- Help text generation

**Expected output**:
```
=== Twin Test Suite ===
[PASS] make install should succeed
[PASS] twin binary should exist after install
...
Total tests: 8
Passed: 12
Failed: 0
```

### Integration Tests

Tests real rsync operations with a remote server:

```bash
make test-integration
```

**Requirements**:
- `TWIN_TEST_REMOTE` environment variable set
- SSH access to test remote
- Write permissions on test remote

Tests include:
- Basic file synchronization
- Directory sync
- Pull-back functionality
- Custom rsync flags
- Remote directory creation

**Expected output**:
```
=== Integration Tests ===
[PASS] Files sync correctly
[PASS] Directories sync correctly
...
```

### Configuration Tests

Tests configuration file functionality:

```bash
./test_config.sh
```

Tests include:
- Config file creation
- Saved paths and flags
- Multiple directory pairings
- Config persistence

### Git Integration Tests

Tests git remote setup functionality:

```bash
./test_git.sh
```

Tests include:
- Git repository detection
- Remote setup and configuration
- Conflict handling
- SSH config parsing
- Non-git directory handling
- Config persistence

**Expected output**:
```
======================================
  Twin Git Integration Test Suite
======================================

[PASS] Git repository detection - local
[PASS] Configuration schema - git integration fields
...
Total tests:  10
Passed:       15
Failed:       0

All tests passed!
```

### Run All Tests

```bash
# Unit tests only
make test

# Include integration tests (requires test remote)
make test && make test-integration && ./test_config.sh && ./test_git.sh
```

## Code Structure

### Main Components

```
twin/
├── twin                 # Main bash script (sync logic, git integration)
├── twin-config          # Python config manager (JSON read/write)
├── test_twin.sh         # Unit tests
├── test_integration.sh  # Integration tests
├── test_config.sh       # Config persistence tests
├── test_git.sh          # Git integration tests
├── Makefile             # Installation and test targets
├── README.md            # User-facing documentation
├── CONTRIBUTING.md      # This file
└── docs/                # Detailed documentation
    ├── git-integration.md
    ├── advanced-usage.md
    ├── ssh-setup.md
    └── troubleshooting.md
```

### twin Script Structure

The main `twin` bash script is organized into sections:

1. **Default values** (lines 12-24): Configuration variables
2. **Helper functions** (lines 26-221): Git detection, SSH parsing, prompts
3. **show_help()** (lines 223-257): Help text
4. **Argument parsing** (lines 259-325): Command-line flags
5. **Configuration loading** (lines 337-363): Read saved config
6. **SSH testing** (lines 370-376): Verify connection
7. **Git integration** (lines 390-452): Set up git remotes
8. **Rsync execution** (lines 454-468): Perform sync

### twin-config Script

Python script for JSON configuration management:

1. **get_config_filename()**: Generate config filename
2. **read_config()**: Read JSON from file
3. **write_config()**: Write/update JSON
4. **main()**: CLI argument handling

## Making Changes

### Development Workflow

1. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes**:
   - Edit `twin` for bash functionality
   - Edit `twin-config` for config management
   - Add tests for new features

3. **Test changes**:
   ```bash
   make test
   ./test_git.sh
   # Test manually
   ./twin -h
   ```

4. **Commit changes**:
   ```bash
   git add .
   git commit -m "feat: Add new feature"
   ```

### Code Style

#### Bash (twin)

- Indent with 4 spaces
- Use meaningful variable names
- Add comments for complex logic
- Quote variables: `"$VARIABLE"`
- Use `set -e` for error handling
- Functions before usage

**Example**:
```bash
# Good
check_remote_git_repo() {
    local remote="$1"
    local path="$2"
    ssh "$remote" "[ -d '$path/.git' ]" 2>/dev/null
}

# Avoid
check_remote_git_repo() {
local remote=$1; local path=$2
ssh $remote [ -d $path/.git ] 2>/dev/null
}
```

#### Python (twin-config)

- Follow PEP 8
- Use 4-space indentation
- Add docstrings to functions
- Type hints encouraged

**Example**:
```python
def read_config(remote: str, directory: str = None) -> dict:
    """Read configuration for a remote from the current or specified directory"""
    # Implementation
```

### Testing New Features

1. **Add unit tests** to `test_twin.sh`
2. **Add integration tests** if feature uses SSH/rsync
3. **Add git tests** to `test_git.sh` if feature affects git integration
4. **Document** in appropriate docs file

### Documentation

When adding features:

1. **Update README.md** if core functionality changes
2. **Add to appropriate guide**:
   - Git features → `docs/git-integration.md`
   - Advanced rsync → `docs/advanced-usage.md`
   - SSH config → `docs/ssh-setup.md`
3. **Update help text** in `twin` script
4. **Add examples** showing usage

## Pull Request Process

### Before Submitting

1. **Run all tests**:
   ```bash
   make test
   ./test_config.sh
   ./test_git.sh
   ```

2. **Check for shellcheck warnings** (if available):
   ```bash
   shellcheck twin
   ```

3. **Test manually**:
   ```bash
   # Test basic functionality
   ./twin -h
   ./twin testserver /tmp/test
   ```

4. **Update documentation**

### Submitting PR

1. **Push to your fork**:
   ```bash
   git push origin feature/my-feature
   ```

2. **Create pull request** on GitHub

3. **Describe changes**:
   - What problem does it solve?
   - How does it work?
   - Any breaking changes?
   - Test coverage

4. **Link related issues**

### PR Review Checklist

- [ ] Tests pass
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
- [ ] Commit messages are clear
- [ ] Feature is backwards compatible

## Code Review

We review PRs for:

- **Functionality**: Does it work as intended?
- **Tests**: Are there adequate tests?
- **Documentation**: Is it documented?
- **Code quality**: Is it readable and maintainable?
- **Compatibility**: Does it work across environments?

## Release Process

(For maintainers)

1. Update version number
2. Update CHANGELOG.md
3. Tag release: `git tag v1.2.3`
4. Push tag: `git push origin v1.2.3`
5. Create GitHub release

## Questions?

- Open an issue for bugs or feature requests
- Start a discussion for questions
- Check existing issues before creating new ones

---

Thank you for contributing to Twin!

[Back to main README](../README.md)
