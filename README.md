# Shipping Route and Rate Search Service

## Overview

This service allows you to search for shipping routes between ports based on various criteria (cheapest, fastest, direct only, etc.), including currency conversion and route cost calculation.

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

See the structure example below.

### 3. Run the Application

You can start the program in two ways:

```bash
ruby application/main.rb
```
or
```bash
bin/route_finder
```

### 4. Input Parameters

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

### 5. Run Tests

```bash
rake test
rake coverage
```

The coverage report will be generated in the `coverage/` directory and will open in your browser when using the `rake coverage` command.

### 6. Run with Docker

```bash
docker build -t route-finder .
docker run -it --rm -v "$PWD/data.json:/app/data.json" route-finder
```

#### Run tests in Docker

```bash
docker run --rm -it route-finder bundle exec rake test
```

#### Run with parameters via Docker

```bash
echo -e "CNSHA\nNLRTM\ncheapest" | docker run -i --rm -v "$PWD/data.json:/app/data.json" route-finder
```

---

## Environment Variables

The following environment variables control the application behavior:

- `RETURN_MULTIPLE_ROUTES` — if `true`, the program outputs all routes matching the search criteria (e.g. all cheapest or fastest routes). If `false`, only one optimal route is shown.
- `OUTPUT_FORMAT` — output format. Currently only `json` is supported, but this variable is reserved for future expansion.
- `COVERAGE` — if `true`, enables code coverage collection with simplecov when running tests.
- `INPUT_TYPE` — input method for search parameters. Default is `stdin` (keyboard input), but the variable is reserved for future expansion.
- `MAX_LEGS` — maximum number of legs in an indirect route. Limits the search depth for complex routes.
- `DATA_FILE` — name of the data file for searching routes and rates (default is `data.json`).

Example usage:

```bash
RETURN_MULTIPLE_ROUTES=true OUTPUT_FORMAT=json MAX_LEGS=4 DATA_FILE=data.json ruby application/main.rb
```

Or with Docker:

```bash
docker run -e RETURN_MULTIPLE_ROUTES=true -e OUTPUT_FORMAT=json -e MAX_LEGS=4 -e DATA_FILE=data.json -it --rm -v "$PWD/data.json:/app/data.json" route-finder
```

---

## Output Features

- Output format is controlled by the `OUTPUT_FORMAT` variable (default: JSON).
- If multiple routes fully match the criteria (e.g. several cheapest or fastest), and `RETURN_MULTIPLE_ROUTES=true`, the response will be an array of routes.
- Each route (or route leg) is represented as a separate object with detailed information.

### Example `data.json` structure

```json
{
  "sailings": [
    {
      "sailing_code": "ERXQ",
      "origin_port": "CNSHA",
      "destination_port": "ESBCN",
      "departure_date": "2022-01-29",
      "arrival_date": "2022-02-06"
    },
    {
      "sailing_code": "ETRG",
      "origin_port": "ESBCN",
      "destination_port": "NLRTM",
      "departure_date": "2022-02-16",
      "arrival_date": "2022-02-20"
    }
    // ... more sailings ...
  ],
  "rates": [
    {
      "sailing_code": "ERXQ",
      "amount": "261.96",
      "currency": "EUR"
    },
    {
      "sailing_code": "ETRG",
      "amount": "69.96",
      "currency": "USD"
    }
    // ... more rates ...
  ],
  "exchange_rates": [
    {
      "date": "2022-01-29",
      "usd": 1.1138,
      "eur": 1.0
    },
    {
      "date": "2022-02-16",
      "usd": 1.1350,
      "eur": 1.0
    }
    // ... more rates ...
  ]
}
```

### Example program output

For the cheapest route (possibly with a transfer):

```json
[
  {
    "origin_port": "CNSHA",
    "destination_port": "ESBCN",
    "departure_date": "2022-01-29",
    "arrival_date": "2022-02-06",
    "sailing_code": "ERXQ",
    "rate": "261.96",
    "rate_currency": "EUR"
  },
  {
    "origin_port": "ESBCN",
    "destination_port": "NLRTM",
    "departure_date": "2022-02-16",
    "arrival_date": "2022-02-20",
    "sailing_code": "ETRG",
    "rate": "69.96",
    "rate_currency": "USD"
  }
]
```

For a direct route, the response will contain only one object.

### Example output with RETURN_MULTIPLE_ROUTES=true

If `RETURN_MULTIPLE_ROUTES` is set to `true`, the program may return several routes, each matching the selected criteria. In this case, the response is an array of routes, where each route is an array of legs:

```
RETURN_MULTIPLE_ROUTES=true OUTPUT_FORMAT=json MAX_LEGS=4 DATA_FILE=data.json ruby application/main.rb
CNSHA
NLRTM
cheapest
[
  [
    {
      "origin_port": "CNSHA",
      "destination_port": "ESBCN",
      "departure_date": "2022-01-29",
      "arrival_date": "2022-02-12",
      "sailing_code": "ERXQ",
      "rate": "261.96",
      "rate_currency": "EUR"
    },
    {
      "origin_port": "ESBCN",
      "destination_port": "NLRTM",
      "departure_date": "2022-02-16",
      "arrival_date": "2022-02-20",
      "sailing_code": "ETRG",
      "rate": "69.96",
      "rate_currency": "USD"
    }
  ]
]
```

Each nested array is a separate route consisting of one or more legs.

---

## Search Criteria

- `cheapest-direct` — Cheapest direct sailing
- `cheapest` — Cheapest route (may include transfers)
- `fastest` — Fastest route (by total journey time)

---

## Key Components

- **JsonRepository** — loads sailings, rates, and exchange rates from JSON
- **RouteSearchStrategyFactory** — selects the search strategy by criteria
- **RouteFinder** — finds routes using the selected strategy
- **UniversalConverter** — converts currencies by date
- **OutputHandler** — formats and prints the result

## Contacts
Questions and suggestions: sedovolosiy@gmail.com
