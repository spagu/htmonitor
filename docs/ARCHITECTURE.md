# Architecture Documentation

## 🏗️ System Architecture

The .htaccess Geo-Redirection Testing Monorepo follows a modular architecture with clear separation of concerns.

```mermaid
graph TB
    subgraph "Applications Layer"
        A[Go Monitor App]
        B[Python Tester App]
        C[Docker Setup App]
    end
    
    subgraph "Shared Layer"
        D[.htaccess Rules]
        E[GeoIP Mock Service]
        F[Common Configurations]
    end
    
    subgraph "Tools Layer"
        G[Test Scripts]
        H[Compiled Binaries]
        I[Utilities]
    end
    
    subgraph "Infrastructure"
        J[Apache Server]
        K[Docker Environment]
        L[File System Watcher]
    end
    
    A --> D
    A --> L
    B --> E
    B --> J
    C --> J
    C --> K
    G --> J
    H --> D
    
    D --> J
    E --> J
```

## 📦 Component Overview

### Applications (`apps/`)

#### htaccess-monitor
- **Technology**: Go with Bubble Tea TUI framework
- **Purpose**: Real-time monitoring and testing
- **Features**:
  - File system watcher for .htaccess changes
  - Terminal UI with live updates
  - HTTP test runner
  - Multi-country testing

#### python-tester
- **Technology**: Python 3.8+
- **Purpose**: Comprehensive testing suite
- **Features**:
  - Google Bot user agent spoofing
  - LiteSpeed server detection
  - JSON result export
  - Bash scripts with visual output

#### docker-setup
- **Technology**: Docker & Docker Compose
- **Purpose**: Containerized testing environment
- **Features**:
  - Apache with mod_rewrite
  - GeoIP simulation
  - Volume mounting
  - Service orchestration

### Shared Packages (`packages/`)

#### shared
- **Purpose**: Common configurations and resources
- **Contents**:
  - `.htaccess` - Geo-redirection rules
  - `geoip-mock.php` - Country simulation service
  - Shared documentation

### Tools (`tools/`)

- **test-scripts/**: Testing utilities and scripts
- **htaccess-monitor**: Compiled Go binary
- **wpexportjson-linux-amd64**: WordPress utility

## 🔄 Data Flow

### 1. File Monitoring Flow
```mermaid
sequenceDiagram
    participant FM as File Monitor
    participant FS as File System
    participant TR as Test Runner
    participant UI as Terminal UI
    
    FS->>FM: .htaccess file changed
    FM->>TR: Trigger test run
    TR->>TR: Execute HTTP tests
    TR->>UI: Update results
    UI->>UI: Refresh display
```

### 2. HTTP Testing Flow
```mermaid
sequenceDiagram
    participant TC as Test Client
    participant GM as GeoIP Mock
    participant AS as Apache Server
    participant HR as .htaccess Rules
    
    TC->>GM: Set country code
    TC->>AS: HTTP request with country header
    AS->>HR: Apply redirection rules
    HR->>AS: Return redirect/response
    AS->>TC: HTTP response
    TC->>TC: Analyze result
```

### 3. Multi-Country Testing
```mermaid
sequenceDiagram
    participant PT as Python Tester
    participant Countries as Country List
    participant Server as Test Server
    participant Results as Result Store
    
    PT->>Countries: Iterate through countries
    loop For each country
        PT->>Server: Test with country code
        Server->>PT: Return response
        PT->>Results: Store test result
    end
    PT->>Results: Generate JSON report
```

## 🧩 Design Patterns

### 1. Observer Pattern
- **File Watcher**: Observes .htaccess file changes
- **UI Updates**: Observes test result changes
- **Implementation**: Go channels and fsnotify

### 2. Strategy Pattern
- **User Agents**: Different Google Bot strategies
- **Test Types**: Regular vs Bot testing strategies
- **Output Formats**: JSON, Terminal, Log formats

### 3. Factory Pattern
- **Test Creation**: Creates different test types
- **HTTP Clients**: Creates configured HTTP clients
- **Result Formatters**: Creates appropriate formatters

### 4. Command Pattern
- **Test Execution**: Encapsulates test operations
- **UI Actions**: Keyboard command handling
- **Make Targets**: Build and test commands

## 🔧 Configuration Management

### Environment Variables
```bash
GEOIP_COUNTRY_CODE=AU    # Country simulation
HTTP_TIMEOUT=30          # Request timeout
TEST_DELAY=1.0          # Delay between tests
LOG_LEVEL=INFO          # Logging level
```

### Configuration Files
- `.htaccess` - Apache rewrite rules
- `apps/docker-setup/docker-compose.yml` - Service configuration
- `apps/*/go.mod` - Go module dependencies
- `apps/*/requirements.txt` - Python dependencies

## 🚀 Deployment Architecture

### Local Development
```mermaid
graph LR
    Dev[Developer] --> Local[Local Environment]
    Local --> GM[Go Monitor]
    Local --> PT[Python Tests]
    Local --> Docker[Docker Services]
```

### Docker Environment
```mermaid
graph TB
    subgraph "Docker Network"
        Apache[Apache Container]
        GeoIP[GeoIP Mock Service]
        Volume[Shared Volume]
    end
    
    Host[Host Machine] --> Apache
    Apache --> Volume
    GeoIP --> Volume
    Volume --> Config[.htaccess Config]
```

## 📊 Performance Considerations

### Monitoring Performance
- **File Watcher**: Minimal CPU usage with fsnotify
- **HTTP Tests**: Configurable delays to prevent overload
- **UI Updates**: Efficient terminal rendering with Bubble Tea

### Scalability
- **Concurrent Testing**: Go goroutines for parallel tests
- **Resource Management**: Proper cleanup and connection pooling
- **Memory Usage**: Streaming results for large test suites

### Optimization
- **Caching**: HTTP client reuse
- **Batching**: Group similar tests
- **Lazy Loading**: Load resources on demand

## 🔒 Security Considerations

### Input Validation
- URL validation for test targets
- Country code validation
- File path sanitization

### Network Security
- Local testing environment isolation
- No external network calls in production
- Secure Docker container configuration

### Data Protection
- No sensitive data in logs
- Temporary file cleanup
- Secure configuration management

## 🧪 Testing Strategy

### Unit Testing
- Go: Standard testing package
- Python: pytest framework
- Coverage: Aim for >80% coverage

### Integration Testing
- End-to-end test flows
- Docker environment testing
- Cross-platform compatibility

### Performance Testing
- Load testing with multiple countries
- Memory usage monitoring
- Response time benchmarking

## 📈 Monitoring and Observability

### Logging
- Structured logging with levels
- Rotation and cleanup policies
- Error tracking and alerting

### Metrics
- Test execution times
- Success/failure rates
- Resource utilization

### Health Checks
- Service availability monitoring
- Configuration validation
- Dependency health checks