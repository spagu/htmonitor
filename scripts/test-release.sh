#!/bin/bash

# Test script to debug release issues
set -e

echo "🔍 Debugging release process..."

# Test 1: Check git status
echo "1. Git status:"
git status --porcelain
echo "✅ Git working directory clean"

# Test 2: Check git remote
echo "2. Git remote:"
git remote -v
echo "✅ Git remote configured"

# Test 3: Check gh CLI auth
echo "3. GitHub CLI auth:"
gh auth status
echo "✅ GitHub CLI authenticated"

# Test 4: Check if we can list releases
echo "4. Existing releases:"
gh release list --limit 5 || echo "No releases or permission issue"

# Test 5: Try creating a simple tag
echo "5. Testing git tag creation:"
TEST_TAG="test-$(date +%s)"
git tag "$TEST_TAG"
echo "✅ Created test tag: $TEST_TAG"

# Test 6: Try pushing the tag
echo "6. Testing tag push:"
git push origin "$TEST_TAG"
echo "✅ Pushed test tag"

# Test 7: Try creating a simple release
echo "7. Testing GitHub release creation:"
echo "Test release content" > /tmp/test-release-notes.md
gh release create "$TEST_TAG" --title "Test Release" --notes-file /tmp/test-release-notes.md
echo "✅ Created test release"

# Cleanup
echo "8. Cleaning up test release:"
gh release delete "$TEST_TAG" --yes
git tag -d "$TEST_TAG"
git push origin ":refs/tags/$TEST_TAG"
rm -f /tmp/test-release-notes.md
echo "✅ Cleanup complete"

echo "🎉 All tests passed! Release process should work."