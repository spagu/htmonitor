#!/bin/bash

# Multi-architecture build script for htaccess-monitor
# Follows clean code principles and user rules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="htaccess-monitor"
VERSION=${VERSION:-"1.0.0"}
BUILD_DIR="tools/releases"
SOURCE_DIR="apps/htaccess-monitor"

# Supported architectures
declare -A PLATFORMS=(
    ["linux/amd64"]="linux-amd64"
    ["linux/arm64"]="linux-arm64"
    ["linux/386"]="linux-386"
    ["windows/amd64"]="windows-amd64.exe"
    ["windows/arm64"]="windows-arm64.exe"
    ["windows/386"]="windows-386.exe"
    ["darwin/amd64"]="darwin-amd64"
    ["darwin/arm64"]="darwin-arm64"
    ["freebsd/amd64"]="freebsd-amd64"
    ["freebsd/arm64"]="freebsd-arm64"
    ["openbsd/amd64"]="openbsd-amd64"
    ["netbsd/amd64"]="netbsd-amd64"
)

# Function to print header
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                    🏗️ Multi-Architecture Go Builder 🚀                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}                        Building ${APP_NAME} v${VERSION}                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to print section header
print_section() {
    local title="$1"
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${WHITE} $title${BLUE}$(printf "%*s" $((75 - ${#title})) "")│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Function to build for a specific platform
build_platform() {
    local platform="$1"
    local output_name="$2"
    local goos=$(echo "$platform" | cut -d'/' -f1)
    local goarch=$(echo "$platform" | cut -d'/' -f2)
    
    echo -e "${CYAN}🔨 Building for ${goos}/${goarch}:${NC}"
    echo -e "   ${YELLOW}📦 Target: ${output_name}${NC}"
    
    # Set build environment
    export GOOS="$goos"
    export GOARCH="$goarch"
    export CGO_ENABLED=0
    
    # Build flags for optimization
    local ldflags="-s -w -X main.Version=${VERSION} -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    # Build the binary (change to source directory first)
    if (cd "$SOURCE_DIR" && go build -ldflags "$ldflags" -o "../../${BUILD_DIR}/${APP_NAME}-${output_name}" main.go) 2>/dev/null; then
        local file_size=$(du -h "${BUILD_DIR}/${APP_NAME}-${output_name}" | cut -f1)
        echo -e "   ${GREEN}✅ Success - Size: ${file_size}${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Failed${NC}"
        return 1
    fi
}

# Function to create checksums
create_checksums() {
    print_section "📋 Creating Checksums"
    
    cd "$BUILD_DIR"
    
    # Create SHA256 checksums
    echo -e "${CYAN}🔐 Generating SHA256 checksums:${NC}"
    sha256sum ${APP_NAME}-* > "${APP_NAME}-${VERSION}-checksums.sha256"
    echo -e "   ${GREEN}✅ SHA256 checksums created${NC}"
    
    # Create MD5 checksums for compatibility
    echo -e "${CYAN}🔐 Generating MD5 checksums:${NC}"
    md5sum ${APP_NAME}-* > "${APP_NAME}-${VERSION}-checksums.md5"
    echo -e "   ${GREEN}✅ MD5 checksums created${NC}"
    
    cd - > /dev/null
}

# Function to create release archive
create_archives() {
    print_section "📦 Creating Release Archives"
    
    cd "$BUILD_DIR"
    
    # Create tar.gz archive for Unix systems
    echo -e "${CYAN}📦 Creating tar.gz archive:${NC}"
    tar -czf "${APP_NAME}-${VERSION}-all-platforms.tar.gz" ${APP_NAME}-*
    echo -e "   ${GREEN}✅ tar.gz archive created${NC}"
    
    # Create zip archive for Windows compatibility
    echo -e "${CYAN}📦 Creating zip archive:${NC}"
    zip -q "${APP_NAME}-${VERSION}-all-platforms.zip" ${APP_NAME}-*
    echo -e "   ${GREEN}✅ zip archive created${NC}"
    
    cd - > /dev/null
}

# Function to display build summary
display_summary() {
    print_section "📊 Build Summary"
    
    echo -e "${WHITE}Built binaries:${NC}"
    local count=0
    local total_size=0
    
    for file in "${BUILD_DIR}/${APP_NAME}"-*; do
        if [[ -f "$file" && ! "$file" =~ \.(sha256|md5|tar\.gz|zip)$ ]]; then
            local size=$(du -b "$file" | cut -f1)
            local human_size=$(du -h "$file" | cut -f1)
            echo -e "   ${GREEN}✅${NC} $(basename "$file") - ${human_size}"
            ((count++))
            ((total_size += size))
        fi
    done
    
    local total_human=$(numfmt --to=iec --suffix=B $total_size)
    
    echo ""
    echo -e "${CYAN}📈 Statistics:${NC}"
    echo -e "   ${GREEN}🎯 Total platforms: ${count}${NC}"
    echo -e "   ${GREEN}📏 Total size: ${total_human}${NC}"
    echo -e "   ${GREEN}📁 Output directory: ${BUILD_DIR}${NC}"
    echo -e "   ${GREEN}🏷️  Version: ${VERSION}${NC}"
}

# Function to cleanup on error
cleanup_on_error() {
    echo -e "${RED}❌ Build failed, but keeping successful builds${NC}"
    exit 0  # Don't fail completely if some builds succeeded
}

# Main execution
main() {
    # Don't set error trap to allow partial success
    
    print_header
    
    # Prepare build directory
    print_section "🚀 Preparing Build Environment"
    echo -e "${CYAN}📁 Creating build directory: ${BUILD_DIR}${NC}"
    mkdir -p "$BUILD_DIR"
    
    # Clean previous builds
    echo -e "${CYAN}🧹 Cleaning previous builds:${NC}"
    rm -f "${BUILD_DIR}/${APP_NAME}"-*
    echo -e "   ${GREEN}✅ Cleanup complete${NC}"
    
    # Verify Go installation
    echo -e "${CYAN}🔍 Verifying Go installation:${NC}"
    if ! command -v go &> /dev/null; then
        echo -e "   ${RED}❌ Go is not installed${NC}"
        exit 1
    fi
    
    local go_version=$(go version | cut -d' ' -f3)
    echo -e "   ${GREEN}✅ Go ${go_version} detected${NC}"
    
    # Build for all platforms
    print_section "🏗️ Building for All Platforms"
    
    local success_count=0
    local total_count=${#PLATFORMS[@]}
    
    for platform in "${!PLATFORMS[@]}"; do
        local output_name="${PLATFORMS[$platform]}"
        
        # Continue building even if one fails
        build_platform "$platform" "$output_name" && ((success_count++)) || true
        echo ""
    done
    
    # Check if all builds succeeded
    if [[ $success_count -eq $total_count ]]; then
        echo -e "${GREEN}🎉 All platforms built successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️  ${success_count}/${total_count} platforms built successfully${NC}"
    fi
    
    # Create checksums and archives only if we have successful builds
    if [[ $success_count -gt 0 ]]; then
        create_checksums
        create_archives
        display_summary
        
        echo ""
        echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║${WHITE}                           🎉 Build Complete! 🎉                             ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${CYAN}                    Binaries ready for distribution                          ${PURPLE}║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        # Exit with success if we have any successful builds
        exit 0
    else
        echo -e "${RED}❌ No successful builds${NC}"
        exit 1
    fi
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi