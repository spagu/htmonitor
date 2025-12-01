package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/fsnotify/fsnotify"
	"golang.org/x/term"
)

// Version information (injected during build)
var (
	Version   = "dev"
	BuildTime = "unknown"
)

// Country represents a test country with flag and name
type Country struct {
	Code string
	Flag string
	Name string
}

// TestResult represents the result of a single test
type TestResult struct {
	Country    Country
	Status     int
	StatusText string
	Result     string
}

// LinkTest represents a test case from CSV
type LinkTest struct {
	Agent          string
	Country        string
	URL            string
	ExpectedStatus int
	ExpectedResult string
}

// LinkTestResult represents the result of a link test
type LinkTestResult struct {
	Test    LinkTest
	Status  int
	Result  string
	Success bool
}

// TestSuite represents all test results
type TestSuite struct {
	HomeRegular    []TestResult
	HomeGoogleBot  []TestResult
	ContentRegular []TestResult
	ContentBot     []TestResult
	SpecialCases   []TestResult
	LastUpdate     time.Time
}

// SpecialCase represents a special test case
type SpecialCase struct {
	Name   string
	Status int
	Result string
}

// Countries list with UTF-8 flags
var countries = []Country{
	{"us", "", "United States"},
	{"uk", "", "United Kingdom"},
	{"au", "", "Australia"},
	{"at", "", "Austria"},
	{"ca", "", "Canada"},
	{"fr", "", "France"},
	{"de", "", "Germany"},
	{"ie", "", "Ireland"},
	{"it", "", "Italy"},
	{"ch", "", "Switzerland"},
	{"es", "", "Spain"},
	{"lu", "", "Luxembourg"},
	{"li", "", "Liechtenstein"},
	{"jp", "", "Japan"},
}

// Model represents the application state
type model struct {
	testSuite TestSuite
	tables    []table.Model
	ready     bool
	testing   bool
	width     int
	height    int
}

// Messages
type testCompleteMsg TestSuite
type fileChangedMsg string
type testStartMsg struct{}

// Styles
var (
	statusStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		MarginTop(1)
)

func initialModel() model {
	return model{
		testSuite: TestSuite{},
		tables:    make([]table.Model, 4),
		ready:     false,
		testing:   false,
		width:     120, // Initialize with default width
		height:    40,  // Initialize with default height
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		watchFile(),
		runTests(),
	)
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		if m.ready {
			m.tables = createTables(m.testSuite, m.width)
		}
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "r":
			m.testing = true
			return m, runTests()
		}

	case testStartMsg:
		m.testing = true
		return m, runTests()

	case testCompleteMsg:
		m.testSuite = TestSuite(msg)
		m.tables = createTables(m.testSuite, m.width)
		m.ready = true
		m.testing = false
		return m, watchFile() // Restart file watcher after tests complete

	case fileChangedMsg:
		m.testing = true
		return m, runTests()
	}

	return m, nil
}

