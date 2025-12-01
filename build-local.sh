#!/bin/bash

# Build local binary with version support
set -e

echo "🔨 Building htaccess-monitor with version support..."

cd apps/htaccess-monitor

# Set version for local build
VERSION="dev-$(date +%Y%m%d-%H%M%S)"
BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "📦 Version: $VERSION"
echo "🕒 Build Time: $BUILD_TIME"

# Build with version injection
go build -ldflags "-s -w -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}" -o ../../tools/htaccess-monitor main.go

echo "✅ Built successfully!"
echo "📍 Binary location: tools/htaccess-monitor"
echo "🧪 Test with: ./tools/htaccess-monitor --version"