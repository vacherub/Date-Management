# Date-Management

A Perl script to calculate working days or list public holidays using the [Nager.at API](https://date.nager.at).

## Usage

```
dates.pl -s|--start YYYY-MM-DD [-e|--end YYYY-MM-DD] [-c|--country XX]
dates.pl -l|--list [YYYY] [-c|--country XX]
dates.pl -C|--list-countries
dates.pl -h|--help
```

## Modes

### 1. Calculate working days (`-s` / `-e`)
Computes calendar days, weekends, holidays, and working days between two dates.

```
dates.pl -s 2026-01-01 -e 2026-01-31 -c US
```

### 2. List holidays (`-l`)
Lists all public holidays for a given year (defaults to current year).

```
dates.pl -l 2026 -c IT
```

### 3. List available countries (`-C`)
Shows all country codes supported by the API.

```
dates.pl -C
```

## Parameters

| Short | Long | Description |
|-------|------|-------------|
| `-s` | `--start YYYY-MM-DD` | Start date (ISO 8601). Required in calculation mode. |
| `-e` | `--end YYYY-MM-DD` | End date (ISO 8601). Defaults to today. |
| `-c` | `--country XX` | ISO 3166-1 alpha-2 country code. Default: `IT`. |
| `-l` | `--list [YYYY]` | Year to list holidays for. Defaults to current year. |
| `-C` | `--list-countries` | List all supported country codes. |
| `-h` | `--help` | Show help. |

## Requirements

- Perl 5.10+
- Modules: `DateTime`, `DateTime::Format::Strptime`, `LWP::UserAgent`, `JSON`, `Carp`, `Locale::Country`