func (m model) View() string {
	var sections []string

	// Always show header - plain text to ensure it displays
	now := time.Now()
	dateTime := now.Format("2006-01-02 15:04:05 MST")

	// Simple header that will definitely display
	headerLine := fmt.Sprintf("🖥️ .htaccess Geo-Redirection Mock Tester/Monitor 🌐                    %s", dateTime)
	sections = append(sections, headerLine)
	// sections = append(sections, strings.Repeat("=", 80))

	if !m.ready {
		sections = append(sections, "Initializing tests...")
		sections = append(sections, "Press 'q' to quit, 'r' to run tests manually")
		return lipgloss.JoinVertical(lipgloss.Left, sections...)
	}

	// Status
	status := ""
	if m.testing {
		status = statusStyle.Render(" Running tests...")
	} else {
		status = statusStyle.Render(fmt.Sprintf(" Last updated: %s", m.testSuite.LastUpdate.Format("15:04:05")))
	}
	sections = append(sections, status)

	// Tables in 2x3 grid (2 rows, 3 columns)
	if len(m.tables) >= 5 {
		// Section header for HOMEPAGE
		homepageHeader := lipgloss.NewStyle().
			Foreground(lipgloss.Color("15")).
			Background(lipgloss.Color("33")).
			Bold(true).
			Padding(0, 2).
			MarginBottom(0).
			Render(" Home Page: http://localhost:8080/")

		topRow := lipgloss.JoinHorizontal(lipgloss.Top,
			m.tables[0].View(),
			"  ",
			m.tables[1].View(),
		)

		// Section header for TEST CONTENT PAGE
		testContentHeader := lipgloss.NewStyle().
			Foreground(lipgloss.Color("15")).
			Background(lipgloss.Color("99")).
			Bold(true).
			Padding(0, 2).
			MarginBottom(0).
			Render(" Test Content Page: http://localhost:8080/test-content  ")

		middleRow := lipgloss.JoinHorizontal(lipgloss.Top,
			m.tables[2].View(),
			"  ",
			m.tables[3].View(),
		)

		// Section header for SPECIAL CASES
		specialCasesHeader := lipgloss.NewStyle().
			Foreground(lipgloss.Color("15")).
			Background(lipgloss.Color("129")).
			Bold(true).
			Padding(0, 2).
			MarginBottom(0).
			Render(" SPECIAL CASES")

		bottomRow := m.tables[4].View() // Special cases table

		grid := lipgloss.JoinVertical(lipgloss.Left,
			homepageHeader, topRow,
			testContentHeader, middleRow,
			specialCasesHeader, bottomRow)
		sections = append(sections, grid)
	}

	// Controls
	controls := statusStyle.Render("⌨️ Press 'r' to run tests manually, 'q' to quit")
	sections = append(sections, controls)
	// Branding footer - full width gray background with right-aligned text
	brandingText := "🏢 Tradik Limited / 2025 Commercial License"

	// Use terminal width or fallback
	footerWidth := m.width
	if footerWidth == 0 {
		footerWidth = 120
	}

	// Calculate padding to right-align text
	textLen := len(brandingText)
	leftPadding := footerWidth - textLen - 2 // Leave 2 chars margin from right edge
	if leftPadding < 0 {
		leftPadding = 0
	}

	brandingStyle := lipgloss.NewStyle().
		Background(lipgloss.Color("240")).
		Foreground(lipgloss.Color("15")).
		Width(footerWidth).
		PaddingLeft(leftPadding).
		MarginTop(1)

	branding := brandingStyle.Render(brandingText)
	sections = append(sections, branding)

	return lipgloss.JoinVertical(lipgloss.Left, sections...)
}

func createTables(ts TestSuite, terminalWidth int) []table.Model {
	tables := make([]table.Model, 5)

	// Calculate table width based on terminal size
	// Leave space for padding and borders
	availableWidth := terminalWidth - 10   // Account for margins and spacing
	tableWidth := (availableWidth - 4) / 2 // Two tables side by side with spacing

	// Minimum width to ensure readability
	if tableWidth < 60 {
		tableWidth = 60
	}

	// Table 1: Home Page - Regular Users
	tables[0] = createTable("🏠 Home Page - Regular Users\nURL: http://localhost:8080/", ts.HomeRegular, tableWidth)

	// Table 2: Home Page - Google Bot
	tables[1] = createTable("🤖 Home Page - Google Bot\nURL: http://localhost:8080/", ts.HomeGoogleBot, tableWidth)

	// Table 3: Test Content - Regular Users
	tables[2] = createTable("📄 Test Content - Regular Users\nURL: http://localhost:8080/test-content", ts.ContentRegular, tableWidth)

	// Table 4: Test Content - Google Bot
	tables[3] = createTable("🤖 Test Content - Google Bot\nURL: http://localhost:8080/test-content", ts.ContentBot, tableWidth)

	// Table 5: Special Cases (full width)
	tables[4] = createSpecialCasesTable(ts.SpecialCases, availableWidth)

	return tables
}

func createTable(title string, results []TestResult, tableWidth int) table.Model {
	// Calculate column widths based on table width
	countryWidth := 20
	statusWidth := 8
	resultWidth := tableWidth - countryWidth - statusWidth - 6 // Account for borders and padding

	// Ensure minimum widths
	if resultWidth < 30 {
		resultWidth = 30
	}

	columns := []table.Column{
		{Title: "Country", Width: countryWidth},
		{Title: "Status", Width: statusWidth},
		{Title: "Result", Width: resultWidth},
	}

	rows := make([]table.Row, 0, len(results))
	for _, result := range results {
		statusIcon := getStatusIcon(result.Status)
		rows = append(rows, table.Row{
			fmt.Sprintf("%s %s", result.Country.Flag, result.Country.Name),
			fmt.Sprintf("%s %d", statusIcon, result.Status),
			result.Result,
		})
	}

	t := table.New(
		table.WithColumns(columns),
		table.WithRows(rows),
		table.WithHeight(len(results)+2),
	)

	s := table.DefaultStyles()
	s.Header = s.Header.
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("240")).
		BorderBottom(true).
		Bold(false)
	s.Selected = s.Selected.
		Foreground(lipgloss.Color("229")).
		Background(lipgloss.Color("57")).
		Bold(false)
	t.SetStyles(s)

	return t
}

