#!/bin/bash

# Test script for .htaccess geo-redirection with fancy output
# Tests specified countries: au|at|ca|fr|de|ie|it|ch|es|uk|us|lu|li|ch-fr|ch-it|ca-fr + jp

BASE_URL="http://localhost:8080"
GOOGLEBOT_UA="Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

# Colors for fancy output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Box drawing characters
TOP_LEFT="╔"
TOP_RIGHT="╗"
BOTTOM_LEFT="╚"
BOTTOM_RIGHT="╝"
HORIZONTAL="═"
VERTICAL="║"
CROSS="╬"
T_DOWN="╦"
T_UP="╩"
T_RIGHT="╠"
T_LEFT="╣"

# Define test countries
declare -A COUNTRIES
COUNTRIES[us]="🇺🇸 US"
COUNTRIES[uk]="🇬🇧 UK" 
COUNTRIES[au]="🇦🇺 AU"
COUNTRIES[at]="🇦🇹 AT"
COUNTRIES[ca]="🇨🇦 CA"
COUNTRIES[fr]="🇫🇷 FR"
COUNTRIES[de]="🇩🇪 DE"
COUNTRIES[ie]="🇮🇪 IE"
COUNTRIES[it]="🇮🇹 IT"
COUNTRIES[ch]="🇨🇭 CH"
COUNTRIES[es]="🇪🇸 ES"
COUNTRIES[lu]="🇱🇺 LU"
COUNTRIES[li]="🇱🇮 LI"
COUNTRIES[jp]="🇯🇵 JP"

# Arrays to store results
declare -A HOME_RESULTS
declare -A HOME_GOOGLEBOT_RESULTS
declare -A TESTCONTENT_RESULTS
declare -A TESTCONTENT_GOOGLEBOT_RESULTS

