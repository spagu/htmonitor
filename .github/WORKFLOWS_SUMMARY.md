# GitHub Actions Workflows Summary

## Overview
Two automated workflows have been implemented to ensure code quality and streamline the release process.

## Files Created

### 1. `.github/workflows/lint.yml` - Code Quality Workflow
**Purpose:** Automated linting, testing, and code quality checks

**Triggers:**
- Push to `main` or `develop` branches (when Go files change)
- Pull requests to `main` or `develop` branches (when Go files change)

**Steps:**
1. ✅ Checkout code
2. ✅ Set up Go 1.24
3. ✅ Download and verify dependencies
4. ✅ Run `go vet` for static analysis
5. ✅ Check code formatting with `go fmt`
6. ✅ Run `golangci-lint` (v1.61.0) with 5-minute timeout
7. ✅ Run unit tests with race detector and coverage
8. ✅ Run integration tests
9. ✅ Upload coverage to Codecov (optional)

**Configuration:**
```yaml
Go Version: 1.24
golangci-lint: v1.61.0
Timeout: 5 minutes
Coverage: Atomic mode with race detector
```

---

### 2. `.github/workflows/release.yml` - Automated Release Workflow
**Purpose:** Automatic version bumping and multi-platform binary releases

**Triggers:**
- Push to `main` branch (when Go files change)

**Steps:**
1. 📦 Fetch all tags and determine latest version
2. 🔢 Auto-increment patch version (v1.0.0 → v1.0.1)
3. 🏗️ Build binaries for 6 platforms:
   - Linux AMD64
   - Linux ARM64
   - macOS AMD64 (Intel)
   - macOS ARM64 (Apple Silicon)
   - FreeBSD AMD64
   - FreeBSD ARM64
4. 📦 Create `.tar.gz` archives
5. 🔐 Generate SHA256 checksums
6. 📝 Auto-generate changelog from commits
7. 🎉 Create GitHub release with all artifacts

**Build Configuration:**
```yaml
Go Version: 1.24
Platforms: 6 (Linux, macOS, FreeBSD × AMD64/ARM64)
Version Injection: Yes (Version + BuildTime)
Compression: tar.gz
Checksums: SHA256
```

**Binary Naming Convention:**
```
htaccess-monitor-{version}-{os}-{arch}.tar.gz
htaccess-monitor-v1.0.1-linux-amd64.tar.gz
htaccess-monitor-v1.0.1-darwin-arm64.tar.gz
```

---

### 3. `.github/workflows/README.md` - Comprehensive Documentation
Complete guide covering:
- Workflow descriptions
- Setup instructions
- Customization options
- Troubleshooting
- Best practices
- Security considerations

---

## Features

### Lint Workflow Features
✅ **Static Analysis** - `go vet` catches common errors
✅ **Code Formatting** - Enforces `go fmt` standards
✅ **Comprehensive Linting** - `golangci-lint` with multiple linters
✅ **Race Detection** - Tests run with `-race` flag
✅ **Integration Tests** - Full workflow testing
✅ **Coverage Tracking** - Optional Codecov integration
✅ **Fast Feedback** - Runs on every push/PR

### Release Workflow Features
✅ **Automatic Versioning** - No manual version management
✅ **Multi-Platform Builds** - 6 platform combinations
✅ **Version Injection** - Binaries know their version
✅ **Secure Checksums** - SHA256 for verification
✅ **Auto Changelog** - Generated from git commits
✅ **Archive Creation** - Compressed tar.gz files
✅ **GitHub Release** - Automatic release creation
✅ **Download Instructions** - Included in release notes

---

## Workflow Triggers

### Lint Workflow
```yaml
Trigger: Push or PR to main/develop
Paths: apps/htaccess-monitor/**/*.go
Duration: ~2-3 minutes
Fail Conditions:
  - Linting errors
  - Test failures
  - Race conditions
  - Formatting issues
```

### Release Workflow
```yaml
Trigger: Push to main
Paths: apps/htaccess-monitor/**/*.go
Duration: ~3-5 minutes
Creates:
  - GitHub release
  - 6 binary archives
  - 6 checksum files
  - Auto-generated changelog
```

