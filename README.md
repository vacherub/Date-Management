# Date-Management v1.0

Cálculo de días laborables y consulta de días festivos usando la [API Nager.at](https://date.nager.at).

## Descripción

Script en Perl que, desde terminal, permite calcular días laborables entre dos fechas (excluyendo fines de semana y días festivos) o listar los días festivos de cualquier país soportado por la API Nager.at.

## Modos de uso

### 1. Calcular días laborables (`-s` / `-e`)
Computa días calendario, fines de semana, festivos y días laborables entre dos fechas.

```
dates.pl -s 2026-01-01 -e 2026-01-31 -c US
```

### 2. Listar festivos (`-l`)
Lista todos los días festivos de un año (por defecto el año actual).

```
dates.pl -l 2026 -c IT
```

### 3. Listar países disponibles (`-C`)
Muestra todos los códigos de país soportados por la API.

```
dates.pl -C
```

## Parámetros

| Parámetro | Corto | Valor por defecto | Descripción |
|-----------|-------|-------------------|-------------|
| `--start` | `-s` | — | Fecha inicio (ISO 8601). Obligatorio en modo cálculo. |
| `--end` | `-e` | Hoy | Fecha fin (ISO 8601). |
| `--country` | `-c` | `IT` | Código país ISO 3166-1 alpha-2. |
| `--list` | `-l` | Año actual | Año del que listar festivos. |
| `--list-countries` | `-C` | — | Listar todos los países soportados. |
| `--help` | `-h` | — | Muestra ayuda. |

### Ejemplos

```bash
dates.pl -s 2026-01-01 -e 2026-01-31           # Italia, enero 2026
dates.pl -s 2026-06-01 -e 2026-06-30 -c US     # USA, junio 2026
dates.pl -l 2026 -c IT                          # Festivos Italia 2026
dates.pl -l 2026 -c JP                          # Festivos Japón 2026
dates.pl -C                                     # Países disponibles
dates.pl -h                                     # Ayuda
```

## Fuente de datos

- **Nager.at API v3** — gratuita, sin API key requerida. Datos oficiales de días festivos para más de 100 países.

## Proceso

1. **Fetch** — consulta a la API Nager.at (`/PublicHolidays/{year}/{country}` o `/AvailableCountries`).
2. **Parseo** — decodifica la respuesta JSON con los festivos del año.
3. **Cálculo** — itera día por día entre las fechas, clasificando en:
   - Fin de semana (sábado/domingo)
   - Festivo en día laborable
   - Día laborable
4. **Reporte** — muestra resumen con totales y desglose.

## Salida

El reporte incluye:

1. Período analizado y país
2. Total de días calendario
3. Desglose de no laborables (findes de semana + festivos en semana)
4. Total de días laborables

## Requisitos

- Perl 5.10+
- Módulos: `DateTime`, `DateTime::Format::Strptime`, `LWP::UserAgent`, `JSON`, `Carp`, `Locale::Country`

## History

- **v1.0** — Versión inicial
