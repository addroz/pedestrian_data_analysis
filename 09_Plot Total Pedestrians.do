/***************************************
Generating a plot of log total pedestrians over the year
***************************************/
version 15.0
set more off
set type double, permanent
clear all

set dp period, permanent
set autotabgraphs on


global path = "C:\Users\adamd\OneDrive\Pulpit\RA EE\PedestrianDataAnalysis\Pedestrian Data Analysis\"
cd "${path}"
global statadata = "${path}Stata Data\"
global figures = "${path}Figures\"

/******/
	
use "${statadata}06_Full_Data_Merged.dta", clear

levelsof idlocation if date == td(02jan2020), local(location_ids)
egen OK = anymatch(idlocation), values(`location_ids')
keep if OK == 1

bys date: egen sum_ped = sum(ped)
gen log_sum_ped = log(sum_ped)

// To keep only one TS
keep if idlocation == 1
keep if time_clock == 0

tsset date
tssmooth ma ma7=log_sum_ped, window(6 1 0)

twoway (line log_sum_ped date) (line ma7 date), graphregion(color(white)) /// 
	ytitle("Log Daily Sum of Pedestrians over Locations", size(med)) xtitle("Date", size(med)) /// 
	legend(lab(1 "Daily") lab(2 "7-day MA")) 
graph export "${figures}log_ped_sum_over_year.pdf" , as(pdf) replace 