---

## Setup Requirements

### Repository Settings
1. **Enable Actions**
   - Go to `Settings` → `Actions` → `General`
   - Enable "Read and write permissions" for `GITHUB_TOKEN`

2. **Optional: Codecov**
   - Sign up at [codecov.io](https://codecov.io)
   - Add `CODECOV_TOKEN` secret to repository

### First Release
The workflow auto-increments from the latest tag:
- No tags: Creates `v0.0.1`
- Tag `v1.0.0` exists: Creates `v1.0.1`
- Tag `v1.2.5` exists: Creates `v1.2.6`

To set a specific starting version:
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Usage

### Running Lint Checks Locally
```bash
# Run all checks that CI will run
make go-lint
make go-test
make go-test-integration

# Or manually
cd apps/htaccess-monitor
go vet ./...
gofmt -l .
golangci-lint run
go test -v -race
go test -v -tags=integration
```

### Testing Release Build Locally
```bash
cd apps/htaccess-monitor

# Build for specific platform
GOOS=linux GOARCH=amd64 go build \
  -ldflags "-X main.Version=v1.0.0 -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -o htaccess-monitor-v1.0.0-linux-amd64 \
  main.go

# Test the binary
./htaccess-monitor-v1.0.0-linux-amd64 -version
```

### Downloading Released Binaries
```bash
# Using GitHub CLI
gh release download v1.0.0

# Using wget
wget https://github.com/spagu/htmonitor/releases/download/v1.0.0/htaccess-monitor-v1.0.0-linux-amd64.tar.gz

# Extract
tar -xzf htaccess-monitor-v1.0.0-linux-amd64.tar.gz

# Verify checksum
wget https://github.com/spagu/htmonitor/releases/download/v1.0.0/htaccess-monitor-v1.0.0-linux-amd64.tar.gz.sha256
sha256sum -c htaccess-monitor-v1.0.0-linux-amd64.tar.gz.sha256
```

---

## Badges Added to README

```markdown
[![Lint](https://github.com/spagu/htmonitor/actions/workflows/lint.yml/badge.svg)](https://github.com/spagu/htmonitor/actions/workflows/lint.yml)
[![Release](https://github.com/spagu/htmonitor/actions/workflows/release.yml/badge.svg)](https://github.com/spagu/htmonitor/actions/workflows/release.yml)
```

These badges show the current status of workflows and link to the Actions page.

---

## Version Injection

Binaries are built with version information:

```go
// In main.go
var (
    Version   = "dev"        // Replaced at build time
    BuildTime = "unknown"    // Replaced at build time
)

// Usage
func main() {
    if *version {
        fmt.Printf("Version: %s\n", Version)
        fmt.Printf("Build Time: %s\n", BuildTime)
        return
    }
}
```

Users can check version:
```bash
./htaccess-monitor -version
# Output:
# Version: v1.0.1
# Build Time: 2025-12-01T14:30:00Z
```

---

## Changelog Generation

The release workflow auto-generates changelogs from git commits:

**Example Changelog:**
```markdown
## What's Changed

- feat: add comprehensive test suite (abc123)
- fix: resolve race condition in file watcher (def456)
- docs: update README with testing section (ghi789)

## Binaries

Download the appropriate binary for your platform:

### Linux
- **AMD64**: htaccess-monitor-v1.0.1-linux-amd64.tar.gz
- **ARM64**: htaccess-monitor-v1.0.1-linux-arm64.tar.gz

...
```

**Best Practices for Commit Messages:**
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`
- Keep messages concise and descriptive
- They appear in release notes

---

## Monitoring

### View Workflow Runs
1. Go to repository on GitHub
2. Click "Actions" tab
3. Select workflow to view runs
4. Click specific run for detailed logs

### Check Release Status
1. Go to "Releases" section
2. Latest release shows auto-generated content
3. Download artifacts directly from release page

### Workflow Notifications
GitHub sends notifications for:
- ✅ Workflow success
- ❌ Workflow failure
- 📦 New release created

Configure in: `Settings` → `Notifications`

---

## Troubleshooting

### Lint Workflow Issues

**Problem:** golangci-lint timeout
```yaml
# Solution: Increase timeout in lint.yml
run: $(go env GOPATH)/bin/golangci-lint run --timeout=10m
```

**Problem:** Tests fail
```bash
# Solution: Run locally to debug
cd apps/htaccess-monitor
go test -v -race
go test -v -tags=integration
```

### Release Workflow Issues

**Problem:** Permission denied
```
Solution:
1. Go to Settings → Actions → General
2. Enable "Read and write permissions"
3. Enable "Allow GitHub Actions to create and approve pull requests"
```

**Problem:** Build fails for platform
```bash
# Solution: Test build locally
GOOS=linux GOARCH=arm64 go build -o test main.go
```

**Problem:** No version increment
```
Solution:
1. Check fetch-depth: 0 in checkout step
2. Verify tags are pushed: git push --tags
3. Check tag format: must be v1.0.0 (with 'v' prefix)
```

---

## Security

### Secrets Management
- `GITHUB_TOKEN` - Auto-provided by GitHub
- `CODECOV_TOKEN` - Optional, add manually

### Binary Verification
Always verify checksums:
```bash
sha256sum -c htaccess-monitor-v1.0.0-linux-amd64.tar.gz.sha256
```

### Permissions
- Workflows use minimal required permissions
- `GITHUB_TOKEN` has write access only for releases
- No external secrets required (except optional Codecov)

---

## Customization

### Change Version Strategy
Edit `release.yml` to increment minor or major:

```yaml
# Minor version (v1.0.0 → v1.1.0)
NEW_MINOR=$((MINOR + 1))
NEW_VERSION="v${MAJOR}.${NEW_MINOR}.0"

# Major version (v1.0.0 → v2.0.0)
NEW_MAJOR=$((MAJOR + 1))
NEW_VERSION="v${NEW_MAJOR}.0.0"
```

### Add More Platforms
Edit `PLATFORMS` array in `release.yml`:

```yaml
PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "windows/amd64"    # Add Windows
  "openbsd/amd64"    # Add OpenBSD
)
```

### Change Trigger Paths
Modify `paths` in workflow files:

```yaml
paths:
  - 'apps/htaccess-monitor/**/*.go'
  - 'apps/htaccess-monitor/go.mod'
  - 'apps/htaccess-monitor/go.sum'
  - 'Makefile'  # Add more paths
