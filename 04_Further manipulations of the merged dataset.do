/***************************************
Further definitions and changes in the merged dataset before doing analyses with it

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
use "${statadata}03_Hystreet_Data_Weather_Infections.dta", clear

drop if location==""	//commes from filling up of values in an earlier dofile

***simpler weather variable (only precepitation or not)                                 
gen weather_short="clear" if strpos(weather, "clear")>0
replace weather_short="precepitation" if strpos(weather, "rain")>0 | strpos(weather, "sleet")>0 | strpos(weather, "snow")>0
replace weather_short="cloudy" if strpos(weather, "cloudy")>0
replace weather_short="partly cloudy" if strpos(weather, "partly-cloudy")>0
replace weather_short="wind/fog" if strpos(weather, "wind")>0 | strpos(weather, "fog")>0
encode weather_short, gen(weather_shortnum)

***only precepitation yes/no
gen precepitation=1 if weather=="rain" | weather=="sleet" | weather=="snow"
replace precepitation=0 if precepitation==.

***Define binned temperature variable to later intersect with weather
gen temp_binned=1 if temp<=-3
replace temp_binned=2 if temp>=-2 & temp<=3
replace temp_binned=3 if temp>=4 & temp<=8
replace temp_binned=4 if temp>=9 & temp<=13
replace temp_binned=5 if temp>=14 & temp<=18
replace temp_binned=6 if temp>=19 & temp<=23
replace temp_binned=7 if temp>=24 & temp<=28
replace temp_binned=8 if temp>=29 & temp<=33
replace temp_binned=9 if temp>=34 & temp<41

***Indicators for closings and masks (nationwide --> imprecise; later substituted by more specific policy data)
gen shopsclosed=1 if date>=date("22Mar2020","DMY") & date<date("20Apr2020","DMY") //closed shops
replace shopsclosed=0 if shopsclosed==.
gen restclosed=1 if date>=date("22Mar2020","DMY") & date<date("06May2020","DMY") //closed restaurants
replace restclosed=0 if restclosed==.
gen masks=1 if date>=date("15Apr2020","DMY") //masks required/recommended
replace masks=0 if masks==.


*****Dummies for political actions on local level for relevant cities
**stores closed
gen storesclosed=1 if date>=date("17mar2020","DMY") & date<date("20apr2020","DMY") & (city=="Darmstadt" | city=="Frankfurt a.m." | city=="Hamburg" | city=="Hannover" | city=="Mainz" | city=="Wiesbaden")
replace storesclosed=1 if date>=date("18mar2020","DMY") & date<date("20apr2020","DMY") & (city=="Bonn" | city=="Dortmund" | city=="Düsseldorf" | city=="Freiburg" | city=="Karlsruhe" | city=="Köln" | city=="Mannheim" | city=="Münster" | city=="Stuttgart")
replace storesclosed=1 if (date>=date("18mar2020","DMY") & date<date("22apr2020","DMY") & city=="Berlin") | 	(date>=date("18mar2020","DMY") & date<date("24apr2020","DMY") & city=="Erfurt") | 	(date>=date("18mar2020","DMY") & date<date("27apr2020","DMY") & (city=="Ingolstadt" | city=="München" | city=="Nürnberg")) | 		(date>=date("20mar2020","DMY") & date<date("20apr2020","DMY") & city=="Leipzig") | 	(date>=date("21mar2020","DMY") & date<date("20apr2020","DMY") & city=="Osnabrück") | 		(date>=date("18mar2020","DMY") & date<date("18apr2020","DMY") & city=="Saarbrücken")
replace storesclosed=0 if storesclosed==.


**restaurants closed
gen restaurantsclosed=1 if date>=date("20mar2020","DMY") & date<date("15may2020","DMY") & (city=="Darmstadt" | city=="Frankfurt a.m." | city=="Wiesbaden")
replace restaurantsclosed=1 if date>=date("18mar2020","DMY") & date<date("11may2020","DMY") & (city=="Bonn" | city=="Dortmund" | city=="Düsseldorf" | city=="Köln" | city=="Münster")
replace restaurantsclosed=1 if date>=date("21mar2020","DMY") & date<date("18may2020","DMY") & (city=="Freiburg" | city=="Karlsruhe" | city=="Mannheim" | city=="Stuttgart")
replace restaurantsclosed=1 if date>=date("23mar2020","DMY") & date<date("15may2020","DMY") & city=="Berlin" | date>=date("18mar2020","DMY") & date<date("15may2020","DMY") & city=="Erfurt" | 	date>=date("18mar2020","DMY") & date<date("18may2020","DMY") & (city=="Ingolstadt" | city=="München" | city=="Nürnberg") | 	date>=date("20mar2020","DMY") & date<date("15may2020","DMY") & city=="Leipzig" | 	date>=date("21mar2020","DMY") & date<date("11may2020","DMY") & city=="Osnabrück" | 		date>=date("20mar2020","DMY") & date<date("18may2020","DMY") & city=="Saarbrücken" | 	date>=date("21mar2020","DMY") & date<date("13may2020","DMY") & (city=="Hamburg" | city=="Mainz") | 	date>=date("21mar2020","DMY") & date<date("11may2020","DMY") & city=="Hannover"
replace restaurantsclosed=0 if restaurantsclosed==.


***Create weekend/holidays variable
gen weekend_hol=1 if weekday=="Saturday" | weekday=="Sunday" | holiday==1
replace weekend_hol=0 if weekend_hol==.

***Create variable that captures holidays, sundays and closings during the pandemic
gen closed_sunholclo=1 if weekday=="Sunday" | holiday==1 | storesclosed==1
replace closed_sunholclo=0 if closed_sunholclo==.

gen closed_sunhol=1 if weekday=="Sunday" | holiday==1
replace closed_sunhol=0 if closed_sunhol==.

gen closed_holclosed=1 if holiday==1 | storesclosed==1 & restaurantsclosed==1
replace closed_holclosed=0 if closed_holclosed==.

***Weekend/not working
gen noworkday=1 if weekday=="Sunday" | weekday=="Saturday" | holiday==1 | shopsclosed==1
replace noworkday=0 if noworkday==.

***Sunday or holidays
gen sunhol=1 if weekday=="Sunday" | holiday==1


***Take Log
gen logped=log(ped)

***Encode more variables
encode(location), gen(location_num)
encode(weather_short), gen(weather_short_num)

***Destring variables
destring Verstädterung_Schlüssel, replace

*****Labeling all variables in my dataset
label variable location "Location of Pedestrian-data"
label variable weekday "day of week"
label variable incidents "1 if incident of ped-measurement"
label variable data_available "1 if data available, 0 if filled up"
label variable time_clock "time of the day"
label variable location_ID "ID for each location from ped-data"
label variable holiday "1 if public holiday at this location"
label variable schoolfree "1 if schoool holidays at that location"
label variable Gemeindename "County name"
label variable landkreis_ID "County ID from official county-data"
label variable firsttime "Indicator when ped data is available for a location"
label variable week "week of the year"
label variable temp_binned "binned hourly temperature data"
label variable shopsclosed "Indicator if shops are closed (based on nation wide indicator)"
label variable restclosed "Indicator if restaurants (and shops) are closed (based on nation wide indicator)"
label variable masks "1 if masks are recommended/necessary"
label variable closed_sunholclo "1 if sunday, holiday or stores and restaurants closed"
label variable closed_sunhol "1 if sunday or holiday"
label variable closed_holclosed "1 if holiday or shops closed"
label variable noworkday "1 if Sat, Sun, hol or shops closed"
label variable Verstädterung_Schlüssel "01=dicht besiedelt, 02=mittel, 03=gering besiedelt"


***Correct names which cause problems in Stata
replace location="Goethestraße,Frankfurt" if location=="Goethestraße,Frankfurta.M."
replace location="GroßeBockenheimerStraße,Frankfurt" if location=="GroßeBockenheimerStraße,Frankfurta.M."


***Save dataset
save "${statadata}04_Dataset_Hourly_Merged.dta", replace

