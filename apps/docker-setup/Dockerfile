FROM php:8.2-apache

# Install required packages
RUN apt-get update && apt-get install -y \
    libapache2-mod-geoip \
    geoip-database \
    wget \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite \
    && a2enmod headers \
    && a2enmod env \
    && a2enmod setenvif

# Create directory structure for WordPress-like setup
RUN mkdir -p /var/www/html/uk \
    && mkdir -p /var/www/html/de \
    && mkdir -p /var/www/html/fr \
    && mkdir -p /var/www/html/au \
    && mkdir -p /var/www/html/at \
    && mkdir -p /var/www/html/ca \
    && mkdir -p /var/www/html/ie \
    && mkdir -p /var/www/html/it \
    && mkdir -p /var/www/html/ch \
    && mkdir -p /var/www/html/es \
    && mkdir -p /var/www/html/lu \
    && mkdir -p /var/www/html/li \
    && mkdir -p /var/www/html/ch-fr \
    && mkdir -p /var/www/html/ch-it \
    && mkdir -p /var/www/html/ca-fr \
    && mkdir -p /var/www/html/wp-admin \
    && mkdir -p /var/www/html/wp-content \
    && mkdir -p /var/www/html/wp-includes \
    && mkdir -p /var/www/html/wp-json

# Create mock index.php for Apache testing
RUN echo '<?php' > /var/www/html/index.php && \
    echo 'echo "<h1>Apache Mock Test - Index Page</h1>";' >> /var/www/html/index.php && \
    echo 'echo "<p>Server: " . $_SERVER["SERVER_SOFTWARE"] . "</p>";' >> /var/www/html/index.php && \
    echo 'echo "<p>PHP Version: " . phpversion() . "</p>";' >> /var/www/html/index.php && \
    echo 'echo "<p>Request URI: " . $_SERVER["REQUEST_URI"] . "</p>";' >> /var/www/html/index.php && \
    echo 'echo "<p>Country Code: " . ($_SERVER["GEOIP_COUNTRY_CODE"] ?? "Not Set") . "</p>";' >> /var/www/html/index.php && \
    echo 'echo "<p>User Agent: " . $_SERVER["HTTP_USER_AGENT"] . "</p>";' >> /var/www/html/index.php && \
    echo 'echo "<p>Timestamp: " . date("Y-m-d H:i:s") . "</p>";' >> /var/www/html/index.php && \
    echo '?>' >> /var/www/html/index.php

# Create test pages for each country
RUN echo '<!DOCTYPE html><html><head><title>US Home</title></head><body><h1>🇺🇸 United States - Main Site</h1><p>This is the main US site (no redirect)</p><p><a href="/test-content">Test Content</a></p></body></html>' > /var/www/html/index.html
RUN echo '<!DOCTYPE html><html><head><title>UK Site</title></head><body><h1>🇬🇧 United Kingdom Site</h1><p>Welcome to the UK version</p><p><a href="/uk/test-content">Test Content</a></p></body></html>' > /var/www/html/uk/index.html
RUN echo '<!DOCTYPE html><html><head><title>German Site</title></head><body><h1>🇩🇪 Deutsche Website</h1><p>Willkommen auf der deutschen Version</p><p><a href="/de/test-content">Test Content</a></p></body></html>' > /var/www/html/de/index.html
RUN echo '<!DOCTYPE html><html><head><title>French Site</title></head><body><h1>🇫🇷 Site Français</h1><p>Bienvenue sur la version française</p><p><a href="/fr/test-content">Test Content</a></p></body></html>' > /var/www/html/fr/index.html
RUN echo '<!DOCTYPE html><html><head><title>Australian Site</title></head><body><h1>🇦🇺 Australian Site</h1><p>G'\''day! Welcome to the Australian version</p><p><a href="/au/test-content">Test Content</a></p></body></html>' > /var/www/html/au/index.html
RUN echo '<!DOCTYPE html><html><head><title>Austrian Site</title></head><body><h1>🇦🇹 Österreichische Website</h1><p>Willkommen in Österreich</p><p><a href="/at/test-content">Test Content</a></p></body></html>' > /var/www/html/at/index.html
RUN echo '<!DOCTYPE html><html><head><title>Canadian Site</title></head><body><h1>🇨🇦 Canadian Site</h1><p>Welcome to the Canadian version, eh!</p><p><a href="/ca/test-content">Test Content</a></p></body></html>' > /var/www/html/ca/index.html
RUN echo '<!DOCTYPE html><html><head><title>Irish Site</title></head><body><h1>🇮🇪 Irish Site</h1><p>Fáilte to the Irish version</p><p><a href="/ie/test-content">Test Content</a></p></body></html>' > /var/www/html/ie/index.html
RUN echo '<!DOCTYPE html><html><head><title>Italian Site</title></head><body><h1>🇮🇹 Sito Italiano</h1><p>Benvenuti nella versione italiana</p><p><a href="/it/test-content">Test Content</a></p></body></html>' > /var/www/html/it/index.html
RUN echo '<!DOCTYPE html><html><head><title>Swiss Site</title></head><body><h1>🇨🇭 Swiss Site</h1><p>Welcome to the Swiss version</p><p><a href="/ch/test-content">Test Content</a></p></body></html>' > /var/www/html/ch/index.html
RUN echo '<!DOCTYPE html><html><head><title>Spanish Site</title></head><body><h1>🇪🇸 Sitio Español</h1><p>Bienvenidos a la versión española</p><p><a href="/es/test-content">Test Content</a></p></body></html>' > /var/www/html/es/index.html

