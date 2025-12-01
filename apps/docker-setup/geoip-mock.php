<?php
/**
 * GeoIP Mock for Testing
 * Displays current environment variables and allows manual country setting
 */

$country = $_ENV['GEOIP_COUNTRY_CODE'] ?? 'NOT_SET';
$query = $_SERVER['QUERY_STRING'] ?? '';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
$test_country_header = $_SERVER['HTTP_X_TEST_COUNTRY'] ?? '';

?>
<!DOCTYPE html>
<html>
<head>
    <title>GeoIP Mock - Testing Interface</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .info-box { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .country-buttons { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 20px 0; }
        .country-btn { padding: 10px; text-align: center; background: #007cba; color: white; text-decoration: none; border-radius: 3px; }
        .country-btn:hover { background: #005a87; }
        .debug { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 10px 0; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌍 GeoIP Mock Testing Interface</h1>
        
        <div class="info-box">
            <h2>Current Status</h2>
            <p><strong>Detected Country:</strong> <code><?php echo htmlspecialchars($country); ?></code></p>
            <p><strong>Query String:</strong> <code><?php echo htmlspecialchars($query); ?></code></p>
            <p><strong>User Agent:</strong> <code><?php echo htmlspecialchars($user_agent); ?></code></p>
            <p><strong>Test Country Header:</strong> <code><?php echo htmlspecialchars($test_country_header); ?></code></p>
        </div>

        <div class="debug">
            <h3>🔧 How to Test</h3>
            <p><strong>Method 1 - Query Parameter:</strong> Add <code>?country=XX</code> to any URL</p>
            <p><strong>Method 2 - HTTP Header:</strong> Send <code>X-Test-Country: XX</code> header</p>
            <p><strong>Method 3 - Use buttons below</strong></p>
        </div>

        <h2>🌎 Test Different Countries</h2>
        <div class="country-buttons">
            <a href="/?country=US" class="country-btn">🇺🇸 US</a>
            <a href="/?country=GB" class="country-btn">🇬🇧 UK</a>
            <a href="/?country=DE" class="country-btn">🇩🇪 Germany</a>
            <a href="/?country=FR" class="country-btn">🇫🇷 France</a>
            <a href="/?country=AU" class="country-btn">🇦🇺 Australia</a>
            <a href="/?country=AT" class="country-btn">🇦🇹 Austria</a>
            <a href="/?country=CA" class="country-btn">🇨🇦 Canada</a>
            <a href="/?country=IE" class="country-btn">🇮🇪 Ireland</a>
            <a href="/?country=IT" class="country-btn">🇮🇹 Italy</a>
            <a href="/?country=CH" class="country-btn">🇨🇭 Switzerland</a>
            <a href="/?country=ES" class="country-btn">🇪🇸 Spain</a>
            <a href="/?country=LU" class="country-btn">🇱🇺 Luxembourg</a>
            <a href="/?country=LI" class="country-btn">🇱🇮 Liechtenstein</a>
            <a href="/?country=JP" class="country-btn">🇯🇵 Japan (Unknown)</a>
            <a href="/?country=BR" class="country-btn">🇧🇷 Brazil (Unknown)</a>
            <a href="/" class="country-btn">❓ No Country</a>
        </div>

        <h2>🤖 Test Google Bot</h2>
        <div class="info-box">
            <p>Use curl to test Google Bot behavior:</p>
            <pre><code>curl -H "X-Test-Country: DE" -A "Googlebot/2.1" http://localhost:8080/</code></pre>
            <pre><code>curl "http://localhost:8080/?country=UK" -A "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"</code></pre>
        </div>

        <h2>📋 Test Results</h2>
        <div class="info-box">
            <p><strong>Expected Behavior:</strong></p>
            <ul>
                <li><strong>US:</strong> No redirect (stay on main page)</li>
                <li><strong>UK/Unknown:</strong> Redirect to /uk/</li>
                <li><strong>DE:</strong> Redirect to /de/</li>
                <li><strong>FR/LU:</strong> Redirect to /fr/</li>
                <li><strong>AU:</strong> Redirect to /au/</li>
                <li><strong>Google Bot:</strong> No redirect (should stay on main page)</li>
            </ul>
        </div>

        <div class="debug">
            <h3>🔍 Debug Information</h3>
            <p><strong>Server Variables:</strong></p>
            <pre><?php
                $debug_vars = [
                    'REQUEST_URI' => $_SERVER['REQUEST_URI'] ?? '',
                    'HTTP_HOST' => $_SERVER['HTTP_HOST'] ?? '',
                    'SERVER_NAME' => $_SERVER['SERVER_NAME'] ?? '',
                    'QUERY_STRING' => $_SERVER['QUERY_STRING'] ?? '',
                    'HTTP_USER_AGENT' => $_SERVER['HTTP_USER_AGENT'] ?? '',
                ];
                foreach ($debug_vars as $key => $value) {
                    echo "$key: " . htmlspecialchars($value) . "\n";
                }
            ?></pre>
        </div>
    </div>
</body>
</html>
