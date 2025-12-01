.PHONY: help install test run clean lint format check-deps docker-setup-network

# Colors
ifneq (,$(findstring xterm,${TERM}))
   BLACK        := $(shell tput -Txterm setaf 0)
   RED          := $(shell tput -Txterm setaf 1)
   GREEN        := $(shell tput -Txterm setaf 2)
   YELLOW       := $(shell tput -Txterm setaf 3)
   LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
   PURPLE       := $(shell tput -Txterm setaf 5)
   BLUE         := $(shell tput -Txterm setaf 6)
   WHITE        := $(shell tput -Txterm setaf 7)
   RESET := $(shell tput -Txterm sgr0)
else
   BLACK        := ""
   RED          := ""
   GREEN        := ""
   YELLOW       := ""
   LIGHTPURPLE  := ""
   PURPLE       := ""
   BLUE         := ""
   WHITE        := ""
   RESET        := ""
endif

# Docker networks
DOCKER_NETWORKS := red-network

# Default target
help:
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

install: ## 📦 Install all dependencies (Go and Python)
	@echo "${BLUE}📦 Installing dependencies:${RESET}"
	@echo " ${GREEN}🐹 Go dependencies${RESET}"
	cd apps/htaccess-monitor && go mod tidy
	@echo " ${GREEN}🐍 Python dependencies${RESET}"
	pip install -r apps/python-tester/requirements.txt

check-deps: ## 🔍 Check if dependencies are installed
	@echo "${BLUE}🔍 Checking dependencies:${RESET}"
	@python -c "import requests; print(' ${GREEN}✓ requests installed${RESET}')"
	@cd apps/htaccess-monitor && go mod verify && echo " ${GREEN}✓ Go modules verified${RESET}" || echo " ${RED}✗ Go modules invalid${RESET}"

run: check-deps ## 🚀 Run default localhost tests
	@echo "${BLUE}🚀 Running localhost tests:${RESET}"
	cd apps/python-tester && python googlebot_spoof_tester.py --url http://localhost:8080

test: check-deps ## 🧪 Run Python tests
	@echo "${BLUE}🧪 Running Python tests:${RESET}"
	cd apps/python-tester && python googlebot_spoof_tester.py --url http://localhost:8080 --output test_results.json

test-all: check-deps ## 🎯 Run comprehensive tests
	@echo "${BLUE}🎯 Running comprehensive tests with all bot types:${RESET}"
	cd apps/python-tester && python googlebot_spoof_tester.py --url http://localhost:8080 --all-bots --output comprehensive_test_results.json

test-url: check-deps ## 🌐 Test custom URL (make test-url URL=...)
ifndef URL
	@echo "${RED}❌ Error: URL parameter required. Usage: make test-url URL=https://example.com${RESET}"
	@exit 1
endif
	@echo "${BLUE}🌐 Running test on $(URL):${RESET}"
	cd apps/python-tester && python googlebot_spoof_tester.py --url $(URL) --output custom_test_results.json

