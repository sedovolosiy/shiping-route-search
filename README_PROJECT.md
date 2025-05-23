# Project Guide: Shipping Route and Rate Search

## Overview
This project implements a service for searching shipping routes between ports based on various criteria (cheapest, fastest, direct, etc.), including currency conversion and route cost calculation.

## Project Structure

- `application/` — main business logic and services
  - `main.rb` — entry point, application startup
  - `boot.rb` — dependency loading and initialization
  - `services/` — services for route search, input/output handling, etc.
    - `route_search/` — route search strategies (direct, cheapest, fastest)
    - `currency/` — currency conversion services
- `domain/` — domain models and contracts
  - `models/` — models: sailings, rates, exchange rates
  - `contracts/` — abstract classes (interfaces) for strategies and converters
- `infrastructure/` — infrastructure components
  - `repositories/` — loading data from JSON
  - `utils/` — input parsers, output serializers
- `tests/` — unit tests (Minitest)
- `data.json` — sample input data (sailings, rates, exchange rates)
- `Dockerfile` — for containerized runs
- `Gemfile`, `Gemfile.lock` — Ruby dependencies

## How to Run

### 1. Install Dependencies

```bash
bundle install
```

### 2. Prepare Input Data

The `data.json` file must contain the following keys:
- `sailings` — array of sailings
- `rates` — array of rates
- `exchange_rates` — exchange rates by date

See the sample structure in `data.json`.

### 3. Run the Application

```bash
ruby application/main.rb
```

#### Input
By default, the application expects input from the keyboard (stdin):
1. Origin port code (e.g. CNSHA)
2. Destination port code (e.g. NLRTM)
3. Search criteria (`cheapest`, `cheapest-direct`, `fastest`)

Example:
```
CNSHA
NLRTM
cheapest
```

#### Output Format
Default is JSON. You can change it via the `OUTPUT_FORMAT` environment variable (only `json` is supported).

### 4. Run Tests

```bash
# Run all tests
rake test

# Run tests with coverage report
rake coverage
```

The coverage report will be generated in the `coverage/` directory and will automatically open in your browser when using the `rake coverage` command.

### 5. Run with Docker

```bash
docker build -t route-finder .
docker run -it --rm -v "$PWD/data.json:/app/data.json" route-finder
```
#### 5.1 Run tests with Docker

```bash
docker run --rm -it route-finder bundle exec rake test
```

### 6. Run with Docker and Provide Input Parameters

By default, the application expects interactive input (stdin).  
To provide parameters non-interactively, you can use input redirection or `echo`:

**Example using `echo`:**
```bash
echo -e "CNSHA\nNLRTM\ncheapest" | docker run -i --rm -v "$PWD/data.json:/app/data.json" route-finder
```

This command will:
- Pass `CNSHA` as the origin port,
- `NLRTM` as the destination port,
- `cheapest` as the search criteria,
to the application running inside the Docker container.

You can replace the values as needed for your test case.

> **Note:**  
> If you previously built your Docker image with a different name (for example, `shipping-app`), use that name in the run command instead of `route-finder`.  
>  
> You can check your local images with:
> ```bash
> docker images
> ```
>  
> If needed, rebuild the image with the desired name:
> ```bash
> docker build -t route-finder .
> `````

## Key Components

- **JsonRepository** — loads sailings, rates, and exchange rates from JSON
- **RouteSearchStrategyFactory** — selects the search strategy by criteria
- **RouteFinder** — finds routes using the selected strategy
- **UniversalConverter** — converts currencies by date
- **OutputHandler** — formats and prints the result

## Contacts
Questions and suggestions: sedovolosiy@gmail.com
