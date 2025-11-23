# SSH Configuration Guide

Twin relies on SSH for remote connections. This guide covers SSH setup, key-based authentication, and troubleshooting connection issues.

## Table of Contents

- [Basic SSH Config](#basic-ssh-config)
- [Key-Based Authentication](#key-based-authentication)
- [Advanced Configuration](#advanced-configuration)
- [Multiple Identity Files](#multiple-identity-files)
- [Connection Optimization](#connection-optimization)
- [Troubleshooting](#troubleshooting)

## Basic SSH Config

Twin uses SSH host aliases from your `~/.ssh/config` file.

### Simple Configuration

```bash
# Edit SSH config
nano ~/.ssh/config

# Add host configuration
Host myserver
    HostName example.com
    User deploy
    Port 22
```

Usage with Twin:
```bash
twin myserver /var/www/myapp
```

### Multiple Hosts

```bash
Host staging
    HostName staging.example.com
    User deploy
    Port 22

Host production
    HostName production.example.com
    User deploy
    Port 22

Host backup
    HostName backup.example.com
    User backup
    Port 2222
```

Usage:
```bash
twin staging /var/www/staging
twin production /var/www/production
twin backup /mnt/backups
```

## Key-Based Authentication

Twin requires passwordless SSH access. Set up SSH keys for seamless operation.

### Generate SSH Key

```bash
# Generate new SSH key pair
ssh-keygen -t ed25519 -C "your_email@example.com"

# For older systems, use RSA:
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Accept default location (~/.ssh/id_ed25519)
# Set a passphrase (recommended) or press Enter to skip
```

### Copy Key to Remote

```bash
# Copy public key to remote server
ssh-copy-id user@example.com

# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh user@example.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Test Connection

```bash
# Should connect without password prompt
ssh myserver exit

# If successful, Twin will work
twin myserver
```

### SSH Config with Key

```bash
Host myserver
    HostName example.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

## Advanced Configuration

### Connection Timeouts

```bash
Host myserver
    HostName example.com
    User deploy
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Explanation:
- `ConnectTimeout`: Timeout for initial connection (seconds)
- `ServerAliveInterval`: Send keepalive every 60 seconds
- `ServerAliveCountMax`: Disconnect after 3 failed keepalives

### Compression

Useful for slow connections:

```bash
Host myserver
    HostName example.com
    User deploy
    Compression yes
```

### Connection Sharing

Speed up multiple SSH connections:

```bash
Host *
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 600
```

Benefits:
- Reuses existing SSH connections
- Faster twin syncs (no re-authentication)
- Persists for 10 minutes after last use

### Strict Host Key Checking

```bash
# Disable for local network (less secure)
Host 192.168.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Enable for production (more secure)
Host production
    HostName production.example.com
    StrictHostKeyChecking yes
```

## Multiple Identity Files

Use different SSH keys for different hosts.

### Setup

```bash
# Generate key for work servers
ssh-keygen -t ed25519 -f ~/.ssh/id_work -C "work@example.com"

# Generate key for personal servers
ssh-keygen -t ed25519 -f ~/.ssh/id_personal -C "personal@example.com"
```

### Configuration

```bash
Host work-*
    IdentityFile ~/.ssh/id_work
    User work-user

Host personal-*
    IdentityFile ~/.ssh/id_personal
    User personal-user

Host work-staging
    HostName staging.work.com

Host work-production
    HostName production.work.com

Host personal-server
    HostName personal.example.com
```

### Usage

```bash
twin work-staging /var/www/app     # Uses id_work
twin personal-server ~/backups     # Uses id_personal
```

## Connection Optimization

### For Local Networks

```bash
Host local-*
    HostName 192.168.1.*
    User deploy
    Compression no              # No compression on fast network
    Ciphers aes128-ctr          # Fast cipher for LAN
    TCPKeepAlive yes
```

### For Slow/Remote Connections

```bash
Host remote-*
    User deploy
    Compression yes
    CompressionLevel 9
    Ciphers aes128-ctr,aes192-ctr,aes256-ctr
    ServerAliveInterval 30
```

### For High-Security Connections

```bash
Host production
    HostName production.example.com
    User deploy
    IdentityFile ~/.ssh/id_ed25519
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
    HostKeyAlgorithms ssh-ed25519
    StrictHostKeyChecking yes
```

## Troubleshooting

### Connection Refused

**Problem**: `ssh: connect to host example.com port 22: Connection refused`

**Solutions**:
1. Check SSH service is running on remote:
   ```bash
   # On remote server
   sudo systemctl status sshd
   sudo systemctl start sshd
   ```

2. Verify correct port:
   ```bash
   # Test specific port
   ssh -p 2222 user@example.com
   ```

3. Check firewall allows SSH:
   ```bash
   # On remote server
   sudo ufw status
   sudo ufw allow 22/tcp
   ```

### Permission Denied

**Problem**: `Permission denied (publickey)`

**Solutions**:
1. Verify key is copied to remote:
   ```bash
   ssh-copy-id user@example.com
   ```

2. Check remote `.ssh` permissions:
   ```bash
   ssh user@example.com "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
   ```

3. Check local key permissions:
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

4. Test with verbose output:
   ```bash
   ssh -v user@example.com
   ```

### Timeout Issues

**Problem**: SSH connection times out

**Solutions**:
1. Increase timeout in SSH config:
   ```bash
   Host myserver
       ConnectTimeout 30
   ```

2. Check network connectivity:
   ```bash
   ping example.com
   ```

3. Try different port:
   ```bash
   ssh -p 2222 user@example.com
   ```

### Host Key Verification Failed

**Problem**: `Host key verification failed`

**Solutions**:
1. Remote host key changed (expected):
   ```bash
   ssh-keygen -R example.com
   ssh user@example.com  # Accept new key
   ```

2. For local network testing (less secure):
   ```bash
   Host 192.168.*
       StrictHostKeyChecking no
       UserKnownHostsFile /dev/null
   ```

### SSH Agent Issues

**Problem**: Key passphrase requested every time

**Solution**: Use SSH agent:
```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Verify key is loaded
ssh-add -l
```

**Persistent agent** (add to `~/.bashrc` or `~/.zshrc`):
```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
fi
```

### Debugging Connection

Get detailed connection information:

```bash
# Maximum verbosity
ssh -vvv user@example.com

# Test specific identity file
ssh -i ~/.ssh/id_ed25519 user@example.com

# Test without config file
ssh -F /dev/null -i ~/.ssh/id_ed25519 user@example.com
```

## Example Configurations

### Full Production Setup

```bash
Host production
    HostName production.example.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_production

    # Security
    StrictHostKeyChecking yes
    PasswordAuthentication no

    # Performance
    Compression yes

    # Reliability
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10

    # Connection sharing
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 600
```

### Local Network Development

```bash
Host dev-*
    User developer
    Port 22
    IdentityFile ~/.ssh/id_dev

    # Performance for LAN
    Compression no
    Ciphers aes128-ctr

    # Reliability
    TCPKeepAlive yes
    ServerAliveInterval 30

    # Less strict for local
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host dev-laptop
    HostName 192.168.1.100

Host dev-desktop
    HostName 192.168.1.101
```

---

[Back to main README](../README.md)
