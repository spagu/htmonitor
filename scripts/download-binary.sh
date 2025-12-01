#!/bin/bash

# Binary download script for htaccess-monitor
# Downloads pre-built binaries from GitHub releases
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
REPO_URL="https://github.com/tradik/htmonitor"
BINARY_NAME="htaccess-monitor"
INSTALL_DIR="tools"

# Function to get latest release version from GitHub API
get_latest_version() {
    local latest_version=""
    
    # Try using gh CLI first (if available)
    if command -v gh &> /dev/null; then
        latest_version=$(gh release list --repo tradik/htmonitor --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null)
    fi
    
    # Fallback to curl with GitHub API
    if [[ -z "$latest_version" ]]; then
        latest_version=$(curl -s "https://api.github.com/repos/tradik/htmonitor/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' 2>/dev/null)
    fi
    
    # Default fallback if API calls fail
    if [[ -z "$latest_version" ]]; then
        latest_version="v1.2.5"
        echo -e "${YELLOW}⚠️  Could not fetch latest version, using fallback: $latest_version${NC}" >&2
    else
        echo -e "${GREEN}🔍 Latest version detected: $latest_version${NC}" >&2
    fi
    
    echo "$latest_version"
}

# Set version (allow override with VERSION environment variable)
VERSION=${VERSION:-$(get_latest_version)}

# Architecture detection
detect_architecture() {
    local os=""
    local arch=""
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        FreeBSD*)   os="freebsd" ;;
        OpenBSD*)   os="openbsd" ;;
        NetBSD*)    os="netbsd" ;;
        *)          os="unknown" ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        arm64|aarch64)  arch="arm64" ;;
        i386|i686)      arch="386" ;;
        *)              arch="unknown" ;;
    esac
    
    # Handle Windows extension
    local extension=""
    if [[ "$os" == "windows" ]]; then
        extension=".exe"
    fi
    
    echo "${os}-${arch}${extension}"
}

# Function to print header
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                    📥 Binary Downloader 🚀                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}                   Downloading ${BINARY_NAME} v${VERSION}                          ${PURPLE}║${NC}"
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

# Function to download binary
download_binary() {
    local architecture="$1"
    local binary_filename="${BINARY_NAME}-${architecture}"
    local target_path="${INSTALL_DIR}/${BINARY_NAME}"
    
    echo -e "${CYAN}🔍 Target architecture: ${architecture}${NC}"
    echo -e "${CYAN}📁 Install path: ${target_path}${NC}"
    echo ""
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Download using GitHub CLI
    echo -e "${YELLOW}⬇️  Downloading binary using GitHub CLI...${NC}"
    if command -v gh >/dev/null 2>&1; then
        # Change to install directory for download
        cd "$INSTALL_DIR"
        if gh release download "${VERSION}" --repo "tradik/htmonitor" --pattern "${binary_filename}" --clobber; then
            # Rename downloaded file to standard name
            if [[ -f "$binary_filename" ]]; then
                mv "$binary_filename" "$BINARY_NAME"
                echo -e "${GREEN}✅ Download completed successfully${NC}"
            else
                echo -e "${RED}❌ Downloaded file not found${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ Download failed with GitHub CLI${NC}"
            return 1
        fi
        cd - >/dev/null
    else
        echo -e "${RED}❌ GitHub CLI (gh) is not available${NC}"
        echo -e "${YELLOW}💡 Please install GitHub CLI: https://cli.github.com/${NC}"
        echo -e "${YELLOW}💡 Alternative: Use 'make go-build' to compile from source${NC}"
        return 1
    fi
    
    # Make executable
    chmod +x "$target_path"
    echo -e "${GREEN}🔧 Made binary executable${NC}"
    
    # Verify download
    if [[ -f "$target_path" ]]; then
        local file_size=$(du -h "$target_path" | cut -f1)
        echo -e "${GREEN}📊 Binary size: ${file_size}${NC}"
        echo -e "${GREEN}✨ Binary ready at: ${target_path}${NC}"
        return 0
    else
        echo -e "${RED}❌ Binary verification failed${NC}"
        return 1
    fi
}

# Function to handle custom architecture
handle_custom_architecture() {
    local custom_arch="$1"
    
    echo -e "${CYAN}🎯 Using custom architecture: ${custom_arch}${NC}"
    
    # Validate custom architecture format
    if [[ ! "$custom_arch" =~ ^(linux|darwin|windows|freebsd|openbsd|netbsd)-(amd64|arm64|386)(\.exe)?$ ]]; then
        echo -e "${RED}❌ Invalid architecture format${NC}"
        echo -e "${YELLOW}💡 Expected format: os-arch (e.g., linux-amd64, windows-amd64.exe)${NC}"
        echo -e "${YELLOW}💡 Supported OS: linux, darwin, windows, freebsd, openbsd, netbsd${NC}"
        echo -e "${YELLOW}💡 Supported arch: amd64, arm64, 386${NC}"
        return 1
    fi
    
    download_binary "$custom_arch"
}

# Function to display available architectures
show_available_architectures() {
    print_section "🏗️ Available Architectures"
    
    echo -e "${WHITE}Supported platforms:${NC}"
    echo -e "   ${GREEN}🐧 Linux:${NC} linux-amd64, linux-arm64, linux-386"
    echo -e "   ${GREEN}🍎 macOS:${NC} darwin-amd64, darwin-arm64"
    echo -e "   ${GREEN}🪟 Windows:${NC} windows-amd64.exe, windows-arm64.exe, windows-386.exe"
    echo -e "   ${GREEN}🔥 FreeBSD:${NC} freebsd-amd64, freebsd-arm64"
    echo -e "   ${GREEN}🐡 OpenBSD:${NC} openbsd-amd64"
    echo -e "   ${GREEN}🚩 NetBSD:${NC} netbsd-amd64"
    echo ""
    echo -e "${CYAN}💡 Usage examples:${NC}"
    echo -e "   ${YELLOW}make go-binary${NC}                    # Auto-detect architecture"
    echo -e "   ${YELLOW}ARCH=linux-arm64 make go-binary${NC}   # Specify architecture"
    echo -e "   ${YELLOW}VERSION=1.1.0 make go-binary${NC}      # Specify version"
}

# Main execution
main() {
    print_header
    
    # Check if user wants to see available architectures
    if [[ "$1" == "--list" || "$1" == "-l" ]]; then
        show_available_architectures
        exit 0
    fi
    
    # Prepare download
    print_section "🚀 Preparing Download"
    
    # Determine architecture
    local target_arch=""
    if [[ -n "$ARCH" ]]; then
        target_arch="$ARCH"
        handle_custom_architecture "$target_arch"
    else
        target_arch=$(detect_architecture)
        
        if [[ "$target_arch" == *"unknown"* ]]; then
            echo -e "${RED}❌ Unable to detect system architecture${NC}"
            echo -e "${YELLOW}💡 Please specify architecture manually:${NC}"
            echo -e "${YELLOW}   ARCH=linux-amd64 make go-binary${NC}"
            echo ""
            show_available_architectures
            exit 1
        fi
        
        echo -e "${GREEN}🔍 Auto-detected architecture: ${target_arch}${NC}"
        download_binary "$target_arch"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║${WHITE}                           🎉 Download Complete! 🎉                          ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${CYAN}                      Binary ready for use                                   ${PURPLE}║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}🚀 Run the binary with:${NC}"
        echo -e "   ${YELLOW}make go-run${NC}"
        echo -e "   ${YELLOW}./tools/htaccess-monitor${NC}"
    else
        echo -e "${RED}❌ Download failed${NC}"
        exit 1
    fi
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi