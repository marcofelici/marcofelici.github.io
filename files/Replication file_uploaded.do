*********************************************************************************************************************************** Marco Felici, 23/08/2024
*** Replication file for "The housing tenure gradient of mental health in the United Kingdom after the Global Financial Crisis" ***
***********************************************************************************************************************************

** Download the data from the UK Data Service
* - Main Survey: University of Essex, Institute for Social and Economic Research. (2023). Understanding Society: Waves 1-13, 2009-2022 and Harmonised BHPS: Waves 1-18, 1991-2009. [data collection]. 18th Edition. UK Data Service. SN: 6614, DOI: http://doi.org/10.5255/UKDA-SN-6614-19
* - COVID-19 Module: University of Essex, Institute for Social and Economic Research. (2021). Understanding Society: COVID-19 Study, 2020-2021. [data collection]. 11th Edition. UK Data Service. SN: 8644, DOI: http://doi.org/10.5255/UKDA-SN-8644-11

** Set up the folder paths

global basepath "[INSERT PATH]"
global datapath "$basepath\Data\6614stata_20240120\UKDA-6614-stata\stata\stata13_se\ukhls"
global covidDatapath "$basepath\Data\8644stata_325C486A55C424120D30D46DD026D8FC_V1\UKDA-8644-stata\stata\stata13_se"
global outpath "$basepath\Output"

** Main analysis: Create year by year estimates based on design suggested by Understanding Society, see "Pooling data from different waves for cross-sectional analysis" here: https://www.understandingsociety.ac.uk/documentation/mainstage/user-guides/main-survey-user-guide/how-to-use-weights-analysis-guidance-for-weights-psu-strata/

clear
clear matrix
clear mata

* 2010 to start

set maxvar 10000

use "$datapath\\a_indresp.dta", clear

merge 1:1 pidp using "$datapath\\b_indresp.dta"

ge weight2010=0

replace weight2010=a_indpxus_xw if a_month>=13 & a_month<=24

ge ind=1

sum ind [aw=a_indpxus_xw] if a_month>=1 & a_month<=12

gen bwtdtot=r(sum_w)

sum ind [aw=b_indpxub_xw] if b_month>=1 & b_month<=12

gen cwtdtot=r(sum_w)

replace weight2010=b_indpxub_xw*(bwtdtot/cwtdtot) if b_month>=1 & b_month<=12

ge psu2010=0

replace psu2010=a_psu if a_month>=13 & a_month<=24

replace psu2010=b_psu if b_month>=1 & b_month<=12

ge strata2010=0

replace strata2010=a_strata if a_month>=13 & a_month<=24

replace strata2010=b_strata if b_month>=1 & b_month<=12

svyset psu2010 [pw=weight2010], strata(strata2010) singleunit(centered)

ge scghq1_dv=0

replace scghq1_dv=a_scghq1_dv if a_month>=13 & a_month<=24

replace scghq1_dv=b_scghq1_dv if b_month>=1 & b_month<=12

replace scghq1_dv = . if scghq1_dv < 0

svy: mean scghq1_dv

drop _merge
merge m:1 a_hidp using "$datapath\\a_hhresp.dta", keepusing(a_tenure_dv) 
drop _merge
merge m:1 b_hidp using "$datapath\\b_hhresp.dta", keepusing(b_tenure_dv) 

replace a_tenure_dv = b_tenure_dv if a_tenure_dv == . // We complement earlier wave with info from later one, and then use the former for the tenure variable
replace a_tenure_dv = . if a_tenure_dv < 0
recode a_tenure_dv (4=3) (6/7=4), gen(tenure_dvCollapsed) // Put housing association and local authority renting together, put furnished and unfurnished private renting together.
label define tenureCollapsed 1 "Owned outright" 2 "Owned with mortgage" 3 "Local aut./housing ass. rented" 4 "Privately rented"
label values tenure_dvCollapsed tenureCollapsed

preserve
drop if tenure_dvCollapsed > 4
graph box scghq1_dv [aweight = weight2010], over(tenure_dvCollapsed, label(alt)) noout graphregion(color(white)) ytitle("GHQ-12 indicator") note("")
graph export "$outpath\boxplotByGroup2010MainSurvey.png", width(2000) replace
restore

svy, over(tenure_dvCollapsed): mean scghq1_dv if tenure_dvCollapsed < 5

estimates store mean2010

