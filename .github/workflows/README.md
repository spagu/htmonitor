# GitHub Actions Workflows

This directory contains automated workflows for the htaccess-monitor project.

## Workflows

### 1. 🔍 Lint Workflow (`lint.yml`)

**Triggers:**
- Push to `main` or `develop` branches (when Go files change)
- Pull requests to `main` or `develop` branches (when Go files change)

**What it does:**
1. ✅ Checks out code
2. ✅ Sets up Go 1.24
3. ✅ Downloads and verifies dependencies
4. ✅ Runs `go vet` for static analysis
5. ✅ Checks code formatting with `go fmt`
6. ✅ Runs `golangci-lint` for comprehensive linting
7. ✅ Runs unit tests with race detector
8. ✅ Runs integration tests
9. ✅ Uploads coverage to Codecov (optional)

**Status Badge:**
```markdown
[![Lint](https://github.com/spagu/htmonitor/actions/workflows/lint.yml/badge.svg)](https://github.com/spagu/htmonitor/actions/workflows/lint.yml)
```

**Configuration:**
- Go version: 1.24
- golangci-lint version: v1.61.0
- Timeout: 5 minutes
- Coverage: Uploaded to Codecov (requires `CODECOV_TOKEN` secret)

---

### 2. 🚀 Release Workflow (`release.yml`)

**Triggers:**
- Push to `main` branch (when Go files change)

**What it does:**
1. 📦 Auto-increments patch version (e.g., v1.0.0 → v1.0.1)
2. 🏗️ Builds binaries for multiple platforms:
   - **Linux**: AMD64, ARM64
   - **macOS**: AMD64 (Intel), ARM64 (Apple Silicon)
   - **FreeBSD**: AMD64, ARM64
3. 📦 Creates `.tar.gz` archives for each binary
4. 🔐 Generates SHA256 checksums
5. 📝 Auto-generates changelog from commits
6. 🎉 Creates GitHub release with all artifacts

**Platforms Built:**
| OS | Architecture | Binary Name |
|----|--------------|-------------|
| Linux | AMD64 | `htaccess-monitor-vX.Y.Z-linux-amd64.tar.gz` |
| Linux | ARM64 | `htaccess-monitor-vX.Y.Z-linux-arm64.tar.gz` |
| macOS | AMD64 | `htaccess-monitor-vX.Y.Z-darwin-amd64.tar.gz` |
| macOS | ARM64 | `htaccess-monitor-vX.Y.Z-darwin-arm64.tar.gz` |
| FreeBSD | AMD64 | `htaccess-monitor-vX.Y.Z-freebsd-amd64.tar.gz` |
| FreeBSD | ARM64 | `htaccess-monitor-vX.Y.Z-freebsd-arm64.tar.gz` |

**Version Injection:**
Each binary is built with version information:
```go
// Injected at build time
var (
    Version   = "vX.Y.Z"
    BuildTime = "2025-12-01T14:30:00Z"
)
```

**Status Badge:**
```markdown
[![Release](https://github.com/spagu/htmonitor/actions/workflows/release.yml/badge.svg)](https://github.com/spagu/htmonitor/actions/workflows/release.yml)
```

---

## Setup Instructions

### Prerequisites

1. **GitHub Repository Settings**
   - Go to `Settings` → `Actions` → `General`
   - Enable "Read and write permissions" for `GITHUB_TOKEN`
   - Enable "Allow GitHub Actions to create and approve pull requests"

