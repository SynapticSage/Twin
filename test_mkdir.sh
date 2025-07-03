#!/bin/bash

# test_mkdir.sh - Test remote directory creation functionality

echo "=== Testing Remote Directory Creation ==="
echo

# Test directory
TEST_DIR="/tmp/twin_mkdir_test_$$"
DEEP_DIR="$TEST_DIR/level1/level2/level3/target"

echo "1. Testing local validation:"
if ./twin remote-archer "$DEEP_DIR" 2>&1 | grep -q "does not exist"; then
    echo "✓ Correctly rejects non-existent local directory"
else
    echo "✗ Failed to catch non-existent local directory"
fi

echo
echo "2. Creating local test directory:"
mkdir -p "$DEEP_DIR"
echo "test content" > "$DEEP_DIR/test.txt"
echo "✓ Created $DEEP_DIR"

echo
echo "3. Testing remote directory creation:"
echo "This will sync to remote-archer:$DEEP_DIR"
echo "(The remote directory structure will be created automatically)"

# Run twin
./twin remote-archer "$DEEP_DIR" 2>&1 | grep -E "(Ensuring remote directory exists|Syncing)"

echo
echo "4. Verifying remote directory was created:"
if ssh remote-archer "test -d '$DEEP_DIR'"; then
    echo "✓ Remote directory exists"
    if ssh remote-archer "test -f '$DEEP_DIR/test.txt'"; then
        echo "✓ File was synced successfully"
    else
        echo "✗ File was not synced"
    fi
else
    echo "✗ Remote directory was not created"
fi

echo
echo "5. Cleaning up:"
rm -rf "$TEST_DIR"
ssh remote-archer "rm -rf '$TEST_DIR'" 2>/dev/null || true
echo "✓ Cleanup complete"

echo
echo "=== Test Complete ==="