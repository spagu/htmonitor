#!/usr/bin/env python3
"""
Google Bot Spoofing and Website Availability Tester
Specifically designed to test tradik.com (LiteSpeed server) and UK website robots.txt
"""

import requests
import time
import logging
import argparse
from urllib.parse import urljoin, urlparse
from typing import Dict, List, Optional, Tuple
import json
from datetime import datetime
import sys
import re


class GoogleBotSpoofer:
    """Google Bot spoofing and website testing utility"""
    
    # Various Google Bot user agents for different purposes
    GOOGLEBOT_USER_AGENTS = {
        'desktop': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        'mobile': 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/W.X.Y.Z Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        'image': 'Googlebot-Image/1.0',
        'news': 'Googlebot-News',
        'video': 'Googlebot-Video/1.0',
        'ads': 'AdsBot-Google (+http://www.google.com/adsbot.html)',
        'adsbot_mobile': 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1 (compatible; AdsBot-Google-Mobile; +http://www.google.com/mobile/adsbot.html)'
    }
    
    def __init__(self, timeout: int = 30, delay: float = 1.0):
        """
        Initialize the GoogleBot spoofer
        
        Args:
            timeout: Request timeout in seconds
            delay: Delay between requests in seconds
        """
        self.timeout = timeout
        self.delay = delay
        self.session = requests.Session()
        self.results = []
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('googlebot_test.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def get_headers(self, bot_type: str = 'desktop', custom_headers: Optional[Dict] = None) -> Dict[str, str]:
        """
        Generate headers for Google Bot spoofing
        
        Args:
            bot_type: Type of Google Bot to spoof
            custom_headers: Additional custom headers
            
        Returns:
            Dictionary of headers
        """
        headers = {
            'User-Agent': self.GOOGLEBOT_USER_AGENTS.get(bot_type, self.GOOGLEBOT_USER_AGENTS['desktop']),
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
        
        if custom_headers:
            headers.update(custom_headers)
            
        return headers
    
    def check_robots_txt(self, url: str, bot_type: str = 'desktop') -> Dict:
        """
        Check robots.txt file for a given URL
        
        Args:
            url: Target URL
            bot_type: Type of Google Bot to spoof
            
        Returns:
            Dictionary with robots.txt analysis results
        """
        parsed_url = urlparse(url)
        robots_url = f"{parsed_url.scheme}://{parsed_url.netloc}/robots.txt"
        
        self.logger.info(f"Checking robots.txt for {robots_url}")
        
        try:
            headers = self.get_headers(bot_type)
            response = self.session.get(robots_url, headers=headers, timeout=self.timeout)
            
            result = {
                'url': robots_url,
                'status_code': response.status_code,
                'accessible': response.status_code == 200,
                'content_length': len(response.text) if response.status_code == 200 else 0,
                'server': response.headers.get('Server', 'Unknown'),
                'content_type': response.headers.get('Content-Type', 'Unknown'),
                'timestamp': datetime.now().isoformat(),
                'bot_type': bot_type
            }
            
            if response.status_code == 200:
                result['content'] = response.text
                result['disallow_rules'] = self._parse_robots_disallow(response.text)
                result['sitemap_urls'] = self._parse_robots_sitemaps(response.text)
            else:
                result['content'] = None
                result['disallow_rules'] = []
                result['sitemap_urls'] = []
                
            return result
            
        except requests.RequestException as e:
            self.logger.error(f"Error checking robots.txt for {robots_url}: {str(e)}")
            return {
                'url': robots_url,
                'error': str(e),
                'accessible': False,
                'timestamp': datetime.now().isoformat(),
                'bot_type': bot_type
            }
    
    def _parse_robots_disallow(self, robots_content: str) -> List[str]:
        """Parse disallow rules from robots.txt content"""
        disallow_rules = []
        lines = robots_content.split('\n')
        
        for line in lines:
            line = line.strip()
            if line.lower().startswith('disallow:'):
                rule = line.split(':', 1)[1].strip()
                if rule:
                    disallow_rules.append(rule)
                    
        return disallow_rules
    
    def _parse_robots_sitemaps(self, robots_content: str) -> List[str]:
        """Parse sitemap URLs from robots.txt content"""
        sitemap_urls = []
        lines = robots_content.split('\n')
        
        for line in lines:
            line = line.strip()
            if line.lower().startswith('sitemap:'):
                url = line.split(':', 1)[1].strip()
                if url:
                    sitemap_urls.append(url)
                    
        return sitemap_urls
    
    def test_website_availability(self, url: str, bot_type: str = 'desktop') -> Dict:
        """
        Test website availability and response characteristics
        
        Args:
            url: Target URL to test
            bot_type: Type of Google Bot to spoof
            
        Returns:
            Dictionary with test results
        """
        self.logger.info(f"Testing availability for {url} with {bot_type} bot")
        
        try:
            headers = self.get_headers(bot_type)
            start_time = time.time()
            response = self.session.get(url, headers=headers, timeout=self.timeout)
            response_time = time.time() - start_time
            
            # Detect LiteSpeed server
            server_header = response.headers.get('Server', '').lower()
            is_litespeed = 'litespeed' in server_header or 'lsws' in server_header
            
            result = {
                'url': url,
                'status_code': response.status_code,
                'response_time': round(response_time, 3),
                'server': response.headers.get('Server', 'Unknown'),
                'is_litespeed': is_litespeed,
                'content_length': len(response.content),
                'content_type': response.headers.get('Content-Type', 'Unknown'),
                'cache_control': response.headers.get('Cache-Control', 'None'),
                'x_litespeed_cache': response.headers.get('X-LiteSpeed-Cache', 'None'),
                'x_litespeed_vary': response.headers.get('X-LiteSpeed-Vary', 'None'),
                'accessible': 200 <= response.status_code < 400,
                'redirected': len(response.history) > 0,
                'final_url': response.url,
                'timestamp': datetime.now().isoformat(),
                'bot_type': bot_type,
                'headers': dict(response.headers)
            }
            
            if response.history:
                result['redirect_chain'] = [r.url for r in response.history]
                
            # Check for geo-redirection patterns (based on .htaccess analysis)
            if '/uk/' in response.url or response.status_code in [301, 302]:
                result['geo_redirected'] = True
            else:
                result['geo_redirected'] = False
                
            return result
            
        except requests.RequestException as e:
            self.logger.error(f"Error testing {url}: {str(e)}")
            return {
                'url': url,
                'error': str(e),
                'accessible': False,
                'timestamp': datetime.now().isoformat(),
                'bot_type': bot_type
            }
    
    def comprehensive_test(self, url: str, test_all_bots: bool = False) -> Dict:
        """
        Run comprehensive tests on a website
        
        Args:
            url: Target URL
            test_all_bots: Whether to test with all bot types
            
        Returns:
            Dictionary with comprehensive test results
        """
        self.logger.info(f"Starting comprehensive test for {url}")
        
        bot_types = list(self.GOOGLEBOT_USER_AGENTS.keys()) if test_all_bots else ['desktop']
        
        results = {
            'target_url': url,
            'test_timestamp': datetime.now().isoformat(),
            'robots_tests': {},
            'availability_tests': {},
            'summary': {}
        }
        
        for bot_type in bot_types:
            self.logger.info(f"Testing with {bot_type} bot")
            
            # Test robots.txt
            robots_result = self.check_robots_txt(url, bot_type)
            results['robots_tests'][bot_type] = robots_result
            
            # Test website availability
            availability_result = self.test_website_availability(url, bot_type)
            results['availability_tests'][bot_type] = availability_result
            
            # Add delay between requests
            if len(bot_types) > 1:
                time.sleep(self.delay)
        
        # Generate summary
        results['summary'] = self._generate_summary(results)
        
        return results
    
    def _generate_summary(self, results: Dict) -> Dict:
        """Generate summary of test results"""
        summary = {
            'total_tests': len(results['availability_tests']),
            'successful_tests': 0,
            'litespeed_detected': False,
            'geo_redirection_detected': False,
            'robots_accessible': False,
            'common_issues': []
        }
        
        for bot_type, test_result in results['availability_tests'].items():
            if test_result.get('accessible', False):
                summary['successful_tests'] += 1
                
            if test_result.get('is_litespeed', False):
                summary['litespeed_detected'] = True
                
            if test_result.get('geo_redirected', False):
                summary['geo_redirection_detected'] = True
        
        # Check robots.txt accessibility
        for bot_type, robots_result in results['robots_tests'].items():
            if robots_result.get('accessible', False):
                summary['robots_accessible'] = True
                break
        
        return summary
    
    def test_tradik_com_specifically(self) -> Dict:
        """
        Specific tests for tradik.com with LiteSpeed server considerations
        
        Returns:
            Dictionary with tradik.com specific test results
        """
        self.logger.info("Running specific tests for tradik.com")
        
        tradik_urls = [
            'https://tradik.com',
            'https://tradik.com/uk/',
            'https://tradik.com/robots.txt',
            'https://tradik.com/sitemap.xml',
            'https://tradik.com/sitemap_index.xml'
        ]
        
        results = {
            'target': 'tradik.com',
            'test_timestamp': datetime.now().isoformat(),
            'url_tests': {},
            'litespeed_analysis': {},
            'uk_specific_tests': {}
        }
        
        for url in tradik_urls:
            self.logger.info(f"Testing tradik.com URL: {url}")
            
            # Test with desktop bot
            test_result = self.test_website_availability(url, 'desktop')
            results['url_tests'][url] = test_result
            
            # Special analysis for LiteSpeed cache headers
            if test_result.get('is_litespeed'):
                results['litespeed_analysis'][url] = {
                    'cache_status': test_result.get('x_litespeed_cache', 'Not found'),
                    'vary_header': test_result.get('x_litespeed_vary', 'Not found'),
                    'server_header': test_result.get('server', 'Unknown')
                }
            
            time.sleep(self.delay)
        
        # UK-specific tests
        uk_test = self.test_website_availability('https://tradik.com', 'desktop')
        results['uk_specific_tests'] = {
            'redirected_to_uk': '/uk/' in uk_test.get('final_url', ''),
            'geo_detection': uk_test.get('geo_redirected', False),
            'final_destination': uk_test.get('final_url', 'Unknown')
        }
        
        return results
    
    def save_results(self, results: Dict, filename: str = None) -> str:
        """
        Save test results to JSON file
        
        Args:
            results: Test results dictionary
            filename: Output filename (optional)
            
        Returns:
            Filename where results were saved
        """
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"googlebot_test_results_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Results saved to {filename}")
        return filename


def main():
    """Main function to run the Google Bot spoofer"""
    parser = argparse.ArgumentParser(description='Google Bot Spoofing and Website Availability Tester')
    parser.add_argument('--url', type=str, help='Target URL to test')
    parser.add_argument('--all-bots', action='store_true', help='Test with all Google Bot types')
    parser.add_argument('--tradik-test', action='store_true', help='Run specific tests for tradik.com')
    parser.add_argument('--timeout', type=int, default=30, help='Request timeout in seconds')
    parser.add_argument('--delay', type=float, default=1.0, help='Delay between requests in seconds')
    parser.add_argument('--output', type=str, help='Output filename for results')
    
    args = parser.parse_args()
    
    # Initialize the spoofer
    spoofer = GoogleBotSpoofer(timeout=args.timeout, delay=args.delay)
    
    if args.tradik_test:
        # Run tradik.com specific tests
        print("Running tradik.com specific tests...")
        results = spoofer.test_tradik_com_specifically()
        
        # Also run comprehensive test on main tradik.com
        comprehensive_results = spoofer.comprehensive_test('https://tradik.com', args.all_bots)
        results['comprehensive_test'] = comprehensive_results
        
    elif args.url:
        # Run comprehensive test on specified URL
        print(f"Running comprehensive test on {args.url}...")
        results = spoofer.comprehensive_test(args.url, args.all_bots)
        
    else:
        # Default: run tradik.com tests
        print("No URL specified. Running default tradik.com tests...")
        results = spoofer.test_tradik_com_specifically()
        comprehensive_results = spoofer.comprehensive_test('https://tradik.com', args.all_bots)
        results['comprehensive_test'] = comprehensive_results
    
    # Save results
    output_file = spoofer.save_results(results, args.output)
    
    # Print summary
    print("\n" + "="*50)
    print("TEST SUMMARY")
    print("="*50)
    
    if 'comprehensive_test' in results:
        summary = results['comprehensive_test'].get('summary', {})
        print(f"Total tests: {summary.get('total_tests', 0)}")
        print(f"Successful tests: {summary.get('successful_tests', 0)}")
        print(f"LiteSpeed detected: {summary.get('litespeed_detected', False)}")
        print(f"Geo-redirection detected: {summary.get('geo_redirection_detected', False)}")
        print(f"Robots.txt accessible: {summary.get('robots_accessible', False)}")
    
    if 'uk_specific_tests' in results:
        uk_tests = results['uk_specific_tests']
        print(f"UK redirection: {uk_tests.get('redirected_to_uk', False)}")
        print(f"Final destination: {uk_tests.get('final_destination', 'Unknown')}")
    
    print(f"\nDetailed results saved to: {output_file}")


if __name__ == "__main__":
    main()
