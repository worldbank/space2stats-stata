* Basic tests

net install space2stats, from("https://raw.githubusercontent.com/worldbank/space2stats-stata/main/src") replace

*net install blackmarble, from("https://raw.githubusercontent.com/worldbank/blackmarble-stata/main/src") replace


query_s2s, datasets(population_2020) iso3(USA)
