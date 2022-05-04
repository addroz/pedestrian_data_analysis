/***************************************
Merging daily and hourly data
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
global data_hourly = "${statadata}05_Dataset_Hourly_To_Merge_With_Daily.dta"
global data_daily = "${path}Input\merge_data_daily.dta"

/******/

use "${data_daily}", clear


forvalues x=44/64{
	local prev_x = `x' - 1
	local next_x = `x' + 1
	by id : gen outbreak_`x' = outbreak_`prev_x'[_n-1]
	replace outbreak_`x' = 0 if outbreak_`x' == .
	
	by id : gen outbreak_`next_x'_1 = outbreak_`x'_1[_n-1]
	replace outbreak_`next_x'_1 = 0 if outbreak_`next_x'_1 == .
	by id : gen outbreak_`next_x'_2 = outbreak_`x'_2[_n-1]
	replace outbreak_`next_x'_2 = 0 if outbreak_`next_x'_2 == .
	by id : gen outbreak_`next_x'_3 = outbreak_`x'_3[_n-1]
	replace outbreak_`next_x'_3 = 0 if outbreak_`next_x'_3 == .
} 

save "${statadata}06_Data_Daily_Modified.dta", replace

use "${data_hourly}", clear

rename landkreis_ID idlandkreis
rename location_ID idlocation

destring idlandkreis, replace

merge m:1 date idlandkreis using "${statadata}06_Data_Daily_Modified.dta"

// drop if _merge == 2
keep if _merge == 3
drop _merge
sort date time_clock idlandkreis idlocation

// How many outbreaks are in the data - by location and by landkreis
list date idlandkreis if time_clock == 0 & outbreak_1 == 1

gen log_ped = log(ped)
order log_ped, after(ped)

* gen period indicators
gen pre_period_ID=1 if outbreak_1==1 | outbreak_2==1 | outbreak_3==1 | outbreak_4==1 |  outbreak_5==1 | outbreak_6==1 |  outbreak_7==1 | outbreak_8==1 | ///
						outbreak_9==1 | outbreak_10==1 | outbreak_11==1 | outbreak_12==1 |  outbreak_13==1 | outbreak_14==1 | outbreak_15==1 | outbreak_16==1 | outbreak_17==1 | outbreak_18==1 | outbreak_19==1 |  outbreak_20==1 | outbreak_21==1
replace	pre_period_ID=0 if pre_period_ID==.
		
gen information_period_ID=1 if outbreak_22==1 | outbreak_23==1 | outbreak_24==1 | outbreak_25==1 | outbreak_26==1 |  outbreak_27==1 | outbreak_28==1
replace	information_period_ID=0 if information_period_ID==.
		
gen post_period_ID= 1 if outbreak_29==1 | outbreak_30==1 | outbreak_31==1 | outbreak_32==1 |  outbreak_33==1 | outbreak_34==1 |  outbreak_35==1 | outbreak_36==1 | ///
									   outbreak_37==1 | outbreak_38==1 | outbreak_39==1 | outbreak_40==1 |  outbreak_41==1 | outbreak_42==1   | outbreak_43==1 
replace	post_period_ID=0 if post_period_ID==.

* gen region indicators
// North Germany - SH, LS, BR, MK
gen region = 1 if state_id_v2 == 1 | state_id_v2 == 2 | state_id_v2 == 3 | state_id_v2 == 12 | state_id_v2 == 13    
// Central Germany - RW, HS, RP, SX, SA, TH
replace region = 2 if state_id_v2 == 5 | state_id_v2 == 6 | state_id_v2 == 7 | state_id_v2 == 10 | state_id_v2 == 14 | state_id_v2 == 15 | state_id_v2 == 16
// South Germany - BW, BV
replace region = 3 if state_id_v2 == 8 | state_id_v2 == 8

// West Germany
gen zone = 1 if state_id_v2 == 1 | state_id_v2 == 3 | state_id_v2 == 5 | state_id_v2 == 6 | ///
				state_id_v2 == 7 | state_id_v2 == 8 | state_id_v2 == 9 | state_id_v2 == 10
// East Germany
replace	zone = 2 if zone==.

save "${statadata}06_Full_Data_Merged.dta", replace
