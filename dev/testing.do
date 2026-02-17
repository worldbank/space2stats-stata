* Basic tests

net install space2stats, from("https://raw.githubusercontent.com/worldbank/space2stats-stata/main/src") replace

query_s2s, datasets(population_2020) iso3(USA)
query_s2s, datasets(population_2020 flood_exposure urbanization) iso3(USA MEX CAN)
query_s2s, datasets(ntl_viirs_bm_annual) iso3(USA) date_start(2020) date_end(2023)
query_s2s, datasets(ntl_viirs_bm_monthly) iso3(MEX) date_start(2020-01-01) date_end(2021-12-31)
query_s2s, datasets(ntl_viirs_bm_annual population_2020) iso3(USA) adm_level(1)
query_s2s, datasets(ntl_viirs_bm_annual flood_exposure) iso3(USA MEX CAN) adm_level(0)
query_s2s, datasets(ntl_viirs_bm_annual ntl_viirs_len_annual) iso3(BRA) date_start(2015) date_end(2023)
query_s2s, datasets(flood_exposure population_2020 urbanization) iso3(IND BGD PAK)
query_s2s, datasets(ntl_viirs_bm_annual) iso3(CHN IND) date_start(2012) date_end(2024) adm_level(0)
query_s2s, datasets(ntl_viirs_bm_annual flood_exposure population_2020 urbanization) iso3(USA)