func createSpecialCasesTable(results []TestResult, tableWidth int) table.Model {
	// Calculate column widths for special cases table
	testCaseWidth := 25
	statusWidth := 8
	resultWidth := tableWidth - testCaseWidth - statusWidth - 6 // Account for borders and padding

	// Ensure minimum widths
	if resultWidth < 35 {
		resultWidth = 35
	}

	columns := []table.Column{
		{Title: "Test Case", Width: testCaseWidth},
		{Title: "Status", Width: statusWidth},
		{Title: "Result", Width: resultWidth},
	}

	rows := make([]table.Row, 0, len(results))
	for _, result := range results {
		statusIcon := getStatusIcon(result.Status)
		rows = append(rows, table.Row{
			result.Country.Name, // Using Name field for test case name
			fmt.Sprintf("%s %d", statusIcon, result.Status),
			result.Result,
		})
	}

	t := table.New(
		table.WithColumns(columns),
		table.WithRows(rows),
		table.WithHeight(len(results)+2),
	)

	s := table.DefaultStyles()
	s.Header = s.Header.
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("240")).
		BorderBottom(true).
		Bold(false)
	s.Selected = s.Selected.
		Foreground(lipgloss.Color("229")).
		Background(lipgloss.Color("57")).
		Bold(false)
	t.SetStyles(s)

	return t
}

func getStatusIcon(status int) string {
	switch status {
	case 200:
		return "✅"
	case 302:
		return "🔄"
	default:
		return "❌"
	}
}

func runTests() tea.Cmd {
	return func() tea.Msg {
		baseURL := "http://localhost:8080"
		googleBotUA := "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

		ts := TestSuite{
			LastUpdate: time.Now(),
		}

		// Test home page - regular users
		for _, country := range countries {
			result := testURL(baseURL+"/", country.Code, "")
			ts.HomeRegular = append(ts.HomeRegular, TestResult{
				Country:    country,
				Status:     result.Status,
				StatusText: result.StatusText,
				Result:     result.Result,
			})
		}

		// Test home page - Google Bot
		for _, country := range countries {
			result := testURL(baseURL+"/", country.Code, googleBotUA)
			ts.HomeGoogleBot = append(ts.HomeGoogleBot, TestResult{
				Country:    country,
				Status:     result.Status,
				StatusText: result.StatusText,
				Result:     result.Result,
			})
		}

		// Test content - regular users
		for _, country := range countries {
			result := testURL(baseURL+"/test-content", country.Code, "")
			ts.ContentRegular = append(ts.ContentRegular, TestResult{
				Country:    country,
				Status:     result.Status,
				StatusText: result.StatusText,
				Result:     result.Result,
			})
		}

		// Test content - Google Bot
		for _, country := range countries {
			result := testURL(baseURL+"/test-content", country.Code, googleBotUA)
			ts.ContentBot = append(ts.ContentBot, TestResult{
				Country:    country,
				Status:     result.Status,
				StatusText: result.StatusText,
				Result:     result.Result,
			})
		}

		// Test special cases
		specialCases := []struct {
			name    string
			url     string
			headers map[string]string
		}{
			{"No Country Set", baseURL + "/", map[string]string{}},
			{"Empty Country Code", baseURL + "/", map[string]string{"X-Test-Country": ""}},
			{"WordPress Admin", baseURL + "/wp-admin/", map[string]string{"X-Test-Country": "DE"}},
			{"Robots.txt", baseURL + "/robots.txt", map[string]string{"X-Test-Country": "DE"}},
			{"Sitemap", baseURL + "/sitemap_index.xml", map[string]string{"X-Test-Country": "DE"}},
		}

		for _, testCase := range specialCases {
			result := testSpecialURL(testCase.url, testCase.headers)
			ts.SpecialCases = append(ts.SpecialCases, TestResult{
				Country:    Country{Code: "", Flag: "", Name: testCase.name},
				Status:     result.Status,
				StatusText: result.StatusText,
				Result:     result.Result,
			})
		}

		return testCompleteMsg(ts)
	}
}

type HTTPResult struct {
	Status     int
	StatusText string
	Result     string
}

func testURL(url, countryCode, userAgent string) HTTPResult {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Timeout: 5 * time.Second,
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return HTTPResult{Status: 0, StatusText: "Error", Result: "Request failed"}
	}

	req.Header.Set("X-Test-Country", strings.ToUpper(countryCode))
	if userAgent != "" {
		req.Header.Set("User-Agent", userAgent)
	}

	resp, err := client.Do(req)
	if err != nil {
		return HTTPResult{Status: 0, StatusText: "Error", Result: "Connection failed"}
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			log.Printf("Error closing response body: %v", err)
		}
	}()

	result := "No redirect"
	switch resp.StatusCode {
	case 301, 302:
		if location := resp.Header.Get("Location"); location != "" {
			result = location
		}
	}

	return HTTPResult{
		Status:     resp.StatusCode,
		StatusText: resp.Status,
		Result:     result,
	}
}

func testSpecialURL(url string, headers map[string]string) HTTPResult {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Timeout: 5 * time.Second,
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return HTTPResult{Status: 0, StatusText: "Error", Result: "Request failed"}
	}

	// Set custom headers
	for key, value := range headers {
		req.Header.Set(key, value)
	}

	resp, err := client.Do(req)
	if err != nil {
		return HTTPResult{Status: 0, StatusText: "Error", Result: "Connection failed"}
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			log.Printf("Error closing response body: %v", err)
		}
	}()

	result := "No redirect"
	switch resp.StatusCode {
	case 301, 302:
		if location := resp.Header.Get("Location"); location != "" {
			result = location
		}
	case 200:
		if strings.Contains(url, "wp-admin") {
			result = "No redirect (protected)"
		} else if strings.Contains(url, "robots.txt") {
			result = "No redirect (SEO protected)"
		} else if strings.Contains(url, "sitemap") {
			result = "No redirect (SEO protected)"
		}
	}

	return HTTPResult{
		Status:     resp.StatusCode,
		StatusText: resp.Status,
		Result:     result,
	}
}

func watchFile() tea.Cmd {
	return func() tea.Msg {
		watcher, err := fsnotify.NewWatcher()
		if err != nil {
			return fmt.Errorf("failed to create watcher: %w", err)
		}
		defer func() {
			if err := watcher.Close(); err != nil {
				log.Printf("Error closing watcher: %v", err)
			}
		}()

		// Add .htaccess file to watcher (now in packages/shared)
		htaccessPath := "../../.htaccess"
		if err := watcher.Add(htaccessPath); err != nil {
			return fmt.Errorf("failed to watch .htaccess: %w", err)
		}

		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return nil
				}

				// Check if the event is for .htaccess file
				if filepath.Base(event.Name) == ".htaccess" {
					// Trigger on Write, Create, or Rename events
					if event.Op&fsnotify.Write == fsnotify.Write ||
						event.Op&fsnotify.Create == fsnotify.Create ||
						event.Op&fsnotify.Rename == fsnotify.Rename {
						return fileChangedMsg(event.Name)
					}
				}

			case err, ok := <-watcher.Errors:
				if !ok {
					return nil
				}
				log.Printf("Watcher error: %v", err)
			}
		}
	}
}

// parseLinkTestFile reads and parses the links.testing CSV file
func parseLinkTestFile(filename string) ([]LinkTest, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer func() {
		if err := file.Close(); err != nil {
			log.Printf("Error closing file: %v", err)
		}
	}()

	reader := csv.NewReader(file)
	reader.TrimLeadingSpace = true

	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	var tests []LinkTest
	// Skip header row
	for i, record := range records {
		if i == 0 || len(record) < 5 {
			continue
		}

		// Parse expected status
		expectedStatus, err := strconv.Atoi(strings.TrimSpace(record[3]))
		if err != nil {
			expectedStatus = 200 // default
		}

		test := LinkTest{
			Agent:          strings.TrimSpace(record[0]),
			Country:        strings.TrimSpace(record[1]),
			URL:            strings.TrimSpace(record[2]),
			ExpectedStatus: expectedStatus,
			ExpectedResult: strings.TrimSpace(record[4]),
		}
		tests = append(tests, test)
	}

	return tests, nil
}

// runLinkTests executes tests from links.testing file
func runLinkTests(tests []LinkTest) []LinkTestResult {
	var results []LinkTestResult

	for _, test := range tests {
		var userAgent string
		if strings.ToLower(test.Agent) == "googlebot" {
			userAgent = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
		}

		// Set country header
		countryCode := strings.ToUpper(test.Country)
		if countryCode == "UK" {
			countryCode = "GB"
		}

		httpResult := testURL(test.URL, countryCode, userAgent)

		// Check if result matches expectations - status code is primary indicator
		success := true
		if httpResult.Status != test.ExpectedStatus {
			success = false
		} else {
			// If status matches, check result only for additional validation
			if test.ExpectedResult != "No redirect" && !strings.Contains(httpResult.Result, test.ExpectedResult) {
				// Only fail if status is redirect but result doesn't match expected redirect
				if httpResult.Status == 301 || httpResult.Status == 302 {
					success = false
				}
			}
			if test.ExpectedResult == "No redirect" && httpResult.Result != "No redirect" {
				// Only fail if we expected no redirect but got one with wrong status
				if httpResult.Status != test.ExpectedStatus {
					success = false
				}
			}
		}

		result := LinkTestResult{
			Test:    test,
			Status:  httpResult.Status,
			Result:  httpResult.Result,
			Success: success,
		}
		results = append(results, result)
	}

	return results
}

// FilterState represents the current filtering options
type FilterState struct {
	hideFails  bool
	hidePasses bool
}

// applyFilters returns filtered results based on current filter state
func applyFilters(results []LinkTestResult, filter FilterState) []LinkTestResult {
	if !filter.hideFails && !filter.hidePasses {
		return results // No filtering
	}

	var filtered []LinkTestResult
	for _, result := range results {
		if filter.hideFails && !result.Success {
			continue // Skip failed tests
		}
		if filter.hidePasses && result.Success {
			continue // Skip passed tests
		}
		filtered = append(filtered, result)
	}
	return filtered
}

// displayLinkTestResults shows results with pagination and filtering support
func displayLinkTestResults(results []LinkTestResult) {
	const maxResultsPerPage = 15 // Maximum results to show at once
	filter := FilterState{}      // Start with no filters

	for {
		// Apply current filters
		filteredResults := applyFilters(results, filter)

		if len(filteredResults) <= maxResultsPerPage {
			// Show all results if small enough
			displayResultsPageWithFilter(filteredResults, 0, len(filteredResults), 1, 1, filter, len(results))
		} else {
			// Paginated display for large result sets
			totalPages := (len(filteredResults) + maxResultsPerPage - 1) / maxResultsPerPage
			currentPage := 0

			for {
				start := currentPage * maxResultsPerPage
				end := start + maxResultsPerPage
				if end > len(filteredResults) {
					end = len(filteredResults)
				}

				displayResultsPageWithFilter(filteredResults, start, end, currentPage+1, totalPages, filter, len(results))

				if totalPages == 1 {
					break
				}

				// Show navigation options
				fmt.Printf("\n Page %d/%d - Navigation: [n]ext, [p]revious, [f]ilter fails, [h]ide passes, [q]uit, [Ctrl+C] stop\n",
					currentPage+1, totalPages)

				// Read single keypress
				key, err := readSingleKey()
				if err != nil {
					continue
				}

				switch key {
				case 'n', 'N':
					if currentPage < totalPages-1 {
						currentPage++
					}
				case 'p', 'P':
					if currentPage > 0 {
						currentPage--
					}
				case 'f', 'F':
					filter.hideFails = !filter.hideFails
					return // Exit pagination loop to refresh with new filter
				case 'h', 'H':
					filter.hidePasses = !filter.hidePasses
					return // Exit pagination loop to refresh with new filter
				case 'q', 'Q', 27, 3: // 27 is ESC, 3 is Ctrl+C
					fmt.Print("\033[?25h") // Show cursor before exit
					return
				default:
					// Any other key shows current page again
				}
			}
		}

		// Wait for keypress (controls shown in footer)
		key, err := readSingleKey()
		if err != nil {
			continue
		}

		switch key {
		case 'f', 'F':
			filter.hideFails = !filter.hideFails
		case 'h', 'H':
			filter.hidePasses = !filter.hidePasses
		case 'q', 'Q', 27, 3: // q, Q, ESC, Ctrl+C
			fmt.Print("\033[?25h") // Show cursor before exit
			return
		default:
			// Any other key refreshes display
		}

		// Continue loop to refresh display with new filter
	}
}

// Global terminal width cache
var cachedTermWidth int

// getTerminalWidth returns the terminal width, caching it for consistency
func getTerminalWidth() int {

	if cachedTermWidth == 0 {
		width, _, err := term.GetSize(int(os.Stdout.Fd()))
		if err != nil {
			cachedTermWidth = 180 // default width
		} else {
			cachedTermWidth = width
		}
	}
	return cachedTermWidth
}

// refreshTerminalWidth forces a recalculation of terminal width
func refreshTerminalWidth() {
	cachedTermWidth = 0
}

// readSingleKey reads a single keypress without requiring Enter
func readSingleKey() (byte, error) {
	// Save current terminal state
	oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
	if err != nil {
		return 0, err
	}
	defer func() {
		if err := term.Restore(int(os.Stdin.Fd()), oldState); err != nil {
			log.Printf("Error restoring terminal: %v", err)
		}
	}()

	// Read single byte
	buf := make([]byte, 1)
	_, err = os.Stdin.Read(buf)
	if err != nil {
		return 0, err
	}

	return buf[0], nil
}

// displayResultsPageWithFilter shows a specific page of results with filter information
func displayResultsPageWithFilter(results []LinkTestResult, start, end, currentPage, totalPages int, filter FilterState, totalOriginal int) {
	displayResultsPageCore(results, start, end, currentPage, totalPages, filter, totalOriginal)
}

