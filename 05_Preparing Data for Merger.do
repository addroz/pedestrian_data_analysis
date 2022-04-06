/***************************************
Cleaning and preparing the data to be merged with daily data
***************************************/
version 15.0
set more off
set type double, permanent
clear all

set dp period, permanent
set autotabgraphs on


global path = "C:\Users\adamd\OneDrive\Pulpit\RA EE\PedestrianDataAnalysis\Pedestrian Data Analysis\"
cd "${path}"
global raw = "${path}Input\Hystreet-data2020\"
global statadata = "${path}Stata Data\"
global output = "${path}Output\"
global graphs = "${path}Graphs\"
global figures = "${path}FinalFigures\"
global temp = "${path}temp\"

/******/

use "${statadata}04_Dataset_Hourly_Merged.dta", clear

drop if data_available != 1

capture drop weekday data_available d* location Gemeindename Flächekm2 Bev_insgesamt
capture drop Bev_maenl Bev_weibl Bev_jekm2 Postleitzahl Längengrad Breitengrad Verstädterung_Schlüssel
capture drop Verstädterung_Bezeichnung incident_day anzahlfall_meld meldcases_Bundesl
capture drop meldcases_DE meldcases_7days anzahlfall_ref refcases_Bundesl refcases_DE
capture drop refcases_7days precepitation temp_binned temp_daily_binned rain_daily_binned
capture drop shopsclosed restclosed masks storesclosed restaurantsclosed weekend_hol
capture drop closed_sunholclo closed_sunhol closed_holclosed noworkday sunhol logped
capture drop location_num anzahlfall_meld100k meldcases_7days100k anzahlfall_ref100k
capture drop refcases_7days100k meldcases_DE100k refcases_DE100k weather_shortnum rain_daily
capture drop weather weather_short Bundesland_num Bundesland
capture drop holiday schoolfree city firsttime year month week weekday_num

rename weathernum weather_num

tabulate incidents, generate(i)

drop incidents

rename i1 laser_failure
rename i2 laser_vac

recode laser_failure (mis = 0)
recode laser_vac (mis = 0)

gen date_tmp = substr(time, 1, 10)
gen date = date(date_tmp, "YMD")
format date %td

drop time date_tmp

sort landkreis_ID location_ID date time_clock

order date time_clock landkreis_ID location_ID 

tabulate weather_num

tabulate weather_short_num 

save "${statadata}05_Dataset_Hourly_To_Merge_With_Daily.dta", replace
