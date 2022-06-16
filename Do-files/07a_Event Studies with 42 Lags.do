/***************************************
Event study analysis
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

global leads " i.outbreak_1 i.outbreak_2 i.outbreak_3 i.outbreak_4  i.outbreak_5 i.outbreak_6  i.outbreak_7 i.outbreak_8  i.outbreak_9  i.outbreak_10 i.outbreak_11 i.outbreak_12 i.outbreak_13  i.outbreak_14  i.outbreak_15   i.outbreak_16 i.outbreak_17  i.outbreak_18  i.outbreak_19  i.outbreak_20"
global lags " i.outbreak_22  i.outbreak_23  i.outbreak_24  i.outbreak_25 i.outbreak_26   i.outbreak_27 i.outbreak_28  i.outbreak_29  i.outbreak_30 i.outbreak_31 i.outbreak_32 i.outbreak_33  i.outbreak_34  i.outbreak_35 i.outbreak_36   i.outbreak_37 i.outbreak_38  i.outbreak_39  i.outbreak_40 i.outbreak_41  i.outbreak_42 i.outbreak_43"
global lags_42 " i.outbreak_22  i.outbreak_23  i.outbreak_24  i.outbreak_25 i.outbreak_26   i.outbreak_27 i.outbreak_28  i.outbreak_29  i.outbreak_30 i.outbreak_31 i.outbreak_32 i.outbreak_33  i.outbreak_34  i.outbreak_35 i.outbreak_36   i.outbreak_37 i.outbreak_38  i.outbreak_39  i.outbreak_40 i.outbreak_41  i.outbreak_42 i.outbreak_43 i.outbreak_44 i.outbreak_45 i.outbreak_46 i.outbreak_47 i.outbreak_48 i.outbreak_49 i.outbreak_50 i.outbreak_51 i.outbreak_52 i.outbreak_53 i.outbreak_54 i.outbreak_55 i.outbreak_56 i.outbreak_57 i.outbreak_58 i.outbreak_59 i.outbreak_60 i.outbreak_61 i.outbreak_62 i.outbreak_63 i.outbreak_64"
global FE_s " i.region#i.date i.idlocation#i.ID_phase#i.dow#i.time_clock"
global npi  " i.weather_num i.temp npi_day_care npi_primary_schools npi_secondary_schools npi_workplace npi_travel_domestic npi_travel_foreign npi_public_transport  npi_mask_mandate npi_distancing npi_exit_restrictions npi_contacts_private npi_contacts_public npi_testing npi_services npi_accomodation npi_dining npi_retail npi_events_indoor npi_events_outdoor npi_night_life npi_sport_indoor npi_sport_outdoor npi_culture_educ_est"

global binned_pre_3 "i.outbreak_0_1##i.idlandkreis i.outbreak_0_2##i.idlandkreis i.outbreak_0_3##i.idlandkreis i.outbreak_0_1 i.outbreak_0_2 i.outbreak_0_3"
global binned_post_3 "i.outbreak_44_1##i.idlandkreis i.outbreak_44_2##i.idlandkreis  i.outbreak_44_3##i.idlandkreis i.outbreak_44_1 i.outbreak_44_2 i.outbreak_44_3 "
global binned_post_3_42 "i.outbreak_65_1##i.idlandkreis i.outbreak_65_2##i.idlandkreis  i.outbreak_65_3##i.idlandkreis i.outbreak_65_1 i.outbreak_65_2 i.outbreak_65_3 "

local p_cutoff p_v1

local start_period = 22
local number_lags=42
local number_leads=21
local bin_lags= `number_lags' +1
local bin_leads= `number_leads' +1
local bin_total_lags= `start_period' + `bin_lags'
local bin_total_leads= `start_period' - `bin_leads'
       
local last_lag=`start_period' +`number_lags'
local reference_period=`start_period' - 1
local last_lead=`reference_period' - 1
local first_lead =`start_period' - `number_leads'
local first_lag=`reference_period' + 1

local n_periods 6
local starthours 0 0 6 6 12 18
local numhours 24 6 6 4 6 6

forvalues s=1/`n_periods'{
	use "${statadata}06_Full_Data_Merged.dta", clear
	local s_start: word `s' of `starthours'
	local s_num: word `s' of `numhours'
	
	keep if time_clock >= `s_start' & time_clock < `s_start' + `s_num'
	
	keep if laser_failure == 0
	keep if laser_vac == 0
	
	matrix drop _all
	mata: mata clear
	mat C = J(120,4,.)
	local  column = 1
	local  row = 1		
					
	reghdfe log_ped $leads $lags_42, absorb($FE_s $binned_pre_3 $binned_post_3_42 $npi) cluster(idlandkreis) nocons
					
	local  row = 1
	forvalues x=`first_lead'/`last_lead'{
							
		scalar coef_`x' = _b[1.outbreak_`x'] 
		scalar ci_low_`x' = ( _b[1.outbreak_`x'] - (invttail(e(df_r),0.025)*_se[1.outbreak_`x'] )) 
		scalar ci_high_`x' = (_b[1.outbreak_`x'] + (invttail(e(df_r),0.025)*_se[1.outbreak_`x'] )) 
		mat C[`row',1] = `x'
		mat C[`row',2] = coef_`x'
		mat C[`row',3] = ci_low_`x'
		mat C[`row',4] = ci_high_`x'
		local row =`row' + 1
	}
					
	mat C[`reference_period',1] = `reference_period'
	mat C[`reference_period',2] = 0
	mat C[`reference_period',3] = 0
	mat C[`reference_period',4] = 0
					
	local  row = `reference_period' + 1
	forvalues x=`first_lag'/`last_lag'{						
		scalar coef_`x' = _b[1.outbreak_`x'] 
		scalar ci_low_`x' = ( _b[1.outbreak_`x'] - (invttail(e(df_r),0.025)*_se[1.outbreak_`x'] )) 
		scalar ci_high_`x' = (_b[1.outbreak_`x'] + (invttail(e(df_r),0.025)*_se[1.outbreak_`x'] )) 
		mat C[`row',1] = `x'
		mat C[`row',2] = coef_`x'
		mat C[`row',3] = ci_low_`x'
		mat C[`row',4] = ci_high_`x'
		local row =`row' + 1
	}
					
	mat list C
	preserve
	drop _all
	svmat C

	rename C1 time
	rename C2 coef_outbreak
	rename C3 ci_outbreak_high
	rename C4 ci_outbreak_low
				
	/* Event study on mobility */
	twoway (scatter coef_outbreak time,  msymbol(D) lcolor(navy) mcolor(navy) ) (rcap ci_outbreak_high ci_outbreak_low time, lcolor(navy)), ///
			yscale(r(-0.2 (0.05) 0.2)) ylabel(-0.2 (0.05) 0.2, labgap(*1.4)) yscale(titlegap(*3)) xscale(titlegap(*4)) ///
			xline(25.5, lwidth(12.67) lc(gs14))    yline(0, lcolor(black)) xline(22, lc(cranberry))  xlabel(`first_lead' "- `number_leads'" 8 "-14"   15 "-7"  `start_period'  "0" 29 "+7"  36 "+14" 43 "+21" 50 "+28" 57 "+35" `last_lag' "+ `number_lags'" , labgap(*1.4)) ///
			ytitle("Estimated Effect Relative to t=-1", size(medlarge))  graphregion(color(white)) legend(off) xtitle("Days Relative to Start of the Outbreak", size(medlarge))							
	
	graph export "${figures}from_`s_start'_`s_num'h_window_region_fes_42_lags.pdf" , as(pdf) replace 
	
	restore
}
