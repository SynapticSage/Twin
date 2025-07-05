#!/bin/bash

# test_config.sh - Test configuration file functionality

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Testing Twin Configuration Files ===${NC}"
echo

# Test directory
TEST_DIR="/tmp/twin_config_test_$$"
CONFIG_TEST_DIR="$TEST_DIR/project"

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
    rm -f .twin.test-config.json
    ssh remote-archer "rm -rf $TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Setup
echo "Setting up test environment..."
mkdir -p "$CONFIG_TEST_DIR"
cd "$CONFIG_TEST_DIR"
echo "test content" > test.txt

# Test 1: Initial pairing creates config
echo -e "\n${YELLOW}Test 1: Initial pairing creates config${NC}"
if ../../twin remote-archer "$TEST_DIR/remote_target" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Initial pairing succeeded${NC}"
    
    if [ -f ".twin.remote-archer.json" ]; then
        echo -e "${GREEN}✓ Config file created${NC}"
        
        # Check config content
        SAVED_PATH=$(../../twin-config read remote-archer --field remote_path)
        if [ "$SAVED_PATH" = "$TEST_DIR/remote_target" ]; then
            echo -e "${GREEN}✓ Remote path saved correctly${NC}"
        else
            echo -e "${RED}✗ Remote path incorrect (got: $SAVED_PATH)${NC}"
        fi
    else
        echo -e "${RED}✗ Config file not created${NC}"
    fi
else
    echo -e "${RED}✗ Initial pairing failed${NC}"
fi

# Test 2: Subsequent sync uses saved config
echo -e "\n${YELLOW}Test 2: Subsequent sync uses saved config${NC}"
echo "updated content" >> test.txt
OUTPUT=$(../../twin remote-archer 2>&1)
if echo "$OUTPUT" | grep -q "Using saved remote path"; then
    echo -e "${GREEN}✓ Using saved remote path${NC}"
    
    # Verify file synced to correct location
    if ssh remote-archer "test -f '$TEST_DIR/remote_target/test.txt'"; then
        echo -e "${GREEN}✓ File synced to saved location${NC}"
    else
        echo -e "${RED}✗ File not found at saved location${NC}"
    fi
else
    echo -e "${RED}✗ Not using saved config${NC}"
fi

# Test 3: Custom rsync flags are saved
echo -e "\n${YELLOW}Test 3: Custom rsync flags are saved${NC}"
if ../../twin -e "-avz" remote-archer >/dev/null 2>&1; then
    SAVED_FLAGS=$(../../twin-config read remote-archer --field rsync_flags)
    if [ "$SAVED_FLAGS" = "-avz" ]; then
        echo -e "${GREEN}✓ Custom flags saved correctly${NC}"
    else
        echo -e "${RED}✗ Flags not saved (got: $SAVED_FLAGS)${NC}"
    fi
else
    echo -e "${RED}✗ Failed to set custom flags${NC}"
fi

# Test 4: Different directories can have different pairings
echo -e "\n${YELLOW}Test 4: Multiple directory pairings${NC}"
mkdir -p "$TEST_DIR/project2"
cd "$TEST_DIR/project2"
echo "project2 content" > test2.txt

if ../../twin remote-archer "$TEST_DIR/different_target" >/dev/null 2>&1; then
    if [ -f ".twin.remote-archer.json" ]; then
        SAVED_PATH=$(../../twin-config read remote-archer --field remote_path)
        if [ "$SAVED_PATH" = "$TEST_DIR/different_target" ]; then
            echo -e "${GREEN}✓ Different directory has different pairing${NC}"
        else
            echo -e "${RED}✗ Pairing incorrect for second directory${NC}"
        fi
    else
        echo -e "${RED}✗ Config not created for second directory${NC}"
    fi
else
    echo -e "${RED}✗ Failed to create second pairing${NC}"
fi

# Test 5: Config persists across syncs
echo -e "\n${YELLOW}Test 5: Config persistence${NC}"
cd "$CONFIG_TEST_DIR"
TIMESTAMP_BEFORE=$(../../twin-config read remote-archer --field last_sync)
sleep 1
../../twin remote-archer >/dev/null 2>&1
TIMESTAMP_AFTER=$(../../twin-config read remote-archer --field last_sync)

if [ "$TIMESTAMP_BEFORE" != "$TIMESTAMP_AFTER" ]; then
    echo -e "${GREEN}✓ Config updates last_sync timestamp${NC}"
else
    echo -e "${RED}✗ Timestamp not updated${NC}"
fi

echo -e "\n${GREEN}Configuration tests completed!${NC}"