// displayResultsPageCore contains the core display logic
func displayResultsPageCore(results []LinkTestResult, start, end, currentPage, totalPages int, filter FilterState, totalOriginal int) {
	// Clear screen and reset cursor position
	fmt.Print("\033[2J\033[H\033[0m")
	// Ensure we're at the top and flush output
	fmt.Print("\033[1;1H")
	if err := os.Stdout.Sync(); err != nil {
		log.Printf("Error syncing stdout: %v", err)
	}

	// Refresh terminal width on each display to handle resizing
	refreshTerminalWidth()
	termWidth := max(80, getTerminalWidth())
	//termWidth := 400
	// Header with full width
	now := time.Now()
	dateTime := now.Format("2006-01-02 15:04:05 MST")
	title := ".htaccess Geo-Redirection Link Tester"

	// Create full-width header
	spacing := termWidth - len(title) - len(dateTime)
	if spacing < 1 {
		spacing = 1
	}
	headerLine := fmt.Sprintf("%s%s%s", title, strings.Repeat(" ", spacing), dateTime)
	fmt.Println(headerLine)
	fmt.Print("\r")
	fmt.Println(strings.Repeat("═", termWidth))
	fmt.Print("\r")

	// Status line with pagination and filter info
	//filterInfo := ""

	//if filter.hideFails && filter.hidePasses {
	//	filterInfo = " (All filtered)"
	//} else if filter.hideFails {
	//	filterInfo = " (Fails hidden)"
	//} else if filter.hidePasses {
	//	filterInfo = " (Passes hidden)"
	//}

	//if totalPages > 1 {
	//	fmt.Printf(" Link Testing Mode - %d/%d test cases%s (Page %d/%d)\n\n", len(results), totalOriginal, filterInfo, currentPage, totalPages)
	//} else {
	//	fmt.Printf(" Link Testing Mode - %d/%d test cases executed%s\n\n", len(results), totalOriginal, filterInfo)
	//}

	// Controls info before table
	//fmt.Println("  Watching for changes... (Press Ctrl+C to stop)")
	//fmt.Println()

	// Create styled table with colors and icons
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FFFFFF")).
		Background(lipgloss.Color("#7C3AED")).
		Bold(true).
		Padding(0, 1)

	fmt.Println(headerStyle.Render(" 🧪 TEST RESULTS 🧪 "))
	fmt.Print("\r")

	fmt.Println(strings.Repeat("─", termWidth))
	fmt.Print("\r")

	// Create colorful table headers with icons
	agentHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#FF6B6B")).Bold(true).Render("   Agent")
	countryHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#4ECDC4")).Bold(true).Render("Country")
	urlHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#45B7D1")).Bold(true).Render("URL")
	expectedHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#96CEB4")).Bold(true).Render("Expected")
	actualHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#FFEAA7")).Bold(true).Render(" Actual")
	resultHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#DDA0DD")).Bold(true).Render("Result")
	expectedResultHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#98D8C8")).Bold(true).Render("Expected Result")
	statusHeader := lipgloss.NewStyle().Foreground(lipgloss.Color("#F7DC6F")).Bold(true).Render("Status")

	fmt.Printf("%-29s %-23s %-56s %-24s %-26s %-56s %-56s %-11s\n",
		agentHeader, countryHeader, urlHeader, expectedHeader, actualHeader, resultHeader, expectedResultHeader, statusHeader)
	fmt.Print("\r")
	fmt.Println(strings.Repeat("─", termWidth))
	fmt.Print("\r")

	totalSuccessCount := 0

	// Count total successes for summary
	for _, result := range results {
		if result.Success {
			totalSuccessCount++
		}
	}

	// Display current page results
	for i := start; i < end; i++ {
		result := results[i]

		// Colorful status with styling and icons
		var statusText string
		if result.Success {
			statusText = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00FF00")).
				Bold(true).
				Render("✅ PASS")
		} else {
			statusText = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#FF0000")).
				Bold(true).
				Render("❌ FAIL")
		}

		// Add icons for different agents
		var agentIcon string
		if strings.Contains(strings.ToLower(result.Test.Agent), "googlebot") {
			agentIcon = "🤖"
		} else if strings.Contains(strings.ToLower(result.Test.Agent), "browser") {
			agentIcon = "🌐"
		} else {
			agentIcon = "🔍"
		}

		// Color code the agent with icon
		agentStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#FF6B6B")).Render(agentIcon + " " + result.Test.Agent)

		// Color code the country with flag
		countryStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#4ECDC4")).Render(result.Test.Country)

		// Color code the URL with link icon
		url := result.Test.URL
		if len(url) > 35 {
			url = url[:32] + "..."
		}
		urlStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#45B7D1")).Render(url)

		// Color code status codes with icons
		var expectedIcon, actualIcon string
		if result.Test.ExpectedStatus >= 200 && result.Test.ExpectedStatus < 300 {
			expectedIcon = "✅"
		} else if result.Test.ExpectedStatus >= 300 && result.Test.ExpectedStatus < 400 {
			expectedIcon = "🔄"
		} else if result.Test.ExpectedStatus >= 400 {
			expectedIcon = "❌"
		}

		if result.Status >= 200 && result.Status < 300 {
			actualIcon = "✅"
		} else if result.Status >= 300 && result.Status < 400 {
			actualIcon = "🔄"
		} else if result.Status >= 400 {
			actualIcon = "❌"
		}

		expectedStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#96CEB4")).Render(expectedIcon + " " + fmt.Sprintf("%d", result.Test.ExpectedStatus))
		actualStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#FFEAA7")).Render(actualIcon + " " + fmt.Sprintf("%d", result.Status))

		resultText := result.Result
		if len(resultText) > 42 {
			resultText = resultText[:38] + "..."
		}
		resultStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#DDA0DD")).Render(resultText)
		expectedResult := result.Test.ExpectedResult
		if len(expectedResult) > 42 {
			expectedResult = expectedResult[:38] + "..."
		}
		expectedResultStyled := lipgloss.NewStyle().Foreground(lipgloss.Color("#98D8C8")).Render(expectedResult)

		// Use proper padding for visual alignment
		fmt.Printf("%s %s %s %s %s %s %s %s\n",
			padToWidth(agentStyled, 12),
			padToWidth(countryStyled, 7),
			padToWidth(urlStyled, 40),
			padToWidth(expectedStyled, 8),
			padToWidth(actualStyled, 9),
			padToWidth(resultStyled, 39),
			padToWidth(expectedResultStyled, 39),
			statusText)
		fmt.Print("\r")

	}

	fmt.Print("\r")
	fmt.Println(strings.Repeat("─", termWidth))
	fmt.Print("\r")

	// Summary with status styling (show total, not just current page)
	successRate := float64(totalSuccessCount) / float64(len(results)) * 100
	fmt.Printf("📊 Summary: %d/%d tests passed (%.1f%%)\n", totalSuccessCount, len(results), successRate)
	fmt.Print("\r")

	if totalSuccessCount == len(results) {
		fmt.Println("✅ All tests passed!")
		fmt.Print("\r")

	} else {
		fmt.Printf("⚠️  %d tests failed\n", len(results)-totalSuccessCount)
		fmt.Print("\r")
	}

	fmt.Println()
	fmt.Print("\r")

	// Filter legend and controls (above footer)
	legendText := "Controls: [f] Toggle hide fails | [h] Toggle hide passes | [q] Quit"
	if filter.hideFails || filter.hidePasses {
		statusText := ""
		if filter.hideFails && filter.hidePasses {
			statusText = " | Status: All filtered"
		} else if filter.hideFails {
			statusText = " | Status: Fails hidden"
		} else if filter.hidePasses {
			statusText = " | Status: Passes hidden"
		}
		legendText += statusText
	}
	fmt.Printf(" %s\n\n", legendText)
	fmt.Print("\r")

	// Full-width footer with same styling as main version
	footerText := "Tradik Limited / 2025 Commercial License"
	textLen := len(footerText)
	leftPadding := termWidth - textLen - 2 // Leave 2 chars margin from right edge
	if leftPadding < 0 {
		leftPadding = 0
	}

	// Create footer with gray background and white text to match main version
	footer := strings.Repeat(" ", leftPadding) + footerText + "  "
	if len(footer) < termWidth {
		footer += strings.Repeat(" ", termWidth-len(footer))
	}

	fmt.Printf("\033[48;5;240m\033[38;5;15m%s\033[0m\n", footer)
	fmt.Print("\r")
	// Hide cursor and ensure output is flushed
	fmt.Print("\033[?25l")
	if err := os.Stdout.Sync(); err != nil {
		log.Printf("Error syncing stdout: %v", err)
	}
}

