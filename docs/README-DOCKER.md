# Docker Testing Environment for .htaccess

## Quick Start

```bash
# Build and start the container
docker-compose up --build -d

# Run automated tests
./test-scripts/test-countries.sh

# Open testing interface in browser
open http://localhost:8080/geoip-mock.php
```

## What's Included

### 🐳 **Docker Environment**
- **Apache server** with mod_rewrite enabled
- **GeoIP mocking** via query parameters or headers
- **WordPress-like structure** for realistic testing
- **Country-specific pages** for all supported regions

### 🌍 **GeoIP Mocking Methods**

#### Method 1: Query Parameters
```bash
curl http://localhost:8080/?country=DE
curl http://localhost:8080/?country=UK
curl http://localhost:8080/?country=US
```

#### Method 2: HTTP Headers
```bash
curl -H "X-Test-Country: DE" http://localhost:8080/
curl -H "X-Test-Country: UK" http://localhost:8080/
curl -H "X-Test-Country: US" http://localhost:8080/
```

#### Method 3: Web Interface
Visit `http://localhost:8080/geoip-mock.php` for interactive testing with country buttons.

### 🤖 **Google Bot Testing**

```bash
# Test Google Bot with different countries
curl -H "X-Test-Country: DE" -A "Googlebot/2.1" http://localhost:8080/
curl -H "X-Test-Country: UK" -A "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" http://localhost:8080/

# Test Google Bot without country (should not redirect)
curl -A "Googlebot/2.1" http://localhost:8080/
```

## Supported Countries

| Code | Country | Expected Redirect | Flag |
|------|---------|------------------|------|
| `US` | United States | No redirect | 🇺🇸 |
| `GB` | United Kingdom | `/uk/` | 🇬🇧 |
| `DE` | Germany | `/de/` | 🇩🇪 |
| `FR` | France | `/fr/` | 🇫🇷 |
| `LU` | Luxembourg | `/fr/` | 🇱🇺 |
| `AU` | Australia | `/au/` | 🇦🇺 |
| `AT` | Austria | `/at/` | 🇦🇹 |
| `CA` | Canada | `/ca/` | 🇨🇦 |
| `IE` | Ireland | `/ie/` | 🇮🇪 |
| `IT` | Italy | `/it/` | 🇮🇹 |
| `CH` | Switzerland | `/ch/` | 🇨🇭 |
| `LI` | Liechtenstein | `/ch/` | 🇱🇮 |
| `ES` | Spain | `/es/` | 🇪🇸 |
| **Other** | Any other | `/uk/` (fallback) | ❓ |

## Testing Scenarios

### ✅ **Expected Behaviors**

1. **US Users**: Stay on main site (no redirect)
2. **Known Countries**: Redirect to country-specific subdirectory
3. **Unknown Countries**: Fallback to UK (`/uk/`)
4. **Google Bot**: No redirect regardless of country
5. **WordPress Admin**: No redirect (protected)
6. **SEO Files**: No redirect (robots.txt, sitemap)

### 🧪 **Test Commands**

```bash
# Test different countries
curl -I -H "X-Test-Country: DE" http://localhost:8080/
curl -I -H "X-Test-Country: US" http://localhost:8080/
curl -I -H "X-Test-Country: JP" http://localhost:8080/  # Unknown country

# Test Google Bot exception
curl -I -A "Googlebot/2.1" http://localhost:8080/

# Test protected areas
curl -I -H "X-Test-Country: DE" http://localhost:8080/wp-admin/
curl -I -H "X-Test-Country: DE" http://localhost:8080/robots.txt

# Test with query parameters
curl -I "http://localhost:8080/?country=FR"
curl -I "http://localhost:8080/?country=AU"
```

## Debugging

### 📊 **View Logs**
```bash
# Real-time logs
docker-compose logs -f htaccess-tester

# Apache access logs (with country info)
docker-compose exec htaccess-tester tail -f /var/log/apache2/access.log

# Apache error logs
docker-compose exec htaccess-tester tail -f /var/log/apache2/error.log
```

### 🔍 **Debug Headers**
The server adds debug headers to help troubleshoot:
- `X-Debug-Country`: Shows detected country code
- `X-Debug-Query`: Shows query string

### 🛠️ **Interactive Shell**
```bash
# Access container shell
docker-compose exec htaccess-tester bash

# Check .htaccess syntax
docker-compose exec htaccess-tester apache2ctl configtest

# View current .htaccess
docker-compose exec htaccess-tester cat /var/www/html/.htaccess
```

## File Structure

```
📁 Docker Environment
├── 🐳 Dockerfile - Apache + PHP setup
├── ⚙️ docker-compose.yml - Service orchestration
├── 🌐 apache-vhost.conf - Apache configuration with GeoIP mock
├── 🧪 geoip-mock.php - Interactive testing interface
├── 📋 test-scripts/
│   └── test-countries.sh - Automated test script
├── 📄 .htaccess - Your actual .htaccess file (mounted)
└── 📊 logs/ - Apache logs (mounted volume)
```

## Troubleshooting

### Common Issues

1. **Port 8080 in use**
   ```bash
   # Change port in docker-compose.yml
   ports:
     - "8081:80"  # Use different port
   ```

2. **.htaccess not working**
   ```bash
   # Check if file is mounted correctly
   docker-compose exec htaccess-tester ls -la /var/www/html/.htaccess
   
   # Restart container after .htaccess changes
   docker-compose restart htaccess-tester
   ```

3. **Redirects not working**
   ```bash
   # Check Apache error logs
   docker-compose logs htaccess-tester
   
   # Verify mod_rewrite is enabled
   docker-compose exec htaccess-tester apache2ctl -M | grep rewrite
   ```

### Testing Tips

1. **Use curl -I** for headers only (faster testing)
2. **Check X-Debug-Country header** to verify country detection
3. **Test both methods**: query params and headers
4. **Use the web interface** for visual testing
5. **Monitor logs** in real-time during testing

## Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove images (optional)
docker-compose down --rmi all

# Remove volumes (optional)
docker-compose down -v
```
