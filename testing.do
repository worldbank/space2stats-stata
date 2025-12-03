* Testing

* FUNCTIONS
* -- space2stats: Get data
* -- Something to get geojson of map? 
* -- Or just do something just for black marble originally?

* WITHIN FUNCTION
* -- Add 

* s2s-blackmarble
* Arguments
* -- time_unit [required]
* -- iso [if blank, all]
* -- start_date [if blank, all]
* -- end_date [if blank, all]
* -- metric [sum, mean, median,  -- can take multiple]
* -- pixles_include [all, only_near_gas_flare, exclude_near_gas_flare]
* -- gas_flare_buffer_km [5, 10 -- can take multiple]
* -- quality_vars_include [TRUE vs FALSE]


* space2stats
* Description: Extract variables at ADM 2 level
* Arguments
* -- variables_timevary [Think for black marble]
* -- variables_constime []
* -- iso3 [can be multiple; blank for all countries]
* -- time_unit [annual vs month]. Specify which variables for each.
* -- start_date []

import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095354/adm2_space2stats_population_2020.csv", clear

*import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv", clear
*import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095356/adm2_VIIRS.csv", clear
*import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095357/adm2_urbanization_ghssmod.csv", clear


