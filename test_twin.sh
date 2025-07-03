#!/bin/bash

# test_twin.sh - Comprehensive test suite for twin tool
# This script tests installation, functionality, and error handling

# Don't exit on error - we're testing error conditions
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test directories
TEST_DIR="/tmp/twin_test_$$"
TEST_LOCAL_DIR="$TEST_DIR/local"
TEST_REMOTE_DIR="$TEST_DIR/remote"
TEST_INSTALL_DIR="$TEST_DIR/bin"

# Clean up function
cleanup() {
    rm -rf "$TEST_DIR"
    # Remove test SSH config entry if it exists
    if grep -q "Host twin-test-localhost" ~/.ssh/config 2>/dev/null; then
        sed -i.bak '/Host twin-test-localhost/,/^$/d' ~/.ssh/config
        rm -f ~/.ssh/config.bak
    fi
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Test framework functions
test_start() {
    local test_name="$1"
    echo -e "${BLUE}[TEST]${NC} $test_name"
    ((TOTAL_TESTS++))
}

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        test_pass "$message"
    else
        test_fail "$message (expected: '$expected', got: '$actual')"
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    if [ -f "$file" ]; then
        test_pass "$message"
    else
        test_fail "$message (file not found: $file)"
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="$2"
    
    if [ -d "$dir" ]; then
        test_pass "$message"
    else
        test_fail "$message (directory not found: $dir)"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$message"
    else
        test_fail "$message (string '$needle' not found)"
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" -eq "$actual" ]; then
        test_pass "$message"
    else
        test_fail "$message (expected exit code: $expected, got: $actual)"
    fi
}

# Setup test environment
setup_test_env() {
    echo -e "${YELLOW}Setting up test environment...${NC}"
    
    # Create test directories
    mkdir -p "$TEST_LOCAL_DIR"
    mkdir -p "$TEST_REMOTE_DIR"
    mkdir -p "$TEST_INSTALL_DIR"
    
    # Create test files in local directory
    echo "test file 1" > "$TEST_LOCAL_DIR/file1.txt"
    echo "test file 2" > "$TEST_LOCAL_DIR/file2.txt"
    mkdir -p "$TEST_LOCAL_DIR/subdir"
    echo "test file 3" > "$TEST_LOCAL_DIR/subdir/file3.txt"
    
    # Set up mock SSH config for localhost testing
    if ! grep -q "Host twin-test-localhost" ~/.ssh/config 2>/dev/null; then
        cat >> ~/.ssh/config << EOF

Host twin-test-localhost
    HostName localhost
    User $USER
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    fi
    
    echo -e "${GREEN}Test environment ready${NC}"
}

# Test 1: Installation
test_installation() {
    test_start "Installation tests"
    
    # Test make install
    cd "$(dirname "$0")"
    make install PREFIX="$TEST_INSTALL_DIR" > /dev/null 2>&1
    local exit_code=$?
    assert_exit_code 0 $exit_code "make install should succeed"
    assert_file_exists "$TEST_INSTALL_DIR/bin/twin" "twin binary should exist after install"
    
    # Test if binary is executable
    if [ -x "$TEST_INSTALL_DIR/bin/twin" ]; then
        test_pass "twin binary is executable"
    else
        test_fail "twin binary is not executable"
    fi
    
    # Test make uninstall
    make uninstall PREFIX="$TEST_INSTALL_DIR" > /dev/null 2>&1
    exit_code=$?
    assert_exit_code 0 $exit_code "make uninstall should succeed"
    
    if [ ! -f "$TEST_INSTALL_DIR/bin/twin" ]; then
        test_pass "twin binary removed after uninstall"
    else
        test_fail "twin binary still exists after uninstall"
    fi
    
    # Reinstall for remaining tests
    make install PREFIX="$TEST_INSTALL_DIR" > /dev/null 2>&1
}

# Test 2: Help functionality
test_help() {
    test_start "Help functionality"
    
    # Test -h flag
    output=$("$TEST_INSTALL_DIR/bin/twin" -h 2>&1) || true
    assert_contains "$output" "Usage: twin" "Help should show usage"
    assert_contains "$output" "Options:" "Help should show options"
    assert_contains "$output" "-p" "Help should document -p flag"
    assert_contains "$output" "-e" "Help should document -e flag"
}

# Test 3: Argument parsing
test_argument_parsing() {
    test_start "Argument parsing"
    
    # Test missing ssh-remote-name
    output=$("$TEST_INSTALL_DIR/bin/twin" 2>&1) || true
    assert_contains "$output" "ssh-remote-name is required" "Should error on missing remote"
    
    # Test invalid option
    output=$("$TEST_INSTALL_DIR/bin/twin" -x 2>&1) || true
    assert_contains "$output" "Invalid option" "Should error on invalid option"
}

# Test 4: Directory validation
test_directory_validation() {
    test_start "Directory validation"
    
    # Test non-existent directory
    output=$("$TEST_INSTALL_DIR/bin/twin" twin-test-localhost "/non/existent/dir" 2>&1) || true
    assert_contains "$output" "Directory '/non/existent/dir' does not exist" "Should error on non-existent directory"
}

