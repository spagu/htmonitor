package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestGetStatusIcon tests the status icon mapping
func TestGetStatusIcon(t *testing.T) {
	tests := []struct {
		name     string
		status   int
		expected string
	}{
		{"Status 200", 200, "✅"},
		{"Status 302", 302, "🔄"},
		{"Status 404", 404, "❌"},
		{"Status 500", 500, "❌"},
		{"Status 301", 301, "❌"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := getStatusIcon(tt.status)
			if result != tt.expected {
				t.Errorf("getStatusIcon(%d) = %s, want %s", tt.status, result, tt.expected)
			}
		})
	}
}

// TestMax tests the max function
func TestMax(t *testing.T) {
	tests := []struct {
		name     string
		a        int
		b        int
		expected int
	}{
		{"a greater", 10, 5, 10},
		{"b greater", 5, 10, 10},
		{"equal", 7, 7, 7},
		{"negative numbers", -5, -10, -5},
		{"zero and positive", 0, 5, 5},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := max(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("max(%d, %d) = %d, want %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

// TestStripAnsiCodes tests ANSI code stripping
func TestStripAnsiCodes(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"no ansi codes", "hello world", "hello world"},
		{"with color codes", "\x1b[31mred text\x1b[0m", "red text"},
		{"multiple codes", "\x1b[1m\x1b[31mbold red\x1b[0m", "bold red"},
		{"empty string", "", ""},
		{"only ansi codes", "\x1b[31m\x1b[0m", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := stripAnsiCodes(tt.input)
			if result != tt.expected {
				t.Errorf("stripAnsiCodes(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

// TestVisualWidth tests visual width calculation
func TestVisualWidth(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected int
	}{
		{"simple ascii", "hello", 5},
		{"with ansi codes", "\x1b[31mred\x1b[0m", 3},
		{"empty string", "", 0},
		{"emoji", "🔥", 2},
		{"mixed", "test🔥", 6},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := visualWidth(tt.input)
			if result != tt.expected {
				t.Errorf("visualWidth(%q) = %d, want %d", tt.input, result, tt.expected)
			}
		})
	}
}

// TestPadToWidth tests padding functionality
func TestPadToWidth(t *testing.T) {
	tests := []struct {
		name        string
		input       string
		targetWidth int
		minLength   int
	}{
		{"pad needed", "test", 10, 10},
		{"no pad needed", "test", 3, 4},
		{"exact width", "test", 4, 4},
		{"with ansi", "\x1b[31mred\x1b[0m", 10, 10},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := padToWidth(tt.input, tt.targetWidth)
			if len(result) < tt.minLength {
				t.Errorf("padToWidth(%q, %d) length = %d, want at least %d", tt.input, tt.targetWidth, len(result), tt.minLength)
			}
		})
	}
}

// TestApplyFilters tests result filtering
func TestApplyFilters(t *testing.T) {
	results := []LinkTestResult{
		{Success: true},
		{Success: false},
		{Success: true},
		{Success: false},
	}

	tests := []struct {
		name          string
		filter        FilterState
		expectedCount int
	}{
		{"no filter", FilterState{hideFails: false, hidePasses: false}, 4},
		{"hide fails", FilterState{hideFails: true, hidePasses: false}, 2},
		{"hide passes", FilterState{hideFails: false, hidePasses: true}, 2},
		{"hide both", FilterState{hideFails: true, hidePasses: true}, 0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			filtered := applyFilters(results, tt.filter)
			if len(filtered) != tt.expectedCount {
				t.Errorf("applyFilters() returned %d results, want %d", len(filtered), tt.expectedCount)
			}
		})
	}
}

// TestParseLinkTestFile tests CSV parsing
func TestParseLinkTestFile(t *testing.T) {
	// Create temporary test file
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.csv")

	csvContent := `Agent,Country,URL,ExpectedStatus,ExpectedResult
Browser,US,http://example.com,200,No redirect
GoogleBot,UK,http://example.com/page,302,http://example.com/uk/page
Browser,DE,http://example.com,301,http://example.com/de`

	err := os.WriteFile(testFile, []byte(csvContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	tests, err := parseLinkTestFile(testFile)
	if err != nil {
		t.Fatalf("parseLinkTestFile() error = %v", err)
	}

	if len(tests) != 3 {
		t.Errorf("parseLinkTestFile() returned %d tests, want 3", len(tests))
	}

	// Verify first test
	if tests[0].Agent != "Browser" {
		t.Errorf("First test Agent = %s, want Browser", tests[0].Agent)
	}
	if tests[0].Country != "US" {
		t.Errorf("First test Country = %s, want US", tests[0].Country)
	}
	if tests[0].ExpectedStatus != 200 {
		t.Errorf("First test ExpectedStatus = %d, want 200", tests[0].ExpectedStatus)
	}
}

// TestParseLinkTestFileInvalid tests error handling
func TestParseLinkTestFileInvalid(t *testing.T) {
	tests := []struct {
		name    string
		content string
	}{
		{"empty file", ""},
		{"only header", "Agent,Country,URL,ExpectedStatus,ExpectedResult"},
		{"invalid status", "Browser,US,http://example.com,invalid,No redirect"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tmpDir := t.TempDir()
			testFile := filepath.Join(tmpDir, "test.csv")
			err := os.WriteFile(testFile, []byte(tt.content), 0644)
			if err != nil {
				t.Fatalf("Failed to create test file: %v", err)
			}

			tests, err := parseLinkTestFile(testFile)
			if err != nil && tt.name == "empty file" {
				return // Expected error for empty file
			}
			if len(tests) > 0 && tt.name == "only header" {
				t.Errorf("Expected no tests for header-only file, got %d", len(tests))
			}
		})
	}
}

// TestParseLinkTestFileNotFound tests missing file handling
func TestParseLinkTestFileNotFound(t *testing.T) {
	_, err := parseLinkTestFile("/nonexistent/file.csv")
	if err == nil {
		t.Error("parseLinkTestFile() expected error for nonexistent file, got nil")
	}
}

// TestTestURL tests HTTP request functionality with mock server
func TestTestURL(t *testing.T) {
	tests := []struct {
		name           string
		statusCode     int
		location       string
		expectedStatus int
		expectedResult string
	}{
		{"200 OK", 200, "", 200, "No redirect"},
		{"302 redirect", 302, "http://example.com/redirect", 302, "http://example.com/redirect"},
		{"301 redirect", 301, "http://example.com/moved", 301, "http://example.com/moved"},
		{"302 no location", 302, "", 302, "No redirect"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mock server
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				// Verify headers
				if r.Header.Get("X-Test-Country") == "" {
					t.Error("X-Test-Country header not set")
				}

				if tt.location != "" {
					w.Header().Set("Location", tt.location)
				}
				w.WriteHeader(tt.statusCode)
			}))
			defer server.Close()

			result := testURL(server.URL, "US", "")

			if result.Status != tt.expectedStatus {
				t.Errorf("testURL() status = %d, want %d", result.Status, tt.expectedStatus)
			}
			if result.Result != tt.expectedResult {
				t.Errorf("testURL() result = %s, want %s", result.Result, tt.expectedResult)
			}
		})
	}
}

