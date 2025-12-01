#!/bin/bash

# Google Bot Language Testing Script for tradik.com
# Tests all country/language endpoints with fancy icons and formatting

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Google Bot User Agent
USER_AGENT="Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

# Base URL
BASE_URL="https://tradik.com"

# Country/Language mappings with flags and names
declare -A COUNTRIES
COUNTRIES[us]="🇺🇸 United States"
COUNTRIES[uk]="🇬🇧 United Kingdom"
COUNTRIES[au]="🇦🇺 Australia"
COUNTRIES[at]="🇦🇹 Austria"
COUNTRIES[ca]="🇨🇦 Canada"
COUNTRIES[fr]="🇫🇷 France"
COUNTRIES[de]="🇩🇪 Germany"
COUNTRIES[ie]="🇮🇪 Ireland"
COUNTRIES[it]="🇮🇹 Italy"
COUNTRIES[ch]="🇨🇭 Switzerland"
COUNTRIES[es]="🇪🇸 Spain"
COUNTRIES[lu]="🇱🇺 Luxembourg"
COUNTRIES[li]="🇱🇮 Liechtenstein"
COUNTRIES[ch-fr]="🇨🇭 Switzerland (French)"
COUNTRIES[ch-it]="🇨🇭 Switzerland (Italian)"
COUNTRIES[ca-fr]="🇨🇦 Canada (French)"

# Arrays to store results for table
declare -a TABLE_COUNTRIES
declare -a TABLE_URLS
declare -a TABLE_STATUS
declare -a TABLE_TIME
declare -a TABLE_SERVER
declare -a TABLE_CACHE

