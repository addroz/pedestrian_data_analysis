/***************************************
Reading in the Landkreise and according cities in Germany

***************************************/
version 15.1
set more off
set type double, permanent
clear all

set dp period, permanent
set autotabgraphs on


global path = "C:\Users\adamd\OneDrive\Pulpit\RA EE\PedestrianDataAnalysis\Pedestrian Data Analysis\"
cd "${path}"
global raw = "${path}Input\"
global statadata = "${path}Stata Data\"
global output = "${path}Output\"
global graphs = "${path}Graphs\"
global temp = "${path}temp\"

*****************************************

***Data source for Landkreise: https://www.destatis.de/DE/Themen/Laender-Regionen/Regionales/Gemeindeverzeichnis/Administrativ/Archiv/GVAuszugQ/AuszugGV3QAktuell.html

import excel "${path}Input\Landkreise und weitere Daten_Stand 30092020.xlsx", sheet("Onlineprodukt_Gemeinden") cellrange(A7:T16076)

rename (A B C D E F G H I J K L M N O P Q R S T) (Satzart Textkennzeichen Land RB Kreis VB Gem Gemeindename Flächekm2 Bev_insgesamt Bev_maenl Bev_weibl Bev_jekm2 Postleitzahl Längengrad Breitengrad Reisegebiet_Schlüssel Reisegebiet_Bezeichnung Verstädterung_Schlüssel Verstädterung_Bezeichnung)


***gen laenderid like in infection-dataset
gen landkreis_ID=Land+RB+Kreis if Land!="" & RB!="" & Kreis!=""
*tab landkreis_ID

rename Land Bundesland_num
destring Bundesland_num, replace


***Same city names as in Hystreet-Dataset to merge
gen city=Gemeindename
replace city = subinstr(city, ", Stadt", "", .)
replace city = subinstr(city, ", Landeshauptstadt", "", .)
replace city = subinstr(city, ", Universitätsstadt", "", .)
replace city = subinstr(city, ", Freie und Hansestadt", "", .)
replace city = subinstr(city, ", Hansestadt", "", .)
replace city = subinstr(city, ", Wissenschaftsstadt", "", .)


*by hand for  Limburg, Freiburg im Breisgau, Oldenburg, Frankfurt am Main, Bergisch Gladbach, Münster
replace city = "Limburg" if city=="Limburg a.d. Lahn, Kreisstadt"
replace city = "Freiburg" if city=="Freiburg im Breisgau"
replace city = "Oldenburg" if city=="Oldenburg (Oldenburg)"
replace city = "Frankfurt a.m." if city=="Frankfurt am Main"

replace city = "Bergisch-Gladbach" if city=="Bergisch Gladbach"
*replace city = "Münster" if city==""

***Drop not needed observations and mark duplicates
drop if Postleitzahl=="" //if there is no PLZ it is a region and not a city

sort Gemeindename landkreis_ID Bundesland_num
quietly by Gemeindename landkreis_ID Bundesland_num:  gen dup = cond(_N==1,0,_n)
*tab dup

*drop if dup>=2

sort city Bundesland_num
quietly by city Bundesland_num:  gen dup2 = cond(_N==1,0,_n)
*tab dup2

drop if dup!=0
drop if dup2!=0 & city!="Münster"


***save as statadata
save "${statadata}02_Landkreise.dta", replace