// TestTestURLWithUserAgent tests user agent header
func TestTestURLWithUserAgent(t *testing.T) {
	expectedUA := "TestBot/1.0"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("User-Agent") != expectedUA {
			t.Errorf("User-Agent = %s, want %s", r.Header.Get("User-Agent"), expectedUA)
		}
		w.WriteHeader(200)
	}))
	defer server.Close()

	testURL(server.URL, "US", expectedUA)
}

// TestTestSpecialURL tests special URL handling
func TestTestSpecialURL(t *testing.T) {
	tests := []struct {
		name           string
		url            string
		statusCode     int
		expectedResult string
	}{
		{"wp-admin 200", "/wp-admin/", 200, "No redirect (protected)"},
		{"robots.txt 200", "/robots.txt", 200, "No redirect (SEO protected)"},
		{"sitemap 200", "/sitemap.xml", 200, "No redirect (SEO protected)"},
		{"redirect", "/page", 302, "http://example.com/redirect"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if tt.statusCode == 302 {
					w.Header().Set("Location", "http://example.com/redirect")
				}
				w.WriteHeader(tt.statusCode)
			}))
			defer server.Close()

			result := testSpecialURL(server.URL+tt.url, map[string]string{"X-Test-Country": "DE"})

			if !strings.Contains(result.Result, tt.expectedResult) && result.Result != tt.expectedResult {
				t.Errorf("testSpecialURL() result = %s, want to contain %s", result.Result, tt.expectedResult)
			}
		})
	}
}