matrix define overallOutput = (r(table)[1,1..4] \ r(table)[5..6,1..4])
mat coln overallOutput = outright mortgage social private
mat rown overallOutput = b2010 lb2010 ub2010

matrix list overallOutput

summarize scghq1_dv [aweight = weight2010] if tenure_dvCollapsed == 1, detail
matrix define distribution2010 = (`r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize scghq1_dv [aweight = weight2010] if tenure_dvCollapsed == 2, detail
matrix define distribution2010 = (distribution2010 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize scghq1_dv [aweight = weight2010] if tenure_dvCollapsed == 3, detail
matrix define distribution2010 = (distribution2010 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize scghq1_dv [aweight = weight2010] if tenure_dvCollapsed == 4, detail
matrix define distribution2010 = (distribution2010 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')

mat coln distribution2010 = min p1 p5 p10 p25 p50 p75 p90 p95 p99 max
mat rown distribution2010 = outright mortgage social private

* Add remaining years

global letters "b c d e f g h i j k l m"
global years "2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021"
local val = 1
while `val' < 12  {
	local letter = word("$letters", `val')
	use "$datapath\\`letter'_indresp.dta", clear
    local letterLagged = word("$letters", `val' + 1)
	merge 1:1 pidp using "$datapath\\`letterLagged'_indresp.dta"
    
	local year = word("$years", `val')

	ge weight`year'=0
	
	if `val' < 5 {
		replace weight`year'=`letter'_indpxub_xw if `letter'_month>=13 & `letter'_month<=24

		ge ind=1

		sum ind [aw=`letter'_indpxub_xw] if `letter'_month>=1 & `letter'_month<=12

		gen bwtdtot=r(sum_w)

		sum ind [aw=`letterLagged'_indpxub_xw] if `letterLagged'_month>=1 & `letterLagged'_month<=12

		gen cwtdtot=r(sum_w)

		replace weight`year'=`letterLagged'_indpxub_xw*(bwtdtot/cwtdtot) if `letterLagged'_month>=1 & `letterLagged'_month<=12	
	} 
	else {
		replace weight`year'=`letter'_indpxui_xw if `letter'_month>=13 & `letter'_month<=24

		ge ind=1

		sum ind [aw=`letter'_indpxui_xw] if `letter'_month>=1 & `letter'_month<=12

		gen bwtdtot=r(sum_w)

		sum ind [aw=`letterLagged'_indpxui_xw] if `letterLagged'_month>=1 & `letterLagged'_month<=12

		gen cwtdtot=r(sum_w)

		replace weight`year'=`letterLagged'_indpxui_xw*(bwtdtot/cwtdtot) if `letterLagged'_month>=1 & `letterLagged'_month<=12			
	}

	ge psu`year'=0

	replace psu`year'=`letter'_psu if `letter'_month>=13 & `letter'_month<=24

	replace psu`year'=`letterLagged'_psu if `letterLagged'_month>=1 & `letterLagged'_month<=12

	ge strata`year'=0

	replace strata`year'=`letter'_strata if `letter'_month>=13 & `letter'_month<=24

	replace strata`year'=`letterLagged'_strata if `letterLagged'_month>=1 & `letterLagged'_month<=12

	svyset psu`year' [pw=weight`year'], strata(strata`year') singleunit(centered)

	ge scghq1_dv = 0

	replace scghq1_dv = `letter'_scghq1_dv if `letter'_month>=13 & `letter'_month<=24

	replace scghq1_dv = `letterLagged'_scghq1_dv if `letterLagged'_month>=1 & `letterLagged'_month<=12

	replace scghq1_dv = . if scghq1_dv < 0

	svy: mean scghq1_dv

	drop _merge
	merge m:1 `letter'_hidp using "$datapath\\`letter'_hhresp.dta", keepusing(`letter'_tenure_dv) 
	drop _merge
	merge m:1 `letterLagged'_hidp using "$datapath\\`letterLagged'_hhresp.dta", keepusing(`letterLagged'_tenure_dv) 

	replace `letter'_tenure_dv = `letterLagged'_tenure_dv if `letter'_tenure_dv == . // We complement earlier wave with info from later one, and then use the former for the tenure variable
	replace `letter'_tenure_dv = . if `letter'_tenure_dv < 0
	recode `letter'_tenure_dv (4=3) (6/7=4), gen(tenure_dvCollapsed) // Put housing association and local authority renting together, put furnished and unfurnished private renting together.
	label define tenureCollapsed 1 "Owned outright" 2 "Owned with mortgage" 3 "Local aut./housing ass. rented" 4 "Privately rented"
	label values tenure_dvCollapsed tenureCollapsed
	
	preserve
    drop if tenure_dvCollapsed > 4  // Exclude residual tenure categories
    graph box scghq1_dv [aweight = weight`year'], over(tenure_dvCollapsed, label(alt)) noout graphregion(color(white)) ytitle("GHQ-12 indicator") note("")
    graph export "$outpath\boxplotByGroup`year'MainSurvey.png", width(2000) replace
    restore

	svy, over(tenure_dvCollapsed): mean scghq1_dv if tenure_dvCollapsed < 5
	
	estimates store mean`year'

	matrix define newOutput = (r(table)[1,1..4] \ r(table)[5..6,1..4])
	mat rown newOutput = b`year' lb`year' ub`year'

	matrix define overallOutput = (overallOutput \ newOutput)
	
	matrix list overallOutput
	
	summarize scghq1_dv [aweight = weight`year'] if tenure_dvCollapsed == 1, detail
    matrix define distribution`year' = (`r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize scghq1_dv [aweight = weight`year'] if tenure_dvCollapsed == 2, detail
    matrix define distribution`year' = (distribution`year' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize scghq1_dv [aweight = weight`year'] if tenure_dvCollapsed == 3, detail
    matrix define distribution`year' = (distribution`year' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize scghq1_dv [aweight = weight`year'] if tenure_dvCollapsed == 4, detail
    matrix define distribution`year' = (distribution`year' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')

    mat coln distribution`year' = min p1 p5 p10 p25 p50 p75 p90 p95 p99 max
    mat rown distribution`year' = outright mortgage social private
	
	local val = `val' + 1
}

esttab mean2010 mean2011 mean2012 mean2013 mean2014 mean2015 using "$outpath\table1aMainSurvey.tex", replace ci nostar keep(c.scghq1_dv@1.tenure_dvCollapsed c.scghq1_dv@2.tenure_dvCollapsed c.scghq1_dv@3.tenure_dvCollapsed c.scghq1_dv@4.tenure_dvCollapsed) coeflabel(c.scghq1_dv@1.tenure_dvCollapsed "Owned outright" c.scghq1_dv@2.tenure_dvCollapsed "Owned with mortgage" c.scghq1_dv@3.tenure_dvCollapsed "Local aut./housing ass. rented" c.scghq1_dv@4.tenure_dvCollapsed "Privately rented") mtitles("2010" "2011" "2012" "2013" "2014" "2015") nonotes nonumbers 

esttab mean2016 mean2017 mean2018 mean2019 mean2020 mean2021 using "$outpath\table1bMainSurvey.tex", replace ci nostar keep(c.scghq1_dv@1.tenure_dvCollapsed c.scghq1_dv@2.tenure_dvCollapsed c.scghq1_dv@3.tenure_dvCollapsed c.scghq1_dv@4.tenure_dvCollapsed) coeflabel(c.scghq1_dv@1.tenure_dvCollapsed "Owned outright" c.scghq1_dv@2.tenure_dvCollapsed "Owned with mortgage" c.scghq1_dv@3.tenure_dvCollapsed "Local aut./housing ass. rented" c.scghq1_dv@4.tenure_dvCollapsed "Privately rented") mtitles("2016" "2017" "2018" "2019" "2020" "2021") nonotes nonumbers 

global my_matrix_rownames: rownames overallOutput
disp "$my_matrix_rownames"

clear
svmat overallOutput, names(col)

generate value = ""
forvalues val = 1(3)36 {
	replace value = word("$my_matrix_rownames", `val') in `val'
	local val2 = `val' + 1
	replace value = word("$my_matrix_rownames", `val' + 1) in `val2'
	local val3 = `val' + 2
	replace value = word("$my_matrix_rownames", `val' + 2) in `val3'
}

gen year = substr(value, -4, 4)
destring year, replace
gen statistic = substr(value, 1, 2)
drop value

reshape wide outright mortgage social private, i(year) j(statistic) string

twoway (scatter outrightb2 year) (scatter mortgageb2 year) (scatter socialb2 year) (scatter privateb2 year) (rcap outrightlb outrightub year) (rcap mortgagelb mortgageub year) (rcap sociallb socialub year) (rcap privatelb privateub year), legend(label(1 "Owned outright") label(2 "Owned with mortgage") label(3 "Local aut./housing ass. rented") label(4 "Privately rented") order(1 2 3 4)) graphregion(color(white)) xtitle("") ytitle("GHQ-12 indicator") xlabel(2010(1)2021, alt)
graph export "$outpath\Figure1GHQ_MainSurvey.png", width(2000) replace

esttab matrix(distribution2010) using "$outpath\distribution2010MainSurvey.tex", tex nomtitles replace
esttab matrix(distribution2021) using "$outpath\distribution2021MainSurvey.tex", tex nomtitles replace

** Appendix B: COVID-19 Study estimation

clear
clear matrix
clear mata
estimates clear

* Wave 1 COVID to start

set maxvar 10000

preserve
use "$covidDatapath\mainstage_data_2019\jk_hhresp_cv.dta", clear
drop if j_hidp < 0
save "$covidDatapath\mainstage_data_2019\jk_hhresp_cv_j.dta", replace
restore

preserve
use "$covidDatapath\mainstage_data_2019\jk_hhresp_cv.dta", clear
drop if k_hidp < 0
save "$covidDatapath\mainstage_data_2019\jk_hhresp_cv_k.dta", replace
restore

use "$covidDatapath\ca_indresp_w", clear

svyset psu [pw=ca_betaindin_xw], strata(strata) singleunit(scaled)

replace ca_scghq1_dv = . if ca_scghq1_dv < 0

svy: mean ca_scghq1_dv

merge m:1 j_hidp using "$covidDatapath\mainstage_data_2019\jk_hhresp_cv_j.dta", keepusing(jk_tenure_dv) // For this wave use tenure from mainstage
drop _merge
rename jk_tenure_dv jk_tenure_dv_j

merge m:1 k_hidp using "$covidDatapath\mainstage_data_2019\jk_hhresp_cv_k.dta", keepusing(jk_tenure_dv) 
drop _merge
rename jk_tenure_dv jk_tenure_dv_k
	
gen tenure_dv = jk_tenure_dv_j
replace tenure_dv = jk_tenure_dv_k if tenure_dv == .
replace tenure_dv = . if tenure_dv < 0

recode tenure_dv (4=3) (6/7=4), gen(tenure_dvCollapsed) // Put housing association and local authority renting together, put furnished and unfurnished private renting together.
label define tenureCollapsed 1 "Owned outright" 2 "Owned with mortgage" 3 "Local aut./housing ass. rented" 4 "Privately rented"
label values tenure_dvCollapsed tenureCollapsed

preserve
drop if tenure_dvCollapsed > 4
graph box ca_scghq1_dv [aweight = ca_betaindin_xw], over(tenure_dvCollapsed, label(alt)) noout graphregion(color(white)) ytitle("GHQ-12 indicator") note("")
graph export "$outpath\boxplotByGroupW1CovidSurvey.png", width(2000) replace
restore

gen scghq1_dv = ca_scghq1_dv

svy, over(tenure_dvCollapsed): mean scghq1_dv if tenure_dvCollapsed < 5

estimates store meanW1

matrix define overallOutput = (r(table)[1,1..4] \ r(table)[5..6,1..4])
mat coln overallOutput = outright mortgage social private
mat rown overallOutput = b1 lb1 ub1

matrix list overallOutput

summarize ca_scghq1_dv [aweight = ca_betaindin_xw] if tenure_dvCollapsed == 1, detail
matrix define distribution1 = (`r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize ca_scghq1_dv [aweight = ca_betaindin_xw] if tenure_dvCollapsed == 2, detail
matrix define distribution1 = (distribution1 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize ca_scghq1_dv [aweight = ca_betaindin_xw] if tenure_dvCollapsed == 3, detail
matrix define distribution1 = (distribution1 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize ca_scghq1_dv [aweight = ca_betaindin_xw] if tenure_dvCollapsed == 4, detail
matrix define distribution1 = (distribution1\ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')

mat coln distribution1 = min p1 p5 p10 p25 p50 p75 p90 p95 p99 max
mat rown distribution1 = outright mortgage social private

* Add the remaining waves

global letters "b c d e f g h i"
local val = 1
while `val' < 9  {
	local letter = word("$letters", `val')
	local letterMinus1 = word("$letters", `val' - 1)
	local valPlus1 = `val' + 1
	use "$covidDatapath\\c`letter'_indresp_w.dta", clear
	
	svyset psu [pw = c`letter'_betaindin_xw], strata(strata) singleunit(scaled)	

	replace c`letter'_scghq1_dv = . if c`letter'_scghq1_dv < 0

	svy: mean c`letter'_scghq1_dv
	
	if `val' == 1 {
		merge m:1 j_hidp using "$covidDatapath\mainstage_data_2019\jk_hhresp_cv_j.dta", keepusing(jk_tenure_dv) // For this wave use tenure from mainstage
        drop _merge
        rename jk_tenure_dv jk_tenure_dv_j

        merge m:1 k_hidp using "$covidDatapath\mainstage_data_2019\jk_hhresp_cv_k.dta", keepusing(jk_tenure_dv) 
        drop _merge
        rename jk_tenure_dv jk_tenure_dv_k
		
		gen tenure_dv = cb_hsownd_cv
		replace tenure_dv = 4 if (cb_hsownd_cv == 4 & (jk_tenure_dv_j == 3 | jk_tenure_dv_j == 4)) | (cb_hsownd_cv == 4 & (jk_tenure_dv_k == 3 | jk_tenure_dv_k == 4))
		replace tenure_dv = 6 if (cb_hsownd_cv == 4 & (jk_tenure_dv_j == 6 | jk_tenure_dv_j == 7)) | (cb_hsownd_cv == 4 & (jk_tenure_dv_k == 6 | jk_tenure_dv_k == 7))
		replace tenure_dv = . if cb_hsownd_cv == 4 & jk_tenure_dv_j == . & jk_tenure_dv_k == . // Since in that case we don't know whether is social renting or private renting
		drop if pidp == .
		save "$covidDatapath\c`letter'_indresp_w_tenUpdate.dta", replace
	}
	else if (`val' == 2) {
        merge 1:1 pidp using "$covidDatapath\c`letterMinus1'_indresp_w_tenUpdate.dta", keepusing(tenure_dv)  // Use previous wave tenure
	}
	else if (`val' == 4 | `val' == 6) {
        merge 1:1 pidp using "$covidDatapath\c`letterMinus1'_indresp_w_tenUpdate.dta", keepusing(tenure_dv)  // Use previous wave tenure
		replace tenure_dv = c`letter'_hsownd_cv if c`letter'_hsownd_cv > 0
	}
	else if (`val' == 5 | `val' == 7){
		gen tenure_dv = c`letter'_hsownd_cv
		replace tenure_dv = c`letter'_ff_hsownd_cv if tenure_dv < 0             // Use last available tenure to complement given very low numbers of main variable
		drop if pidp == .
		save "$covidDatapath\c`letter'_indresp_w_tenUpdate.dta", replace
	}
	else {
		gen tenure_dv = c`letter'_hsownd_cv 
		drop if pidp == .
		save "$covidDatapath\c`letter'_indresp_w_tenUpdate.dta", replace
	}

	replace tenure_dv = . if tenure_dv < 0
	recode tenure_dv (3=.) (4=3) (6=4), gen(tenure_dvCollapsed) // Put housing association and local authority renting together, put furnished and unfurnished private renting together.
	label define tenureCollapsed 1 "Owned outright" 2 "Owned with mortgage" 3 "Local aut./housing ass. rented" 4 "Privately rented"
	label values tenure_dvCollapsed tenureCollapsed
	
	preserve
    drop if tenure_dvCollapsed > 4  // Exclude residual tenure categories
    graph box c`letter'_scghq1_dv [aweight = c`letter'_betaindin_xw], over(tenure_dvCollapsed, label(alt)) noout graphregion(color(white)) ytitle("GHQ-12 indicator") note("")
    graph export "$outpath\boxplotByGroupW`valPlus1'CovidSurvey.png", width(2000) replace
    restore
    
	gen scghq1_dv = c`letter'_scghq1_dv
	
	svy, over(tenure_dvCollapsed): mean scghq1_dv if tenure_dvCollapsed < 5
	
	estimates store meanW`valPlus1'

	matrix define newOutput = (r(table)[1,1..4] \ r(table)[5..6,1..4])
	mat rown newOutput = b`valPlus1' lb`valPlus1' ub`valPlus1'

	matrix define overallOutput = (overallOutput \ newOutput)
	
	matrix list overallOutput
	
	summarize c`letter'_scghq1_dv [aweight = c`letter'_betaindin_xw] if tenure_dvCollapsed == 1, detail
    matrix define distribution`valPlus1' = (`r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize c`letter'_scghq1_dv [aweight = c`letter'_betaindin_xw] if tenure_dvCollapsed == 2, detail
    matrix define distribution`valPlus1' = (distribution`valPlus1' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize c`letter'_scghq1_dv [aweight = c`letter'_betaindin_xw] if tenure_dvCollapsed == 3, detail
    matrix define distribution`valPlus1' = (distribution`valPlus1' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize c`letter'_scghq1_dv [aweight = c`letter'_betaindin_xw] if tenure_dvCollapsed == 4, detail
    matrix define distribution`valPlus1' = (distribution`valPlus1' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')

    mat coln distribution`valPlus1' = min p1 p5 p10 p25 p50 p75 p90 p95 p99 max
    mat rown distribution`valPlus1' = outright mortgage social private
	
	local val = `val' + 1
}

esttab meanW1 meanW2 meanW3 meanW4 meanW5 using "$outpath\table1aCovidSurvey.tex", replace ci nostar keep(c.scghq1_dv@1.tenure_dvCollapsed c.scghq1_dv@2.tenure_dvCollapsed c.scghq1_dv@3.tenure_dvCollapsed c.scghq1_dv@4.tenure_dvCollapsed) coeflabel(c.scghq1_dv@1.tenure_dvCollapsed "Owned outright" c.scghq1_dv@2.tenure_dvCollapsed "Owned with mortgage" c.scghq1_dv@3.tenure_dvCollapsed "Local aut./housing ass. rented" c.scghq1_dv@4.tenure_dvCollapsed "Privately rented") mtitles("Wave 1" "Wave 2" "Wave 3" "Wave 4" "Wave 5") nonotes nonumbers 

esttab meanW6 meanW7 meanW8 meanW9 using "$outpath\table1bCovidSurvey.tex", replace ci nostar keep(c.scghq1_dv@1.tenure_dvCollapsed c.scghq1_dv@2.tenure_dvCollapsed c.scghq1_dv@3.tenure_dvCollapsed c.scghq1_dv@4.tenure_dvCollapsed) coeflabel(c.scghq1_dv@1.tenure_dvCollapsed "Owned outright" c.scghq1_dv@2.tenure_dvCollapsed "Owned with mortgage" c.scghq1_dv@3.tenure_dvCollapsed "Local aut./housing ass. rented" c.scghq1_dv@4.tenure_dvCollapsed "Privately rented") mtitles("Wave 6" "Wave 7" "Wave 8" "Wave 9") nonotes nonumbers 

global my_matrix_rownames: rownames overallOutput
disp "$my_matrix_rownames"

clear
svmat overallOutput, names(col)

generate statistic = ""
forvalues val = 1(3)27 {
	replace statistic = "b" in `val'
	local val2 = `val' + 1
	replace statistic = "lb" in `val2'
	local val3 = `val' + 2
	replace statistic = "ub" in `val3'
}

seq wave, f(1) t(9) b(3)

reshape wide outright mortgage social private, i(wave) j(statistic) string

twoway (scatter outrightb wave) (scatter mortgageb wave) (scatter socialb wave) (scatter privateb wave) (rcap outrightlb outrightub wave) (rcap mortgagelb mortgageub wave) (rcap sociallb socialub wave) (rcap privatelb privateub wave), legend(label(1 "Owned outright") label(2 "Owned with mortgage") label(3 "Local aut./housing ass. rented") label(4 "Privately rented") order(1 2 3 4)) graphregion(color(white)) xtitle("Wave") ytitle("GHQ-12 indicator") xlabel(1(1)9, alt)
graph export "$outpath\Figure1GHQ_CovidSurvey.png", width(2000) replace

esttab matrix(distribution1) using "$outpath\distribution1CovidSurvey.tex", tex nomtitles replace
esttab matrix(distribution9) using "$outpath\distribution9CovidSurvey.tex", tex nomtitles replace

** Appendix C: Wave by wave estimation

clear
clear matrix
clear mata

* Wave 1 to start

set maxvar 10000

use "$datapath\\a_indresp.dta", clear

svyset a_psu [pw=a_indpxus_xw], strata(a_strata) singleunit(scaled)

replace a_scghq1_dv = . if a_scghq1_dv < 0

svy: mean a_scghq1_dv

merge m:1 a_hidp using "$datapath\\a_hhresp.dta", keepusing(a_tenure_dv) 
drop _merge
	
replace a_tenure_dv = . if a_tenure_dv < 0
recode a_tenure_dv (4=3) (6/7=4), gen(tenure_dvCollapsed) // Put housing association and local authority renting together, put furnished and unfurnished private renting together.
label define tenureCollapsed 1 "Owned outright" 2 "Owned with mortgage" 3 "Local aut./housing ass. rented" 4 "Privately rented"
label values tenure_dvCollapsed tenureCollapsed

preserve
drop if tenure_dvCollapsed > 4
graph box a_scghq1_dv [aweight = a_indpxus_xw], over(tenure_dvCollapsed, label(alt)) noout graphregion(color(white)) ytitle("GHQ-12 indicator") note("") 
graph export "$outpath\boxplotByGroupW1WaveAnalysis.png", width(2000) replace
restore

gen scghq1_dv = a_scghq1_dv

svy, over(tenure_dvCollapsed): mean scghq1_dv if tenure_dvCollapsed < 5

estimates store meanW1

matrix define overallOutput = (r(table)[1,1..4] \ r(table)[5..6,1..4])
mat coln overallOutput = outright mortgage social private
mat rown overallOutput = b1 lb1 ub1

matrix list overallOutput

summarize a_scghq1_dv [aweight = a_indpxus_xw] if tenure_dvCollapsed == 1, detail
matrix define distribution1 = (`r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize a_scghq1_dv [aweight = a_indpxus_xw] if tenure_dvCollapsed == 2, detail
matrix define distribution1 = (distribution1 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize a_scghq1_dv [aweight = a_indpxus_xw] if tenure_dvCollapsed == 3, detail
matrix define distribution1 = (distribution1 \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
summarize a_scghq1_dv [aweight = a_indpxus_xw] if tenure_dvCollapsed == 4, detail
matrix define distribution1 = (distribution1\ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')

mat coln distribution1 = min p1 p5 p10 p25 p50 p75 p90 p95 p99 max
mat rown distribution1 = outright mortgage social private

* Add the remaining waves

global letters "b c d e f g h i j k l m"
local val = 1
while `val' < 13  {
	local letter = word("$letters", `val')
	local valPlus1 = `val' + 1
	use "$datapath\\`letter'_indresp.dta", clear
	
	if `val' < 5 {
	    svyset `letter'_psu [pw = `letter'_indpxub_xw], strata(`letter'_strata) singleunit(scaled)	
		gen weight = `letter'_indpxub_xw
	} 
	else {
	    svyset `letter'_psu [pw = `letter'_indpxui_xw], strata(`letter'_strata) singleunit(scaled)		
		gen weight = `letter'_indpxui_xw
	}

	replace `letter'_scghq1_dv = . if `letter'_scghq1_dv < 0

	svy: mean `letter'_scghq1_dv

	merge m:1 `letter'_hidp using "$datapath\\`letter'_hhresp.dta", keepusing(`letter'_tenure_dv) 
	drop _merge

	replace `letter'_tenure_dv = . if `letter'_tenure_dv < 0
	recode `letter'_tenure_dv (4=3) (6/7=4), gen(tenure_dvCollapsed) // Put housing association and local authority renting together, put furnished and unfurnished private renting together.
	label define tenureCollapsed 1 "Owned outright" 2 "Owned with mortgage" 3 "Local aut./housing ass. rented" 4 "Privately rented"
	label values tenure_dvCollapsed tenureCollapsed
	
	preserve
    drop if tenure_dvCollapsed > 4  // Exclude residual tenure categories
    graph box `letter'_scghq1_dv [aweight = weight], over(tenure_dvCollapsed, label(alt)) noout graphregion(color(white)) ytitle("GHQ-12 indicator") note("")
    graph export "$outpath\boxplotByGroupW`valPlus1'WaveAnalysis.png", width(2000) replace
    restore
    
	gen scghq1_dv = `letter'_scghq1_dv
	
	svy, over(tenure_dvCollapsed): mean scghq1_dv if tenure_dvCollapsed < 5
	
	estimates store meanW`valPlus1'

	matrix define newOutput = (r(table)[1,1..4] \ r(table)[5..6,1..4])
	mat rown newOutput = b`valPlus1' lb`valPlus1' ub`valPlus1'

	matrix define overallOutput = (overallOutput \ newOutput)
	
	matrix list overallOutput
	
	summarize `letter'_scghq1_dv [aweight = weight] if tenure_dvCollapsed == 1, detail
    matrix define distribution`valPlus1' = (`r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize `letter'_scghq1_dv [aweight = weight] if tenure_dvCollapsed == 2, detail
    matrix define distribution`valPlus1' = (distribution`valPlus1' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize `letter'_scghq1_dv [aweight = weight] if tenure_dvCollapsed == 3, detail
    matrix define distribution`valPlus1' = (distribution`valPlus1' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')
    summarize `letter'_scghq1_dv [aweight = weight] if tenure_dvCollapsed == 4, detail
    matrix define distribution`valPlus1' = (distribution`valPlus1' \ `r(min)', `r(p1)', `r(p5)', `r(p10)', `r(p25)', `r(p50)', `r(p75)', `r(p90)', `r(p95)', `r(p99)', `r(max)')

    mat coln distribution`valPlus1' = min p1 p5 p10 p25 p50 p75 p90 p95 p99 max
    mat rown distribution`valPlus1' = outright mortgage social private
	
	local val = `val' + 1
}

esttab meanW1 meanW2 meanW3 meanW4 meanW5 meanW6 meanW7 using "$outpath\table1aWaveAnalysis.tex", replace ci nostar keep(c.scghq1_dv@1.tenure_dvCollapsed c.scghq1_dv@2.tenure_dvCollapsed c.scghq1_dv@3.tenure_dvCollapsed c.scghq1_dv@4.tenure_dvCollapsed) coeflabel(c.scghq1_dv@1.tenure_dvCollapsed "Owned outright" c.scghq1_dv@2.tenure_dvCollapsed "Owned with mortgage" c.scghq1_dv@3.tenure_dvCollapsed "Local aut./housing ass. rented" c.scghq1_dv@4.tenure_dvCollapsed "Privately rented") mtitles("Wave 1" "Wave 2" "Wave 3" "Wave 4" "Wave 5" "Wave 6" "Wave 7") nonotes nonumbers 

esttab meanW8 meanW9 meanW10 meanW11 meanW12 meanW13 using "$outpath\table1bWaveAnalysis.tex", replace ci nostar keep(c.scghq1_dv@1.tenure_dvCollapsed c.scghq1_dv@2.tenure_dvCollapsed c.scghq1_dv@3.tenure_dvCollapsed c.scghq1_dv@4.tenure_dvCollapsed) coeflabel(c.scghq1_dv@1.tenure_dvCollapsed "Owned outright" c.scghq1_dv@2.tenure_dvCollapsed "Owned with mortgage" c.scghq1_dv@3.tenure_dvCollapsed "Local aut./housing ass. rented" c.scghq1_dv@4.tenure_dvCollapsed "Privately rented") mtitles("Wave 8" "Wave 9" "Wave 10" "Wave 11" "Wave 12" "Wave 13") nonotes nonumbers 

global my_matrix_rownames: rownames overallOutput
disp "$my_matrix_rownames"

clear
svmat overallOutput, names(col)

generate statistic = ""
forvalues val = 1(3)39 {
	replace statistic = "b" in `val'
	local val2 = `val' + 1
	replace statistic = "lb" in `val2'
	local val3 = `val' + 2
	replace statistic = "ub" in `val3'
}

seq wave, f(1) t(13) b(3)

reshape wide outright mortgage social private, i(wave) j(statistic) string

twoway (scatter outrightb wave) (scatter mortgageb wave) (scatter socialb wave) (scatter privateb wave) (rcap outrightlb outrightub wave) (rcap mortgagelb mortgageub wave) (rcap sociallb socialub wave) (rcap privatelb privateub wave), legend(label(1 "Owned outright") label(2 "Owned with mortgage") label(3 "Local aut./housing ass. rented") label(4 "Privately rented") order(1 2 3 4)) graphregion(color(white)) xtitle("Wave") ytitle("GHQ-12 indicator") xlabel(1(1)13, alt)
graph export "$outpath\Figure1GHQ_WaveAnalysis.png", width(2000) replace

esttab matrix(distribution1) using "$outpath\distribution1WaveAnalysis.tex", tex nomtitles replace
esttab matrix(distribution13) using "$outpath\distribution13WaveAnalysis.tex", tex nomtitles replace