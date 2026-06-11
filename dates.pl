#!/usr/bin/env perl
use strict;
use warnings;
use 5.010; 
use utf8;  

# --- Configure STDOUT and STDERR for UTF-8 ---
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# --- Required modules ---
use Getopt::Long qw(:config no_ignore_case bundling);
use DateTime;
use DateTime::Format::Strptime; 
use LWP::UserAgent;
use JSON qw(decode_json);
use Carp qw(croak);
use Locale::Country qw(code2country); 

# --- Constants and Global Variables ---
use constant {
    SATURDAY => 6,
    SUNDAY   => 7,
};
my $API_BASE        = 'https://date.nager.at/api/v3';
my $DEFAULT_COUNTRY = 'IT'; 

# Parameter variables
my ($start_str, $end_str, $country_code, $list_year_str, $list_countries_flag, $help_flag);

# --- 1. Parameter Parsing ---
my $getopt_result = GetOptions(
    'start|s=s'           => \$start_str,
    'end|e=s'             => \$end_str,
    'country|c=s'         => \$country_code,
    'list|l:s'            => \$list_year_str,
    'list-countries|C'    => \$list_countries_flag,
    'help|h'              => \$help_flag,
);

unless ($getopt_result) {
    croak "Error parsing parameters. Use --help for options.";
}

# --- 2. Control Variable Preparation and Strict Cleanup ---
$country_code = defined $country_code ? uc($country_code) : $DEFAULT_COUNTRY;
$country_code =~ s/\s+//g; 

my $display_country_name = code2country(lc($country_code)) || "Unknown Country ($country_code)";

# Single help text with explicit ISO specifications
my $help_text = <<EOF;
Usage:
  $0 -s|--start YYYY-MM-DD [-e|--end YYYY-MM-DD] [-c|--country XX]
  $0 -l|--list [YYYY] [-c|--country XX]
  $0 -C|--list-countries
  $0 -h|--help

Description: Calculate working days or list holidays using the Nager.at API.

Parameters:
  -s, --start YYYY-MM-DD   Start date (required in Calculation Mode).
                            Must follow ISO 8601 international date standard (e.g. 2026-01-01).
  -e, --end YYYY-MM-DD     End date. Optional (default: today).
                            Must follow ISO 8601 international date standard (e.g. 2026-06-08).
  -c, --country XX         Two-letter country code per ISO 3166-1 alpha-2.
                            Default: $country_code ($display_country_name).
  -l, --list [YYYY]        Year to list holidays for. Optional (default: current year).
  -C, --list-countries     List all valid ISO 3166-1 alpha-2 country codes
                            available in the API.
  -h, --help               Show this help.
EOF

# Show help if requested or if required parameters are missing
if ($help_flag || (!defined $start_str && !defined $list_year_str && !$list_countries_flag)) {
    print $help_text;
    exit 0;
}

# Validate that incompatible modes are not mixed
if (($list_countries_flag && $start_str) || ($list_countries_flag && defined $list_year_str) || (defined $list_year_str && $start_str)) {
    croak "Error: Cannot mix main modes ('--start', '--list', or '--list-countries').";
}

# --- User agent configuration ---
my $ua = LWP::UserAgent->new(timeout => 15, env_proxy => 1, ssl_opts => { verify_hostname => 1 });
$ua->agent("$0/1.1 (script)"); 
$ua->default_header('Accept' => 'application/json'); 

# =================================================================================
# --- MODE 1: LIST COUNTRIES ---
# =================================================================================
if ($list_countries_flag) {
    my $url = "$API_BASE/AvailableCountries";
    my $res = $ua->get($url);
    
    unless ($res->is_success) {
        croak sprintf("Critical network error (HTTP %s): %s", $res->code, $res->status_line);
    }

    if ($res->content =~ /^\s*<!DOCTYPE html/i) {
        croak "Critical error: The API firewall intercepted the request returning HTML.";
    }

    my $raw_content = $res->content;
    my $data;
    if (defined $raw_content && $raw_content ne '') {
        eval { $data = decode_json($raw_content); };
        croak "Error decoding JSON for countries: $@" if $@;
    }
    $data //= [];

    if (@$data) {
        foreach my $country (sort { ($a->{countryCode} || '') cmp ($b->{countryCode} || '') } @$data) {
            my $code = $country->{countryCode} || '??';
            say sprintf("(%s) %s", uc($code), $country->{name} || 'No name');
        }
    }
    exit 0;
}

