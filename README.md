# MTGtrade scanner

CLI-tool for looking up the best prices for Magic the Gathering cards on [mtgtrade.net](https://mtgtrade.net/) marketplace.

Built for my own personal use. Work in progress.

## Getting Started

1. Install dependencies
```
bundle
```
2. Prepare dabatase (requires PostgreSQL)
```
rake db_create db_migrate db_seed
```

### Executing program

Scrape the marketplace for specific cards:
```
rake scrape_offers
```

Show offers grouped by sellers
```
rake show_offers
```
See `--help` for additional options
```
rake show_offers -- --help
```

## Authors

Sergey Tomashevsky
