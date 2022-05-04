/***************************************
Merging of all Mobility datasets form Hystreet.com

***************************************/
version 15.1
set more off
set type double, permanent
clear all

set dp period, permanent
set autotabgraphs on

global path = "C:\Users\adamd\OneDrive\Pulpit\RA EE\PedestrianDataAnalysis\Pedestrian Data Analysis\"
cd "${path}"
global raw = "${path}Input\Hystreet-data\"
global statadata = "${path}Stata Data\"
global temp = "${path}temp\"

*****************************************
***Import of the data
local files: dir "${raw}" files "*.csv"
cd "${raw}"
foreach file in `files' {
	import delimited using "`file'", delimiter(";") encoding(UTF-8) stringcols(7) clear
	save "${temp}\`file'.dta", replace
}


***Checking such that in each file really is only one location included
cd "${temp}"
local files: dir "${temp}" files "*.dta"
foreach file in `files'{
	use "`file'", clear
	levelsof location
	assert r(r)==1
}


**Checking such that in each file each date really occurs only once
cd "${temp}"
local files: dir "${temp}" files "*.dta"
foreach file in `files'{
	use "`file'", clear
	duplicates list timeofmeasurement
}
//no duplicates found with respect to timeofmeasurement



***Appending all datasets
cd "${temp}"
dir *.dta
clear
local allfiles: dir . files "*.dta"
append using `allfiles'

codebook	//check e.g. that all 123 locations are included;

duplicates list		//check that no duplicates are in the dataset

replace location=subinstr(location, " ","", .)

rename pedestrianscount ped
rename temperatureinºc temp
rename weathercondition weather 


***Create entries for earlier dates also for those locations, which do not have such early dates available
gen data_available=1

gen date=date(timeofmeasurement,"YMD####")
format date %td

gen date_complete=clock(time,"YMDhms#")
format date_complete %tc

*Time of the day
gen time_clock=hh(date_complete)

save "${statadata}00_Hystreet-data_long", replace