# =================================================================================
# --- MODE 2: LIST HOLIDAYS ---
# =================================================================================
if (defined $list_year_str) {
    if ($list_year_str eq '') {
        $list_year_str = DateTime->now(time_zone => 'local')->year;
    }

    unless ($list_year_str =~ /^\d{4}$/) {
        croak "Error: '--list' requires a valid 4-digit year. Received: '$list_year_str'";
    }
    
    my $url = "$API_BASE/PublicHolidays/$list_year_str/$country_code";
    my $res = $ua->get($url);
    
    unless ($res->is_success) {
        croak sprintf("API error: No records found for country '%s' in year '%s' (HTTP %s)", 
                      $country_code, $list_year_str, $res->code);
    }

    if ($res->content =~ /^\s*<!DOCTYPE html/i) {
        croak "Critical error: The remote server returned an HTML page instead of structured data.";
    }

    my $raw_content = $res->content;
    my $data;
    if (defined $raw_content && $raw_content ne '') {
        eval { $data = decode_json($raw_content); };
        croak "Error decoding JSON: the API did not return a valid structure. $@" if $@;
    }
    $data //= [];

    if (@$data) {
        foreach my $holiday (sort { $a->{date} cmp $b->{date} } @$data) {
            my $local_name   = $holiday->{localName} || '';
            my $english_name = $holiday->{name}      || '';
            my $final_name   = $local_name;

            if ($final_name eq '') {
                $final_name = $english_name;
            }
            elsif ($english_name ne '' && $local_name ne $english_name) {
                $final_name .= " ($english_name)";
            }

            say sprintf("%s - %s", $holiday->{date}, $final_name);
        }
    }
    exit 0;
}

# =================================================================================
# --- MODE 3: DAY CALCULATION ---
# =================================================================================
unless ($end_str) {
    $end_str = DateTime->now(time_zone => 'local')->truncate(to => 'day')->ymd('-');
}

my $strptime_parser = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d', time_zone => 'local', on_error => 'croak'
);

my ($start_dt, $end_dt);
eval {
    $start_dt = $strptime_parser->parse_datetime($start_str);
    $end_dt    = $strptime_parser->parse_datetime($end_str);
};
croak "Error parsing dates (use YYYY-MM-DD per ISO 8601): $@" if $@;

if ($start_dt->compare($end_dt) == 1) {
    ($start_dt, $end_dt) = ($end_dt, $start_dt);
}

my %holidays_dates;
for my $year ($start_dt->year .. $end_dt->year) {
    my $url = "$API_BASE/PublicHolidays/$year/$country_code";
    my $res = $ua->get($url);
    
    unless ($res->is_success) {
        croak sprintf("API error for year %s: Country '%s' not supported or connection error (HTTP %s)", 
                      $year, $country_code, $res->code);
    }

    # NOTE: Removed strict content-type regex check; only verify if content starts with actual HTML
    if ($res->content =~ /^\s*<!DOCTYPE html/i) {
        croak "Critical error in year $year: Server returned HTML instead of JSON.";
    }

    my $raw_content = $res->content;
    if (defined $raw_content && $raw_content ne '') {
        my $data;
        eval { $data = decode_json($raw_content); };
        croak "JSON error for year $year: $@" if $@;
        
        if (defined $data) {
            $holidays_dates{$_->{date}} = 1 for @$data;
        }
    }
}

my ($total_calendar_days, $weekend_days, $holiday_only_days) = (0, 0, 0);
my $current_dt = $start_dt->clone;

while ($current_dt->compare($end_dt) <= 0) {
    $total_calendar_days++;
    my $day_of_week = $current_dt->day_of_week;
    my $is_weekend  = ($day_of_week == SATURDAY || $day_of_week == SUNDAY);
    my $is_holiday  = exists $holidays_dates{$current_dt->ymd('-')};

    if ($is_weekend) {
        $weekend_days++;
    }
    elsif ($is_holiday) {
        $holiday_only_days++;
    }

    $current_dt->add(days => 1);
}

my $total_non_working_days = $weekend_days + $holiday_only_days;
my $working_days           = $total_calendar_days - $total_non_working_days;

say "";
say "--- Day Analysis Summary ---";
say "";
say "Period analyzed: " . $start_dt->ymd('-') . " to " . $end_dt->ymd('-');
say "Country: $display_country_name";
say "";
say "1. Total calendar days: $total_calendar_days days";
say "2. Non-working days: $total_non_working_days days, of which:";
say "   - Weekends: $weekend_days days";
say "   - Holidays (weekdays): $holiday_only_days days";
say "3. Working days: $working_days days";

exit 0;

