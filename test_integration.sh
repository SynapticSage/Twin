#!/bin/bash

# test_integration.sh - Integration tests for twin tool using real rsync
# This requires SSH access to remote-archer

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Twin Integration Tests ===${NC}"
echo "These tests require SSH access to remote-archer"
echo

# Test setup
TEST_DIR="/tmp/twin_integration_test_$$"
LOCAL_DIR="$TEST_DIR/local"
REMOTE_DIR="$TEST_DIR/remote"
INSTALL_DIR="$TEST_DIR/bin"

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
    ssh remote-archer "rm -rf $TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Setup
echo "Setting up test environment..."
mkdir -p "$LOCAL_DIR"
mkdir -p "$INSTALL_DIR"

# Install twin
echo "Installing twin for testing..."
make install PREFIX="$INSTALL_DIR" > /dev/null

# Test SSH access
echo "Testing SSH access to remote-archer..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 remote-archer exit 2>/dev/null; then
    echo -e "${RED}ERROR: Cannot SSH to remote-archer${NC}"
    echo "Please ensure you have SSH access to remote-archer for testing"
    exit 1
fi

# Create test files
echo "Creating test files..."
echo "file1 content" > "$LOCAL_DIR/file1.txt"
echo "file2 content" > "$LOCAL_DIR/file2.txt"
mkdir -p "$LOCAL_DIR/subdir"
echo "file3 content" > "$LOCAL_DIR/subdir/file3.txt"

# Test 1: Basic sync
echo -e "\n${YELLOW}Test 1: Basic sync${NC}"
cd "$LOCAL_DIR"
if "$INSTALL_DIR/bin/twin" remote-archer; then
    echo -e "${GREEN}✓ Sync command executed successfully${NC}"
    
    # Verify files on remote
    if ssh remote-archer "test -f '$LOCAL_DIR/file1.txt'"; then
        echo -e "${GREEN}✓ file1.txt synced${NC}"
    else
        echo -e "${RED}✗ file1.txt not found on remote${NC}"
    fi
    
    if ssh remote-archer "test -d '$LOCAL_DIR/subdir'"; then
        echo -e "${GREEN}✓ subdir synced${NC}"
    else
        echo -e "${RED}✗ subdir not found on remote${NC}"
    fi
else
    echo -e "${RED}✗ Sync command failed${NC}"
fi

# Test 2: Sync with specific directory
echo -e "\n${YELLOW}Test 2: Sync with specific directory${NC}"
SPECIFIC_DIR="$TEST_DIR/specific"
mkdir -p "$SPECIFIC_DIR"
echo "specific content" > "$SPECIFIC_DIR/specific.txt"

if "$INSTALL_DIR/bin/twin" remote-archer "$SPECIFIC_DIR"; then
    echo -e "${GREEN}✓ Specific directory sync executed${NC}"
    
    if ssh remote-archer "test -f '$SPECIFIC_DIR/specific.txt'"; then
        echo -e "${GREEN}✓ specific.txt synced to correct location${NC}"
    else
        echo -e "${RED}✗ specific.txt not found at expected location${NC}"
    fi
else
    echo -e "${RED}✗ Specific directory sync failed${NC}"
fi

# Test 3: Pull-back functionality
echo -e "\n${YELLOW}Test 3: Pull-back functionality (-p flag)${NC}"
# Create a file on remote that doesn't exist locally
ssh remote-archer "echo 'remote only file' > '$LOCAL_DIR/remote_only.txt'"

cd "$LOCAL_DIR"
if "$INSTALL_DIR/bin/twin" -p remote-archer; then
    echo -e "${GREEN}✓ Pull-back sync executed${NC}"
    
    if [ -f "remote_only.txt" ]; then
        echo -e "${GREEN}✓ Remote file pulled back successfully${NC}"
    else
        echo -e "${RED}✗ Remote file not pulled back${NC}"
    fi
else
    echo -e "${RED}✗ Pull-back sync failed${NC}"
fi

# Test 4: Custom rsync flags
echo -e "\n${YELLOW}Test 4: Custom rsync flags (-e flag)${NC}"
# Create a file to be deleted
echo "to be deleted" > "$LOCAL_DIR/delete_me.txt"
"$INSTALL_DIR/bin/twin" remote-archer "$LOCAL_DIR" > /dev/null 2>&1

# Now delete locally and sync with --delete flag
rm "$LOCAL_DIR/delete_me.txt"
if "$INSTALL_DIR/bin/twin" -e "-av --delete" remote-archer "$LOCAL_DIR" 2>&1 | grep -q "deleting"; then
    echo -e "${GREEN}✓ Custom flags (--delete) working${NC}"
else
    echo -e "${YELLOW}! Could not verify --delete flag (may need verbose output)${NC}"
fi

# Test 5: Help flag
echo -e "\n${YELLOW}Test 5: Help functionality${NC}"
if "$INSTALL_DIR/bin/twin" -h 2>&1 | grep -q "Usage:"; then
    echo -e "${GREEN}✓ Help flag shows usage${NC}"
else
    echo -e "${RED}✗ Help flag not working${NC}"
fi

# Test 6: Remote directory creation
echo -e "\n${YELLOW}Test 6: Remote directory creation${NC}"
DEEP_TEST_DIR="$TEST_DIR/deep/nested/path/test"
mkdir -p "$DEEP_TEST_DIR"
echo "deep test content" > "$DEEP_TEST_DIR/deep.txt"

# First remove the remote directory to ensure it doesn't exist
ssh remote-archer "rm -rf '$TEST_DIR/deep'" 2>/dev/null || true

if "$INSTALL_DIR/bin/twin" remote-archer "$DEEP_TEST_DIR"; then
    echo -e "${GREEN}✓ Deep directory sync executed${NC}"
    
    if ssh remote-archer "test -d '$DEEP_TEST_DIR'"; then
        echo -e "${GREEN}✓ Remote directory structure created${NC}"
    else
        echo -e "${RED}✗ Remote directory structure not created${NC}"
    fi
    
    if ssh remote-archer "test -f '$DEEP_TEST_DIR/deep.txt'"; then
        echo -e "${GREEN}✓ File synced to deep directory${NC}"
    else
        echo -e "${RED}✗ File not synced to deep directory${NC}"
    fi
else
    echo -e "${RED}✗ Deep directory sync failed${NC}"
fi

# Test 7: Error handling
echo -e "\n${YELLOW}Test 7: Error handling${NC}"
# Missing remote
if ! "$INSTALL_DIR/bin/twin" 2>&1 | grep -q "required"; then
    echo -e "${RED}✗ Missing remote error not caught${NC}"
else
    echo -e "${GREEN}✓ Missing remote error caught${NC}"
fi

# Invalid directory
if ! "$INSTALL_DIR/bin/twin" remote-archer "/non/existent/path" 2>&1 | grep -q "does not exist"; then
    echo -e "${RED}✗ Invalid directory error not caught${NC}"
else
    echo -e "${GREEN}✓ Invalid directory error caught${NC}"
fi

# Invalid SSH remote
if ! "$INSTALL_DIR/bin/twin" invalid-host-xyz 2>&1 | grep -q "Cannot connect"; then
    echo -e "${RED}✗ Invalid SSH remote error not caught${NC}"
else
    echo -e "${GREEN}✓ Invalid SSH remote error caught${NC}"
fi

echo -e "\n${GREEN}Integration tests completed!${NC}"