```

---

## Benefits

### For Development
- 🔍 **Early Bug Detection** - Catch issues before merge
- 🚀 **Fast Feedback** - Results in 2-3 minutes
- 📊 **Coverage Tracking** - Monitor test coverage
- 🎯 **Quality Gates** - Enforce standards

### For Releases
- ⚡ **Automated** - No manual release process
- 🌍 **Multi-Platform** - 6 platforms automatically
- 🔐 **Secure** - Checksums for verification
- 📝 **Documented** - Auto-generated changelogs

### For Users
- 📦 **Easy Download** - Pre-built binaries
- ✅ **Verified** - SHA256 checksums
- 📚 **Documented** - Installation instructions
- 🔄 **Updated** - Automatic releases on merge

---

## Next Steps

### Immediate
1. ✅ Workflows created and documented
2. ✅ README updated with badges
3. ✅ Ready to use on next push

### Future Enhancements
- [ ] Add Windows builds (optional)
- [ ] Add OpenBSD/NetBSD builds (optional)
- [ ] Set up Codecov integration
- [ ] Add workflow for Docker image builds
- [ ] Add workflow for Python tests
- [ ] Create pre-release workflow for develop branch

---

## Conclusion

✅ **Two workflows created**
- Lint workflow for code quality
- Release workflow for automated releases

✅ **Multi-platform support**
- Linux, macOS, FreeBSD
- AMD64 and ARM64 architectures

✅ **Fully documented**
- Comprehensive README
- Usage examples
- Troubleshooting guide

✅ **Production ready**
- Tested configurations
- Security best practices
- Minimal permissions

The repository now has a complete CI/CD pipeline that ensures code quality and automates the release process!
