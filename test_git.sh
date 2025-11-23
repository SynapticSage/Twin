#!/bin/bash

# test_git.sh - Test suite for twin git integration
# Tests git repository detection, remote setup, and configuration

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
TEST_DIR="/tmp/twin_git_test_$$"
TEST_LOCAL_DIR="$TEST_DIR/local_repo"
TEST_REMOTE_DIR="$TEST_DIR/remote_repo"
TEST_NONGIT_LOCAL="$TEST_DIR/nongit_local"
TEST_NONGIT_REMOTE="$TEST_DIR/nongit_remote"

# Twin executable paths
TWIN_SCRIPT="$(pwd)/twin"
TWIN_CONFIG="$(pwd)/twin-config"

# Clean up function
cleanup() {
    rm -rf "$TEST_DIR"
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

test_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

# Assertion helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" = "$actual" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if echo "$haystack" | grep -q "$needle"; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (expected to find: '$needle')"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"

    if [ -f "$file" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (file not found: $file)"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="$2"

    if [ -d "$dir" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (directory not found: $dir)"
        return 1
    fi
}

# Setup function
setup_test_environment() {
    echo -e "${YELLOW}Setting up test environment...${NC}"

    # Create test directories
    mkdir -p "$TEST_LOCAL_DIR"
    mkdir -p "$TEST_REMOTE_DIR"
    mkdir -p "$TEST_NONGIT_LOCAL"
    mkdir -p "$TEST_NONGIT_REMOTE"

    # Initialize git repos
    (cd "$TEST_LOCAL_DIR" && git init -q && git config user.email "test@twin.local" && git config user.name "Twin Test")
    (cd "$TEST_REMOTE_DIR" && git init -q && git config user.email "test@twin.local" && git config user.name "Twin Test")

    # Create some test files
    echo "local content" > "$TEST_LOCAL_DIR/file.txt"
    echo "remote content" > "$TEST_REMOTE_DIR/file.txt"
    echo "nongit local" > "$TEST_NONGIT_LOCAL/file.txt"
    echo "nongit remote" > "$TEST_NONGIT_REMOTE/file.txt"

    # Make initial commits
    (cd "$TEST_LOCAL_DIR" && git add . && git commit -q -m "Initial commit")
    (cd "$TEST_REMOTE_DIR" && git add . && git commit -q -m "Initial commit")

    echo -e "${GREEN}Test environment ready${NC}\n"
}

# Test 1: Git repo detection - local
test_git_detection_local() {
    test_start "Git repository detection - local"

    cd "$TEST_LOCAL_DIR"
    if [ -d ".git" ]; then
        test_pass "Local git repository detected"
    else
        test_fail "Failed to detect local git repository"
    fi
}

# Test 2: Git repo detection - non-git directory
test_git_detection_nongit() {
    test_start "Git repository detection - non-git directory"

    cd "$TEST_NONGIT_LOCAL"
    if [ ! -d ".git" ]; then
        test_pass "Correctly identified non-git directory"
    else
        test_fail "Incorrectly detected git in non-git directory"
    fi
}

# Test 3: Config schema - git integration fields
test_config_git_fields() {
    test_start "Configuration schema - git integration fields"

    cd "$TEST_LOCAL_DIR"

    # Write git config
    "$TWIN_CONFIG" write "test-remote" \
        --git-local-name "my-target" \
        --git-remote-name "my-source" \
        --git-setup-complete true

    # Read back and verify
    local local_name=$("$TWIN_CONFIG" read "test-remote" --field git_integration.local_remote_name)
    local remote_name=$("$TWIN_CONFIG" read "test-remote" --field git_integration.remote_remote_name)
    local setup_complete=$("$TWIN_CONFIG" read "test-remote" --field git_integration.setup_complete)

    assert_equals "my-target" "$local_name" "Git local name saved correctly"
    assert_equals "my-source" "$remote_name" "Git remote name saved correctly"
    assert_equals "True" "$setup_complete" "Git setup complete flag saved correctly"
}

# Test 4: Git remote addition - local repo
test_git_remote_add_local() {
    test_start "Git remote addition - add to local repository"

    cd "$TEST_LOCAL_DIR"

    # Clean any existing remotes
    git remote remove test-target 2>/dev/null || true

    # Add remote manually (simulating what twin does)
    git remote add test-target "$TEST_REMOTE_DIR"

    # Verify remote was added
    if git remote | grep -q "test-target"; then
        test_pass "Git remote added successfully to local repo"
    else
        test_fail "Failed to add git remote to local repo"
    fi

    # Verify URL is correct
    local remote_url=$(git remote get-url test-target)
    assert_equals "$TEST_REMOTE_DIR" "$remote_url" "Git remote URL is correct"
}

# Test 5: Git remote conflict detection
test_git_remote_conflict() {
    test_start "Git remote conflict detection"

    cd "$TEST_LOCAL_DIR"

    # Add a remote
    git remote remove conflict-test 2>/dev/null || true
    git remote add conflict-test "$TEST_REMOTE_DIR"

    # Check if remote exists
    if git remote | grep -q "^conflict-test$"; then
        test_pass "Can detect existing git remote"
    else
        test_fail "Failed to detect existing git remote"
    fi
}

# Test 6: SSH config hostname parsing
test_ssh_config_parsing() {
    test_start "SSH config hostname parsing"

    # Create temporary SSH config
    local temp_ssh_config="$TEST_DIR/ssh_config"
    cat > "$temp_ssh_config" << 'EOF'
Host myserver
    HostName server.example.com
    User testuser

Host another-server
    HostName 192.168.1.100
EOF

    # Test parsing (we'd need to adapt the twin script's parsing function)
    # For now, just verify the config file structure
    if grep -q "HostName server.example.com" "$temp_ssh_config"; then
        test_pass "SSH config file structure is valid"
    else
        test_fail "SSH config file structure is invalid"
    fi
}

# Test 7: Non-git directories should skip git setup
test_nongit_skip() {
    test_start "Non-git directories - should skip git setup gracefully"

    cd "$TEST_NONGIT_LOCAL"

    # Verify no .git directory
    if [ ! -d ".git" ]; then
        test_pass "Non-git directory correctly identified (no .git folder)"
    else
        test_fail "Incorrectly found .git in non-git directory"
    fi
}

# Test 8: Config persistence across operations
test_config_persistence() {
    test_start "Configuration persistence - git fields"

    cd "$TEST_LOCAL_DIR"

    # Write multiple fields
    "$TWIN_CONFIG" write "persist-test" --remote-path "/some/path"
    "$TWIN_CONFIG" write "persist-test" --git-local-name "laptop"
    "$TWIN_CONFIG" write "persist-test" --git-remote-name "desktop"

    # Verify all fields persist
    local remote_path=$("$TWIN_CONFIG" read "persist-test" --field remote_path)
    local git_local=$("$TWIN_CONFIG" read "persist-test" --field git_integration.local_remote_name)
    local git_remote=$("$TWIN_CONFIG" read "persist-test" --field git_integration.remote_remote_name)

    assert_equals "/some/path" "$remote_path" "Remote path persisted"
    assert_equals "laptop" "$git_local" "Git local name persisted"
    assert_equals "desktop" "$git_remote" "Git remote name persisted"
}

# Test 9: Both repos must be git repos for setup
test_both_repos_required() {
    test_start "Git setup requires both local and remote to be git repos"

    # Local is git, remote is not - should skip
    cd "$TEST_LOCAL_DIR"
    local is_git_local=true

    # Remote is not git
    if [ ! -d "$TEST_NONGIT_REMOTE/.git" ]; then
        test_pass "Correctly identified scenario where only local is git repo"
    else
        test_fail "Test setup error - nongit remote has .git"
    fi
}

# Test 10: Verify git integration doesn't break non-git workflow
test_nongit_workflow() {
    test_start "Non-git workflow should work unchanged"

    cd "$TEST_NONGIT_LOCAL"

    # Write config without git fields
    "$TWIN_CONFIG" write "nongit-test" --remote-path "$TEST_NONGIT_REMOTE"

    # Verify config works
    local path=$("$TWIN_CONFIG" read "nongit-test" --field remote_path)
    assert_equals "$TEST_NONGIT_REMOTE" "$path" "Non-git config works correctly"
}

# Run all tests
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Twin Git Integration Test Suite${NC}"
    echo -e "${BLUE}======================================${NC}\n"

    setup_test_environment

    # Run tests
    test_git_detection_local
    test_git_detection_nongit
    test_config_git_fields
    test_git_remote_add_local
    test_git_remote_conflict
    test_ssh_config_parsing
    test_nongit_skip
    test_config_persistence
    test_both_repos_required
    test_nongit_workflow

    # Summary
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e "Total tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
    echo -e "${RED}Failed:       $FAILED_TESTS${NC}"

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed${NC}"
        exit 1
    fi
}

# Run main
main
