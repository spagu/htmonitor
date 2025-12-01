# Docker Setup for .htaccess Testing

Docker configuration for running Apache with geo-redirection testing capabilities.

## Features

- Apache with mod_rewrite enabled
- GeoIP mock functionality
- Custom virtual host configuration
- Volume mounting for .htaccess files
- Port 8080 exposure for testing

## Files

- `Dockerfile` - Apache container configuration
- `docker-compose.yml` - Service orchestration
- `apache-vhost.conf` - Virtual host configuration

## Usage

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Testing

Access the test environment at:
- http://localhost:8080/
- http://localhost:8080/geoip-mock.php