clean: ## 🧹 Clean generated files
	@echo "${BLUE}🧹 Cleaning up generated files:${RESET}"
	rm -f *.log
	rm -f *_test_results*.json
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -f *.pyc
	rm -f apps/python-tester/*.log
	rm -f apps/python-tester/*_test_results*.json
	rm -rf apps/python-tester/__pycache__/
	rm -f tools/htaccess-monitor
	rm -rf tools/releases/
	@echo " ${GREEN}✨ Cleanup complete${RESET}"

lint: check-deps ## 🔎 Check code quality
	@echo "${BLUE}🔎 Checking code quality:${RESET}"
	@cd apps/python-tester && python -m py_compile googlebot_spoof_tester.py && echo " ${GREEN}✓ Python code compiles successfully${RESET}"
	@cd apps/htaccess-monitor && go vet ./... && echo " ${GREEN}✓ Go code passes vet${RESET}"
	@cd apps/htaccess-monitor && go fmt ./... && echo " ${GREEN}✓ Go code formatted${RESET}"

format: ## 💅 Format code
	@echo "${BLUE}💅 Formatting code:${RESET}"
	@cd apps/python-tester && python -c "import ast; ast.parse(open('googlebot_spoof_tester.py').read()); print(' ${GREEN}✓ Python syntax is valid${RESET}')"
	@cd apps/htaccess-monitor && go fmt ./... && echo " ${GREEN}✓ Go code formatted${RESET}"

verify: check-deps ## ✅ Quick verification test
	@echo "${BLUE}✅ Verifying script functionality:${RESET}"
	cd apps/python-tester && python googlebot_spoof_tester.py --url https://httpbin.org/get --timeout 10

test-bash: ## 🌍 Run bash script tests
	@echo "${BLUE}🌍 Running bash script to test all languages:${RESET}"
	cd apps/python-tester && ./test_all_languages.sh

test-bash-quick: ## ⚡ Quick bash test
	@echo "${BLUE}⚡ Quick bash test:${RESET}"
	curl -I http://localhost:8080/ -A "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"

go-build: ## 🔨 Build Go monitor application
	@echo "${BLUE}🔨 Building Go monitor:${RESET}"
	cd apps/htaccess-monitor && go build -o ../../tools/htaccess-monitor main.go
	@echo " ${GREEN}✓ Go monitor built successfully${RESET}"

go-binary: ## 📥 Download pre-built Go binary from GitHub releases
	@echo "${BLUE}📥 Downloading pre-built Go binary:${RESET}"
	@./scripts/download-binary.sh

go-build-all: ## 🏗️ Build Go monitor for all architectures
	@echo "${BLUE}🏗️ Building Go monitor for all architectures:${RESET}"
	@./scripts/build-releases.sh || true

go-release: go-build-all ## 📦 Create release packages with checksums
	@echo "${BLUE}📦 Release packages created with checksums and archives${RESET}"
	@echo " ${GREEN}✨ Ready for distribution${RESET}"

go-run: ## 🖥️ Run Go monitor application
	@echo "${BLUE}🖥️ Starting .htaccess monitor:${RESET}"
	cd apps/htaccess-monitor && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 go run main.go

go-test-links: ## 🔗 Test links from links.testing file
	@echo "${BLUE}🔗 Testing links from links.testing file:${RESET}"
	cd apps/htaccess-monitor && go run main.go -test ../../links.testing

go-test-watch: ## 👁️ Watch and test links on file changes
	@echo "${BLUE}👁️ Watching files and testing links:${RESET}"
	cd apps/htaccess-monitor && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 go run main.go -test ../../links.testing -watch

go-deps: ## 📥 Download Go dependencies
	@echo "${BLUE}📥 Downloading Go dependencies:${RESET}"
	cd apps/htaccess-monitor && go mod tidy
	@echo " ${GREEN}✓ Go dependencies updated${RESET}"

go-test: ## 🧪 Run Go unit tests
	@echo "${BLUE}🧪 Running Go unit tests:${RESET}"
	cd apps/htaccess-monitor && go test -v -cover
	@echo " ${GREEN}✓ Go tests completed${RESET}"

go-test-coverage: ## 📊 Run Go tests with coverage report
	@echo "${BLUE}📊 Running Go tests with coverage:${RESET}"
	cd apps/htaccess-monitor && go test -v -coverprofile=coverage.out -covermode=atomic
	cd apps/htaccess-monitor && go tool cover -html=coverage.out -o coverage.html
	@echo " ${GREEN}✓ Coverage report generated: apps/htaccess-monitor/coverage.html${RESET}"

go-test-integration: ## 🔗 Run Go integration tests
	@echo "${BLUE}🔗 Running Go integration tests:${RESET}"
	cd apps/htaccess-monitor && go test -v -tags=integration
	@echo " ${GREEN}✓ Integration tests completed${RESET}"

go-test-bench: ## ⚡ Run Go benchmarks
	@echo "${BLUE}⚡ Running Go benchmarks:${RESET}"
	cd apps/htaccess-monitor && go test -bench=. -benchmem
	@echo " ${GREEN}✓ Benchmarks completed${RESET}"

go-test-all: go-test go-test-integration go-test-bench ## 🎯 Run all Go tests
	@echo " ${GREEN}✨ All Go tests completed${RESET}"

go-lint: ## 🔍 Run Go linter
	@echo "${BLUE}🔍 Running Go linter:${RESET}"
	cd apps/htaccess-monitor && golangci-lint run .
	@echo " ${GREEN}✓ Go linting completed${RESET}"

release: ## 🚀 Create GitHub release (auto-increment version)
	@echo "${BLUE}🚀 Creating GitHub release with auto-incremented version:${RESET}"
	@chmod +x scripts/create-release.sh
	@./scripts/create-release.sh

release-version: ## 🏷️ Create GitHub release with specific version (make release-version VERSION=v1.2.0)
ifndef VERSION
	@echo "${RED}❌ Error: VERSION parameter required. Usage: make release-version VERSION=v1.2.0${RESET}"
	@exit 1
endif
	@echo "${BLUE}🏷️ Creating GitHub release ${VERSION}:${RESET}"
	@chmod +x scripts/create-release.sh
	@./scripts/create-release.sh ${VERSION}

release-draft: ## 📝 Create draft GitHub release (auto-increment version)
	@echo "${BLUE}📝 Creating draft GitHub release:${RESET}"
	@chmod +x scripts/create-release.sh
	@./scripts/create-release.sh --draft

release-prerelease: ## 🧪 Create pre-release (auto-increment version)
	@echo "${BLUE}🧪 Creating GitHub pre-release:${RESET}"
	@chmod +x scripts/create-release.sh
	@./scripts/create-release.sh --prerelease

release-force: ## ⚡ Force create release even if tag exists (make release-force VERSION=v1.2.0)
ifndef VERSION
	@echo "${RED}❌ Error: VERSION parameter required. Usage: make release-force VERSION=v1.2.0${RESET}"
	@exit 1
endif
	@echo "${BLUE}⚡ Force creating GitHub release ${VERSION}:${RESET}"
	@chmod +x scripts/create-release.sh
	@./scripts/create-release.sh $(VERSION) --force

# Docker commands
docker-setup-network: ## 🌐 Creates required networks
	@echo "${BLUE}🌐 Creating docker networks(if not exists):${RESET}"
	@for NETWORK in $(DOCKER_NETWORKS) ; do \
		echo " ${GREEN}🔗 $$NETWORK${RESET}" ; \
		docker network create $$NETWORK >/dev/null 2>&1 || true ; \
	done

docker-build: docker-setup-network ## 🐳 Build Docker image
	@echo "${BLUE}🐳 Building Docker image:${RESET}"
	cd apps/docker-setup && docker-compose build
	@echo " ${GREEN}✓ Docker image built${RESET}"

docker-start: docker-setup-network ## 🚀 Start Docker services
	@echo "${BLUE}🚀 Starting Docker services:${RESET}"
	cd apps/docker-setup && docker-compose up -d
	@echo " ${GREEN}✓ Docker services started${RESET}"

docker-stop: ## 🛑 Stop Docker services
	@echo "${BLUE}🛑 Stopping Docker services:${RESET}"
	cd apps/docker-setup && docker-compose down
	@echo " ${GREEN}✓ Docker services stopped${RESET}"

docker-logs: ## 📋 Show Docker logs
	@echo "${BLUE}📋 Docker logs:${RESET}"
	cd apps/docker-setup && docker-compose logs -f

docker-restart: docker-stop docker-start ## 🔄 Restart Docker services

docker-rebuild: docker-stop docker-build docker-start ## 🔧 Rebuild and restart Docker
