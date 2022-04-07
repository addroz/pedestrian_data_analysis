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

global leads " i.outbreak_1 i.outbreak_2 i.outbreak_3 i.outbreak_4  i.outbreak_5 i.outbreak_6  i.outbreak_7 i.outbreak_8  i.outbreak_9  i.outbreak_10 i.outbreak_11 i.outbreak_12 i.outbreak_13  i.outbreak_14  i.outbreak_15   i.outbreak_16 i.outbreak_17  i.outbreak_18  i.outbreak_19  i.outbreak_20"
global lags " i.outbreak_22  i.outbreak_23  i.outbreak_24  i.outbreak_25 i.outbreak_26   i.outbreak_27 i.outbreak_28  i.outbreak_29  i.outbreak_30 i.outbreak_31 i.outbreak_32 i.outbreak_33  i.outbreak_34  i.outbreak_35 i.outbreak_36   i.outbreak_37 i.outbreak_38  i.outbreak_39  i.outbreak_40 i.outbreak_41  i.outbreak_42 i.outbreak_43"
global FE_s " i.region#i.date i.idlocation#i.ID_phase#i.dow#i.time_clock"
global npi  " i.weather_num i.temp npi_day_care npi_primary_schools npi_secondary_schools npi_workplace npi_travel_domestic npi_travel_foreign npi_public_transport  npi_mask_mandate npi_distancing npi_exit_restrictions npi_contacts_private npi_contacts_public npi_testing npi_services npi_accomodation npi_dining npi_retail npi_events_indoor npi_events_outdoor npi_night_life npi_sport_indoor npi_sport_outdoor npi_culture_educ_est"

global binned_pre_3 "i.outbreak_0_1##i.idlandkreis i.outbreak_0_2##i.idlandkreis i.outbreak_0_3##i.idlandkreis i.outbreak_0_1 i.outbreak_0_2 i.outbreak_0_3"
global binned_post_3 "i.outbreak_44_1##i.idlandkreis i.outbreak_44_2##i.idlandkreis  i.outbreak_44_3##i.idlandkreis i.outbreak_44_1 i.outbreak_44_2 i.outbreak_44_3 "

use "${statadata}06_Full_Data_Merged.dta", clear

*DID
						
reghdfe log_ped i.information_period_ID  post_period_ID#i.time_clock, absorb($binned_pre_3  $binned_post_3 $FE_s) cluster(idlandkreis) nocons
		
reghdfe log_ped i.information_period_ID  post_period_ID#i.time_clock, absorb($binned_pre_3 $npi $binned_post_3 $FE_s) cluster(idlandkreis) nocons
				
restore