# Test 5: SSH connection validation
test_ssh_validation() {
    test_start "SSH connection validation"
    
    # Test invalid SSH remote
    output=$("$TEST_INSTALL_DIR/bin/twin" invalid-ssh-remote 2>&1) || true
    assert_contains "$output" "Cannot connect to SSH remote" "Should error on invalid SSH remote"
}

# Test 6: Basic sync functionality
test_basic_sync() {
    test_start "Basic sync functionality"
    
    # Create a test scenario where we "sync" to a local directory
    # We'll use a wrapper script to simulate rsync behavior
    cat > "$TEST_DIR/rsync_mock" << 'EOF'
#!/bin/bash
# Mock rsync that copies to our test remote directory
if [[ "$*" == *"twin-test-localhost:"* ]]; then
    # Extract source and destination
    src=""
    dest=""
    for arg in "$@"; do
        if [[ "$arg" != -* ]] && [ -z "$src" ]; then
            src="$arg"
        elif [[ "$arg" == twin-test-localhost:* ]]; then
            dest="${arg#twin-test-localhost:}"
        fi
    done
    
    # Simulate rsync by copying locally
    if [ -n "$src" ] && [ -n "$dest" ]; then
        cp -r "$src"* "$TEST_REMOTE_DIR/" 2>/dev/null || true
    fi
fi
exit 0
EOF
    chmod +x "$TEST_DIR/rsync_mock"
    
    # Run twin with mocked rsync
    cd "$TEST_LOCAL_DIR"
    PATH="$TEST_DIR:$PATH" "$TEST_INSTALL_DIR/bin/twin" twin-test-localhost > /dev/null 2>&1
    
    # Check if files were "synced"
    assert_file_exists "$TEST_REMOTE_DIR/file1.txt" "file1.txt should be synced"
    assert_file_exists "$TEST_REMOTE_DIR/file2.txt" "file2.txt should be synced"
    assert_dir_exists "$TEST_REMOTE_DIR/subdir" "subdir should be synced"
}

# Test 7: Custom rsync flags
test_custom_flags() {
    test_start "Custom rsync flags"
    
    # Create a script to capture rsync arguments
    cat > "$TEST_DIR/rsync_capture" << 'EOF'
#!/bin/bash
echo "$@" > /tmp/twin_test_rsync_args
exit 0
EOF
    chmod +x "$TEST_DIR/rsync_capture"
    
    # Run twin with custom flags
    cd "$TEST_LOCAL_DIR"
    PATH="$TEST_DIR:$PATH" RSYNC="rsync_capture" "$TEST_INSTALL_DIR/bin/twin" -e "-av --delete" twin-test-localhost 2>/dev/null || true
    
    # Check if custom flags were passed
    if [ -f /tmp/twin_test_rsync_args ]; then
        args=$(cat /tmp/twin_test_rsync_args)
        assert_contains "$args" "-av --delete" "Custom rsync flags should be used"
        rm -f /tmp/twin_test_rsync_args
    else
        test_fail "Could not capture rsync arguments"
    fi
}

# Test 8: Pull-back functionality
test_pullback() {
    test_start "Pull-back functionality"
    
    # Create a script that counts rsync invocations
    cat > "$TEST_DIR/rsync_counter" << 'EOF'
#!/bin/bash
count_file="/tmp/twin_test_rsync_count"
if [ -f "$count_file" ]; then
    count=$(cat "$count_file")
    ((count++))
else
    count=1
fi
echo $count > "$count_file"
exit 0
EOF
    chmod +x "$TEST_DIR/rsync_counter"
    
    # Run twin with -p flag
    rm -f /tmp/twin_test_rsync_count
    cd "$TEST_LOCAL_DIR"
    PATH="$TEST_DIR:$PATH" RSYNC="rsync_counter" "$TEST_INSTALL_DIR/bin/twin" -p twin-test-localhost 2>/dev/null || true
    
    # Check if rsync was called twice (push and pull)
    if [ -f /tmp/twin_test_rsync_count ]; then
        count=$(cat /tmp/twin_test_rsync_count)
        assert_equals "2" "$count" "rsync should be called twice with -p flag"
        rm -f /tmp/twin_test_rsync_count
    else
        test_fail "Could not count rsync invocations"
    fi
}

# Main test runner
main() {
    echo -e "${YELLOW}=== Twin Test Suite ===${NC}"
    echo
    
    # Setup
    setup_test_env
    echo
    
    # Run tests
    test_installation
    echo
    test_help
    echo
    test_argument_parsing
    echo
    test_directory_validation
    echo
    test_ssh_validation
    echo
    test_basic_sync
    echo
    test_custom_flags
    echo
    test_pullback
    echo
    
    # Summary
    echo -e "${YELLOW}=== Test Summary ===${NC}"
    echo -e "Total tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run the test suite
main "$@"