# Function to test URL and return status/location
test_url() {
    local country="$1"
    local url="$2"
    local user_agent="$3"
    
    # Convert country code to uppercase for .htaccess compatibility
    country_upper=$(echo "$country" | tr '[:lower:]' '[:upper:]')
    
    if [[ -n "$user_agent" ]]; then
        response=$(curl -s -I -H "X-Test-Country: $country_upper" -A "$user_agent" "$url" 2>/dev/null)
    else
        response=$(curl -s -I -H "X-Test-Country: $country_upper" "$url" 2>/dev/null)
    fi
    
    status=$(echo "$response" | grep "HTTP" | awk '{print $2}')
    location=$(echo "$response" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r\n')
    
    if [[ "$status" == "200" ]]; then
        echo "200|No redirect"
    elif [[ "$status" == "302" ]]; then
        echo "302|$location"
    else
        echo "$status|Error"
    fi
}

# Fancy header function
print_header() {
    local title="$1"
    local width=80
    echo -e "${CYAN}${TOP_LEFT}$(printf '%*s' $((width-2)) '' | tr ' ' "${HORIZONTAL}")${TOP_RIGHT}${NC}"
    echo -e "${CYAN}${VERTICAL}${BOLD}${WHITE} $title $(printf '%*s' $((width-${#title}-4)) '')${NC}${CYAN}${VERTICAL}${NC}"
    echo -e "${CYAN}${BOTTOM_LEFT}$(printf '%*s' $((width-2)) '' | tr ' ' "${HORIZONTAL}")${BOTTOM_RIGHT}${NC}"
    echo ""
}

# Fancy section header
print_section() {
    local title="$1"
    echo -e "${PURPLE}▓▓▓ $title ▓▓▓${NC}"
    echo ""
}

print_header "🌍 .htaccess Geo-Redirection Test Results"

# Collect all test results
for country in "${!COUNTRIES[@]}"; do
    # Test home page - regular user
    result=$(test_url "$country" "$BASE_URL/")
    HOME_RESULTS[$country]=$result
    
    # Test home page - Google Bot
    result=$(test_url "$country" "$BASE_URL/" "$GOOGLEBOT_UA")
    HOME_GOOGLEBOT_RESULTS[$country]=$result
    
    # Test test-content - regular user
    result=$(test_url "$country" "$BASE_URL/test-content")
    TESTCONTENT_RESULTS[$country]=$result
    
    # Test test-content - Google Bot
    result=$(test_url "$country" "$BASE_URL/test-content" "$GOOGLEBOT_UA")
    TESTCONTENT_GOOGLEBOT_RESULTS[$country]=$result
done

# Function to print fancy table
print_table() {
    local title="$1"
    local -n results_ref=$2
    
    print_section "$title"
    
    # Table header with colors
    echo -e "${BLUE}╔══════════╦════════╦════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${BOLD}${WHITE} Country  ${NC}${BLUE}║${BOLD}${WHITE} Status ${NC}${BLUE}║${BOLD}${WHITE} Result                                             ${NC}${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════╬════════╬════════════════════════════════════════════════════╣${NC}"
    
    for country in us uk au at ca fr de ie it ch es lu li jp; do
        if [[ -n "${results_ref[$country]}" ]]; then
            IFS='|' read -r status result <<< "${results_ref[$country]}"
            flag="${COUNTRIES[$country]}"
            
            if [[ "$status" == "200" ]]; then
                status_display="✅ $status"
                result_display="$result"
            elif [[ "$status" == "302" ]]; then
                status_display="🔄 $status"
                result_display="$result"
            else
                status_display="❌ $status"
                result_display="$result"
            fi
            
            printf "${BLUE}║${NC} %-14s ${BLUE}║${NC} %-6s ${BLUE}║${NC} %-50s ${BLUE}║${NC}\n" "$flag" "$status_display" "$result_display"
        fi
    done
    echo -e "${BLUE}╚══════════╩════════╩════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print all tables
print_table "🏠 Home Page - Regular Users" HOME_RESULTS
print_table "🤖 Home Page - Google Bot" HOME_GOOGLEBOT_RESULTS
print_table "📄 Test Content - Regular Users" TESTCONTENT_RESULTS
print_table "🤖 Test Content - Google Bot" TESTCONTENT_GOOGLEBOT_RESULTS

# Special cases table
print_section "🔍 Special Cases"
echo -e "${PURPLE}╔══════════════════════╦════════╦════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${BOLD}${WHITE} Test Case            ${NC}${PURPLE}║${BOLD}${WHITE} Status ${NC}${PURPLE}║${BOLD}${WHITE} Result                                 ${NC}${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════╬════════╬════════════════════════════════════════╣${NC}"

# Test no country set (empty header)
result=$(curl -s -I "$BASE_URL/" 2>/dev/null)
status=$(echo "$result" | grep "HTTP" | awk '{print $2}')
location=$(echo "$result" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r\n')
if [[ "$status" == "302" ]]; then
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "No Country Set" "🔄 $status" "$location"
else
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "No Country Set" "✅ $status" "No redirect"
fi

# Test empty country code
result=$(curl -s -I -H "X-Test-Country: " "$BASE_URL/" 2>/dev/null)
status=$(echo "$result" | grep "HTTP" | awk '{print $2}')
location=$(echo "$result" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r\n')
if [[ "$status" == "302" ]]; then
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "Empty Country Code" "🔄 $status" "$location"
else
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "Empty Country Code" "✅ $status" "No redirect"
fi

# Test WordPress admin
result=$(curl -s -I -H "X-Test-Country: DE" "$BASE_URL/wp-admin/" 2>/dev/null)
status=$(echo "$result" | grep "HTTP" | awk '{print $2}')
if [[ "$status" == "200" ]]; then
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "WordPress Admin" "✅ $status" "No redirect (protected)"
else
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "WordPress Admin" "❌ $status" "Error"
fi

# Test robots.txt
result=$(curl -s -I -H "X-Test-Country: DE" "$BASE_URL/robots.txt" 2>/dev/null)
status=$(echo "$result" | grep "HTTP" | awk '{print $2}')
if [[ "$status" == "200" ]]; then
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "Robots.txt" "✅ $status" "No redirect (SEO protected)"
else
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "Robots.txt" "❌ $status" "Error"
fi

# Test sitemap
result=$(curl -s -I -H "X-Test-Country: DE" "$BASE_URL/sitemap_index.xml" 2>/dev/null)
status=$(echo "$result" | grep "HTTP" | awk '{print $2}')
if [[ "$status" == "200" ]]; then
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "Sitemap" "✅ $status" "No redirect (SEO protected)"
else
    printf "${PURPLE}║${NC} %-20s ${PURPLE}║${NC} %-6s ${PURPLE}║${NC} %-38s ${PURPLE}║${NC}\n" "Sitemap" "❌ $status" "Error"
fi

echo -e "${PURPLE}╚══════════════════════╩════════╩════════════════════════════════════════╝${NC}"

echo ""
print_section "📊 Summary & Statistics"

# Count results
total_countries=${#COUNTRIES[@]}
home_redirects=0
home_no_redirects=0
googlebot_redirects=0
googlebot_no_redirects=0

for country in "${!COUNTRIES[@]}"; do
    IFS='|' read -r status result <<< "${HOME_RESULTS[$country]}"
    if [[ "$status" == "200" ]]; then
        ((home_no_redirects++))
    elif [[ "$status" == "302" ]]; then
        ((home_redirects++))
    fi
    
    IFS='|' read -r status result <<< "${HOME_GOOGLEBOT_RESULTS[$country]}"
    if [[ "$status" == "200" ]]; then
        ((googlebot_no_redirects++))
    elif [[ "$status" == "302" ]]; then
        ((googlebot_redirects++))
    fi
done

# Fancy summary box
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${BOLD}${WHITE}                           📊 TEST STATISTICS                           ${NC}${GREEN}║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════════════╣${NC}"
printf "${GREEN}║${NC} ${CYAN}🌍 Total Countries Tested:\t\t${NC} ${BOLD}${WHITE}$total_countries${NC}\t\t %-15s ${GREEN}║${NC}\n"
printf "${GREEN}║${NC} ${YELLOW}👥 Regular Users - Redirects:\t\t${NC} ${BOLD}${WHITE}$home_redirects${NC}\t\t %-15s ${GREEN}║${NC}\n"
printf "${GREEN}║${NC} ${GREEN}👥 Regular Users - No Redirects:\t${NC} ${BOLD}${WHITE}$home_no_redirects${NC}\t\t %-15s ${GREEN}║${NC}\n"
printf "${GREEN}║${NC} ${YELLOW}🤖 Google Bot - Redirects:\t\t${NC} ${BOLD}${WHITE}$googlebot_redirects${NC}\t\t %-15s ${GREEN}║${NC}\n"
printf "${GREEN}║${NC} ${GREEN}🤖 Google Bot - No Redirects:\t\t${NC} ${BOLD}${WHITE}$googlebot_no_redirects${NC}\t\t %-15s ${GREEN}║${NC}\n"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${CYAN}💡 ${BOLD}Manual Testing:${NC} ${BLUE}http://localhost:8080/geoip-mock.php${NC}"
echo -e "${CYAN}📊 ${BOLD}View Logs:${NC} ${BLUE}docker-compose logs htaccess-tester${NC}"
echo ""

# Final status
if [[ $home_no_redirects -eq 1 && $googlebot_no_redirects -gt 0 ]]; then
    echo -e "${GREEN}✅ ${BOLD}All tests completed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  ${BOLD}Review results above for any issues${NC}"
fi
