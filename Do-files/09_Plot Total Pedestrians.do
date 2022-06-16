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

// By date

use "${statadata}06_Full_Data_Merged.dta", clear
bys date: egen sum_ped = sum(ped)
bys date: egen count_ids = count(idlocation)

gen mean_ped = sum_ped/count_ids * 24

// To keep only one TS
keep if idlocation == 1
keep if time_clock == 0

tsset date
tssmooth ma ma7=mean_ped, window(6 1 0)

twoway (line mean_ped date) (line ma7 date), graphregion(color(white)) /// 
	ytitle("Mean Pedestrians Count: by Day", size(med)) xtitle("Date", size(med)) /// 
	legend(lab(1 "Daily") lab(2 "7-day MA")) ///
	tlabel(01jan2020 01mar2020 01may2020 01jul2020 01sep2020 01nov2020 01jan2021, format(%tdMon-YY))
graph export "${figures}mean_ped_over_year.pdf" , as(pdf) replace 

// By time_clock

use "${statadata}06_Full_Data_Merged.dta", clear
bys time_clock: egen sum_ped = sum(ped)
bys time_clock: egen count_ids = count(idlocation)

gen mean_ped = sum_ped/count_ids

// To keep only one TS
keep if idlocation == 1
keep if date == date("20200102","YMD")

tsset time_clock

twoway (line mean_ped time_clock), graphregion(color(white)) /// 
	ytitle("Mean Pedestrians Count: by Hour", size(med)) xtitle("Hour", size(med)) /// 
	legend(lab(1 "Pedestrians by Hour"))
graph export "${figures}mean_ped_over_day.pdf" , as(pdf) replace 
