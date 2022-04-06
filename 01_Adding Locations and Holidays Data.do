/***************************************
Structuring the merged Hystreet data

***************************************/
version 15.1
set more off
set type double, permanent
clear all

set dp period, permanent
set autotabgraphs on

global path = "C:\Users\adamd\OneDrive\Pulpit\RA EE\PedestrianDataAnalysis\Pedestrian Data Analysis\"
cd "${path}"
global raw = "${path}Input\Hystreet-data\"
global statadata = "${path}Stata Data\"
global temp = "${path}temp\"

*****************************************

use "${statadata}00_Hystreet-data_long", clear

***Define the state (Bundesland) for each city
gen Bundesland="BE" if strpos(location, ",Berlin")>0
replace Bundesland="BW" if (strpos(location, ",Biberach")>0 | strpos(location, ",Heilbronn")>0 | strpos(location, ",Heidelberg")>0 | strpos(location, ",Ulm")>0 | strpos(location, ",Freiburg")>0 | strpos(location, ",Karlsruhe")>0 | strpos(location, ",Stuttgart")>0 | strpos(location, ",Mannheim")>0 | strpos(location, ",Reutlingen")>0) & Bundesland==""


replace Bundesland="BY" if (strpos(location, ",Augsburg")>0 | strpos(location, ",Nürnberg")>0 | strpos(location, ",Bamberg")>0 | strpos(location, ",Erlangen")>0 | strpos(location, ",München")>0 | strpos(location, ",Ingolstadt")>0 | strpos(location, ",Passau")>0 | strpos(location, ",Würzburg")>0) & Bundesland==""

replace Bundesland="HB" if strpos(location, ",Bremen")>0 & Bundesland==""

replace Bundesland="HE" if (strpos(location, ",Darmstadt")>0 | strpos(location, ",Frankfurt")>0 | strpos(location, ",Wiesbaden")>0 | strpos(location, ",Gießen")>0 | strpos(location, ",Limburg")>0) & Bundesland==""
replace Bundesland="HH" if strpos(location, ",Hamburg")>0 & Bundesland==""
replace Bundesland="MV" if strpos(location, ",Rostock")>0 & Bundesland==""
replace Bundesland="NI" if (strpos(location, ",Oldenburg")>0 | strpos(location, ",Braunschweig")>0 | strpos(location, ",Osnabrück")>0 | strpos(location, ",Hannover")>0 | strpos(location, ",Hildesheim")>0 | strpos(location, ",Göttingen")>0 | strpos(location, ",Celle")>0) & Bundesland==""

replace Bundesland="NW" if (strpos(location, ",Aachen")>0 | strpos(location, ",Münster")>0 | strpos(location, ",Bielefeld")>0 | strpos(location, ",Brilon")>0 | strpos(location, ",Köln")>0 | strpos(location, ",Düsseldorf")>0 | strpos(location, ",Bergisch-Gladbach")>0 | strpos(location, ",Mönchengladbach")>0 | strpos(location, ",Krefeld")>0 | strpos(location, ",Essen")>0 | strpos(location, ",Lemgo")>0 | strpos(location, ",Bocholt")>0 | strpos(location, ",Bonn")>0 | strpos(location, ",Wuppertal")>0 | strpos(location, ",Dortmund")>0 | strpos(location, ",Paderborn")>0) & Bundesland==""

replace Bundesland="RP" if (strpos(location, ",Mainz")>0 | strpos(location, ",Trier")>0 | strpos(location, ",Koblenz")>0) & Bundesland==""
replace Bundesland="SH" if (strpos(location, ",Lübeck")>0 | strpos(location, ",Flensburg")>0 | strpos(location, ",Kiel")>0) & Bundesland==""
replace Bundesland="SL" if strpos(location, ",Saarbrücken")>0 & Bundesland==""
replace Bundesland="SN" if strpos(location, ",Leipzig")>0 | strpos(location, ",Dresden")>0 & Bundesland==""
replace Bundesland="TH" if strpos(location, ",Erfurt")>0 & Bundesland==""

//Bundesländer missing in the data: Brandenburg and Sachsen-Anhalt

rename timeofmeasurement time

***Create numeric ID variable (to be able to treat data as cross-sectional panel data)
egen location_ID = group(location)

***Define data as cross-sectional panel data
sort location_ID date_complete

duplicates report location_ID date_complete
duplicates drop location_ID date_complete, force

tsset location_ID date_complete, delta (1 hour)