// TestRunLinkTests tests the link test execution
func TestRunLinkTests(t *testing.T) {
	// Create mock server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		country := r.Header.Get("X-Test-Country")
		if country == "US" {
			w.WriteHeader(200)
		} else {
			w.Header().Set("Location", "http://example.com/redirect")
			w.WriteHeader(302)
		}
	}))
	defer server.Close()

	tests := []LinkTest{
		{
			Agent:          "Browser",
			Country:        "US",
			URL:            server.URL,
			ExpectedStatus: 200,
			ExpectedResult: "No redirect",
		},
		{
			Agent:          "Browser",
			Country:        "UK",
			URL:            server.URL,
			ExpectedStatus: 302,
			ExpectedResult: "http://example.com/redirect",
		},
	}

	results := runLinkTests(tests)

	if len(results) != 2 {
		t.Errorf("runLinkTests() returned %d results, want 2", len(results))
	}

	// Check first result (should pass)
	if !results[0].Success {
		t.Error("First test should pass")
	}

	// Check second result (should pass)
	if !results[1].Success {
		t.Error("Second test should pass")
	}
}

// TestCountryStructure tests Country struct
func TestCountryStructure(t *testing.T) {
	country := Country{
		Code: "us",
		Flag: "🇺🇸",
		Name: "United States",
	}

	if country.Code != "us" {
		t.Errorf("Country.Code = %s, want us", country.Code)
	}
	if country.Name != "United States" {
		t.Errorf("Country.Name = %s, want United States", country.Name)
	}
}

// TestHTTPResult tests HTTPResult struct
func TestHTTPResult(t *testing.T) {
	result := HTTPResult{
		Status:     200,
		StatusText: "OK",
		Result:     "No redirect",
	}

	if result.Status != 200 {
		t.Errorf("HTTPResult.Status = %d, want 200", result.Status)
	}
	if result.Result != "No redirect" {
		t.Errorf("HTTPResult.Result = %s, want No redirect", result.Result)
	}
}

// TestLinkTestResult tests LinkTestResult struct
func TestLinkTestResult(t *testing.T) {
	test := LinkTest{
		Agent:          "Browser",
		Country:        "US",
		URL:            "http://example.com",
		ExpectedStatus: 200,
		ExpectedResult: "No redirect",
	}

	result := LinkTestResult{
		Test:    test,
		Status:  200,
		Result:  "No redirect",
		Success: true,
	}

	if !result.Success {
		t.Error("LinkTestResult.Success should be true")
	}
	if result.Test.Agent != "Browser" {
		t.Errorf("LinkTestResult.Test.Agent = %s, want Browser", result.Test.Agent)
	}
}

// BenchmarkGetStatusIcon benchmarks status icon retrieval
func BenchmarkGetStatusIcon(b *testing.B) {
	for i := 0; i < b.N; i++ {
		getStatusIcon(200)
		getStatusIcon(302)
		getStatusIcon(404)
	}
}

// BenchmarkStripAnsiCodes benchmarks ANSI code stripping
func BenchmarkStripAnsiCodes(b *testing.B) {
	input := "\x1b[31m\x1b[1mcolored text\x1b[0m"
	for i := 0; i < b.N; i++ {
		stripAnsiCodes(input)
	}
}

// BenchmarkApplyFilters benchmarks filtering
func BenchmarkApplyFilters(b *testing.B) {
	results := make([]LinkTestResult, 100)
	for i := 0; i < 100; i++ {
		results[i] = LinkTestResult{Success: i%2 == 0}
	}
	filter := FilterState{hideFails: true}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		applyFilters(results, filter)
	}
}
