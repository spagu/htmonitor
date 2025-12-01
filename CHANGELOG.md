# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-09

## [v1.2.6] - 2025-09-09

### Added
- Release v1.2.6 with multi-platform binaries

## [v1.2.5] - 2025-09-09

### Added
- Release v1.2.5 with multi-platform binaries

## [v1.2.4] - 2025-09-09

### Added
- Release v1.2.4 with multi-platform binaries

## [v1.2.3] - 2025-09-09

### Added
- Release v1.2.3 with multi-platform binaries

## [v1.2.2] - 2025-09-09

### Added
- Release v1.2.2 with multi-platform binaries

## [v1.2.1] - 2025-09-09

### Added
- Release v1.2.1 with multi-platform binaries

## [v1.2.0] - 2025-09-09

### Added
- Release v1.2.0 with multi-platform binaries

### Added
- **Monorepo Structure**: Converted repository to proper monorepo format
- **Go Monitor Application**: Real-time terminal UI monitor with Bubble Tea framework
- **Workspace Configuration**: Added workspace.json for monorepo management
- **Comprehensive Documentation**: Individual README files for each application
- **Modular Architecture**: Separated applications, packages, tools, and documentation

### Changed
- **Repository Structure**: Reorganized into monorepo format with apps/, packages/, tools/, docs/
- **File Locations**: Moved files to appropriate monorepo directories
- **Makefile**: Updated build commands to work with new structure
- **Path References**: Updated all internal path references for monorepo structure
- **.gitignore**: Enhanced for monorepo with application-specific ignores

### Moved
- `main.go` → `apps/htaccess-monitor/main.go`
- `googlebot_spoof_tester.py` → `apps/python-tester/googlebot_spoof_tester.py`
- `Dockerfile` → `apps/docker-setup/Dockerfile`
- `.htaccess` → `.htaccess`
- `geoip-mock.php` → `apps/docker-setup/geoip-mock.php`
- Documentation → `docs/` directory

## [1.0.0] - 2024-01-08

### Added
- Initial release of Google Bot Spoofer & Website Availability Tester
- Multiple Google Bot user agent spoofing (desktop, mobile, image, news, video, ads)
- LiteSpeed server detection and cache header analysis
- Comprehensive robots.txt parsing and analysis
- UK geo-redirection testing based on .htaccess patterns
- JSON results export with detailed test data
- Response time monitoring and performance analysis
- Comprehensive logging to file and console
- Command-line interface with multiple options
- Specific tradik.com testing functionality
- Error handling and timeout management
- Request delay implementation for server-friendly testing

### Features
- **GoogleBotSpoofer Class**: Main testing utility with comprehensive bot spoofing
- **Robots.txt Analysis**: Parse disallow rules and sitemap URLs
- **LiteSpeed Detection**: Identify and analyze LiteSpeed-specific headers
- **Geo-redirection Testing**: Test UK-specific redirection patterns
- **Multi-bot Testing**: Support for all major Google Bot types
- **Performance Monitoring**: Response time and server performance analysis
- **Structured Output**: JSON format results with detailed metadata

### Security
- Authentic Google Bot user agents
- Respectful request delays
- Proper timeout handling
- Error boundary implementation

### Documentation
- Comprehensive README with usage examples
- Clean code principles implementation
- WCAG 2.2 compliance considerations
- MIT License inclusion
