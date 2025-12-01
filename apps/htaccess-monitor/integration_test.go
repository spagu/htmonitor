//go:build integration

package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// TestIntegrationFullWorkflow tests the complete workflow
func TestIntegrationFullWorkflow(t *testing.T) {
	// Create test CSV file
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "links.testing")

	// Create mock HTTP server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		country := r.Header.Get("X-Test-Country")
		userAgent := r.Header.Get("User-Agent")

		// Simulate geo-redirection logic
		if country == "US" {
			w.WriteHeader(200)
		} else if country == "UK" || country == "GB" {
			w.Header().Set("Location", "http://example.com/uk")
			w.WriteHeader(302)
		} else {
			w.Header().Set("Location", "http://example.com/"+country)
			w.WriteHeader(302)
		}

		// GoogleBot gets different treatment
		if userAgent != "" && userAgent == "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" {
			w.WriteHeader(200)
		}
	}))
	defer server.Close()

	// Create test CSV with mock server URL
	csvContent := `Agent,Country,URL,ExpectedStatus,ExpectedResult
Browser,US,` + server.URL + `,200,No redirect
Browser,UK,` + server.URL + `,302,http://example.com/uk
GoogleBot,UK,` + server.URL + `,200,No redirect
Browser,DE,` + server.URL + `,302,http://example.com/DE`

	err := os.WriteFile(testFile, []byte(csvContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Parse test file
	tests, err := parseLinkTestFile(testFile)
	if err != nil {
		t.Fatalf("parseLinkTestFile() error = %v", err)
	}

	if len(tests) != 4 {
		t.Errorf("Expected 4 tests, got %d", len(tests))
	}

	// Run tests
	results := runLinkTests(tests)

	if len(results) != 4 {
		t.Errorf("Expected 4 results, got %d", len(results))
	}

	// Verify results
	passCount := 0
	for _, result := range results {
		if result.Success {
			passCount++
		}
	}

	if passCount < 3 {
		t.Errorf("Expected at least 3 passing tests, got %d", passCount)
	}
}

// TestIntegrationFilterWorkflow tests filtering functionality
func TestIntegrationFilterWorkflow(t *testing.T) {
	// Create test results
	results := []LinkTestResult{
		{
			Test: LinkTest{
				Agent:          "Browser",
				Country:        "US",
				URL:            "http://example.com",
				ExpectedStatus: 200,
				ExpectedResult: "No redirect",
			},
			Status:  200,
			Result:  "No redirect",
			Success: true,
		},
		{
			Test: LinkTest{
				Agent:          "Browser",
				Country:        "UK",
				URL:            "http://example.com",
				ExpectedStatus: 302,
				ExpectedResult: "http://example.com/uk",
			},
			Status:  200,
			Result:  "No redirect",
			Success: false,
		},
		{
			Test: LinkTest{
				Agent:          "Browser",
				Country:        "DE",
				URL:            "http://example.com",
				ExpectedStatus: 302,
				ExpectedResult: "http://example.com/de",
			},
			Status:  302,
			Result:  "http://example.com/de",
			Success: true,
		},
	}

	// Test no filter
	filtered := applyFilters(results, FilterState{})
	if len(filtered) != 3 {
		t.Errorf("No filter: expected 3 results, got %d", len(filtered))
	}

	// Test hide fails
	filtered = applyFilters(results, FilterState{hideFails: true})
	if len(filtered) != 2 {
		t.Errorf("Hide fails: expected 2 results, got %d", len(filtered))
	}
	for _, r := range filtered {
		if !r.Success {
			t.Error("Hide fails: found failed test in results")
		}
	}

	// Test hide passes
	filtered = applyFilters(results, FilterState{hidePasses: true})
	if len(filtered) != 1 {
		t.Errorf("Hide passes: expected 1 result, got %d", len(filtered))
	}
	for _, r := range filtered {
		if r.Success {
			t.Error("Hide passes: found passed test in results")
		}
	}

	// Test hide both
	filtered = applyFilters(results, FilterState{hideFails: true, hidePasses: true})
	if len(filtered) != 0 {
		t.Errorf("Hide both: expected 0 results, got %d", len(filtered))
	}
}

// TestIntegrationHTTPTimeout tests timeout handling
func TestIntegrationHTTPTimeout(t *testing.T) {
	// Create slow server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(10 * time.Second) // Longer than client timeout
		w.WriteHeader(200)
	}))
	defer server.Close()

	// Test should timeout
	result := testURL(server.URL, "US", "")

	if result.Status != 0 {
		t.Errorf("Expected timeout (status 0), got status %d", result.Status)
	}
	if result.Result != "Connection failed" {
		t.Errorf("Expected 'Connection failed', got '%s'", result.Result)
	}
}