# Create test-content pages for each country
RUN echo '<!DOCTYPE html><html><head><title>Test Content - US</title></head><body><h1>🇺🇸 Test Content - United States</h1><p>This is test content for the US market.</p><p><a href="/">← Back to Home</a></p></body></html>' > /var/www/html/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - UK</title></head><body><h1>🇬🇧 Test Content - United Kingdom</h1><p>This is test content for the UK market.</p><p><a href="/uk/">← Back to Home</a></p></body></html>' > /var/www/html/uk/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - DE</title></head><body><h1>🇩🇪 Testinhalt - Deutschland</h1><p>Dies ist Testinhalt für den deutschen Markt.</p><p><a href="/de/">← Zurück zur Startseite</a></p></body></html>' > /var/www/html/de/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - FR</title></head><body><h1>🇫🇷 Contenu de Test - France</h1><p>Ceci est du contenu de test pour le marché français.</p><p><a href="/fr/">← Retour à l'\''accueil</a></p></body></html>' > /var/www/html/fr/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - AU</title></head><body><h1>🇦🇺 Test Content - Australia</h1><p>This is test content for the Australian market, mate!</p><p><a href="/au/">← Back to Home</a></p></body></html>' > /var/www/html/au/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - AT</title></head><body><h1>🇦🇹 Testinhalt - Österreich</h1><p>Dies ist Testinhalt für den österreichischen Markt.</p><p><a href="/at/">← Zurück zur Startseite</a></p></body></html>' > /var/www/html/at/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - CA</title></head><body><h1>🇨🇦 Test Content - Canada</h1><p>This is test content for the Canadian market, eh!</p><p><a href="/ca/">← Back to Home</a></p></body></html>' > /var/www/html/ca/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - IE</title></head><body><h1>🇮🇪 Test Content - Ireland</h1><p>This is test content for the Irish market.</p><p><a href="/ie/">← Back to Home</a></p></body></html>' > /var/www/html/ie/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - IT</title></head><body><h1>🇮🇹 Contenuto di Test - Italia</h1><p>Questo è contenuto di test per il mercato italiano.</p><p><a href="/it/">← Torna alla Home</a></p></body></html>' > /var/www/html/it/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - CH</title></head><body><h1>🇨🇭 Test Content - Switzerland</h1><p>This is test content for the Swiss market.</p><p><a href="/ch/">← Back to Home</a></p></body></html>' > /var/www/html/ch/test-content.html
RUN echo '<!DOCTYPE html><html><head><title>Test Content - ES</title></head><body><h1>🇪🇸 Contenido de Prueba - España</h1><p>Este es contenido de prueba para el mercado español.</p><p><a href="/es/">← Volver al Inicio</a></p></body></html>' > /var/www/html/es/test-content.html

# Create WordPress-like files
RUN echo '<?php echo "WordPress Admin Area"; ?>' > /var/www/html/wp-admin/index.php
RUN echo '<?php echo "WordPress JSON API"; ?>' > /var/www/html/wp-json/index.php
RUN echo 'User-agent: *\nDisallow: /wp-admin/\nAllow: /wp-admin/admin-ajax.php\n\nSitemap: https://localhost/sitemap_index.xml' > /var/www/html/robots.txt
RUN echo '<?xml version="1.0" encoding="UTF-8"?><sitemapindex><sitemap><loc>https://localhost/sitemap.xml</loc></sitemap></sitemapindex>' > /var/www/html/sitemap_index.xml

# Create Apache virtual host configuration with GeoIP mock
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Create GeoIP mock script
COPY geoip-mock.php /var/www/html/geoip-mock.php

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
