/***************************************
DiD and interactions analysis
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

global FE_s " i.region#i.date i.idlocation#i.ID_phase#i.dow#i.time_clock"
global FE_s_interact " i.region#i.date##i.time_clock i.idlocation#i.ID_phase#i.dow##i.time_clock"

global npi  " i.weather_num i.temp npi_day_care npi_primary_schools npi_secondary_schools npi_workplace npi_travel_domestic npi_travel_foreign npi_public_transport  npi_mask_mandate npi_distancing npi_exit_restrictions npi_contacts_private npi_contacts_public npi_testing npi_services npi_accomodation npi_dining npi_retail npi_events_indoor npi_events_outdoor npi_night_life npi_sport_indoor npi_sport_outdoor npi_culture_educ_est"
global npi_interact  " i.weather_num##i.time_clock i.temp##i.time_clock npi_day_care##i.time_clock npi_primary_schools##i.time_clock npi_secondary_schools##i.time_clock npi_workplace##i.time_clock npi_travel_domestic##i.time_clock npi_travel_foreign##i.time_clock npi_public_transport##i.time_clock npi_mask_mandate##i.time_clock npi_distancing##i.time_clock npi_exit_restrictions##i.time_clock npi_contacts_private##i.time_clock npi_contacts_public##i.time_clock npi_testing##i.time_clock npi_services##i.time_clock npi_accomodation##i.time_clock npi_dining##i.time_clock npi_retail##i.time_clock npi_events_indoor##i.time_clock npi_events_outdoor##i.time_clock npi_night_life##i.time_clock npi_sport_indoor##i.time_clock npi_sport_outdoor##i.time_clock npi_culture_educ_est##i.time_clock "

global binned_pre_3 " i.outbreak_0_1##i.idlandkreis i.outbreak_0_2##i.idlandkreis i.outbreak_0_3##i.idlandkreis i.outbreak_0_1 i.outbreak_0_2 i.outbreak_0_3 "
global binned_post_3 " i.outbreak_44_1##i.idlandkreis i.outbreak_44_2##i.idlandkreis i.outbreak_44_3##i.idlandkreis i.outbreak_44_1 i.outbreak_44_2 i.outbreak_44_3 "
global binned_pre_3_interact " i.outbreak_0_1##i.idlandkreis##i.time_clock i.outbreak_0_2##i.idlandkreis##i.time_clock i.outbreak_0_3##i.idlandkreis##i.time_clock i.outbreak_0_1##i.time_clock i.outbreak_0_2##i.time_clock i.outbreak_0_3##i.time_clock "
global binned_post_3_interact " i.outbreak_44_1##i.idlandkreis##i.time_clock i.outbreak_44_2##i.idlandkreis##i.time_clock i.outbreak_44_3##i.idlandkreis##i.time_clock i.outbreak_44_1##i.time_clock i.outbreak_44_2##i.time_clock i.outbreak_44_3##i.time_clock "

use "${statadata}06_Full_Data_Merged.dta", clear

// DiD without main effects

forvalues x=0/23{
	gen h_post_period_`x' = 0
	replace	h_post_period_`x' = 1 if post_period_ID == 1 & time_clock == `x'
	label variable h_post_period_`x' "`x':00" 
}

reghdfe log_ped h_post_period*, absorb(i.information_period_ID##i.time_clock $npi_interact $FE_s_interact $binned_pre_3_interact $binned_post_3_interact) cluster(idlandkreis) nocons

coefplot, drop(_cons) xline(0) xtitle("Estimated Post-Period Effect", size(medlarge)) ytitle("Time of the Day", size(medlarge)) ///
		graphregion(color(white)) legend(off) msymbol(D) lcolor(navy) mcolor(navy) ciopts(recast(rcap))
graph export "${figures}did_without_main_effect.pdf" , as(pdf) replace 

use "${statadata}06_Full_Data_Merged.dta", clear

// No Main Effects, for the four periods

forvalues x=0/3{
	gen h_post_period_`x' = 0
	replace	h_post_period_`x' = 1 if post_period_ID == 1 & time_clock >= 6*`x' & time_clock < 6*(`x' + 1)
	local y1 = 6*`x'
	local y2 = 6*(`x'+1) - 1
	label variable h_post_period_`x' "`y1':00 - `y2':00" 
}

reghdfe log_ped h_post_period*, absorb(i.information_period_ID##i.time_clock $npi_interact $FE_s_interact $binned_pre_3_interact $binned_post_3_interact) cluster(idlandkreis) nocons

coefplot, drop(_cons) xline(0) xtitle("Estimated Post-Period Effect", size(medlarge)) ytitle("Time of the Day", size(medlarge)) ///
		graphregion(color(white)) legend(off) msymbol(D) lcolor(navy) mcolor(navy) ciopts(recast(rcap))
graph export "${figures}did_without_main_effect_4_periods.pdf" , as(pdf) replace 

// DiD on separate time clocks, to be sure everything works as intended

matrix drop _all
mata: mata clear
mat C = J(24,3,.)

forvalues x=0/23{
	use "${statadata}06_Full_Data_Merged.dta", clear
	keep if time_clock == `x'
	dis `x'
	reghdfe log_ped i.information_period_ID i.post_period_ID, absorb($npi $FE_s_separate $binned_pre_3 $binned_post_3) cluster(idlandkreis) nocons
	
	mat C[`x' + 1,1] = _b[1.post_period_ID]
	mat C[`x' + 1,2] = ( _b[1.post_period_ID] - (invttail(e(df_r),0.025)*_se[1.post_period_ID] )) 
	mat C[`x' + 1,3] = (_b[1.post_period_ID] + (invttail(e(df_r),0.025)*_se[1.post_period_ID] ))
	matrix list C
}

matrix rownames C = "00" "01" "02" "03" "04" "05" "06" "07" "08" "09" ///
					"10" "11" "12" "13" "14" "15" "16" "17" "18" "19" ///
					"20" "21" "22" "23" 
matrix colnames C = EST LL UL

coefplot matrix(C[,1]), ci((C[,2] C[,3])) xline(0) xtitle("Estimated Post-Period Effect", size(medlarge)) ytitle("Time of the Day", size(medlarge)) ///
		graphregion(color(white)) legend(off) msymbol(D) lcolor(navy) mcolor(navy) ciopts(recast(rcap))
graph export "${figures}did_separate_periods.pdf" , as(pdf) replace 




//Same analysis using weekdays only
use "${statadata}06_Full_Data_Merged.dta", clear

keep if dow < 6
keep if dow > 0

// DiD without main effects

forvalues x=0/23{
	gen h_post_period_`x' = 0
	replace	h_post_period_`x' = 1 if post_period_ID == 1 & time_clock == `x'
	label variable h_post_period_`x' "`x':00" 
}

reghdfe log_ped h_post_period*, absorb(i.information_period_ID##i.time_clock $npi_interact $FE_s_interact $binned_pre_3_interact $binned_post_3_interact) cluster(idlandkreis) nocons

coefplot, drop(_cons) xline(0) xtitle("Estimated Post-Period Effect", size(medlarge)) ytitle("Time of the Day", size(medlarge)) ///
		graphregion(color(white)) legend(off) msymbol(D) lcolor(navy) mcolor(navy) ciopts(recast(rcap))
graph export "${figures}did_without_main_effect_no_weekends.pdf" , as(pdf) replace 


use "${statadata}06_Full_Data_Merged.dta", clear

keep if dow < 6
keep if dow > 0

// No Main Effects, for the four periods

forvalues x=0/3{
	gen h_post_period_`x' = 0
	replace	h_post_period_`x' = 1 if post_period_ID == 1 & time_clock >= 6*`x' & time_clock < 6*(`x' + 1)
	local y1 = 6*`x'
	local y2 = 6*(`x'+1) - 1
	label variable h_post_period_`x' "`y1':00 - `y2':00" 
}

reghdfe log_ped h_post_period*, absorb(i.information_period_ID##i.time_clock $npi_interact $FE_s_interact $binned_pre_3_interact $binned_post_3_interact) cluster(idlandkreis) nocons

coefplot, drop(_cons) xline(0) xtitle("Estimated Post-Period Effect", size(medlarge)) ytitle("Time of the Day", size(medlarge)) ///
		graphregion(color(white)) legend(off) msymbol(D) lcolor(navy) mcolor(navy) ciopts(recast(rcap))
graph export "${figures}did_without_main_effect_4_periods_no_weekends.pdf" , as(pdf) replace 