// TestIntegrationSpecialURLs tests special URL handling
func TestIntegrationSpecialURLs(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// All special URLs should return 200
		w.WriteHeader(200)
	}))
	defer server.Close()

	specialURLs := []struct {
		path           string
		expectedResult string
	}{
		{"/wp-admin/", "No redirect (protected)"},
		{"/robots.txt", "No redirect (SEO protected)"},
		{"/sitemap.xml", "No redirect (SEO protected)"},
		{"/sitemap_index.xml", "No redirect (SEO protected)"},
	}

	for _, test := range specialURLs {
		t.Run(test.path, func(t *testing.T) {
			result := testSpecialURL(server.URL+test.path, map[string]string{"X-Test-Country": "DE"})

			if result.Status != 200 {
				t.Errorf("Expected status 200, got %d", result.Status)
			}
			if result.Result != test.expectedResult {
				t.Errorf("Expected result '%s', got '%s'", test.expectedResult, result.Result)
			}
		})
	}
}

// TestIntegrationRedirectChain tests redirect handling
func TestIntegrationRedirectChain(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Return redirect
		w.Header().Set("Location", "http://example.com/final")
		w.WriteHeader(302)
	}))
	defer server.Close()

	result := testURL(server.URL, "UK", "")

	if result.Status != 302 {
		t.Errorf("Expected status 302, got %d", result.Status)
	}
	if result.Result != "http://example.com/final" {
		t.Errorf("Expected redirect to 'http://example.com/final', got '%s'", result.Result)
	}
}

// TestIntegrationUserAgentHandling tests different user agents
func TestIntegrationUserAgentHandling(t *testing.T) {
	googleBotUA := "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ua := r.Header.Get("User-Agent")
		if ua == googleBotUA {
			// GoogleBot gets 200
			w.WriteHeader(200)
		} else {
			// Regular users get redirected
			w.Header().Set("Location", "http://example.com/redirect")
			w.WriteHeader(302)
		}
	}))
	defer server.Close()

	// Test regular user
	regularResult := testURL(server.URL, "UK", "")
	if regularResult.Status != 302 {
		t.Errorf("Regular user: expected status 302, got %d", regularResult.Status)
	}

	// Test GoogleBot
	botResult := testURL(server.URL, "UK", googleBotUA)
	if botResult.Status != 200 {
		t.Errorf("GoogleBot: expected status 200, got %d", botResult.Status)
	}
}

// TestIntegrationCSVEdgeCases tests CSV parsing edge cases
func TestIntegrationCSVEdgeCases(t *testing.T) {
	tmpDir := t.TempDir()

	tests := []struct {
		name        string
		content     string
		expectError bool
		expectCount int
	}{
		{
			name: "with spaces",
			content: `Agent,Country,URL,ExpectedStatus,ExpectedResult
Browser , US , http://example.com , 200 , No redirect`,
			expectError: false,
			expectCount: 1,
		},
		{
			name: "with quotes",
			content: `Agent,Country,URL,ExpectedStatus,ExpectedResult
"Browser","US","http://example.com",200,"No redirect"`,
			expectError: false,
			expectCount: 1,
		},
		{
			name: "missing columns",
			content: `Agent,Country,URL,ExpectedStatus,ExpectedResult
Browser,US,http://example.com`,
			expectError: true, // CSV parser will error on wrong number of fields
			expectCount: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			testFile := filepath.Join(tmpDir, tt.name+".csv")
			err := os.WriteFile(testFile, []byte(tt.content), 0644)
			if err != nil {
				t.Fatalf("Failed to create test file: %v", err)
			}

			results, err := parseLinkTestFile(testFile)
			if tt.expectError && err == nil {
				t.Error("Expected error, got nil")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if len(results) != tt.expectCount {
				t.Errorf("Expected %d results, got %d", tt.expectCount, len(results))
			}
		})
	}
}

// TestIntegrationCountryCodeNormalization tests country code handling
func TestIntegrationCountryCodeNormalization(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		country := r.Header.Get("X-Test-Country")
		// Verify country code is uppercase
		if country != "US" && country != "UK" && country != "DE" {
			t.Errorf("Country code not uppercase: %s", country)
		}
		w.WriteHeader(200)
	}))
	defer server.Close()

	// Test with lowercase country codes
	testURL(server.URL, "us", "")
	testURL(server.URL, "uk", "")
	testURL(server.URL, "de", "")
}
