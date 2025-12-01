# .htaccess Geo-Redirection Monitor

A real-time terminal UI application built with Go that monitors `.htaccess` file changes and automatically tests geo-redirection rules.

## Features

- Real-time monitoring of `.htaccess` file changes
- Automatic testing of geo-redirection rules for multiple countries
- Beautiful terminal UI with live updates
- Tests both regular users and Google Bot user agents
- Special case testing (WordPress admin, robots.txt, sitemap)
- Comprehensive test results with status indicators

## Installation

```bash
go mod tidy
go build -o htaccess-monitor main.go
```

## Usage

```bash
# Run the monitor
go run main.go

# Or use the built binary
./htaccess-monitor
```

## Links Watcher

The monitor can watch `links.testing` and `.htaccess` and automatically re-run link tests whenever either file changes.

### Run (from repo root)

```bash
make go-test-watch
```

### Run (direct)

```bash
cd apps/htaccess-monitor
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
  go run main.go -test ../../links.testing -watch
```

### Controls

- `f` – Toggle hide fails
- `h` – Toggle hide passes
- `q` – Quit

### CSV format (links.testing)

```
Agent, Country, URL, Expected status, Expected result
Browser, US, http://localhost:8080/ , 200, No redirect
Googlebot, UK, http://localhost:8080/ , 200, No redirect
Browser, FR, http://localhost:8080/uk , 301, http://localhost:8080/uk/
```

Notes:
- `Agent` supports `Browser` or `Googlebot`.
- UK is mapped internally to `GB` for the `X-Test-Country` header.
- On redirects (301/302), `Expected result` should be contained in the `Location` response header.

## Controls

- `r` - Run tests manually
- `q` - Quit application

## Dependencies

- github.com/charmbracelet/bubbletea
- github.com/charmbracelet/bubbles
- github.com/charmbracelet/lipgloss
- github.com/fsnotify/fsnotify