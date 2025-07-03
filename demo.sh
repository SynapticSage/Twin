#!/bin/bash

# demo.sh - Demonstrates twin tool usage

echo "=== Twin Tool Demo ==="
echo

# Show help
echo "1. Showing help:"
./twin -h
echo

# Show error handling
echo "2. Error handling - missing remote:"
./twin 2>&1 || true
echo

echo "3. Error handling - invalid directory:"
./twin myserver /non/existent/path 2>&1 || true
echo

echo "=== Installation ==="
echo "To install twin:"
echo "  make install"
echo "  make install PREFIX=~/bin  # Custom location"
echo

echo "=== Usage Examples ==="
echo "Basic sync:"
echo "  twin myserver                    # Sync current directory"
echo "  twin myserver /path/to/project   # Sync specific directory"
echo
echo "Bidirectional sync:"
echo "  twin -p myserver                 # Push then pull back"
echo
echo "Custom rsync options:"
echo "  twin -e '-av --delete' myserver  # Use --delete flag"
echo "  twin -e '-avz' myserver          # Add compression"
echo

echo "=== SSH Configuration ==="
echo "Add this to ~/.ssh/config for easy access:"
echo "
Host myserver
    HostName example.com
    User myusername
    Port 22
"