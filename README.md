# space2stats-stata: Query Space2Stats Datasets at ADM 0-2 Levels

__THIS PACKAGE IS CURRENTLY UNDER DEVELOPMENT.__

A Stata package to easily load, filter, and merge datasets from the World Bank's [Space2Stats](https://worldbank.github.io/DECAT_Space2Stats/readme.html) initiative at the ADM 2, 1, and 0 level. The packages queries data from two Space2Stat Development Data Hub (DDH) repositories:

* The main [Space2Stats Database](https://datacatalog.worldbank.org/int/search/dataset/0066820/Space2Stats-Database), to query data on:
  - Population Demographics, 2020 ([WorldPop](https://www.worldpop.org/))
  - Degree of Urbanization ([GHS-SMOD](https://human-settlement.emergency.copernicus.eu/ghs_smod2023.php))
  - Annual Nighttime Lights (2012 to present) ([World Bank, Light Every Night](https://worldbank.github.io/OpenNightLights/wb-light-every-night-readme.html))
  - Flood Exposure ([Fathom v3](https://www.fathom.global/newsroom/fathom-launches-global-flood-map/) and [WorldPop](https://www.worldpop.org/))

* The [Space2Stats Database of Monthly and Annual Black Marble Nighttime Lights](https://datacatalog.worldbank.org/int/search/dataset/0066940/Space2Stats-Monthly---Annual-Black-Marble-Nighttime-Lights), to query data on:
  - Annual Nighttime Lights (2012 to present) ([NASA, Black Marble](https://blackmarble.gsfc.nasa.gov/))
  - Monthly Nighttime Lights (2012 to present) ([NASA, Black Marble](https://blackmarble.gsfc.nasa.gov/))

*__Note:__ The main Space2Stats database aggregates data at the H3 level to the ADM2 level, and the temporal resolution is annual. The Space2Stats Black Marble database is separate, as the data are aggregated from raw satellite imagery to the ADM2 level and include monthly data.*

## Overview

`query_s2s` simplifies access to multiple World Bank spatial datasets by:
- Loading data directly from the World Bank Development Data Hub (DDH)
- Filtering by country and date range
- Merging multiple datasets automatically
- Aggregating to different administrative levels (ADM0, ADM1, or ADM2)
- Handling temporal data (annual and monthly) efficiently

## Installation

```stata
net install space2stats-stata, from("https://raw.githubusercontent.com/worldbank/space2stats-stata/main/src") replace
```

## Syntax

```stata
query_s2s, ///
    datasets(string) ///
    [
        iso3(string) ///
        date_start(string) ///
        date_end(string) ///
        adm_level(integer 2)
        add_admin_names(integer 0)
    ]
```

## Parameters

### Required Parameters

- **`datasets(string)`**: One or more datasets to load (space-separated)
  - `ntl_viirs_bm_annual` - Nighttime lights (VIIRS, [NASA Black Marble](https://blackmarble.gsfc.nasa.gov/)), annual (2012 to present)
  - `ntl_viirs_bm_monthly` - Nighttime lights (VIIRS, [NASA Black Marble](https://blackmarble.gsfc.nasa.gov/)), monthly (2012 to present)
  - `ntl_viirs_len_annual` - Nighttime lights (VIIRS, [World Bank Light Every Night](https://worldbank.github.io/OpenNightLights/wb-light-every-night-readme.html)), annual (2012 to present)
  - `flood_exposure` - Flood exposure data ([Fathom v3](https://www.fathom.global/newsroom/fathom-launches-global-flood-map/) and [WorldPop](https://www.worldpop.org/))
  - `population_2020` - Population data for 2020 ([WorldPop](https://www.worldpop.org/))
  - `urbanization` - Urbanization data ([GHS-SMOD](https://human-settlement.emergency.copernicus.eu/ghs_smod2023.php))

### Optional Parameters

- **`iso3(string)`**: Filter by ISO3 country codes (space-separated)
  - Example: `iso3(USA MEX CAN)`
  - If omitted, loads data for all countries

- **`date_start(string)`**: Start date for temporal filtering
  - Format: `yyyy-mm-dd` or `yyyy`
  - Only applies to NTL datasets
  - Example: `date_start(2020-01-01)` or `date_start(2020)`

- **`date_end(string)`**: End date for temporal filtering
  - Format: `yyyy-mm-dd` or `yyyy`
  - Only applies to NTL datasets
  - Example: `date_end(2023-12-31)` or `date_end(2023)`

- **`adm_level(integer)`**: Administrative level for aggregation
  - `0` - Country level (ADM0)
  - `1` - First administrative division (ADM1, e.g., states/provinces)
  - `2` - Second administrative division (ADM2, e.g., counties/districts) **[default]**

- **`add_admin_names(integer)`**: Add administrative level 1 and 2 names; names come from the [World Bank Official Boundaries Admin 2 - Additional Attributes](https://datacatalog.worldbank.org/int/search/dataset/0038272/World-Bank-Official-Boundaries) dataset
  - `0` - False **[default]**
  - `1` - True
  
## Important Notes

### Dataset Compatibility
- **Cannot combine** `ntl_viirs_bm_monthly` with `ntl_viirs_bm_annual` or `ntl_viirs_len_annual` due to different temporal structures
- All other dataset combinations are supported

### Date Filtering
- Date filtering only applies to NTL datasets
- Non-NTL datasets (flood_exposure, population_2020, urbanization) represent single time periods

## Examples

### Example 1: Load Single Dataset for One Country
```stata
query_s2s, datasets(population_2020) iso3(USA)
```

### Example 2: Load Multiple Datasets for Multiple Countries
```stata
query_s2s, datasets(population_2020 flood_exposure urbanization) iso3(USA MEX CAN)
```

### Example 3: Load Annual NTL Data with Date Filter
```stata
query_s2s, datasets(ntl_viirs_bm_annual) iso3(USA) date_start(2020) date_end(2023)
```

### Example 4: Load Monthly NTL Data for Specific Date Range
```stata
query_s2s, datasets(ntl_viirs_bm_monthly) iso3(MEX) date_start(2020-01-01) date_end(2021-12-31)
```

### Example 5: Aggregate to ADM1 (State/Province) Level
```stata
query_s2s, datasets(ntl_viirs_bm_annual population_2020) iso3(USA) adm_level(1)
```

### Example 6: Aggregate to ADM0 (Country) Level
```stata
query_s2s, datasets(ntl_viirs_bm_annual flood_exposure) iso3(USA MEX CAN) adm_level(0)
```

### Example 7: Load Multiple NTL Datasets (Annual Only)
```stata
query_s2s, datasets(ntl_viirs_bm_annual ntl_viirs_len_annual) iso3(BRA) date_start(2015) date_end(2023)
```

### Example 8: Load All Static Datasets for a Region
```stata
query_s2s, datasets(flood_exposure population_2020 urbanization) iso3(IND BGD PAK)
```

### Example 9: Time Series Analysis at Country Level
```stata
query_s2s, datasets(ntl_viirs_bm_annual) iso3(CHN IND) date_start(2012) date_end(2024) adm_level(0)
```

### Example 10: Comprehensive Dataset at ADM2 Level
```stata
query_s2s, datasets(ntl_viirs_bm_annual flood_exposure population_2020 urbanization) iso3(USA)
```

## Output

The function loads the requested datasets into Stata's memory with:
- Automatic merging based on administrative codes and temporal variables
- Variable labels indicating the source dataset
- A summary showing:
  - Datasets loaded
  - Administrative level
  - Countries (if filtered)
  - Date range (if specified)
  - Number of observations
  - List of variables

## Technical Details

### Aggregation Logic
When `adm_level` is set to 1 or 0, the function aggregates data using:
- **Sum**: Population counts, night-time lights totals
- **Mean**: Average statistics, percentages
- **Max**: Maximum values

### Merge Strategy
- Datasets with matching temporal structures (year or date) use 1:1 merges
- Static datasets (no time dimension) use m:1 merges with temporal datasets
- Merge keys adjust automatically based on `adm_level`

## Troubleshooting

### Common Issues

**Issue**: Error loading data
- **Solution**: Check your internet connection; data is loaded from World Bank APIs

**Issue**: "Cannot combine monthly and annual datasets"
- **Solution**: Use separate queries for monthly vs. annual NTL data

**Issue**: Out of memory
- **Solution**: Filter by specific countries or date ranges to reduce data size

**Issue**: Variables not found after collapse
- **Solution**: Check that the requested datasets contain the expected variables

## Authors

Stata package developed by Robert Marty (rmarty@worldbank.org) and Sahiti Sarva (ssarva@worldbank.org).

## License

This project is licensed under the MIT License together with the [World Bank IGO Rider](WB-IGO-RIDER.md). The Rider is purely procedural: it reserves all privileges and immunities enjoyed by the World Bank, without adding restrictions to the MIT permissions. Please review both files before using, distributing or contributing.

## Citation

If you use this function in your research, please cite the underlying datasets from the World Bank Data Catalog and acknowledge the Space2Stats initiative.