# Function to print header
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                    🤖 Google Bot Language Tester 🌍                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}                        Testing tradik.com endpoints                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to print section header
print_section() {
    local title="$1"
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${WHITE} $title${BLUE}$(printf "%*s" $((75 - ${#title})) "")│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Function to test URL
test_url() {
    local url="$1"
    local country_code="$2"
    local country_name="$3"
    
    echo -e "${CYAN}🔍 Testing:${NC} ${WHITE}$url${NC}"
    echo -e "${YELLOW}📍 Target:${NC} $country_name"
    
    # Perform curl request
    response=$(curl -I -s -w "HTTPSTATUS:%{http_code};TIME:%{time_total};SIZE:%{size_download};REDIRECT:%{redirect_url}" \
                   -A "$USER_AGENT" \
                   --max-time 30 \
                   "$url")
    
    # Extract information
    http_status=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    time_total=$(echo "$response" | grep -o "TIME:[0-9.]*" | cut -d: -f2)
    redirect_url=$(echo "$response" | grep -o "REDIRECT:.*" | cut -d: -f2-)
    
    # Get headers
    server=$(echo "$response" | grep -i "^server:" | cut -d: -f2- | tr -d '\r\n' | sed 's/^ *//')
    cache_control=$(echo "$response" | grep -i "^cache-control:" | cut -d: -f2- | tr -d '\r\n' | sed 's/^ *//')
    litespeed_cache=$(echo "$response" | grep -i "^x-litespeed-cache:" | cut -d: -f2- | tr -d '\r\n' | sed 's/^ *//')
    content_type=$(echo "$response" | grep -i "^content-type:" | cut -d: -f2- | tr -d '\r\n' | sed 's/^ *//')
    
    # Store results for table
    TABLE_COUNTRIES+=("$country_name")
    TABLE_URLS+=("$url")
    TABLE_STATUS+=("$http_status")
    TABLE_TIME+=("${time_total}s")
    TABLE_SERVER+=("${server:-N/A}")
    TABLE_CACHE+=("${litespeed_cache:-N/A}")
    
    # Status icon and color
    if [[ "$http_status" =~ ^2[0-9][0-9]$ ]]; then
        status_icon="✅"
        status_color="$GREEN"
    elif [[ "$http_status" =~ ^3[0-9][0-9]$ ]]; then
        status_icon="🔄"
        status_color="$YELLOW"
    elif [[ "$http_status" =~ ^4[0-9][0-9]$ ]]; then
        status_icon="❌"
        status_color="$RED"
    elif [[ "$http_status" =~ ^5[0-9][0-9]$ ]]; then
        status_icon="💥"
        status_color="$RED"
    else
        status_icon="❓"
        status_color="$WHITE"
    fi
    
    # Print results
    echo -e "${status_color}${status_icon} Status:${NC} ${status_color}$http_status${NC}"
    echo -e "${PURPLE}⏱️  Time:${NC} ${time_total}s"
    
    if [[ -n "$server" ]]; then
        if [[ "$server" =~ [Ll]ite[Ss]peed ]]; then
            echo -e "${GREEN}🚀 Server:${NC} $server ${GREEN}(LiteSpeed Detected!)${NC}"
        else
            echo -e "${BLUE}🖥️  Server:${NC} $server"
        fi
    fi
    
    if [[ -n "$litespeed_cache" ]]; then
        echo -e "${GREEN}💾 LiteSpeed Cache:${NC} $litespeed_cache"
    fi
    
    if [[ -n "$cache_control" ]]; then
        echo -e "${CYAN}🗂️  Cache Control:${NC} $cache_control"
    fi
    
    if [[ -n "$content_type" ]]; then
        echo -e "${YELLOW}📄 Content Type:${NC} $content_type"
    fi
    
    if [[ -n "$redirect_url" && "$redirect_url" != "" ]]; then
        echo -e "${PURPLE}🔀 Redirect:${NC} $redirect_url"
    fi
    
    echo ""
}

# Function to test robots.txt
test_robots() {
    local url="$BASE_URL/robots.txt"
    
    print_section "🤖 Testing robots.txt"
    echo -e "${CYAN}🔍 Testing:${NC} ${WHITE}$url${NC}"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code};TIME:%{time_total}" \
                   -A "$USER_AGENT" \
                   --max-time 30 \
                   "$url")
    
    http_status=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    time_total=$(echo "$response" | grep -o "TIME:[0-9.]*" | cut -d: -f2)
    content=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*;TIME:[0-9.]*$//')
    
    if [[ "$http_status" == "200" ]]; then
        echo -e "${GREEN}✅ Status:${NC} ${GREEN}$http_status${NC}"
        echo -e "${PURPLE}⏱️  Time:${NC} ${time_total}s"
        echo -e "${BLUE}📝 Content Preview:${NC}"
        echo "$content" | head -10 | sed 's/^/   /'
        if [[ $(echo "$content" | wc -l) -gt 10 ]]; then
            echo -e "   ${YELLOW}... (truncated)${NC}"
        fi
    else
        echo -e "${RED}❌ Status:${NC} ${RED}$http_status${NC}"
        echo -e "${PURPLE}⏱️  Time:${NC} ${time_total}s"
    fi
    echo ""
}

# Function to test main domain
test_main_domain() {
    print_section "🏠 Testing Main Domain"
    test_url "$BASE_URL/" "main" "🌐 Main Domain"
}

# Function to print results table
print_results_table() {
    print_section "📊 Results Summary Table"
    
    # Table header
    echo -e "${WHITE}┌─────────────────────────────────┬─────────────────────────────────┬────────┬────────┬─────────────┬─────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}             Country             ${WHITE}│${YELLOW}              URL               ${WHITE}│${GREEN} Status ${WHITE}│${PURPLE}  Time  ${WHITE}│${BLUE}   Server    ${WHITE}│${GREEN}    Cache    ${WHITE}│${NC}"
    echo -e "${WHITE}├─────────────────────────────────┼─────────────────────────────────┼────────┼────────┼─────────────┼─────────────┤${NC}"
    
    # Table rows
    for i in "${!TABLE_COUNTRIES[@]}"; do
        local country="${TABLE_COUNTRIES[$i]}"
        local url="${TABLE_URLS[$i]}"
        local status="${TABLE_STATUS[$i]}"
        local time="${TABLE_TIME[$i]}"
        local server="${TABLE_SERVER[$i]}"
        local cache="${TABLE_CACHE[$i]}"
        
        # Truncate long values for table formatting
        country=$(printf "%-31s" "${country:0:31}")
        url_short=$(printf "%-31s" "${url:0:31}")
        status=$(printf "%-6s" "$status")
        time=$(printf "%-6s" "$time")
        server_short=$(printf "%-11s" "${server:0:11}")
        cache_short=$(printf "%-11s" "${cache:0:11}")
        
        # Color code status
        if [[ "${TABLE_STATUS[$i]}" =~ ^2[0-9][0-9]$ ]]; then
            status_colored="${GREEN}$status${NC}"
        elif [[ "${TABLE_STATUS[$i]}" =~ ^3[0-9][0-9]$ ]]; then
            status_colored="${YELLOW}$status${NC}"
        elif [[ "${TABLE_STATUS[$i]}" =~ ^4[0-9][0-9]$ ]]; then
            status_colored="${RED}$status${NC}"
        elif [[ "${TABLE_STATUS[$i]}" =~ ^5[0-9][0-9]$ ]]; then
            status_colored="${RED}$status${NC}"
        else
            status_colored="${WHITE}$status${NC}"
        fi
        
        # Color code server (highlight LiteSpeed)
        if [[ "$server" =~ [Ll]ite[Ss]peed ]]; then
            server_colored="${GREEN}$server_short${NC}"
        else
            server_colored="${BLUE}$server_short${NC}"
        fi
        
        # Color code cache
        if [[ "$cache" != "N/A" ]]; then
            cache_colored="${GREEN}$cache_short${NC}"
        else
            cache_colored="${WHITE}$cache_short${NC}"
        fi
        
        echo -e "${WHITE}│${NC}$country${WHITE}│${NC}$url_short${WHITE}│${NC}$status_colored${WHITE}│${PURPLE}$time${WHITE}│${NC}$server_colored${WHITE}│${NC}$cache_colored${WHITE}│${NC}"
    done
    
    # Table footer
    echo -e "${WHITE}└─────────────────────────────────┴─────────────────────────────────┴────────┴────────┴─────────────┴─────────────┘${NC}"
    echo ""
    
    # Statistics
    local total_tests=${#TABLE_STATUS[@]}
    local success_count=0
    local redirect_count=0
    local error_count=0
    local litespeed_count=0
    
    for status in "${TABLE_STATUS[@]}"; do
        if [[ "$status" =~ ^2[0-9][0-9]$ ]]; then
            ((success_count++))
        elif [[ "$status" =~ ^3[0-9][0-9]$ ]]; then
            ((redirect_count++))
        else
            ((error_count++))
        fi
    done
    
    for server in "${TABLE_SERVER[@]}"; do
        if [[ "$server" =~ [Ll]ite[Ss]peed ]]; then
            ((litespeed_count++))
        fi
    done
    
    echo -e "${CYAN}📈 Statistics:${NC}"
    echo -e "   ${GREEN}✅ Success (2xx):${NC} $success_count/$total_tests"
    echo -e "   ${YELLOW}🔄 Redirects (3xx):${NC} $redirect_count/$total_tests"
    echo -e "   ${RED}❌ Errors (4xx/5xx):${NC} $error_count/$total_tests"
    echo -e "   ${GREEN}🚀 LiteSpeed Detected:${NC} $litespeed_count/$total_tests"
    echo ""
}

# Function to test all country endpoints
test_all_countries() {
    print_section "🌍 Testing All Country/Language Endpoints"
    
    for country_code in "${!COUNTRIES[@]}"; do
        country_name="${COUNTRIES[$country_code]}"
        url="$BASE_URL/$country_code/"
        test_url "$url" "$country_code" "$country_name"
        sleep 1  # Be respectful to the server
    done
}

# Function to print summary
print_summary() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                              📊 Test Summary                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}✅ Test completed for ${#COUNTRIES[@]} country endpoints + main domain + robots.txt${NC}"
    echo -e "${BLUE}🤖 User Agent: $USER_AGENT${NC}"
    echo -e "${YELLOW}📅 Test Date: $(date)${NC}"
    echo -e "${CYAN}🌐 Target: $BASE_URL${NC}"
    echo ""
    echo -e "${WHITE}💡 Tips:${NC}"
    echo -e "   • ${GREEN}✅${NC} = Success (2xx status)"
    echo -e "   • ${YELLOW}🔄${NC} = Redirect (3xx status)"
    echo -e "   • ${RED}❌${NC} = Client Error (4xx status)"
    echo -e "   • ${RED}💥${NC} = Server Error (5xx status)"
    echo -e "   • ${GREEN}🚀${NC} = LiteSpeed server detected"
    echo ""
}

# Main execution
main() {
    clear
    print_header
    
    echo -e "${WHITE}Starting comprehensive Google Bot testing...${NC}"
    echo -e "${CYAN}This will test all country/language endpoints for tradik.com${NC}"
    echo ""
    
    # Test robots.txt first
    test_robots
    
    # Test main domain
    test_main_domain
    
    # Test all country endpoints
    test_all_countries
    
    # Print results table
    print_results_table
    
    # Print summary
    print_summary
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ Error: curl is not installed${NC}"
    echo -e "${YELLOW}Please install curl to run this script${NC}"
    exit 1
fi

# Run main function
main