// watchFilesAndRetest monitors files for changes and re-runs tests
func watchFilesAndRetest(testFile string) {
	fmt.Printf("👁️  Watching files for changes: %s, .htaccess\n", testFile)
	fmt.Println("Press Ctrl+C to stop watching")

	// Initial test run
	runTestsOnce(testFile)

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		fmt.Printf("❌ Failed to create watcher: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		if err := watcher.Close(); err != nil {
			log.Printf("Error closing watcher: %v", err)
		}
	}()

	// Add files to watch
	if err := watcher.Add(testFile); err != nil {
		fmt.Printf("❌ Failed to watch test file %s: %v\n", testFile, err)
		os.Exit(1)
	}

	htaccessPath := "../../.htaccess"
	if err := watcher.Add(htaccessPath); err != nil {
		fmt.Printf("❌ Failed to watch .htaccess file %s: %v\n", htaccessPath, err)
		os.Exit(1)
	}

	// Create channels for communication
	quit := make(chan bool)
	// Initialize global filter
	globalFilter = FilterState{}

	// Handle keyboard input in separate goroutine
	go func() {
		for {
			key, err := readSingleKey()
			if err != nil {
				select {
				case <-quit:
					return
				default:
					continue
				}
			}

			switch key {
			case 'f', 'F':
				globalFilter.hideFails = !globalFilter.hideFails
				runTestsOnce(testFile)
			case 'h', 'H':
				globalFilter.hidePasses = !globalFilter.hidePasses
				runTestsOnce(testFile)
			case 'q', 'Q', 27, 3: // q, Q, ESC, Ctrl+C
				fmt.Print("\033[?25h") // Show cursor before exit
				quit <- true
				return
			}
		}
	}()

	for {
		select {
		case event, ok := <-watcher.Events:
			if !ok {
				return
			}

			// Check for write events
			if event.Op&fsnotify.Write == fsnotify.Write ||
				event.Op&fsnotify.Create == fsnotify.Create ||
				event.Op&fsnotify.Rename == fsnotify.Rename {

				// Small delay to ensure file write is complete
				time.Sleep(500 * time.Millisecond)
				runTestsOnce(testFile)
			}

		case err, ok := <-watcher.Errors:
			if !ok {
				return
			}
			fmt.Printf("❌ Watcher error: %v\n", err)
		case <-quit:
			return
		}
	}
}

