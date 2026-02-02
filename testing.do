* Testing

import delimited ///
    "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095685/ntl_adm2_annual.csv", ///
    clear bindquote(strict)
	
keep adm2cd_c adm1cd_c
	
duplicates drop adm2cd_c adm1cd_c, force
	
xx
	
keep adm2cd_c adm1cd_c

gen adm_alt = substr(adm2cd_c, 1, strlen(adm2cd_c) - 3)
	
gen eq = adm_alt == adm1cd_c	

table eq
STOP
	
	
I want to add a parameter to the function that is: adm_level. The default should be 2, but should also accept 1 and 0.

Here's what this should do:

If adm = 2, nothing should change.

If adm = 1, at the end of the code the data should be collapsed to the ADM1 level. Here's the relevant code to use for collapsing:

* ntl_viirs_bm_annual
collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
		       ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
			   ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
			   ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
			   ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
        by(iso3 adm1cd_c nam_0 nam_1 year) 

* ntl_viirs_bm_monthly
collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
		       ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
			   ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
			   ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
			   ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
        by(iso3 adm1cd_c nam_0 nam_1 date) 
		
* ntl_viirs_csm_annual
collapse (sum) sum_viirs_ntl, by(iso3 adm1cd_c year) 
		
* flood_exposure
collapse (sum) pop pop_flood (mean) pop_flood_pct, by(iso3 adm1cd_c) 

* population_2020
collapse (sum) sum_*, by(iso3 adm1cd_c) 

* urbanization
collapse (sum) ghs_*, by(iso3 adm1cd_c) 

If adm = 0, the same as for adm = 1, but in collapse should be: by(iso3 nam_0) 

Make the following changes:

1. At the very end of the code, add this:

label var sum_viirs_ntl "Dataset: NTL VIIRS (Colorado School of Mines)"

foreach v of varlist ntl_* {
    label var `v' "Dataset: NTL VIIRS Black Marble"
}

foreach v of varlist ghs_* {
    label var `v' "Dataset: Urbanization, GHS-SMOD"
}

foreach v of varlist pop* {
    label var `v' "Dataset: Flood Exposure, Fathom v3 and WorldPop"
}

foreach v of varlist sum_pop* {
    label var `v' "Dataset: Population, WorldPop"
}

2. In beginning of code, create a check so that the "ntl_viirs_bm_monthly" cannot be specified with "ntl_viirs_bm_annual" or "ntl_viirs_csm_annual"


xx
	
* Simplify iso3 variable name
rename iso_a3 iso3

compress iso3 adm2cd_c adm1cd_c nam_0 nam_1 nam_2

