# GitHub Actions CI/CD

This project includes automated testing and quality checks via GitHub Actions.

## Workflows

### Main CI Workflow (`ci.yml`)
- **Triggers**: Push to main/master/develop branches, Pull Requests
- **Ruby versions tested**: 3.2, 3.3, 3.4
- **Features**:
  - Runs full test suite with coverage reporting
  - Syntax checking for all Ruby files
  - Docker image build and basic functionality test
  - Coverage upload to Codecov

### Simple Test Workflow (`test.yml`)
- **Triggers**: Same as main CI
- **Features**:
  - Focused on running tests with Ruby 3.4
  - Generates and uploads coverage artifacts
  - Lightweight alternative to the full CI workflow

## Setup Requirements

The workflows automatically:
1. Install Ruby and dependencies using Bundler
2. Create `.env` file with `COVERAGE=true` for test coverage
3. Run tests using `bundle exec rake test`
4. Generate coverage reports via SimpleCov

## Coverage Reports

Coverage reports are:
- Generated for each test run when `COVERAGE=true`
- Uploaded to Codecov (main CI workflow)
- Available as downloadable artifacts (test workflow)
- Stored in the `coverage/` directory

## Running Tests Locally

To run tests with the same setup as CI:

```bash
# Install dependencies
bundle install

# Create .env file for coverage
echo "COVERAGE=true" > .env

# Run tests
bundle exec rake test

# View coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

## Docker Testing

The CI also validates the Docker setup:

```bash
# Build the image
docker build -t shipping-app .

# Test with sample input (port origin, destination, criteria)
echo -e "CNSHA\nNLRTM\ncheapest" | docker run -i --rm -v "$PWD/data.json:/app/data.json" shipping-app
```

Note: The application expects input via stdin in this format:
1. Origin port code (e.g., CNSHA)
2. Destination port code (e.g., NLRTM) 
3. Search criteria (cheapest, fastest, cheapest-direct)