2. **Optional: Codecov Integration**
   - Sign up at [codecov.io](https://codecov.io)
   - Get your repository token
   - Add as secret: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`
   - Name: `CODECOV_TOKEN`
   - Value: Your Codecov token

### First Release

The release workflow will auto-increment versions. If no tags exist, it starts at `v0.0.1`.

To set a specific starting version:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Next merge to `main` will create `v1.0.1`.

### Manual Release

To manually trigger a release:
```bash
# Create and push a tag
git tag v1.2.3
git push origin v1.2.3

# Or use GitHub CLI
gh release create v1.2.3 --generate-notes
```

---

## Workflow Files

### `lint.yml`
- **Purpose**: Code quality and testing
- **Runs on**: Every push/PR to main/develop
- **Duration**: ~2-3 minutes
- **Fail conditions**: 
  - Linting errors
  - Test failures
  - Race conditions detected

### `release.yml`
- **Purpose**: Automated releases
- **Runs on**: Push to main (Go files changed)
- **Duration**: ~3-5 minutes
- **Creates**: GitHub release with binaries

---

## Customization

### Change Version Increment Strategy

Edit `release.yml` to change from patch to minor/major:

```yaml
# For minor version (v1.0.0 → v1.1.0)
NEW_MINOR=$((MINOR + 1))
NEW_VERSION="v${MAJOR}.${NEW_MINOR}.0"

# For major version (v1.0.0 → v2.0.0)
NEW_MAJOR=$((MAJOR + 1))
NEW_VERSION="v${NEW_MAJOR}.0.0"
```

### Add More Platforms

Edit the `PLATFORMS` array in `release.yml`:

```yaml
PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "linux/386"          # Add 32-bit Linux
  "windows/amd64"      # Add Windows
  "openbsd/amd64"      # Add OpenBSD
)
```

### Change Go Version

Update both workflows:
```yaml
- name: Set up Go
  uses: actions/setup-go@v5
  with:
    go-version: '1.24'  # Change version here
```

---

## Troubleshooting

### Lint Workflow Fails

**Issue**: `golangci-lint` times out
```yaml
# Increase timeout in lint.yml
run: $(go env GOPATH)/bin/golangci-lint run --timeout=10m
```

**Issue**: Tests fail
```bash
# Run locally to debug
cd apps/htaccess-monitor
go test -v -race
go test -v -tags=integration
```

### Release Workflow Fails

**Issue**: Permission denied
- Check repository settings: `Settings` → `Actions` → `General`
- Enable "Read and write permissions"

**Issue**: Build fails for specific platform
```bash
# Test locally
GOOS=linux GOARCH=arm64 go build -o test main.go
```

**Issue**: No version increment
- Check if tags are fetched: `fetch-depth: 0` in checkout step
- Verify tag format: `v1.0.0` (must start with 'v')

---

## Monitoring

### View Workflow Runs
- Go to `Actions` tab in GitHub repository
- Click on workflow name to see runs
- Click on specific run to see logs

### Download Release Artifacts
```bash
# Using GitHub CLI
gh release download v1.0.0

# Using wget
wget https://github.com/spagu/htmonitor/releases/download/v1.0.0/htaccess-monitor-v1.0.0-linux-amd64.tar.gz
```

### Verify Checksums
```bash
# Download checksum file
wget https://github.com/spagu/htmonitor/releases/download/v1.0.0/htaccess-monitor-v1.0.0-linux-amd64.tar.gz.sha256

# Verify
sha256sum -c htaccess-monitor-v1.0.0-linux-amd64.tar.gz.sha256
```

---

## Best Practices

1. **Always test locally before pushing**
   ```bash
   make go-lint
   make go-test-all
   ```

2. **Use meaningful commit messages**
   - They appear in auto-generated changelogs
   - Format: `feat: add new feature` or `fix: resolve bug`

3. **Review workflow logs**
   - Check for warnings even if workflow passes
   - Monitor build times

4. **Keep workflows updated**
   - Update Go version regularly
   - Update action versions (e.g., `@v4` → `@v5`)

5. **Test releases**
   - Download and test binaries after release
   - Verify checksums
   - Test on target platforms

---

## Security

### Secrets Management
- Never commit secrets to repository
- Use GitHub Secrets for sensitive data
- Rotate tokens regularly

### Binary Verification
- Always verify checksums before using binaries
- Check release signatures
- Download from official GitHub releases only

### Permissions
- Workflows use minimal required permissions
- `GITHUB_TOKEN` has write access only for releases
- Review permissions in workflow files

---

## Support

For issues with workflows:
1. Check workflow logs in Actions tab
2. Review this README
3. Test locally with same commands
4. Open issue with workflow logs attached

For release issues:
1. Verify tag format (`v1.0.0`)
2. Check repository permissions
3. Review release workflow logs
4. Test build locally

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Go Cross Compilation](https://go.dev/doc/install/source#environment)
- [golangci-lint](https://golangci-lint.run/)
- [Codecov](https://docs.codecov.com/docs)
