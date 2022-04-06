/***************************************
Merging of Hystreet and weather data

***************************************/
version 15.1
set more off
set type double, permanent
clear all

set dp period, permanent
set autotabgraphs on


global path = "C:\Users\adamd\OneDrive\Pulpit\RA EE\PedestrianDataAnalysis\Pedestrian Data Analysis\"
cd "${path}"
global raw = "${path}Input\Hystreet2020-data\"
global statadata = "${path}Stata Data\"
global output = "${path}Output\"
global graphs = "${path}Graphs\"
global temp = "${path}temp\"


*****************************************

use "${statadata}01_Hystreet_Data.dta", clear


***Bundesland as a number (official code for the Bundesland)
gen Bundesland_num=01 if Bundesland=="SH"
replace Bundesland_num=02 if Bundesland=="HH"
replace Bundesland_num=03 if Bundesland=="NI"
replace Bundesland_num=04 if Bundesland=="HB"
replace Bundesland_num=05 if Bundesland=="NW"
replace Bundesland_num=06 if Bundesland=="HE"
replace Bundesland_num=07 if Bundesland=="RP"
replace Bundesland_num=08 if Bundesland=="BW"
replace Bundesland_num=09 if Bundesland=="BY"
replace Bundesland_num=10 if Bundesland=="SL"
replace Bundesland_num=11 if Bundesland=="BE"

replace Bundesland_num=13 if Bundesland=="MV"
replace Bundesland_num=14 if Bundesland=="SN"

replace Bundesland_num=16 if Bundesland=="TH"

***Merge the dataset with the LänderID-dataset
merge m:1 city Bundesland_num using "${path}Stata Data\02_Landkreise.dta", keepus(Gemeindename landkreis_ID Flächekm2 Bev_insgesamt Bev_maenl Bev_weibl Bev_jekm2 Postleitzahl Verstädterung_Schlüssel Verstädterung_Bezeichnung Längengrad Breitengrad)
drop if _merge==2

*tab _merge
drop _merge

***Finding out when for each location I have data
by location_ID, sort: egen firsttime = min(cond(data_available == 1, date, .))
format firsttime %td
tab firsttime if firsttime==date

***calendar week
gen week=week(date)

***Weekday as numeric variable
gen weekday_num=1 if weekday=="Monday"
replace weekday_num=2 if weekday=="Tuesday"
replace weekday_num=3 if weekday=="Wednesday"
replace weekday_num=4 if weekday=="Thursday"
replace weekday_num=5 if weekday=="Friday"
replace weekday_num=6 if weekday=="Saturday"
replace weekday_num=7 if weekday=="Sunday"

***Weather as numeric variable
encode weather, gen(weathernum)

***indicator if incident during a day at some hour
egen incident_day=total(incident=="Laserausfall"), by(date location_ID)

save "${statadata}03_Hystreet_Data_Weather_Infections.dta", replace
