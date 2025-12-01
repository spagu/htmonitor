# Testing Guide for htaccess-monitor

## Overview

This document describes the comprehensive test suite for the htaccess-monitor Go application.

## Test Structure

### Unit Tests (`main_test.go`)
Unit tests cover individual functions and components:

- **`TestGetStatusIcon`** - Tests status code to icon mapping (200, 302, 404, etc.)
- **`TestMax`** - Tests the max utility function
- **`TestStripAnsiCodes`** - Tests ANSI escape code removal
- **`TestVisualWidth`** - Tests visual width calculation for strings with emojis
- **`TestPadToWidth`** - Tests string padding functionality
- **`TestApplyFilters`** - Tests result filtering (hide passes/fails)
- **`TestParseLinkTestFile`** - Tests CSV file parsing
- **`TestParseLinkTestFileInvalid`** - Tests error handling for invalid CSV
- **`TestParseLinkTestFileNotFound`** - Tests missing file handling
- **`TestTestURL`** - Tests HTTP request functionality with mock servers
- **`TestTestURLWithUserAgent`** - Tests user agent header handling
- **`TestTestSpecialURL`** - Tests special URL handling (wp-admin, robots.txt, sitemap)
- **`TestRunLinkTests`** - Tests the complete link testing workflow
- **`TestCountryStructure`** - Tests Country struct
- **`TestHTTPResult`** - Tests HTTPResult struct
- **`TestLinkTestResult`** - Tests LinkTestResult struct

### Integration Tests (`integration_test.go`)
Integration tests verify complete workflows:

- **`TestIntegrationFullWorkflow`** - Tests end-to-end workflow with CSV parsing and HTTP testing
- **`TestIntegrationFilterWorkflow`** - Tests filtering functionality across multiple results
- **`TestIntegrationHTTPTimeout`** - Tests timeout handling for slow servers
- **`TestIntegrationSpecialURLs`** - Tests special URL handling (wp-admin, robots.txt, sitemaps)
- **`TestIntegrationRedirectChain`** - Tests redirect handling
- **`TestIntegrationUserAgentHandling`** - Tests GoogleBot vs regular user handling
- **`TestIntegrationCSVEdgeCases`** - Tests CSV parsing edge cases (spaces, quotes, missing columns)
- **`TestIntegrationCountryCodeNormalization`** - Tests country code uppercase conversion

### Benchmarks
Performance benchmarks for critical functions:

- **`BenchmarkGetStatusIcon`** - Status icon retrieval performance
- **`BenchmarkStripAnsiCodes`** - ANSI code stripping performance
- **`BenchmarkApplyFilters`** - Filter application performance

## Running Tests

### Using Make (Recommended)

```bash
# Run unit tests
make go-test

# Run unit tests with coverage report
make go-test-coverage

# Run integration tests
make go-test-integration

# Run benchmarks
make go-test-bench

# Run all tests
make go-test-all

# Run linter
make go-lint
```

### Using Go Commands Directly

```bash
# Run unit tests
cd apps/htaccess-monitor
go test -v

# Run with coverage
go test -v -cover

# Generate coverage report
go test -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

# Run integration tests
go test -v -tags=integration

# Run benchmarks
go test -bench=. -benchmem

# Run specific test
go test -v -run TestGetStatusIcon

# Run with race detector
go test -race
```

## Test Coverage

Current coverage: **19.5%** of statements

Coverage focuses on:
- ✅ Core utility functions (100%)
- ✅ HTTP testing functions (100%)
- ✅ CSV parsing (100%)
- ✅ Filter logic (100%)
- ⚠️ UI/Display functions (not tested - terminal output)
- ⚠️ File watching (not tested - requires filesystem monitoring)
- ⚠️ Main function (not tested - entry point)

## Test Files

- `main_test.go` - Unit tests (16 test functions)
- `integration_test.go` - Integration tests (8 test functions)
- `coverage.out` - Coverage data (generated)
- `coverage.html` - HTML coverage report (generated)

## Writing New Tests

### Unit Test Template

```go
func TestYourFunction(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected string
    }{
        {"test case 1", "input1", "expected1"},
        {"test case 2", "input2", "expected2"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := yourFunction(tt.input)
            if result != tt.expected {
                t.Errorf("yourFunction(%s) = %s, want %s", 
                    tt.input, result, tt.expected)
            }
        })
    }
}
```

### Integration Test Template

```go
// +build integration

func TestIntegrationYourFeature(t *testing.T) {
    // Setup
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(200)
    }))
    defer server.Close()

    // Test
    result := yourFunction(server.URL)

    // Assert
    if result != expected {
        t.Errorf("Expected %v, got %v", expected, result)
    }
}
```

### Benchmark Template

```go
func BenchmarkYourFunction(b *testing.B) {
    input := "test input"
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        yourFunction(input)
    }
}
```

## Mock HTTP Servers

Tests use `httptest.NewServer` for HTTP testing:

```go
server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    // Verify request headers
    if r.Header.Get("X-Test-Country") != "US" {
        t.Error("Country header not set")
    }
    
    // Send response
    w.Header().Set("Location", "http://example.com/redirect")
    w.WriteHeader(302)
}))
defer server.Close()

// Use server.URL in tests
result := testURL(server.URL, "US", "")
```

## Continuous Integration

Tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: |
    cd apps/htaccess-monitor
    go test -v -race -coverprofile=coverage.out
    go test -v -tags=integration
```

## Test Best Practices

1. **Table-Driven Tests** - Use test tables for multiple scenarios
2. **Subtests** - Use `t.Run()` for organized test output
3. **Mock Servers** - Use `httptest` for HTTP testing
4. **Temp Files** - Use `t.TempDir()` for file operations
5. **Cleanup** - Use `defer` for resource cleanup
6. **Race Detection** - Run with `-race` flag
7. **Coverage** - Aim for >80% coverage of business logic
8. **Fast Tests** - Keep unit tests under 100ms
9. **Isolated Tests** - Tests should not depend on each other
10. **Clear Names** - Use descriptive test names

## Troubleshooting

### Tests Fail Locally

```bash
# Clean and rebuild
make clean
make go-deps
make go-test
```

### Coverage Report Not Generated

```bash
# Ensure coverage.out exists
cd apps/htaccess-monitor
go test -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

### Integration Tests Timeout

Integration tests include HTTP timeout tests that take 10+ seconds. This is expected behavior.

### Race Conditions

```bash
# Run with race detector
go test -race
```

## Performance Benchmarks

Current benchmark results (AMD Ryzen 9 7950X):

```
BenchmarkGetStatusIcon-32       1000000000    0.19 ns/op    0 B/op    0 allocs/op
BenchmarkStripAnsiCodes-32      809494        1264 ns/op    1723 B/op  24 allocs/op
BenchmarkApplyFilters-32        418665        3073 ns/op    15712 B/op 7 allocs/op
```

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure all tests pass
3. Add integration tests for workflows
4. Update this README if needed
5. Run linter: `make go-lint`

## Resources

- [Go Testing Package](https://pkg.go.dev/testing)
- [Table-Driven Tests](https://github.com/golang/go/wiki/TableDrivenTests)
- [httptest Package](https://pkg.go.dev/net/http/httptest)
- [Coverage Tool](https://go.dev/blog/cover)