* Some NTL variables loaded as string; need to convert to numeric
foreach var of varlist ntl_* {
    display "Converting: `var'"
    destring `var', replace force
}

xx

* Some repeated ADM1, such as Aruba; collapse to one
collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
		       ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
			   ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
			   ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
			   ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
        by(iso3 adm1cd_c adm2cd_c nam_0 nam_1 nam_2 year) 

* iso3 adm1cd_c adm2cd_c nam_0 nam_1 nam_2 year
STOP
	
sss

Write a stata function (.ado file) with the following:

1. Function name should be query_s2s

2. Function should have the following arguments:
2.1 iso3: List of country iso3 names, such as 'USA', 'MEX'. Can accept one or multiple

All datasets have an "iso3" variable, so this parameter should filter using "iso3"

2.2 datasets: Can be one or multiple of
-- ntl_viirs_bm_annual
-- ntl_viirs_bm_monthly
-- ntl_viirs_csm_annual
-- flood_exposure
-- population_2020
-- urbanization

Here the CSV files to load for the datasets:
-- ntl_viirs_bm_annual
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095685/ntl_adm2_annual.csv

-- ntl_viirs_bm_monthly
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095686/ntl_adm2_monthly_2012.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095687/ntl_adm2_monthly_2013.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095688/ntl_adm2_monthly_2014.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095689/ntl_adm2_monthly_2015.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095690/ntl_adm2_monthly_2016.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095691/ntl_adm2_monthly_2017.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095692/ntl_adm2_monthly_2018.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095693/ntl_adm2_monthly_2019.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095694/ntl_adm2_monthly_2020.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095695/ntl_adm2_monthly_2021.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095696/ntl_adm2_monthly_2022.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095697/ntl_adm2_monthly_2023.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095698/ntl_adm2_monthly_2024.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095699/ntl_adm2_monthly_2025.csv

-- ntl_viirs_csm_annual
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095356/adm2_VIIRS.csv

-- flood_exposure
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv

-- population_2020
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095354/adm2_space2stats_population_2020.csv

-- urbanization
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095357/adm2_urbanization_ghssmod.csv

2.3. date_start

2.4. date_end 

The date_start and date_end parameters are only relevant for the "ntl_" variables. Do not filter by date_start for other datasets (other datasets only represent one time period). This parameter can be in yyyy-mm-dd or yyyy format. Here's some logic for this:
- yyyy-mm-dd will only be relevant for ntl_viirs_bm_monthly, as the other datasets are annual. 
- If yyyy-mm-dd is entered, just assume jan 1 of the year for annual datasets 
- If yyyy is entered, also assume jan 1 for filtering monthly
- The "ntl_viirs_bm_monthly" is captured across multiple .csv files, one for each year. Multiple .csv files may need to be loaded depending on the date range.

Here are some other notes
- iso3 is optional.

Here's some other info:

- For the date variables:
-- The "ntl_viirs_bm_monthly" datasets have a "date" variable in a "yyyy-mm-dd" format (the variable is a string)
-- The "ntl_viirs_bm_annual" dataset has a variable "year" that is in "yyyy" format (its a numeric variable)
-- The "ntl_viirs_csm_annual" has variables like "sum_viirs_ntl_2012", "sum_viirs_ntl_2013".... This will need to be converted from wide to long format.

- If multiple datasets are specified, they should be merged using the "iso3" and "adm2cd_c" variables (ntl_ datasets will also have to be merged using date/year)

- The output should replace the current dataset in memory

- If date_start and date_end are not specified for the ntl datasets, all available data should be loaded

- For multiple inputs to a parameter (eg, iso3), expected syntax should be like: iso3(USA MEX) (ie, not comma separated - just a space)



iso3(USA, MEX)
Or comma-separated: iso3(USA, MEX)

ss
	

* Black Marble ----------
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095685/ntl_adm2_annual.csv

https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095686/ntl_adm2_monthly_2012.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095687/ntl_adm2_monthly_2013.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095688/ntl_adm2_monthly_2014.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095689/ntl_adm2_monthly_2015.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095690/ntl_adm2_monthly_2016.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095691/ntl_adm2_monthly_2017.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095692/ntl_adm2_monthly_2018.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095693/ntl_adm2_monthly_2019.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095694/ntl_adm2_monthly_2020.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095695/ntl_adm2_monthly_2021.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095696/ntl_adm2_monthly_2022.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095697/ntl_adm2_monthly_2023.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095698/ntl_adm2_monthly_2024.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095699/ntl_adm2_monthly_2025.csv

* Space2Stats 
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095356/adm2_VIIRS.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095354/adm2_space2stats_population_2020.csv
https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095357/adm2_urbanization_ghssmod.csv

* 2012


* 2013
https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095687/ntl_adm2_monthly_2013.csv

STOP



* ssc install insheetjson, replace

net install libjson, from("https://wbuchanan.github.io/stata-libjson") replace
ssc install insheetjson, replace


insheetjson ISO_A3 date ntl_sum ///
    using "https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?filter=ISO_A3%20in%20(%27USA%27,%20%27MEX%27)&select=ISO_A3,%20date,%20ntl_sum", ///
    table(value) clear

	
STOP 


clear all
set more off

* Define the URL
local url "https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?&filter=ISO_A3%20in%20(%27USA%27,%20%27MEX%27)&select=ISO_A3,%20date,%20ntl_sum"

* Import JSON data using jsonio
* First, install jsonio if you haven't already (uncomment the line below if needed)
* ssc install jsonio, replace

* Method 1: Using jsonio (recommended for Stata 18)
capture jsonio import "`url'", file(tempdata)

load this json file as a dataframe in stata, using insheetjson
"https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?&filter=ISO_A3%20in%20(%27USA%27,%20%27MEX%27)&select=ISO_A3,%20date,%20ntl_sum"

insheetjson

STOP

WEBSITE
https://datacatalog.worldbank.org/int/search/dataset/0066940/Space2Stats-Monthly---Annual-Black-Marble-Nighttime-Lights
https://datacatalog.worldbank.org/search/dataset/0066940/Space2Stats-Monthly---Annual-Black-Marble-Nighttime-Lights

BASEURL: 2012
https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?

SELECT
https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?&select=ISO_A3, date, ntl_sum

FILTER
https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?&filter=ISO_A3 in ('USA', 'MEX')

SELECT AND FILTER
https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?&filter=ISO_A3 in ('USA', 'MEX')&select=ISO_A3, date, ntl_sum



https://ddh-internal-openapi.worldbank.org/resources/DR0095686/data?&filter=ISO_A3%20in%20(%27USA%27,%20%27MEX%27)&select=ISO_A3,%20date,%20ntl_sum



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


