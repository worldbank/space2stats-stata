* Setup Package

* https://github.com/lsms-worldbank/adodown

local run_ad_setup   0 
local run_ad_command 0
local run_ad_publish 1

* point a local to the folder where the package will be created
local myfolder "~/Documents/github/space2stats-stata"

* Package meta info
local pkg "space2stats"
local aut "Robert Marty"
local des "This package queries satellite data"
local url "https://github.com/worldbank/space2stats-stata/adodown"
local con "rmarty@worldbank.org"

* Setup ------------------------------------------------------------------------
if `run_ad_setup' == 1{

	* Set up adodown-styled package folder
	ad_setup, adfolder("`myfolder'") autoprompt    ///
		 name("`pkg'") author("`aut'") desc("`des'") ///
		 url("`url'") contact("`con'")
}
	 
* Make commands ----------------------------------------------------------------
if `run_ad_command' == 1{
	ad_command create query_s2s, adf("`myfolder'") pkg("`pkg'")
}

if `run_ad_publish' == 1{
	ad_publish, adfolder("`myfolder'")
}

