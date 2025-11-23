# Troubleshooting Guide

Common issues and solutions when using Twin.

## Table of Contents

- [Connection Issues](#connection-issues)
- [Sync Issues](#sync-issues)
- [Configuration Issues](#configuration-issues)
- [Git Integration Issues](#git-integration-issues)
- [Permission Errors](#permission-errors)
- [Performance Issues](#performance-issues)

## Connection Issues

### Cannot Connect to SSH Remote

**Error**: `Error: Cannot connect to SSH remote 'myserver'`

**Solutions**:

1. **Verify SSH config exists**:
   ```bash
   grep -A 5 "^Host myserver" ~/.ssh/config
   ```

2. **Test SSH connection directly**:
   ```bash
   ssh myserver exit
   # Should connect without password
   ```

3. **Check SSH config format**:
   ```bash
   Host myserver
       HostName example.com
       User deploy
       # Note: SSH config is indented with spaces or tabs
   ```

4. **Verify network connectivity**:
   ```bash
   ping example.com
   ```

See [SSH Setup Guide](ssh-setup.md) for detailed SSH configuration.

### Connection Timeout

**Error**: Connection times out when syncing

**Solutions**:

1. **Increase SSH timeout**:
   ```bash
   # In ~/.ssh/config
   Host myserver
       ConnectTimeout 30
       ServerAliveInterval 60
   ```

2. **Test connection speed**:
   ```bash
   time ssh myserver exit
   ```

3. **Check firewall/network**:
   ```bash
   # Test if port is open
   nc -zv example.com 22
   ```

## Sync Issues

### Files Not Syncing

**Problem**: Files exist locally but don't appear on remote

**Diagnosis**:

```bash
# Run with dry-run to see what would sync
twin -e "-av --dry-run" myserver

# Check what Twin would transfer
```

**Common causes**:

1. **Files are excluded**:
   ```bash
   # Check rsync flags for --exclude
   cat .twin.myserver.json | grep rsync_flags
   ```

2. **Files are newer on remote**:
   ```bash
   # Force transfer regardless of timestamp
   twin -e "-av --ignore-times" myserver
   ```

3. **Permission issues** (see [Permission Errors](#permission-errors))

### Partial Transfer

**Problem**: Transfer interrupts midway

**Solution**:

```bash
# Enable partial transfer resume
twin -e "-avuP" myserver
# -P = --partial --progress
```

### Files Deleted Unexpectedly

**Problem**: Files disappear after sync

**Cause**: Using `--delete` flag

**Check**:
```bash
cat .twin.myserver.json | grep rsync_flags
# Look for --delete
```

**Fix**:
```bash
# Remove --delete flag
twin -e "-avu --progress" myserver
```

## Configuration Issues

### Configuration Not Saving

**Problem**: Twin doesn't remember remote path or flags

**Check**:

1. **Verify config file exists**:
   ```bash
   ls -la .twin.*.json
   ```

2. **Check file permissions**:
   ```bash
   ls -la .twin.myserver.json
   # Should be writable by user
   ```

3. **Verify twin-config is executable**:
   ```bash
   which twin-config
   ls -la $(which twin-config)
   ```

### Config File Corrupted

**Problem**: Error reading config file

**Solution**:

```bash
# Check config format
cat .twin.myserver.json
# Should be valid JSON

# If corrupted, remove and re-pair
rm .twin.myserver.json
twin myserver /remote/path
```

### Multiple Configs Interfering

**Problem**: Wrong remote path used

**Cause**: Multiple `.twin.*.json` files in directory

**Check**:
```bash
ls -la .twin.*.json
```

**Solution**: Each remote should have one config file. Remove extras:
```bash
rm .twin.old-server.json
```

## Git Integration Issues

### Git Remote Already Exists

**Error**: `Warning: Git remote 'target' already exists on local machine`

**Solutions**:

1. **Provide alternate name when prompted**:
   ```
   Enter alternate name (or press Enter to skip): staging
   ```

2. **Remove existing remote**:
   ```bash
   git remote remove target
   twin -g myserver  # Force re-setup
   ```

3. **Use custom name from start**:
   ```bash
   twin --git-local-name custom-name myserver
   ```

### Git Remote Not Created

**Problem**: Expected git remote setup didn't happen

**Check**:

1. **Both directories are git repos**:
   ```bash
   ls -la .git        # Local
   ssh myserver "ls -la /remote/path/.git"  # Remote
   ```

2. **Setup wasn't skipped**:
   ```bash
   # Check if -G flag was used
   # Check config
   cat .twin.myserver.json | grep git_integration
   ```

3. **Setup already completed**:
   ```bash
   # Check if setup_complete is true
   cat .twin.myserver.json | grep setup_complete
   ```

**Force git setup**:
```bash
twin -g myserver
```

### Cannot Fetch from Git Remote

**Problem**: `git fetch target` fails after Twin setup

**Check**:

1. **Verify remote exists**:
   ```bash
   git remote -v
   ```

2. **Test SSH connection**:
   ```bash
   ssh myserver exit
   ```

3. **Verify remote path is git repo**:
   ```bash
   ssh myserver "cd /remote/path && git status"
   ```

4. **Check remote URL**:
   ```bash
   git remote get-url target
   # Should be: myserver:/remote/path
   ```

See [Git Integration Guide](git-integration.md) for more details.

## Permission Errors

### Permission Denied on Remote

**Error**: `rsync: mkdir "/remote/path" failed: Permission denied`

**Solutions**:

1. **Check remote directory permissions**:
   ```bash
   ssh myserver "ls -ld /remote/path"
   ```

2. **Verify SSH user has write access**:
   ```bash
   ssh myserver "touch /remote/path/test.txt && rm /remote/path/test.txt"
   ```

3. **Create directory with correct ownership**:
   ```bash
   ssh myserver "sudo mkdir -p /remote/path && sudo chown $USER /remote/path"
   ```

### File Ownership Issues

**Problem**: Synced files have wrong owner on remote

**Solution**: Use rsync's ownership preservation (may require sudo):

```bash
# Preserve ownership (may need sudo on remote)
twin -e "-avugo" myserver

# Or set specific owner on remote
ssh myserver "sudo chown -R webuser:webgroup /remote/path"
```

## Performance Issues

### Slow Sync Speed

**Problem**: Syncs take too long

**Diagnose**:

```bash
# Add verbose and progress flags
twin -e "-avuP" myserver
# Watch transfer speed
```

**Solutions**:

1. **Enable compression** (slow network):
   ```bash
   twin -e "-avuz" myserver
   ```

2. **Disable compression** (fast network):
   ```bash
   twin -e "-avu" myserver
   ```

3. **Use faster checksum** (if using checksums):
   ```bash
   # Switch to timestamp (faster)
   twin -e "-avu" myserver
   ```

4. **Limit bandwidth** (if saturating network):
   ```bash
   twin -e "-avu --bwlimit=1000" myserver  # 1000 KB/s
   ```

### High CPU Usage

**Problem**: CPU maxed during sync

**Cause**: Compression is CPU-intensive

**Solution**:

```bash
# Disable compression
twin -e "-avu" myserver

# Or lower compression level
twin -e "-avuz --compress-level=3" myserver
```

### Many Small Files Slow

**Problem**: Thousands of small files sync slowly

**Solutions**:

1. **Exclude unnecessary files**:
   ```bash
   twin -e '-avu --exclude=node_modules/ --exclude=.git/' myserver
   ```

2. **Use checksum for fewer checks** (paradoxically faster for many unchanged files):
   ```bash
   twin -e "-av --checksum" myserver
   ```

## Common Error Messages

### "Error: ssh-remote-name is required"

**Cause**: No remote name provided

**Fix**:
```bash
twin myserver  # Not: twin
```

### "Directory does not exist"

**Cause**: Local directory path invalid

**Fix**:
```bash
cd ~/correct/path
twin myserver
```

### "rsync: command not found"

**Cause**: rsync not installed on local or remote

**Fix**:
```bash
# On local machine
sudo apt install rsync  # Debian/Ubuntu
brew install rsync      # macOS

# On remote
ssh myserver "sudo apt install rsync"
```

### "python3: command not found"

**Cause**: Python 3 not available for twin-config

**Fix**:
```bash
# Install Python 3
sudo apt install python3  # Debian/Ubuntu
brew install python3      # macOS

# Verify
python3 --version
```

## Getting Help

If you encounter an issue not covered here:

1. **Check verbose output**:
   ```bash
   twin -e "-avvv" myserver  # Maximum verbosity
   ```

2. **Check logs**:
   ```bash
   # SSH connection logs
   ssh -vvv myserver exit

   # Rsync detailed log
   twin -e "-avvv --log-file=/tmp/rsync.log" myserver
   cat /tmp/rsync.log
   ```

3. **Report issue**: [GitHub Issues](https://github.com/your-repo/twin/issues)
   - Include Twin version
   - Include error message
   - Include relevant config (redact sensitive data)

---

[Back to main README](../README.md)
