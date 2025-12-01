#!/bin/bash

# GitHub Release Script using gh CLI
# Usage: ./scripts/create-release.sh [version] [--draft] [--prerelease]
# Example: ./scripts/create-release.sh v1.2.0 --draft

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASES_DIR="$PROJECT_ROOT/tools/releases"

# Default values
VERSION=""
DRAFT=""
PRERELEASE=""
FORCE=""

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
🚀 GitHub Release Script

Usage: $0 [version] [options]

Arguments:
  version           Version to release (e.g., v1.2.0, 1.2.0)
                   If not provided, will auto-increment patch version

Options:
  --draft          Create as draft release
  --prerelease     Mark as pre-release
  --force          Force release even if tag exists
  --help           Show this help message

Examples:
  $0 v1.2.0                    # Create release v1.2.0
  $0 v1.2.0 --draft           # Create draft release
  $0 v1.2.0 --prerelease      # Create pre-release
  $0                           # Auto-increment patch version

Requirements:
  - gh CLI tool installed and authenticated
  - Git repository with remote origin
  - Go 1.24+ for building binaries

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --draft)
            DRAFT="--draft"
            shift
            ;;
        --prerelease)
            PRERELEASE="--prerelease"
            shift
            ;;
        --force)
            FORCE="--force"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                print_error "Multiple versions specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "gh CLI is not installed. Install from: https://cli.github.com/"
        exit 1
    fi
    
    # Check if authenticated with GitHub
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub. Run: gh auth login"
        exit 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed"
        exit 1
    fi
    
    # Check Go version
    GO_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
    if [[ $(echo "$GO_VERSION 1.24" | tr ' ' '\n' | sort -V | head -n1) != "1.24" ]]; then
        print_error "Go 1.24+ required, found $GO_VERSION"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to get the latest tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
}

# Function to auto-increment version
auto_increment_version() {
    local latest_tag=$(get_latest_tag)
    local version_number=$(echo "$latest_tag" | sed 's/^v//')
    
    # Split version into parts
    IFS='.' read -ra VERSION_PARTS <<< "$version_number"
    local major=${VERSION_PARTS[0]:-0}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}
    
    # Increment patch version
    patch=$((patch + 1))
    
    echo "v${major}.${minor}.${patch}"
}

# Function to validate version format
validate_version() {
    local version="$1"
    
    # Add 'v' prefix if not present
    if [[ ! "$version" =~ ^v ]]; then
        version="v$version"
    fi
    
    # Validate semantic version format
    if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $version"
        print_info "Expected format: v1.2.3 or 1.2.3"
        exit 1
    fi
    
    echo "$version"
}

# Function to check if tag exists
check_tag_exists() {
    local version="$1"
    
    if git tag -l | grep -q "^$version$"; then
        if [[ -z "$FORCE" ]]; then
            print_error "Tag $version already exists. Use --force to override."
            exit 1
        else
            print_warning "Tag $version exists, but --force specified"
            git tag -d "$version" 2>/dev/null || true
            git push origin ":refs/tags/$version" 2>/dev/null || true
        fi
    fi
}

# Function to get repository info
get_repo_info() {
    local remote_url=$(git config --get remote.origin.url)
    
    # Handle both SSH and HTTPS URLs
    if [[ "$remote_url" =~ git@github\.com:(.+)\.git ]]; then
        # SSH format: git@github.com:user/repo.git
        echo "${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ https://github\.com/(.+)\.git ]]; then
        # HTTPS format: https://github.com/user/repo.git
        echo "${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ https://github\.com/(.+) ]]; then
        # HTTPS format without .git: https://github.com/user/repo
        echo "${BASH_REMATCH[1]}"
    else
        print_error "Could not parse GitHub repository from remote URL: $remote_url"
        exit 1
    fi
}

