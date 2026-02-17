*! version 0.0 20260213 - Robert Marty - rmarty@worldbank.org
*! Query Space2Stats datasets from World Bank Data Catalog
*! Syntax: query_s2s, [iso3(string)] datasets(string) [date_start(string)] [date_end(string)] [adm_level(integer 2)] [add_admin_names(integer 0)]

program define query_s2s
    version 14.0
    syntax, datasets(string) [iso3(string) date_start(string) date_end(string) adm_level(integer 2) add_admin_names(integer 0)]
    
    * Validate adm_level
    if !inlist(`adm_level', 0, 1, 2) {
        di as error "adm_level must be 0, 1, or 2"
        error 198
    }
    
    * Validate add_admin_names
    if !inlist(`add_admin_names', 0, 1) {
        di as error "add_admin_names must be 0 or 1"
        error 198
    }
    
    * Validate dataset combinations
    local has_monthly = 0
    local has_annual = 0
    local has_len = 0
    foreach dataset of local datasets {
        if "`dataset'" == "ntl_viirs_bm_monthly" {
            local has_monthly = 1
        }
        if "`dataset'" == "ntl_viirs_bm_annual" {
            local has_annual = 1
        }
        if "`dataset'" == "ntl_viirs_len_annual" {
            local has_len = 1
        }
    }
    
    if `has_monthly' == 1 & (`has_annual' == 1 | `has_len' == 1) {
        di as error "ntl_viirs_bm_monthly cannot be combined with ntl_viirs_bm_annual or ntl_viirs_len_annual"
        di as error "These datasets have different temporal structures (monthly vs annual)"
        error 198
    }
    
    * Clear any existing data
    clear
    
    * Initialize merge tracker
    local base_merge_keys "iso3 adm2cd_c"
    if `adm_level' == 1 {
        local base_merge_keys "iso3 adm1cd_c"
    }
    else if `adm_level' == 0 {
        local base_merge_keys "iso3"
    }
    
    * Parse datasets list
    local dataset_list `datasets'
    
    * Load adm1cd_c mapping if needed for adm_level = 1
    if `adm_level' == 1 {
        local need_adm1_mapping = 0
        foreach dataset of local dataset_list {
            if inlist("`dataset'", "ntl_viirs_len_annual", "flood_exposure", "population_2020", "urbanization") {
                local need_adm1_mapping = 1
            }
        }
        
        if `need_adm1_mapping' == 1 {
            di as text "Loading ADM1 mapping for aggregation..."
            tempfile adm1_mapping
            * Load CSV from URL
            qui import delimited ///
                "https://datacatalogfiles.worldbank.org/ddh-published/0038272/DR0095374/WB_Official_Boundaries_Admin2_additional_columns.csv", ///
                clear bindquote(strict)
            * Create adm1cd_c as copy of adm1cd
            qui gen adm1cd_c = adm1cd
            * Fill missing adm1cd_c using adm1cd_t
            qui replace adm1cd_c = adm1cd_t if missing(adm1cd_c)
            * Keep only selected variables
            qui keep adm1cd_c adm2cd_c
            qui save `adm1_mapping'
            local have_adm1_mapping = 1
        }
        else {
            local have_adm1_mapping = 0
        }
    }
    
    * Create temporary files for each dataset type
    tempfile master_data
    local have_master = 0
    local master_has_year = 0
    local master_has_date = 0
    
    * Process each dataset
    foreach dataset of local dataset_list {
        
        * Validate dataset name
        if !inlist("`dataset'", "ntl_viirs_bm_annual", "ntl_viirs_bm_monthly", ///
            "ntl_viirs_len_annual", "flood_exposure", "population_2020", "urbanization") {
            di as error "Invalid dataset: `dataset'"
            di as error "Valid datasets: ntl_viirs_bm_annual, ntl_viirs_bm_monthly, ntl_viirs_len_annual, flood_exposure, population_2020, urbanization"
            error 198
        }
        
        * Load dataset based on type
        if "`dataset'" == "ntl_viirs_bm_annual" {
            di as text "Loading dataset: ntl_viirs_bm_annual..."
            tempfile temp_annual
            qui import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095685/ntl_adm2_annual.csv", clear bindquote(strict)
            
            * Some NTL variables loaded as string; need to convert to numeric
            foreach var of varlist ntl_* {
                qui destring `var', replace force
            }
            * Simplify iso3 variable name
            qui rename iso_a3 iso3
            
            * Fix string variables - compress and convert strL to proper str
            qui compress iso3 adm2cd_c nam_0 nam_1 nam_2
            
            * Convert adm1cd_c to string if numeric
            capture confirm numeric variable adm1cd_c
            if _rc == 0 {
                qui tostring adm1cd_c, replace
            }
            qui compress adm1cd_c
            
            * Some repeated ADM1, such as Aruba; collapse to one at ADM2 level
            qui collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
                    (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
                           ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
                           ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
                           ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
                           ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
                    (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
                    by(iso3 adm1cd_c adm2cd_c nam_0 nam_1 nam_2 year)
            
            * Filter by iso3 if specified
            if "`iso3'" != "" {
                local iso3_condition = ""
                foreach country of local iso3 {
                    if "`iso3_condition'" == "" {
                        local iso3_condition `"iso3 == "`country'""'
                    }
                    else {
                        local iso3_condition `"`iso3_condition' | iso3 == "`country'""'
                    }
                }
                qui keep if `iso3_condition'
            }
            
            * Filter by date range if specified
            if "`date_start'" != "" | "`date_end'" != "" {
                * Parse date_start (extract year)
                if "`date_start'" != "" {
                    if strlen("`date_start'") == 4 {
                        local year_start = `date_start'
                    }
                    else {
                        local year_start = substr("`date_start'", 1, 4)
                    }
                    qui keep if year >= `year_start'
                }
                
                * Parse date_end (extract year)
                if "`date_end'" != "" {
                    if strlen("`date_end'") == 4 {
                        local year_end = `date_end'
                    }
                    else {
                        local year_end = substr("`date_end'", 1, 4)
                    }
                    qui keep if year <= `year_end'
                }
            }
            
            * Aggregate based on adm_level
            if `adm_level' == 1 {
                qui collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
                        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
                               ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
                               ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
                               ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
                               ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
                        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
                        by(iso3 adm1cd_c nam_0 nam_1 year)
            }
            else if `adm_level' == 0 {
                qui collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
                        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
                               ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
                               ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
                               ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
                               ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
                        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
                        by(iso3 nam_0 year)
            }
            
            * Save the annual data
            qui save `temp_annual'
            
            * Merge with master if it exists, otherwise make this the master
            if `have_master' == 0 {
                qui save `master_data', replace
                local have_master = 1
                local master_has_year = 1
            }
            else {
                qui use `master_data', clear
                * Determine merge strategy based on what's in master
                if `master_has_year' == 1 {
                    * Both have year - use 1:1 merge
                    qui merge 1:1 `base_merge_keys' year using `temp_annual', nogen
                }
                else if `master_has_date' == 1 {
                    * Master has date, incoming has year - extract year from date first
                    qui gen year = year(date(date, "YMD"))
                    qui merge m:1 `base_merge_keys' year using `temp_annual', nogen
                    local master_has_year = 1
                }
                else {
                    * Master has no temporal component - use 1:m merge (one static row to many years)
                    qui merge 1:m `base_merge_keys' using `temp_annual', nogen
                    local master_has_year = 1
                }
                qui save `master_data', replace
            }
        }
        
        else if "`dataset'" == "ntl_viirs_bm_monthly" {
            di as text "Loading dataset: ntl_viirs_bm_monthly..."
            * Determine which years to load
            local years_to_load ""
            
            if "`date_start'" == "" & "`date_end'" == "" {
                local years_to_load "2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025"
            }
            else {
                * Parse date range to determine years
                local year_start = 2012
                local year_end = 2025
                
                if "`date_start'" != "" {
                    if strlen("`date_start'") == 4 {
                        local year_start = `date_start'
                    }
                    else {
                        local year_start = substr("`date_start'", 1, 4)
                    }
                }
                
                if "`date_end'" != "" {
                    if strlen("`date_end'") == 4 {
                        local year_end = `date_end'
                    }
                    else {
                        local year_end = substr("`date_end'", 1, 4)
                    }
                }
                
                forvalues yr = `year_start'/`year_end' {
                    if `yr' >= 2012 & `yr' <= 2025 {
                        local years_to_load "`years_to_load' `yr'"
                    }
                }
            }
            
            * Load and append monthly data for each year
            tempfile temp_monthly temp_monthly_all
            local monthly_first = 1
            
            foreach yr of local years_to_load {
                di as text "  Loading monthly data for year: `yr'..."
                * Define URL for each year
                if `yr' == 2012 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095686/ntl_adm2_monthly_2012.csv"
                if `yr' == 2013 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095687/ntl_adm2_monthly_2013.csv"
                if `yr' == 2014 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095688/ntl_adm2_monthly_2014.csv"
                if `yr' == 2015 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095689/ntl_adm2_monthly_2015.csv"
                if `yr' == 2016 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095690/ntl_adm2_monthly_2016.csv"
                if `yr' == 2017 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095691/ntl_adm2_monthly_2017.csv"
                if `yr' == 2018 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095692/ntl_adm2_monthly_2018.csv"
                if `yr' == 2019 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095693/ntl_adm2_monthly_2019.csv"
                if `yr' == 2020 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095694/ntl_adm2_monthly_2020.csv"
                if `yr' == 2021 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095695/ntl_adm2_monthly_2021.csv"
                if `yr' == 2022 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095696/ntl_adm2_monthly_2022.csv"
                if `yr' == 2023 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095697/ntl_adm2_monthly_2023.csv"
                if `yr' == 2024 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095698/ntl_adm2_monthly_2024.csv"
                if `yr' == 2025 local url "https://datacatalogfiles.worldbank.org/ddh-published/0066940/DR0095699/ntl_adm2_monthly_2025.csv"
                
                qui import delimited "`url'", clear bindquote(strict)
                
                * Some NTL variables loaded as string; need to convert to numeric
                foreach var of varlist ntl_* {
                    qui destring `var', replace force
                }
                * Simplify iso3 variable name
                qui rename iso_a3 iso3
                
                * Fix string variables - compress and convert strL to proper str
                qui compress iso3 adm2cd_c nam_0 nam_1 nam_2 date
                
                * Convert adm1cd_c to string if numeric
                capture confirm numeric variable adm1cd_c
                if _rc == 0 {
                    qui tostring adm1cd_c, replace
                }
                qui compress adm1cd_c
                
                * Some repeated ADM1, such as Aruba; collapse to one at ADM2 level
                qui collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
                        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
                               ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
                               ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
                               ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
                               ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
                        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
                        by(iso3 adm1cd_c adm2cd_c nam_0 nam_1 nam_2 date)
                
                * Filter by iso3 if specified
                if "`iso3'" != "" {
                    local iso3_condition = ""
                    foreach country of local iso3 {
                        if "`iso3_condition'" == "" {
                            local iso3_condition `"iso3 == "`country'""'
                        }
                        else {
                            local iso3_condition `"`iso3_condition' | iso3 == "`country'""'
                        }
                    }
                    qui keep if `iso3_condition'
                }
                
                * Filter by date range if specified
                if "`date_start'" != "" {
                    qui keep if date >= "`date_start'"
                }
                if "`date_end'" != "" {
                    qui keep if date <= "`date_end'"
                }
                
                * Append to monthly dataset
                if `monthly_first' == 1 {
                    qui save `temp_monthly_all', replace
                    local monthly_first = 0
                }
                else {
                    qui append using `temp_monthly_all'
                    qui save `temp_monthly_all', replace
                }
            }
            
            * Load the combined monthly data
            qui use `temp_monthly_all', clear
            
            * Aggregate based on adm_level
            if `adm_level' == 1 {
                qui collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
                        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
                               ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
                               ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
                               ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
                               ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
                        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
                        by(iso3 adm1cd_c nam_0 nam_1 date)
            }
            else if `adm_level' == 0 {
                qui collapse (sum) ntl_sum ntl_gf_5km_sum ntl_nogf_5km_sum ntl_gf_10km_sum ntl_nogf_10km_sum ///
                        (mean) ntl_mean ntl_median ntl_q05 ntl_q95 ///
                               ntl_gf_5km_mean ntl_gf_5km_median ntl_gf_5km_q05 ntl_gf_5km_q95 ///
                               ntl_nogf_5km_mean ntl_nogf_5km_median ntl_nogf_5km_q05 ntl_nogf_5km_q95 ///
                               ntl_gf_10km_mean ntl_gf_10km_median ntl_gf_10km_q05 ntl_gf_10km_q95 ///
                               ntl_nogf_10km_mean ntl_nogf_10km_median ntl_nogf_10km_q05 ntl_nogf_10km_q95 ///
                        (max)  ntl_max ntl_gf_5km_max ntl_nogf_5km_max ntl_gf_10km_max ntl_nogf_10km_max, ///
                        by(iso3 nam_0 date)
            }
            
            qui save `temp_monthly', replace
            
            * Merge with master if it exists, otherwise make this the master
            if `have_master' == 0 {
                qui save `master_data', replace
                local have_master = 1
                local master_has_date = 1
            }
            else {
                qui use `master_data', clear
                * Determine merge strategy based on what's in master
                if `master_has_date' == 1 {
                    * Both have date - use 1:1 merge
                    qui merge 1:1 `base_merge_keys' date using `temp_monthly', nogen
                }
                else if `master_has_year' == 1 {
                    * Master has year, incoming has date - extract year from date
                    qui use `temp_monthly', clear
                    qui gen year = year(date(date, "YMD"))
                    qui save `temp_monthly', replace
                    qui use `master_data', clear
                    qui merge 1:m `base_merge_keys' year using `temp_monthly', nogen
                    local master_has_date = 1
                }
                else {
                    * Master has no temporal component - use 1:m merge
                    qui merge 1:m `base_merge_keys' using `temp_monthly', nogen
                    local master_has_date = 1
                }
                qui save `master_data', replace
            }
        }
        
        else if "`dataset'" == "ntl_viirs_len_annual" {
            di as text "Loading dataset: ntl_viirs_len_annual..."
            tempfile temp_len
            qui import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095356/adm2_VIIRS.csv", clear bindquote(strict)
            
            * Filter by iso3 if specified
            if "`iso3'" != "" {
                local iso3_condition = ""
                foreach country of local iso3 {
                    if "`iso3_condition'" == "" {
                        local iso3_condition `"iso3 == "`country'""'
                    }
                    else {
                        local iso3_condition `"`iso3_condition' | iso3 == "`country'""'
                    }
                }
                qui keep if `iso3_condition'
            }
            
            * Reshape from wide to long
            qui reshape long sum_viirs_ntl_, i(iso3 adm2cd_c) j(year)
            qui rename sum_viirs_ntl_ sum_viirs_ntl
            
            * Filter by date range if specified
            if "`date_start'" != "" | "`date_end'" != "" {
                if "`date_start'" != "" {
                    if strlen("`date_start'") == 4 {
                        local year_start = `date_start'
                    }
                    else {
                        local year_start = substr("`date_start'", 1, 4)
                    }
                    qui keep if year >= `year_start'
                }
                
                if "`date_end'" != "" {
                    if strlen("`date_end'") == 4 {
                        local year_end = `date_end'
                    }
                    else {
                        local year_end = substr("`date_end'", 1, 4)
                    }
                    qui keep if year <= `year_end'
                }
            }
            
            * Aggregate based on adm_level
            if `adm_level' == 1 {
                * Merge with adm1cd_c mapping
                if `have_adm1_mapping' == 1 {
                    qui merge m:1 adm2cd_c using `adm1_mapping', keep(master match) nogen
                }
                qui collapse (sum) sum_viirs_ntl, by(iso3 adm1cd_c year)
            }
            else if `adm_level' == 0 {
                qui collapse (sum) sum_viirs_ntl, by(iso3 year)
            }
            
            * Check for and remove duplicates
            if `adm_level' == 2 {
                qui duplicates drop iso3 adm2cd_c year, force
            }
            else if `adm_level' == 1 {
                qui duplicates drop iso3 adm1cd_c year, force
            }
            else {
                qui duplicates drop iso3 year, force
            }
            
            * Save the LENs data
            qui save `temp_len'
            
            * Merge with master if it exists, otherwise make this the master
            if `have_master' == 0 {
                qui save `master_data', replace
                local have_master = 1
                local master_has_year = 1
            }
            else {
                qui use `master_data', clear
                * Determine merge strategy based on what's in master
                if `master_has_year' == 1 {
                    * Both have year - use 1:1 merge
                    qui merge 1:1 `base_merge_keys' year using `temp_len', nogen
                }
                else if `master_has_date' == 1 {
                    * Master has date, incoming has year - extract year from date first
                    qui gen year = year(date(date, "YMD"))
                    qui merge m:1 `base_merge_keys' year using `temp_len', nogen
                    local master_has_year = 1
                }
                else {
                    * Master has no temporal component - use 1:m merge
                    qui merge 1:m `base_merge_keys' using `temp_len', nogen
                    local master_has_year = 1
                }
                qui save `master_data', replace
            }
        }
        
        else if "`dataset'" == "flood_exposure" {
            di as text "Loading dataset: flood_exposure..."
            tempfile temp_flood
            qui import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv", clear bindquote(strict)
            
            * Filter by iso3 if specified
            if "`iso3'" != "" {
                local iso3_condition = ""
                foreach country of local iso3 {
                    if "`iso3_condition'" == "" {
                        local iso3_condition `"iso3 == "`country'""'
                    }
                    else {
                        local iso3_condition `"`iso3_condition' | iso3 == "`country'""'
                    }
                }
                qui keep if `iso3_condition'
            }
            
            * Aggregate based on adm_level
            if `adm_level' == 1 {
                * Merge with adm1cd_c mapping
                if `have_adm1_mapping' == 1 {
                    qui merge m:1 adm2cd_c using `adm1_mapping', keep(master match) nogen
                }
                qui collapse (sum) pop pop_flood (mean) pop_flood_pct, by(iso3 adm1cd_c)
            }
            else if `adm_level' == 0 {
                qui collapse (sum) pop pop_flood (mean) pop_flood_pct, by(iso3)
            }
            
            * Save the flood data
            qui save `temp_flood'
            
            * Merge with master if it exists, otherwise make this the master
            if `have_master' == 0 {
                qui save `master_data', replace
                local have_master = 1
            }
            else {
                qui use `master_data', clear
                * Static dataset - always use m:1 merge if master has temporal component
                if `master_has_year' == 1 | `master_has_date' == 1 {
                    qui merge m:1 `base_merge_keys' using `temp_flood', nogen
                }
                else {
                    qui merge 1:1 `base_merge_keys' using `temp_flood', nogen
                }
                qui save `master_data', replace
            }
        }
        
        else if "`dataset'" == "population_2020" {
            di as text "Loading dataset: population_2020..."
            tempfile temp_pop
            qui import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095354/adm2_space2stats_population_2020.csv", clear bindquote(strict)
            
            * Filter by iso3 if specified
            if "`iso3'" != "" {
                local iso3_condition = ""
                foreach country of local iso3 {
                    if "`iso3_condition'" == "" {
                        local iso3_condition `"iso3 == "`country'""'
                    }
                    else {
                        local iso3_condition `"`iso3_condition' | iso3 == "`country'""'
                    }
                }
                qui keep if `iso3_condition'
            }
            
            * Aggregate based on adm_level
            if `adm_level' == 1 {
                * Merge with adm1cd_c mapping
                if `have_adm1_mapping' == 1 {
                    qui merge m:1 adm2cd_c using `adm1_mapping', keep(master match) nogen
                }
                qui collapse (sum) sum_*, by(iso3 adm1cd_c)
            }
            else if `adm_level' == 0 {
                qui collapse (sum) sum_*, by(iso3)
            }
            
            * Save the population data
            qui save `temp_pop'
            
            * Merge with master if it exists, otherwise make this the master
            if `have_master' == 0 {
                qui save `master_data', replace
                local have_master = 1
            }
            else {
                qui use `master_data', clear
                * Static dataset - always use m:1 merge if master has temporal component
                if `master_has_year' == 1 | `master_has_date' == 1 {
                    qui merge m:1 `base_merge_keys' using `temp_pop', nogen
                }
                else {
                    qui merge 1:1 `base_merge_keys' using `temp_pop', nogen
                }
                qui save `master_data', replace
            }
        }
        
        else if "`dataset'" == "urbanization" {
            di as text "Loading dataset: urbanization..."
            tempfile temp_urban
            qui import delimited "https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095357/adm2_urbanization_ghssmod.csv", clear bindquote(strict)
            
            * Filter by iso3 if specified
            if "`iso3'" != "" {
                local iso3_condition = ""
                foreach country of local iso3 {
                    if "`iso3_condition'" == "" {
                        local iso3_condition `"iso3 == "`country'""'
                    }
                    else {
                        local iso3_condition `"`iso3_condition' | iso3 == "`country'""'
                    }
                }
                qui keep if `iso3_condition'
            }
            
            * Aggregate based on adm_level
            if `adm_level' == 1 {
                * Merge with adm1cd_c mapping
                if `have_adm1_mapping' == 1 {
                    qui merge m:1 adm2cd_c using `adm1_mapping', keep(master match) nogen
                }
                qui collapse (sum) ghs_*, by(iso3 adm1cd_c)
            }
            else if `adm_level' == 0 {
                qui collapse (sum) ghs_*, by(iso3)
            }
            
            * Save the urbanization data
            qui save `temp_urban'
            
            * Merge with master if it exists, otherwise make this the master
            if `have_master' == 0 {
                qui save `master_data', replace
                local have_master = 1
            }
            else {
                qui use `master_data', clear
                * Static dataset - always use m:1 merge if master has temporal component
                if `master_has_year' == 1 | `master_has_date' == 1 {
                    qui merge m:1 `base_merge_keys' using `temp_urban', nogen
                }
                else {
                    qui merge 1:1 `base_merge_keys' using `temp_urban', nogen
                }
                qui save `master_data', replace
            }
        }
    }
    
    * Load the final merged dataset into memory
    if `have_master' == 1 {
        qui use `master_data', clear
    }
    
    * Add administrative names if requested
    if `add_admin_names' == 1 & `adm_level' < 2 {
        di as text "Loading administrative names..."
        tempfile admin_names
        preserve
        qui import delimited ///
            "https://datacatalogfiles.worldbank.org/ddh-published/0038272/DR0095374/WB_Official_Boundaries_Admin2_additional_columns.csv", ///
            clear bindquote(strict)
        * Create adm1cd_c as copy of adm1cd
        qui gen adm1cd_c = adm1cd
        * Fill missing adm1cd_c using adm1cd_t
        qui replace adm1cd_c = adm1cd_t if missing(adm1cd_c)
        * Keep selected variables
        qui keep ///
            adm1cd_c adm2cd_c ///
            nam_1_gaul nam_2_gaul ///
            nam_1_stat nam_2_stat ///
            nam_1_srce nam_2_srce ///
            nam_1_ntve nam_2_ntve ///
            nam_1_wiki nam_2_wiki ///
            p_name_1 p_name_2
        qui save `admin_names'
        restore
        
        * Merge based on admin level
        if `adm_level' == 2 {
            qui merge m:1 adm2cd_c using `admin_names', keep(master match) nogen
        }
        else if `adm_level' == 1 {
            * For ADM1, need to collapse to unique adm1cd_c
            preserve
            qui use `admin_names', clear
            * Keep only ADM1 variables and make unique by adm1cd_c
            qui keep adm1cd_c nam_1_gaul nam_1_stat nam_1_srce nam_1_ntve nam_1_wiki p_name_1
            qui duplicates drop adm1cd_c, force
            qui save `admin_names', replace
            restore
            
            qui merge m:1 adm1cd_c using `admin_names', keep(master match) nogen
        }
    }
    else if `add_admin_names' == 1 & `adm_level' == 2 {
        di as text "Loading administrative names..."
        tempfile admin_names
        preserve
        qui import delimited ///
            "https://datacatalogfiles.worldbank.org/ddh-published/0038272/DR0095374/WB_Official_Boundaries_Admin2_additional_columns.csv", ///
            clear bindquote(strict)
        * Create adm1cd_c as copy of adm1cd
        qui gen adm1cd_c = adm1cd
        * Fill missing adm1cd_c using adm1cd_t
        qui replace adm1cd_c = adm1cd_t if missing(adm1cd_c)
        * Keep selected variables
        qui keep ///
            adm1cd_c adm2cd_c ///
            nam_1_gaul nam_2_gaul ///
            nam_1_stat nam_2_stat ///
            nam_1_srce nam_2_srce ///
            nam_1_ntve nam_2_ntve ///
            nam_1_wiki nam_2_wiki ///
            p_name_1 p_name_2
        qui save `admin_names'
        restore
        
        * Merge for ADM2 level
        qui merge m:1 adm2cd_c using `admin_names', keep(master match) nogen
    }
    
    * Display summary
    di as text ""
    di as text "Query completed successfully"
    di as text "Datasets loaded: `datasets'"
    di as text "Admin level: `adm_level'"
    if "`iso3'" != "" {
        di as text "Countries: `iso3'"
    }
    if "`date_start'" != "" {
        di as text "Date start: `date_start'"
    }
    if "`date_end'" != "" {
        di as text "Date end: `date_end'"
    }
    qui count
    di as text "Observations: " as result r(N)
    
    * Show variable list
    di as text ""
    di as text "Variables in dataset:"
    describe, short
    
    * Add variable labels based on datasets loaded
    local has_len = 0
    local has_bm = 0
    local has_urbanization = 0
    local has_flood = 0
    local has_population = 0
    
    foreach dataset of local dataset_list {
        if "`dataset'" == "ntl_viirs_len_annual" {
            local has_len = 1
        }
        if "`dataset'" == "ntl_viirs_bm_annual" | "`dataset'" == "ntl_viirs_bm_monthly" {
            local has_bm = 1
        }
        if "`dataset'" == "urbanization" {
            local has_urbanization = 1
        }
        if "`dataset'" == "flood_exposure" {
            local has_flood = 1
        }
        if "`dataset'" == "population_2020" {
            local has_population = 1
        }
    }
    
    if `has_len' == 1 {
        capture label var sum_viirs_ntl "Dataset: NTL VIIRS (World Bank, Light Every Night)"
    }
    
    if `has_bm' == 1 {
        foreach v of varlist ntl_* {
            capture label var `v' "Dataset: NTL VIIRS Black Marble"
        }
    }
    
    if `has_urbanization' == 1 {
        foreach v of varlist ghs_* {
            capture label var `v' "Dataset: Urbanization, GHS-SMOD"
        }
    }
    
    if `has_flood' == 1 {
        foreach v of varlist pop* {
            capture label var `v' "Dataset: Flood Exposure, Fathom v3 and WorldPop"
        }
    }
    
    if `has_population' == 1 {
        foreach v of varlist sum_pop* {
            capture label var `v' "Dataset: Population, WorldPop"
        }
    }
    
end
