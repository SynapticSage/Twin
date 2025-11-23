# Advanced Usage

This guide covers advanced Twin features, complex rsync patterns, and real-world workflow examples.

## Table of Contents

- [Custom Rsync Flags](#custom-rsync-flags)
- [Exclusion Patterns](#exclusion-patterns)
- [Bidirectional Sync](#bidirectional-sync)
- [Multiple Remotes](#multiple-remotes)
- [Configuration Management](#configuration-management)
- [Workflow Examples](#workflow-examples)
- [Performance Optimization](#performance-optimization)

## Custom Rsync Flags

Twin saves custom rsync flags for each remote, so you set them once and they persist.

### Default Flags

Without customization, Twin uses: `-avu --progress`
- `-a`: Archive mode (preserves permissions, timestamps, etc.)
- `-v`: Verbose output
- `-u`: Skip files newer on receiver
- `--progress`: Show transfer progress

### Setting Custom Flags

```bash
twin -e "-av --dry-run" myserver
# Test what would happen without making changes

twin -e "-avu --delete" myserver
# CAUTION: Deletes files on remote that don't exist locally

twin -e "-avz --compress-level=9" myserver
# Maximum compression for slow connections

twin -e "-av --checksum" myserver
# Use checksums instead of timestamps (slower but more accurate)
```

### Commonly Used Flags

```bash
# Show detailed progress
twin -e "-avu --progress" myserver

# Delete extraneous files
twin -e "-avu --delete" myserver

# Preserve hard links
twin -e "-avuH" myserver

# Limit bandwidth (KB/s)
twin -e "-avu --bwlimit=1000" myserver

# Compress during transfer
twin -e "-avuz" myserver
```

## Exclusion Patterns

Exclude files and directories from sync using `--exclude`.

### Basic Exclusions

```bash
# Exclude single directory
twin -e '--exclude=node_modules/' myserver

# Exclude single file pattern
twin -e '--exclude=*.log' myserver

# Exclude multiple patterns
twin -e '--exclude=*.pyc --exclude=__pycache__/' myserver
```

### Common Exclusion Patterns

#### Python Projects

```bash
twin -e '-avu --exclude=.venv/ --exclude=*.pyc --exclude=__pycache__/ --exclude=*.egg-info/' myserver
```

#### Node.js Projects

```bash
twin -e '-avu --exclude=node_modules/ --exclude=.npm/ --exclude=package-lock.json' myserver
```

#### Machine Learning Projects

```bash
twin -e '-avu --exclude=*.h5 --exclude=*.ckpt --exclude=*.pth --exclude=*.parquet --exclude=data/' myserver
```

#### General Development

```bash
twin -e '-avu --exclude=.git/ --exclude=.DS_Store --exclude=.env --exclude=*.swp' myserver
```

### Advanced Exclusion Patterns

```bash
# Exclude hidden files except .gitignore
twin -e '--exclude=.* --include=.gitignore' myserver

# Exclude by size (files larger than 100MB)
twin -e '--max-size=100m' myserver

# Exclude everything then selectively include
twin -e '--exclude=* --include=*.py --include=*.md' myserver
```

### Using Exclude Files

Create `.rsyncignore` pattern:

```bash
# Create exclude file
cat > .twin-exclude << EOF
*.log
*.tmp
.DS_Store
node_modules/
.venv/
EOF

# Use in twin command
twin -e "--exclude-from=.twin-exclude" myserver
```

## Bidirectional Sync

Twin supports bidirectional synchronization with conflict handling.

### Push Then Pull

```bash
twin -p myserver
# 1. Pushes local changes to remote
# 2. Pulls remote changes to local
```

### Pull Only

```bash
twin -P myserver
# Only pulls from remote to local
```

### Handling Conflicts

**Case 1: File modified on both sides**

Rsync will use the newer file by default (timestamp-based). For checksum-based:

```bash
twin -e "-av --checksum" -p myserver
```

**Case 2: File deleted locally, modified remotely**

```bash
# Without --delete, remote file persists
twin -p myserver

# With --delete, remote file is deleted
twin -e "-av --delete" -p myserver
```

## Multiple Remotes

Sync the same local directory to multiple remote hosts.

### Setup Multiple Pairings

```bash
cd ~/my-project

# Pair with staging server
twin staging /var/www/staging

# Pair with production server
twin production /var/www/production

# Pair with backup server
twin backup /mnt/backups/my-project
```

### Configuration Files

Each remote gets its own config:

```bash
ls -la | grep twin
# .twin.staging.json
# .twin.production.json
# .twin.backup.json
```

### Workflow with Multiple Remotes

```bash
# Sync to staging first
twin staging

# Test on staging
# ...

# Deploy to production
twin production

# Backup
twin backup
```

## Configuration Management

### Viewing Configuration

```bash
# Read entire config
./twin-config read myserver

# Read specific field
./twin-config read myserver --field remote_path
./twin-config read myserver --field rsync_flags
./twin-config read myserver --field git_integration.setup_complete
```

### Modifying Configuration

```bash
# Update remote path
./twin-config write myserver --remote-path /new/path

# Update rsync flags
./twin-config write myserver --rsync-flags "-avu --delete"

# Update git integration
./twin-config write myserver --git-local-name newname
```

### Config File Format

```json
{
  "remote_path": "/var/www/myapp",
  "rsync_flags": "-avu --progress --exclude=node_modules/",
  "last_sync": "2025-11-23T10:30:00",
  "git_integration": {
    "local_remote_name": "staging",
    "remote_remote_name": "laptop",
    "setup_complete": true
  }
}
```

### Resetting Configuration

```bash
# Remove config file to reset pairing
rm .twin.myserver.json

# Next twin command will create fresh pairing
twin myserver /remote/path
```

## Workflow Examples

### Example 1: Development to Production

```bash
# Initial setup
cd ~/my-web-app
twin prod /var/www/myapp

# Daily workflow
git add .
git commit -m "Add feature"
git push origin main

# Deploy to production
twin -e "-avu --delete --exclude=.git/" prod

# Check logs on production
ssh prod "tail -f /var/log/app.log"
```

### Example 2: Multi-Machine Development

```bash
# On laptop
cd ~/projects/myapp
twin desktop ~/projects/myapp

# Work on laptop
# ... make changes ...
twin desktop

# Switch to desktop
# On desktop
cd ~/projects/myapp
twin -P laptop  # Pull laptop changes
# ... continue working ...
twin laptop     # Push desktop changes back
```

### Example 3: Large Dataset Management

```bash
# Exclude large binary files from git, sync with rsync
twin -e '-avu --exclude=.git/ --include=*.h5 --include=*.parquet' mlserver

# Then use git for code only
git add *.py *.md
git commit -m "Update model code"
git push origin main
```

### Example 4: Incremental Backups

```bash
# Setup backup remote
twin backup /mnt/backups/my-project

# Regular backups (keeps deleted files on backup)
twin backup

# Full mirror backup (deletes old files)
twin -e "-avu --delete" backup
```

### Example 5: Testing Before Deploy

```bash
# Test with dry-run
twin -e "-av --dry-run" prod

# Review what would change
# ...

# Execute actual sync
twin -e "-av" prod
```

## Performance Optimization

### Compression

Useful for slow network connections:

```bash
# Enable compression
twin -e "-avuz" myserver

# Maximum compression
twin -e "-avuz --compress-level=9" myserver
```

Trade-off: Uses more CPU, saves bandwidth.

### Bandwidth Limiting

Prevent saturating network:

```bash
# Limit to 1000 KB/s
twin -e "-avu --bwlimit=1000" myserver

# Limit to 100 KB/s (very slow connection)
twin -e "-avu --bwlimit=100" myserver
```

### Partial Transfers

Resume interrupted transfers:

```bash
twin -e "-avuP" myserver
# -P is shorthand for --partial --progress
```

### Parallel Transfers

For multiple small files:

```bash
# Note: rsync doesn't natively support parallel transfers
# Use multiple twin commands for different directories:
twin -e "-avu src/" myserver &
twin -e "-avu docs/" myserver &
wait
```

### Checksum vs Timestamp

```bash
# Faster: timestamp-based (default)
twin myserver

# Slower but more accurate: checksum-based
twin -e "-av --checksum" myserver
```

Use checksums when:
- Files modified without timestamp changes
- Syncing across different filesystems
- Ensuring data integrity is critical

---

[Back to main README](../README.md)