# Function to generate changelog
generate_changelog() {
    local version="$1"
    local previous_tag=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")
    local repo_path=$(get_repo_info)
    
    local changelog_file="$RELEASES_DIR/CHANGELOG-$version.md"
    mkdir -p "$RELEASES_DIR"
    
    cat > "$changelog_file" << EOF
# Release $version

## 🚀 What's New

EOF
    
    if [[ -n "$previous_tag" ]]; then
        echo "## 📝 Changes since $previous_tag" >> "$changelog_file"
        echo "" >> "$changelog_file"
        
        # Get commit messages since last tag
        git log "$previous_tag..HEAD" --pretty=format:"- %s (%h)" >> "$changelog_file"
        echo "" >> "$changelog_file"
        echo "" >> "$changelog_file"
    fi
    
    cat >> "$changelog_file" << EOF
## 📦 Assets

This release includes pre-built binaries for multiple platforms:

- **Linux**: amd64, arm64, 386
- **macOS**: amd64, arm64 (Apple Silicon)
- **Windows**: amd64, arm64, 386
- **FreeBSD**: amd64, arm64
- **OpenBSD**: amd64
- **NetBSD**: amd64

## 🔧 Installation

### Using GitHub CLI
\`\`\`bash
gh release download $version --pattern "*linux-amd64*"
chmod +x htaccess-monitor
\`\`\`

### Using Makefile
\`\`\`bash
VERSION=$version make go-binary
\`\`\`

## 🐛 Bug Reports

If you encounter any issues, please report them at: https://github.com/$repo_path/issues

---

**Full Changelog**: https://github.com/$repo_path/compare/$previous_tag...$version
EOF
    
    echo "$changelog_file"
}

# Function to build binaries
build_binaries() {
    print_info "Building multi-platform binaries..."
    
    cd "$PROJECT_ROOT"
    
    # Save changelog file before cleaning releases directory
    local temp_changelog=""
    if [[ -f "$RELEASES_DIR/CHANGELOG-$VERSION.md" ]]; then
        temp_changelog="/tmp/changelog-$VERSION-$$.md"
        cp "$RELEASES_DIR/CHANGELOG-$VERSION.md" "$temp_changelog"
    fi
    
    # Clean previous builds
    rm -rf "$RELEASES_DIR"
    mkdir -p "$RELEASES_DIR"
    
    # Restore changelog file
    if [[ -n "$temp_changelog" && -f "$temp_changelog" ]]; then
        cp "$temp_changelog" "$RELEASES_DIR/CHANGELOG-$VERSION.md"
        rm -f "$temp_changelog"
    fi
    
    # Run build script (ignore exit code, check results instead)
    if [[ -f "scripts/build-releases.sh" ]]; then
        chmod +x scripts/build-releases.sh
        ./scripts/build-releases.sh
        # Don't check exit code here, check actual results below
    else
        print_error "Build script not found: scripts/build-releases.sh"
        return 1
    fi
    
    # Verify binaries were actually created (more reliable than exit code)
    local binary_files=$(find "$RELEASES_DIR" -name "htaccess-monitor-*" -not -name "*.md5" -not -name "*.sha256" -not -name "*.tar.gz" -not -name "*.zip" | wc -l)
    
    if [[ $binary_files -eq 0 ]]; then
        print_error "No binary files were created"
        return 1
    fi
    
    # Count all created files (binaries, checksums, and archives)
    local total_files=$(find "$RELEASES_DIR" -type f | wc -l)
    local archive_count=$(find "$RELEASES_DIR" -name "*.tar.gz" -o -name "*.zip" | wc -l)
    print_success "Built $total_files files ($binary_files binaries, $archive_count archives)"
    
    # Explicitly return success
    return 0
}

# Function to create git tag
create_git_tag() {
    local version="$1"
    local changelog_file="$2"
    
    print_info "Creating git tag $version..."
    
    # Create annotated tag with changelog
    git tag -a "$version" -F "$changelog_file"
    
    # Push tag to remote
    git push origin "$version"
    
    print_success "Created and pushed tag $version"
}

# Function to create GitHub release
create_github_release() {
    local version="$1"
    local changelog_file="$2"
    
    print_info "Creating GitHub release $version..."
    
    # Prepare gh release command
    local gh_cmd="gh release create $version"
    
    # Add options
    if [[ -n "$DRAFT" ]]; then
        gh_cmd="$gh_cmd $DRAFT"
    fi
    
    if [[ -n "$PRERELEASE" ]]; then
        gh_cmd="$gh_cmd $PRERELEASE"
    fi
    
    # Add title and notes
    gh_cmd="$gh_cmd --title \"Release $version\" --notes-file \"$changelog_file\""
    
    # Add all files from releases directory (except changelog and archives)
    local release_files=""
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        # Skip changelog and archive files
        if [[ "$filename" != "CHANGELOG-$version.md" ]] && \
           [[ "$filename" != *.tar.gz ]] && \
           [[ "$filename" != *.zip ]]; then
            release_files="$release_files \"$file\""
        fi
    done < <(find "$RELEASES_DIR" -type f -print0)
    
    if [[ -n "$release_files" ]]; then
        gh_cmd="$gh_cmd $release_files"
    fi
    
    # Execute release command
    eval "$gh_cmd"
    
    print_success "Created GitHub release $version"
}

# Function to update CHANGELOG.md
update_main_changelog() {
    local version="$1"
    local changelog_file="$2"
    
    local main_changelog="$PROJECT_ROOT/CHANGELOG.md"
    
    if [[ -f "$main_changelog" ]]; then
        print_info "Updating main CHANGELOG.md..."
        
        # Create backup
        cp "$main_changelog" "$main_changelog.bak"
        
        # Extract version info and insert at top
        local temp_file=$(mktemp)
        
        # Keep header
        head -n 8 "$main_changelog" > "$temp_file"
        
        # Add new version
        echo "" >> "$temp_file"
        echo "## [$version] - $(date +%Y-%m-%d)" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "### Added" >> "$temp_file"
        echo "- Release $version with multi-platform binaries" >> "$temp_file"
        
        # Add rest of changelog
        tail -n +9 "$main_changelog" >> "$temp_file"
        
        # Replace original
        mv "$temp_file" "$main_changelog"
        
        # Commit changelog update
        git add "$main_changelog"
        git commit -m "docs: update CHANGELOG.md for $version" || true
        git push origin HEAD || true
        
        print_success "Updated main CHANGELOG.md"
    fi
}

# Main function
main() {
    print_info "🚀 Starting GitHub release process..."
    
    # Enable debug mode for troubleshooting
    set -x
    
    # Check prerequisites
    check_prerequisites
    
    # Determine version
    if [[ -z "$VERSION" ]]; then
        VERSION=$(auto_increment_version)
        print_info "Auto-generated version: $VERSION"
    else
        VERSION=$(validate_version "$VERSION")
        print_info "Using specified version: $VERSION"
    fi
    
    # Check if tag exists
    check_tag_exists "$VERSION"
    
    # Generate changelog
    print_info "Generating changelog..."
    local changelog_file=$(generate_changelog "$VERSION")
    print_success "Generated changelog: $changelog_file"
    
    # Build binaries
    if ! build_binaries; then
        print_error "Failed to build binaries"
        exit 1
    fi
    
    # Debug: Show what files we have
    print_info "Files in releases directory:"
    ls -la "$RELEASES_DIR"
    
    # Create git tag
    print_info "About to create git tag..."
    create_git_tag "$VERSION" "$changelog_file"
    
    # Create GitHub release
    print_info "About to create GitHub release..."
    create_github_release "$VERSION" "$changelog_file"
    
    # Update main changelog
    print_info "About to update main changelog..."
    update_main_changelog "$VERSION" "$changelog_file"
    
    print_success "🎉 Successfully created release $VERSION!"
    print_info "View release at: https://github.com/$(get_repo_info)/releases/tag/$VERSION"
    
    # Cleanup
    rm -f "$changelog_file"
    
    # Disable debug mode
    set +x
}

# Run main function
main "$@"