*****Fill up missing dates, then filling up the other values correctly
tsfill //this fills up only gaps in the middle of the data
tsfill, full //this fills all data from the start to the end of the whole period

*Bundesland and location
gsort location_ID -date_complete
replace location = location[_n-1] if missing(location)
replace Bundesland = Bundesland[_n-1] if missing(Bundesland) 

sort location_ID date_complete

*Clock time
replace time_clock=hh(date_complete) if date==.

*Date
replace date=dofC(date_complete) if date==.
format date %td

gen year=yofd(date)
gen month=month(date)
gen day=day(date)

*Define which data was not available (i.e. was filled up)
replace data_available=0 if data_available==.

***Define public holidays (Source: https://www.dgb.de/gesetzliche-feiertage-deutschland-2019-2020)
*National holidays
gen holiday=1 if month==1 & day==1	//Neujahr
replace holiday=1 if date==date("30Mar2018","DMY") | date==date("19Apr2019","DMY") | date==date("10Apr2020","DMY")	//Karfreitag
replace holiday=1 if date==date("02Apr2018","DMY") | date==date("22Apr2019","DMY") | date==date("13Apr2020","DMY")	//Ostermontag
replace holiday=1 if month==5 & day==1	//Tag der Arbeit
replace holiday=1 if date==date("10May2018","DMY") |date==date("30May2019","DMY") | date==date("21May2020","DMY")	//Christi Himmelfahrt
replace holiday=1 if date==date("21May2018","DMY") | date==date("10Jun2019","DMY") | date==date("01Jun2020","DMY")	//Pfingstmontag
replace holiday=1 if month==10 & day==3	//Tag der deutschen Einheit
replace holiday=1 if month==12 & day==25 //1. Weihnachtsfeiertag
replace holiday=1 if month==12 & day==25 //2. Weihnachtsfeiertag


*Regional holidays
replace holiday=1 if (month==1 & day==6) & (Bundesland=="BW" | Bundesland=="BY" | Bundesland=="ST")	//Heilige Drei Könige; holiday in Baden-Württemb., Bayern, Sachsen-Anhalt
replace holiday=1 if month==3 & day==8 & Bundesland=="BE" & (year==2019 | year==2020)	//Intern. Frauentag; holiday in Berlin since 2019
replace holiday=1 if date==date("08May2020","DMY") & Bundesland=="BE"	//75. Jahrestag der Befreiung vom Nationalsozialismus; holiday in Berlin
replace holiday=1 if (date==date("31May2018","DMY") | date==date("20Jun2019","DMY") | date==date("11Jun2020","DMY")) & (Bundesland=="BW" | Bundesland=="BY" | Bundesland=="HE" | Bundesland=="NW" | Bundesland=="RP" | Bundesland=="SL")	//Fronleichnam
replace holiday=1 if month==8 & day==8 & strpos(location, "Augsburg")>0	//Augsburger Friedensfest
replace holiday=1 if month==8 & day==15 & (Bundesland=="SL" | Bundesland=="BY")	//Mariä Himmelfahrt; holiday in Saarland and majority of Bayern
replace holiday=1 if month==9 & day==20 & Bundesland=="TH"	//Weltkindertag; holiday in Thüringen
replace holiday=1 if month==10 & day==31 & (Bundesland=="HB" | Bundesland=="HH" |Bundesland=="MV" | Bundesland=="NI" | Bundesland=="SN" | Bundesland=="ST" | Bundesland=="SH" | Bundesland=="TH")	//Reformationstag
replace holiday=1 if month==11 & day==1 & (Bundesland=="BW" | Bundesland=="BY" | Bundesland=="NW" | Bundesland=="RP" | Bundesland=="SL")	//Allerheiligen
replace holiday=1 if (date==date("21Nov2018","DMY") | date==date("20Nov2019","DMY") | date==date("18Nov2020","DMY")) & Bundesland=="SN"	//Buß- und Bettag

replace holiday=0 if holiday==.


***School holidays (not used in final analysis because it showed no significant effects or changes in results) (sources: https://www.kmk.org/fileadmin/Dateien/pdf/Ferienkalender/FER17_18.pdf; https://www.kmk.org/fileadmin/Dateien/pdf/Ferienkalender/FER18_19.pdf; https://www.kmk.org/fileadmin/Dateien/pdf/Ferienkalender/FER19_20.pdf)
*BW
gen schoolfree=1 if ((date>=date("22May2018","DMY") & date<=date("02Jun2018","DMY")) | (date>=date("26Jun2018","DMY") & date<=date("08Sep2018","DMY")) | (date>=date("29Oct2018","DMY") & date<=date("02Nov2018","DMY")) | (date>=date("24Dec2018","DMY") & date<=date("05Jan2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("27Apr2019","DMY")) | (date>=date("11Jun2019","DMY") & date<=date("21Jun2019","DMY")) | (date>=date("29Jul2019","DMY") & date<=date("10Sep2019","DMY")) | (date>=date("28Oct2019","DMY") & date<=date("31Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("04Jan2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("18Apr2020","DMY")) | (date>=date("02Jun2020","DMY") & date<=date("13Jun2020","DMY")) | (date>=date("30Jul2020","DMY") & date<=date("12Sep2020","DMY"))) & Bundesland=="BW"

*BY
replace schoolfree=1 if ((date>=date("22May2018","DMY") & date<=date("02Jun2018","DMY")) | (date>=date("30Jun2018","DMY") & date<=date("10Sep2018","DMY")) | (date>=date("29Oct2018","DMY") & date<=date("02Nov2018","DMY")) | (date>=date("22Dec2018","DMY") & date<=date("05Jan2019","DMY")) | (date>=date("04Mar2019","DMY") & date<=date("08Mar2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("27Apr2019","DMY")) | (date>=date("11Jun2019","DMY") & date<=date("21Jun2019","DMY")) | (date>=date("29Jul2019","DMY") & date<=date("09Sep2019","DMY")) | (date>=date("28Oct2019","DMY") & date<=date("31Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("04Jan2020","DMY")) | (date>=date("24Feb2020","DMY") & date<=date("28Feb2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("18Apr2020","DMY")) | (date>=date("02Jun2020","DMY") & date<=date("13Jun2020","DMY")) | (date>=date("27Jul2020","DMY") & date<=date("07Sep2020","DMY"))) & Bundesland=="BY"

*BE
replace schoolfree=1 if ((date==date("11May2018","DMY") | date==date("22May2018","DMY")) | (date>=date("05Jul2018","DMY") & date<=date("17Aug2018","DMY")) | (date>=date("22Oct2018","DMY") & date<=date("02Nov2018","DMY")) | (date>=date("22Dec2018","DMY") & date<=date("05Jan2019","DMY")) | (date>=date("04Feb2019","DMY") & date<=date("09Feb2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("26Apr2019","DMY")) | date==date("31May2019","DMY") | date==date("11Jun2019","DMY") | (date>=date("20Jun2019","DMY") & date<=date("02Aug2019","DMY")) | date==date("04Oct2019","DMY") | (date>=date("07Oct2019","DMY") & date<=date("19Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("04Jan2020","DMY")) | (date>=date("03Feb2020","DMY") & date<=date("08Feb2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("17Apr2020","DMY")) | date==date("22May2020","DMY") |  (date>=date("25Jun2020","DMY") & date<=date("07Aug2020","DMY"))) & Bundesland=="BE"

*HB
replace schoolfree=1 if ((date==date("11May2018","DMY") | date==date("22May2018","DMY")) | (date>=date("28Jun2018","DMY") & date<=date("08Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("13Oct2018","DMY")) | (date>=date("24Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("31Jan2019","DMY") & date<=date("01Feb2019","DMY")) | (date>=date("06Apr2019","DMY") & date<=date("23Apr2019","DMY")) | date==date("31May2019","DMY") | date==date("11Jun2019","DMY") | (date>=date("04Jul2019","DMY") & date<=date("14Aug2019","DMY")) | (date>=date("04Oct2019","DMY") & date<=date("18Oct2019","DMY")) | (date>=date("21Dec2019","DMY") & date<=date("06Jan2020","DMY")) | (date>=date("03Feb2020","DMY") & date<=date("04Feb2020","DMY")) | (date>=date("28Mar2020","DMY") & date<=date("14Apr2020","DMY")) | date==date("22May2020","DMY") | date==date("02Jun2020","DMY") | (date>=date("16Jul2020","DMY") & date<=date("26Aug2020","DMY"))) & Bundesland=="HB"

*HH
replace schoolfree=1 if ((date>=date("07May2018","DMY") & date<=date("11May2018","DMY")) | (date>=date("05Jul2018","DMY") & date<=date("15Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("12Oct2018","DMY")) | (date>=date("20Dec2018","DMY") & date<=date("04Jan2019","DMY")) | date==date("01Feb2019","DMY") | (date>=date("04Mar2019","DMY") & date<=date("15Mar2019","DMY")) | (date>=date("13May2019","DMY") & date<=date("17May2019","DMY")) | date==date("31May2019","DMY") | (date>=date("27Jun2019","DMY") & date<=date("07Aug2019","DMY")) | (date>=date("04Oct2019","DMY") & date<=date("18Oct2019","DMY")) | date==date("01Nov2019","DMY") | (date>=date("20Dec2019","DMY") & date<=date("03Jan2020","DMY")) | date==date("31Jan2020","DMY") | (date>=date("02Mar2020","DMY") & date<=date("13Mar2020","DMY")) | (date>=date("18May2020","DMY") & date<=date("22May2020","DMY")) | (date>=date("25Jun2020","DMY") & date<=date("05Aug2020","DMY"))) & Bundesland=="HH"


*HE
replace schoolfree=1 if ((date>=date("25Jul2018","DMY") & date<=date("03Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("13Oct2018","DMY")) | (date>=date("24Dec2018","DMY") & date<=date("12Jan2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("27Apr2019","DMY")) | (date>=date("01Jul2019","DMY") & date<=date("09Aug2019","DMY")) | (date>=date("30Sep2019","DMY") & date<=date("12Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("11Jan2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("18Apr2020","DMY")) | (date>=date("06Jul2020","DMY") & date<=date("14Aug2020","DMY"))) & Bundesland=="HE"

*MV
replace schoolfree=1 if (date==date("11May2018","DMY") |(date>=date("18May2018","DMY") & date<=date("22May2018","DMY")) | (date>=date("09Jul2018","DMY") & date<=date("18Aug2018","DMY")) | (date>=date("08Oct2018","DMY") & date<=date("13Oct2018","DMY")) | (date>=date("01Nov2018","DMY") & date<=date("02Nov2018","DMY")) | (date>=date("24Dec2018","DMY") & date<=date("05Jan2019","DMY")) | (date>=date("04Feb2019","DMY") & date<=date("15Feb2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("24Apr2019","DMY")) | date==date("31May2019","DMY") | (date>=date("07Jun2019","DMY") & date<=date("11Jun2019","DMY")) | (date>=date("01Jul2019","DMY") & date<=date("10Aug2019","DMY")) | (date>=date("04Oct2019","DMY") & date<=date("12Oct2019","DMY")) | date==date("01Nov2019","DMY") | (date>=date("23Dec2019","DMY") & date<=date("04Jan2020","DMY")) | (date>=date("10Feb2020","DMY") & date<=date("21Feb2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("15Apr2020","DMY")) | date==date("22May2020","DMY") | (date>=date("29May2020","DMY") & date<=date("02Jun2020","DMY")) | (date>=date("22Jun2020","DMY") & date<=date("01Aug2020","DMY"))) & Bundesland=="MV"


*NI
replace schoolfree=1 if ((date==date("11May2018","DMY") | date==date("22May2018","DMY")) | (date>=date("28Jun2018","DMY") & date<=date("08Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("12Oct2018","DMY")) | (date>=date("24Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("31Jan2019","DMY") & date<=date("01Feb2019","DMY")) | (date>=date("08Apr2019","DMY") & date<=date("23Apr2019","DMY")) | date==date("31May2019","DMY") | date==date("11Jun2019","DMY") | (date>=date("04Jul2019","DMY") & date<=date("14Aug2019","DMY")) | (date>=date("04Oct2019","DMY") & date<=date("18Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("06Jan2020","DMY")) | (date>=date("03Feb2020","DMY") & date<=date("04Feb2020","DMY")) | (date>=date("30Mar2020","DMY") & date<=date("14Apr2020","DMY")) | date==date("22May2020","DMY") | date==date("02Jun2020","DMY") | (date>=date("16Jul2020","DMY") & date<=date("26Aug2020","DMY"))) & Bundesland=="NI"


*NW
replace schoolfree=1 if ((date>=date("22May2018","DMY") & date<=date("25May2018","DMY")) | (date>=date("16Jul2018","DMY") & date<=date("28Aug2018","DMY")) | (date>=date("15Oct2018","DMY") & date<=date("27Oct2018","DMY")) | (date>=date("21Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("27Apr2019","DMY")) | date==date("11Jun2019","DMY") | (date>=date("15Jul2019","DMY") & date<=date("27Aug2019","DMY")) | (date>=date("14Oct2019","DMY") & date<=date("26Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("06Jan2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("18Apr2020","DMY")) | date==date("02Jun2020","DMY") | (date>=date("29Jun2020","DMY") & date<=date("11Aug2020","DMY"))) & Bundesland=="NW"


*RP
replace schoolfree=1 if ((date>=date("25Jun2018","DMY") & date<=date("03Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("12Oct2018","DMY")) | (date>=date("20Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("25Feb2019","DMY") & date<=date("01Mar2019","DMY")) | (date>=date("23Apr2019","DMY") & date<=date("30Apr2019","DMY")) | (date>=date("01Jul2019","DMY") & date<=date("09Aug2019","DMY")) | (date>=date("30Sep2019","DMY") & date<=date("11Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("06Jan2020","DMY")) | (date>=date("17Feb2020","DMY") & date<=date("21Feb2020","DMY")) | (date>=date("09Apr2020","DMY") & date<=date("17Apr2020","DMY")) | (date>=date("06Jul2020","DMY") & date<=date("14Aug2020","DMY"))) & Bundesland=="RP"

*SL
replace schoolfree=1 if ((date>=date("25Jun2018","DMY") & date<=date("03Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("12Oct2018","DMY")) | (date>=date("20Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("25Feb2019","DMY") & date<=date("05Mar2019","DMY")) | (date>=date("17Apr2019","DMY") & date<=date("26Apr2019","DMY")) | (date>=date("01Jul2019","DMY") & date<=date("09Aug2019","DMY")) | (date>=date("07Oct2019","DMY") & date<=date("18Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("03Jan2020","DMY")) | (date>=date("17Feb2020","DMY") & date<=date("25Feb2020","DMY")) | (date>=date("14Apr2020","DMY") & date<=date("24Apr2020","DMY")) | (date>=date("06Jul2020","DMY") & date<=date("14Aug2020","DMY"))) & Bundesland=="SL"


*SN
replace schoolfree=1 if (date==date("11May2018","DMY") | (date>=date("19May2018","DMY") & date<=date("22May2018","DMY")) | (date>=date("02Jul2018","DMY") & date<=date("10Aug2018","DMY")) | (date>=date("08Oct2018","DMY") & date<=date("20Oct2018","DMY")) | (date>=date("22Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("18Feb2019","DMY") & date<=date("02Mar2019","DMY")) | (date>=date("19Apr2019","DMY") & date<=date("26Apr2019","DMY")) | date==date("31May2019","DMY") | (date>=date("08Jul2019","DMY") & date<=date("16Aug2019","DMY")) | (date>=date("14Oct2019","DMY") & date<=date("25Oct2019","DMY")) | (date>=date("21Dec2019","DMY") & date<=date("03Jan2020","DMY")) | (date>=date("10Feb2020","DMY") & date<=date("22Feb2020","DMY")) | (date>=date("10Apr2020","DMY") & date<=date("18Apr2020","DMY")) | date==date("22May2020","DMY") |  (date>=date("20Jul2020","DMY") & date<=date("28Aug2020","DMY"))) & Bundesland=="SN"


*SH
replace schoolfree=1 if (date==date("11May2018","DMY") | (date>=date("09Jul2018","DMY") & date<=date("18Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("19Oct2018","DMY")) | (date>=date("21Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("04Apr2019","DMY") & date<=date("18Apr2019","DMY")) | date==date("31May2019","DMY") | (date>=date("01Jul2019","DMY") & date<=date("10Aug2019","DMY")) | (date>=date("04Oct2019","DMY") & date<=date("18Oct2019","DMY")) | (date>=date("23Dec2019","DMY") & date<=date("06Jan2020","DMY")) | (date>=date("30Mar2020","DMY") & date<=date("17Apr2020","DMY")) | date==date("22May2020","DMY") | (date>=date("29Jun2020","DMY") & date<=date("08Aug2020","DMY"))) & Bundesland=="SH"

*TH
replace schoolfree=1 if (date==date("11May2018","DMY") | (date>=date("02Jul2018","DMY") & date<=date("11Aug2018","DMY")) | (date>=date("01Oct2018","DMY") & date<=date("13Oct2018","DMY")) | (date>=date("21Dec2018","DMY") & date<=date("04Jan2019","DMY")) | (date>=date("11Feb2019","DMY") & date<=date("15Feb2019","DMY")) | (date>=date("15Apr2019","DMY") & date<=date("27Apr2019","DMY")) | date==date("31May2019","DMY") | (date>=date("08Jul2019","DMY") & date<=date("17Aug2019","DMY")) | (date>=date("07Oct2019","DMY") & date<=date("19Oct2019","DMY")) | (date>=date("21Dec2019","DMY") & date<=date("03Jan2020","DMY")) | (date>=date("10Feb2020","DMY") & date<=date("14Feb2020","DMY")) | (date>=date("06Apr2020","DMY") & date<=date("18Apr2020","DMY")) | date==date("22May2020","DMY") | (date>=date("20Jul2020","DMY") & date<=date("29Aug2020","DMY"))) & Bundesland=="TH"

replace schoolfree=0 if schoolfree==.


***Define the city for each specific location
gen city="Aachen" if strpos(location, "Aachen")>0
replace city="Augsburg" if strpos(location, "Augsburg")>0
replace city="Bamberg" if strpos(location, "Bamberg")>0
replace city="Bergisch-Gladbach" if strpos(location, "Bergisch-Gladbach")>0
replace city="Berlin" if strpos(location, "Berlin")>0
replace city="Biberach" if strpos(location, "Biberach")>0
replace city="Bielefeld" if strpos(location, "Bielefeld")>0
replace city="Bocholt" if strpos(location, "Bocholt")>0
replace city="Bonn" if strpos(location, "Bonn")>0
replace city="Braunschweig" if strpos(location, "Braunschweig")>0
replace city="Bremen" if strpos(location, "Bremen")>0
replace city="Brilon" if strpos(location, "Brilon")>0
replace city="Celle" if strpos(location, "Celle")>0
replace city="Darmstadt" if strpos(location, "Darmstadt")>0
replace city="Dortmund" if strpos(location, "Dortmund")>0
replace city="Dresden" if strpos(location, "Dresden")>0
replace city="Düsseldorf" if strpos(location, "Düsseldorf")>0
replace city="Erfurt" if strpos(location, "Erfurt")>0
replace city="Erlangen" if strpos(location, "Erlangen")>0
replace city="Essen" if strpos(location, "Essen")>0
replace city="Flensburg" if strpos(location, "Flensburg")>0
replace city="Frankfurt a.m." if strpos(location, "Frankfurt")>0
replace city="Freiburg" if strpos(location, "Freiburg")>0
replace city="Gießen" if strpos(location, "Gießen")>0
replace city="Göttingen" if strpos(location, "Göttingen")>0
replace city="Hamburg" if strpos(location, "Hamburg")>0
replace city="Hannover" if strpos(location, "Hannover")>0
replace city="Heidelberg" if strpos(location, "Heidelberg")>0
replace city="Heilbronn" if strpos(location, "Heilbronn")>0
replace city="Hildesheim" if strpos(location, "Hildesheim")>0
replace city="Ingolstadt" if strpos(location, "Ingolstadt")>0
replace city="Karlsruhe" if strpos(location, "Karlsruhe")>0
replace city="Kiel" if strpos(location, "Kiel")>0
replace city="Koblenz" if strpos(location, "Koblenz")>0
replace city="Köln" if strpos(location, "Köln")>0
replace city="Krefeld" if strpos(location, "Krefeld")>0
replace city="Leipzig" if strpos(location, "Leipzig")>0
replace city="Lemgo" if strpos(location, "Lemgo")>0
replace city="Limburg" if strpos(location, "Limburg")>0
replace city="Lübeck" if strpos(location, "Lübeck")>0
replace city="Mainz" if strpos(location, "Mainz")>0
replace city="Mannheim" if strpos(location, "Mannheim")>0
replace city="Mönchengladbach" if strpos(location, "Mönchengladbach")>0
replace city="München" if strpos(location, "München")>0
replace city="Münster" if strpos(location, "Münster")>0
replace city="Nürnberg" if strpos(location, "Nürnberg")>0
replace city="Oldenburg" if strpos(location, "Oldenburg")>0
replace city="Osnabrück" if strpos(location, "Osnabrück")>0
replace city="Paderborn" if strpos(location, "Paderborn")>0
replace city="Passau" if strpos(location, "Passau")>0
replace city="Reutlingen" if strpos(location, "Reutlingen")>0
replace city="Rostock" if strpos(location, "Rostock")>0
replace city="Saarbrücken" if strpos(location, "Saarbrücken")>0
replace city="Stuttgart" if strpos(location, "Stuttgart")>0
replace city="Trier" if strpos(location, "Trier")>0
replace city="Ulm" if strpos(location, "Ulm")>0
replace city="Wiesbaden" if strpos(location, "Wiesbaden")>0
replace city="Wuppertal" if strpos(location, "Wuppertal")>0
replace city="Würzburg" if strpos(location, "Würzburg")>0


save "${statadata}01_Hystreet_Data", replace