// runTestsOnce executes a single test run
func runTestsOnce(testFile string) {
	tests, err := parseLinkTestFile(testFile)
	if err != nil {
		fmt.Printf("❌ Error reading test file: %v\n", err)
		return
	}

	if len(tests) == 0 {
		fmt.Println("⚠️  No tests found in file")
		return
	}

	results := runLinkTests(tests)
	displayLinkTestResultsWatch(results)
}

// Global filter state to persist across refreshes
var globalFilter FilterState

// displayLinkTestResultsWatch shows results in watch mode (non-blocking)
func displayLinkTestResultsWatch(results []LinkTestResult) {
	filteredResults := applyFilters(results, globalFilter)
	displayResultsPageWithFilter(filteredResults, 0, len(filteredResults), 1, 1, globalFilter, len(results))
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func stripAnsiCodes(s string) string {
	ansiRegex := regexp.MustCompile(`\x1b\[[0-9;]*m`)
	return ansiRegex.ReplaceAllString(s, "")
}

func visualWidth(s string) int {
	// First strip ANSI codes
	clean := stripAnsiCodes(s)
	width := 0
	for _, r := range clean {
		// Count emojis and wide characters as 2 width
		if utf8.RuneLen(r) >= 3 {
			width += 2
		} else {
			width += 1
		}
	}
	return width
}

func padToWidth(s string, targetWidth int) string {
	currentWidth := visualWidth(s)
	if currentWidth >= targetWidth {
		return s
	}
	padding := targetWidth - currentWidth
	return s + strings.Repeat(" ", padding)
}

func main() {
	// Parse command line flags
	var testFile = flag.String("test", "", "Run tests from links.testing file")
	var watch = flag.Bool("watch", false, "Watch files for changes and re-run tests")
	var version = flag.Bool("version", false, "Show version information")
	flag.Parse()

	if *version {
		fmt.Printf("Version: %s\n", Version)
		fmt.Printf("Build Time: %s\n", BuildTime)
		return
	}

	// Check if we should run link tests
	if *testFile != "" {
		if *watch {
			// Watch mode - monitor files for changes
			watchFilesAndRetest(*testFile)
		} else {
			// Single run mode
			fmt.Printf("🔍 Running link tests from: %s\n", *testFile)

			tests, err := parseLinkTestFile(*testFile)
			if err != nil {
				fmt.Printf("❌ Error reading test file: %v\n", err)
				os.Exit(1)
			}

			if len(tests) == 0 {
				fmt.Println("⚠️  No tests found in file")
				os.Exit(1)
			}

			fmt.Printf("📋 Found %d test cases\n", len(tests))
			results := runLinkTests(tests)
			displayLinkTestResults(results)
		}
		return
	}

	// Default behavior - run interactive monitor
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error running program: %v", err)
		os.Exit(1)
	}
}
