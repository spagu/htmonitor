# Python Google Bot Spoofer & Website Tester

Comprehensive testing tools for geo-redirection and Google Bot spoofing capabilities.

## Features

- Multiple Google Bot user agents (desktop, mobile, image, news, video, ads)
- LiteSpeed server detection and cache analysis
- Robots.txt parsing and analysis
- UK geo-redirection testing
- JSON results export
- Comprehensive logging
- Country/language endpoint testing with fancy icons

## Files

- `googlebot_spoof_tester.py` - Main Python testing script
- `test_all_languages.sh` - Bash script for testing all country endpoints
- `requirements.txt` - Python dependencies

## Installation

```bash
pip install -r requirements.txt
```

## Usage

```bash
# Python script
python googlebot_spoof_tester.py

# Bash script with fancy output
./test_all_languages.sh
```

## Dependencies

- requests
- colorama
- urllib3