** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name			        analysis_001.do
    //  project:		                SCD Spleeen size
    //  analysts:				        Ian HAMBLETON
    // 	date last modified	    	    26-APR-2022
    //  algorithm task			        Initial analysis

    ** General algorithm set-up
    version 17
    clear all
    macro drop _all
    set more 1
    set linesize 80

    ** Set working directories: this is for DATASET and LOGFILE import and export

    ** DO file path
    local dopath "X:\OneDrive - The University of the West Indies\repo_ianhambleton\repo_w022\"

    ** DATASETS to encrypted SharePoint folder
    local datapath "X:\OneDrive - The University of the West Indies\Writing\w022\data"

    ** LOGFILES to unencrypted OneDrive folder (.gitignore set to IGNORE log files on PUSH to GitHub)
    local logpath "X:\OneDrive - The University of the West Indies\Writing\w022\tech-docs"

    ** REPORTS and Other outputs
    local outputpath "X:\OneDrive - The University of the West Indies\Writing\w022\outputs"

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\analysis_001", replace
** HEADER -----------------------------------------------------

** ---------------------------------------------------
** LOAD ANALYSIS FILE
** Received from Roberta Caixeta
** SAT 21-JAN-2023
** ---------------------------------------------------

import sas using "`datapath'/SAS data/Data sets/combined.sas7bdat", case(lower) 
** sample 10 
** save "`datapath'/nhanes-sample10", replace 

** sample 10 
** save "`datapath'/nhanes-sample10", replace 

** use "`datapath'/nhanes-sample10", clear

** Restrict to participants 20 and older
rename ridageyr agey 
order seqn
order agey , after(seqn)
keep if agey >= 20

** Rename and order medical conditions
foreach var in asthma arthritis chf cad mi stroke copd cancer liverdiz {
	replace `var'=0 if `var'==2
    recode `var' (9 = .)
	label values `var' _cond	
}
order asthma arthritis chf cad mi stroke copd cancer liverdiz, after(agey)

** Combined condition. Combined cad and mi 
drop cad_mi 
gen cad_mi = 0 
replace cad_mi = 1 if cad==1 | mi==1 
replace cad_mi = . if cad==. | mi==.
label var cad_mi "Self-reported coronary artery diasese OR heart attack"
order cad_mi, after(mi) 

** Obesity (standard definition)
drop obesity
gen obesity = 0 
replace obesity = 1 if bmxbmi>=30 & bmxbmi<.
replace obesity = . if bmxbmi==.
order obesity, after(liverdiz)

** Obesity (lower cutpoint of 27.5 for Asian subpopulation)
gen obesity2 = 0 
replace obesity2 = 1 if bmxbmi>=30 & bmxbmi<.
replace obesity2 = 1 if bmxbmi>=27.5 & ridreth3==6 & bmxbmi<.
replace obesity2 = . if bmxbmi==. | ridreth3==.
order obesity2, after(obesity)

** Hypertension 
label var hashtn "Has hypertension (yes/no)"
replace hashtn = 0 if hashtn == 2 
order hashtn, after(obesity)

** Hypertension and untreated
label var htnuntreated "Has untreated hypertension (yes/no)"
replace htnuntreated = 0 if htnuntreated == 2 
order htnuntreated, after(hashtn)

** Diabetes  
label var hasdm "Has Diabetes (yes/no)"
replace hasdm = 0 if hasdm == 2 
order hasdm, after(htnuntreated)

** Diabetes and untreated (may have error = what does "3" mean?)
label var dbuntreated "Has untreated Diabetes (yes/no)"
replace dbuntreated = 0 if dbuntreated == 2 
order dbuntreated, after(hasdm)

** Has hyperlipidaemia
label var hashld "Has hyperlipidaemia (yes/no)"
replace hashld = 0 if hashld == 2 
replace hashld = . if hashld == 9 
order hashld, after(dbuntreated)

** Has CKD - chronic kidney disease
label var hasckd "Has chronic kidney disease (yes/no)"
replace hasckd = 0 if hasckd == 2 
order hasckd, after(hashld)

** Multimorbidity
gen comorbid = 0 
gen cardiomet = 0
gen cvd = 0
gen pulm = 0
gen etc = 0

** ORIGINAL MULTIMORBIDITY CLASSIFICATION
recode hashld (7 = .) 
recode hasdm (3 9 = .)
recode hasckd (9 = .)

** Multimorbidity (ALL - obesity)
egen mm0 = rowtotal(hashtn hashld hasdm obesity cad_mi chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm0 = . if mm0==1 & (hashtn==.| hashld==.| hasdm==.| obesity==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

** Multimorbidity (ALL - obesity2)
egen mm1 = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm1 = . if mm1==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

** Multimorbidity (-minus 1 condition)
egen mm_htn  = rowtotal(hashld hasdm obesity2 cad_mi chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm_htn = . if mm_htn==1 & (hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_hld  = rowtotal(hashtn hasdm obesity2 cad_mi chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm_hld = . if mm_hld==1 & (hashtn==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_dm   = rowtotal(hashtn hashld obesity2 cad_mi chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm_dm = . if mm_dm==1 & (hashtn==.| hashld==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_ob   = rowtotal(hashtn hashld hasdm cad_mi chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm_ob = . if mm_ob==1 & (hashtn==.| hashld==.| hasdm==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_mi   = rowtotal(hashtn hashld hasdm obesity2 chf stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm_mi = . if mm_mi==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_chf  = rowtotal(hashtn hashld hasdm obesity2 cad_mi stroke hasckd asthma copd arthritis cancer liverdiz)
replace mm_chf = . if mm_chf==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_str  = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf hasckd asthma copd arthritis cancer liverdiz)
replace mm_str = . if mm_str==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_ckd  = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke asthma copd arthritis cancer liverdiz)
replace mm_ckd = . if mm_ckd==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| asthma==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_asth = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke hasckd copd arthritis cancer liverdiz)
replace mm_asth = . if mm_asth==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| copd==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_copd = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke hasckd asthma arthritis cancer liverdiz)
replace mm_copd = . if mm_copd==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| arthritis==.| cancer==.| liverdiz==.)

egen mm_arth = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke hasckd asthma copd cancer liverdiz)
replace mm_arth = . if mm_arth==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| cancer==.| liverdiz==.)

egen mm_can  = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke hasckd asthma copd arthritis liverdiz)
replace mm_can = . if mm_can==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| liverdiz==.)

egen mm_liv  = rowtotal(hashtn hashld hasdm obesity2 cad_mi chf stroke hasckd asthma copd arthritis cancer)
replace mm_liv = . if mm_liv==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.| cad_mi==.| chf==.| stroke==.| hasckd==.| asthma==.| copd==.| arthritis==.| cancer==.)

** Multimorbid groups
egen mm_cardio = rowtotal(hashtn hashld hasdm obesity2)
replace mm_cardio = . if mm_cardio==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.)

egen mm_cvd    = rowtotal(cad_mi chf stroke hasckd)
replace mm_cvd = . if mm_cvd==1 & (cad_mi==.| chf==.| stroke==.| hasckd==.)

egen mm_pul    = rowtotal(asthma copd)
replace mm_pul = . if mm_pul==1 & (asthma==.| copd==.)

egen mm_oth    = rowtotal(arthritis cancer liverdiz)
replace mm_oth = . if mm_oth==1 & (arthritis==.| cancer==.| liverdiz==.)

egen mm_pri    = rowtotal(hasdm hashld hashtn obesity2)
replace mm_pri = . if mm_pri==1 & (hashtn==.| hashld==.| hasdm==.| obesity2==.)

label var mm0 "Full co-morbidity score - original obesity"
label var mm1 "Full co-morbidity score"
label var mm_pri "Four primary conditions: htn, dm, hld, obesity"
label var mm_cardio "Cardiovascular risk factors: htn, hld, dm, obesity"
label var mm_cvd "Cardiovascular: cad, mi, chf, stroke, ckd"
label var mm_pul "Pulmonary: asthma, copd"
label var mm_oth "Other: arthritis, cancer, liver dis"

label var mm_htn "Full mm score - htn"
label var mm_htn  "Full mm score - htn"
label var mm_hld  "Full mm score - hld"
label var mm_dm   "Full mm score - dm"
label var mm_ob   "Full mm score - obesity"
label var mm_mi   "Full mm score - cad_mi"
label var mm_chf  "Full mm score - chf"
label var mm_str  "Full mm score - stroke"
label var mm_ckd  "Full mm score - ckd"
label var mm_asth "Full mm score - asthma"
label var mm_copd "Full mm score - copd"
label var mm_arth "Full mm score - arthritis"
label var mm_can  "Full mm score - cancer"
label var mm_liv  "Full mm score - liver disease"

order mm*, after(hasckd)
gen hincome = indhhin2 
rename riagendr gender
rename ridreth3 ethnicity 
rename dmdeduc2 education 
rename indhhin2 householdincome
rename hiq011 hasinsurance 
rename huq030 hasplacehealthcare
rename dmdmartl married 
recode married 77 = .
replace householdincome=. if householdincome==77 | householdincome==99
replace hasinsurance=. if hasinsurance==7 | hasinsurance==9
replace hasplacehealthcare=. if hasplacehealthcare==7 | hasplacehealthcare==9
order gender ethnicity education householdincome hasinsurance hasplacehealthcare , after(agey)

** Label formats

* SEX
label define sex_  1 "Male" 2 "Female"             
label values gender sex_ 

* ETHNICITY
recode ethnicity (1 2 = 1) 
#delimit ; 
    label define ethnicity_ 1 "hispanic" 
                            3 "Non-Hispanic white" 
                            4 "Non-Hispanic black" 
                            6 "Non-Hispanic Asian" 
                            7 "Non-Hispanic other or multiple races";
#delimit cr
label values ethnicity ethnicity_ 

* MARRIED
#delimit ; 
    label define married_   1 "married" 
                            2 "widowed" 
                            3 "divorced" 
                            4 "separated" 
                            6 "never married" 
                            7 "living with partner";
#delimit cr
label values married married_ 
order married , after(education)

* EDUCATION
gen education2 = education
recode education (1 2 = 1) 
recode education (3 4 5 = 3) 
recode education (7 9 = .)
recode education2 (7 9 = .)
#delimit ; 
    label define education_   1 "not high school" 
                            3 "high school / above";
#delimit cr
label values education education_ 

* HOUSEHOLD INCOME
recode householdincome (1 2 3 4 13 = 1) 
recode householdincome (5 6 7 8 9 10 11 12 14 15 = 2) 
#delimit ; 
    label define householdincome_   1 "less than 20k" 
                                    2 "more than 20k";
#delimit cr
label values householdincome householdincome_ 


* INCOME POVERTY
gen incomepovratio = .
replace incomepovratio = 1 if indfmpir < 1
replace incomepovratio = 2 if indfmpir >=1 & indfmpir<2
replace incomepovratio = 3 if indfmpir >=2 & indfmpir<3
replace incomepovratio = 4 if indfmpir >=3 & indfmpir<4
replace incomepovratio = 5 if indfmpir >=4 & indfmpir<5
replace incomepovratio = 6 if indfmpir >=5
#delimit ; 
    label define incomepovratio_    1 "0 to <1" 
                                    2 "1 to <2" 
                                    3 "2 to <3" 
                                    4 "3 to <4" 
                                    5 "4 to <5" 
                                    5 "5+"; 
#delimit cr
label values incomepovratio incomepovratio_ 


* INCOME POVERTY 2
gen incomepovratio2 = .
replace incomepovratio2 = 1 if indfmpir <= 1
replace incomepovratio2 = 2 if indfmpir >1
#delimit ; 
    label define incomepovratio2_   1 "At or below poverty" 
                                    2 "above poverty"; 
#delimit cr
label values incomepovratio2 incomepovratio2_ 
order incomepovratio incomepovratio2, after(hasplacehealthcare)
label var incomepovratio "Poverty grouped"
label var incomepovratio2 "Poverty grouped 2"

* HAS PLACE HEALTHCARE
#delimit ; 
    label define hasplacehealthcare_    1 "yes" 
                                        2 "there is no place"
                                        3 "there is >1 place"; 
#delimit cr
label values hasplacehealthcare hasplacehealthcare_ 

** Keep variables in analysis
** keep seqn-married 


** OUTCOME VARIABLES

    * MULTIMORBIDITY INDICATORS  
    foreach var in mm0 mm1 mm_htn mm_hld mm_dm mm_ob mm_mi mm_chf mm_str mm_ckd mm_asth mm_copd mm_arth mm_can mm_liv mm_pri mm_cardio mm_cvd mm_pul mm_oth {
        gen `var'_bin = 0 
        replace `var'_bin = 1 if `var'>=2 & `var'<.
        replace `var'_bin = . if `var'>=.
        order `var'_bin, after(`var') 
    }


** PART 2
** ANALYSIS

** Survey weighting
    order sdmvstra sdmvpsu wtint2yr, after(seqn)
    svyset sdmvpsu [pweight = wtint2yr], strata(sdmvstra) vce(linearized) singleunit(missing)

** Age Group 
    gen agroup = .
    replace agroup = 1 if agey<=29
    replace agroup = 2 if agey>=30 & agey<=39
    replace agroup = 3 if agey>=40 & agey<=49
    replace agroup = 4 if agey>=50 & agey<=59
    replace agroup = 5 if agey>=60 & agey<=69
    replace agroup = 6 if agey>=70 & agey<=79
    replace agroup = 7 if agey>=80 & agey<=89
    label define agroup_ 1 "20-29" 2 "30-39" 3 "40-49" 4 "50-59" 5 "60-69" 6 "70-79" 7 "80-89"
    label values agroup agroup_ 

** Data dataset for Table construction at end of DO file
save "`datapath/table4_data'", replace




** SAS command 
set linesize 180
** SAS command 
** model comornew (event="1")= Gender AgeRange Ethnicity Education HouseHoldIncome IncomePovRatio HasInsurance HasPlaceHealthcare /STB DF=INFINITY;
** svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or


** Sensitivity analysis of logistic regression
** We run the regression, removing each multimorbidity component in turn
** There are 13 components, so we have the ORIGINAL regression (the observed estimate) and another 13 regressions
** So, we extract 14 estimates for each model predictor.
local outcome = "mm1_bin mm_htn_bin mm_hld_bin mm_dm_bin mm_ob_bin mm_mi_bin mm_chf_bin mm_str_bin mm_ckd_bin mm_asth_bin mm_copd_bin mm_arth_bin mm_can_bin mm_liv_bin"

#delimit ;
postfile post1  gender genderp 
                age20 age20p
                age30 age30p
                age40 age40p 
                age50 age50p 
                age60 age60p
                age70 age70p
                hisp hispp
                black blackp
                asian asianp 
                mult multp 
                educ educp
                income incomep 
                pov povp 
                insure insurep
                noplace noplacep
                mplace mplacep
using "`datapath'/sensitivity1", replace;
#delimit cr
    foreach var of local outcome {
        svy: logit `var' gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
        matrix `var' = r(table)
        #delimit ;
        post post1  (`var'[1,1]) (`var'[4,1])
                    (`var'[1,2]) (`var'[4,2])
                    (`var'[1,3]) (`var'[4,3])
                    (`var'[1,4]) (`var'[4,4])
                    (`var'[1,5]) (`var'[4,5])
                    (`var'[1,6]) (`var'[4,6])
                    (`var'[1,7]) (`var'[4,7])
                    (`var'[1,9]) (`var'[4,9])
                    (`var'[1,11]) (`var'[4,11])
                    (`var'[1,12]) (`var'[4,12])
                    (`var'[1,13]) (`var'[4,13])
                    (`var'[1,15]) (`var'[4,15])
                    (`var'[1,16]) (`var'[4,16])
                    (`var'[1,19]) (`var'[4,19])
                    (`var'[1,21]) (`var'[4,21])
                    (`var'[1,23]) (`var'[4,23])
                    (`var'[1,24]) (`var'[4,24])
                    ;
        #delimit cr
    } 
postclose post1 
matrix list mm1_bin

use "`datapath'/sensitivity1", clear 

* Gen row identifier
gen removed = _n 
#delimit ; 
label define removed_   1 "observed"
                        2 "hypertension"
                        3 "hyperlipidemia"
                        4 "diabetes"
                        5 "obesity"
                        6 "heart attack"
                        7 "chf"
                        8 "stroke"
                        9 "ckd"
                        10 "asthma"
                        11 "copd"
                        12 "arthritis"
                        13 "cancer"
                        14 "liver disease";
#delimit cr
label values removed removed_
order removed 


** Transpose and rename
xpose, clear varname
drop if _n==1 


preserve
    drop if _n==2|_n==4|_n==6|_n==8|_n==10|_n==12|_n==14|_n==16|_n==18|_n==20|_n==22|_n==24|_n==26|_n==28|_n==30|_n==32|_n==34
    gen pred = _n 
    labmask pred , values(_varname)

    #delimit ;
            colorpalette cblind , nograph;
            local list r(p); local hi `r(p7)'; local medhi `r(p4)'; local medlo `r(p3)';  local lo `r(p8)';
            local list r(p); local hi `r(p5)'; local medhi `r(p6)'; local medlo `r(p3)';  local lo `r(p8)';
            #delimit cr
    #delimit cr

    ** EQUIPLOT OF Odds Ratio Range for each predictor
    gen or_obs = v1 
    egen or_min = rowmin(v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14)
    egen or_max = rowmax(v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14)

        #delimit ;
    	graph twoway 
    		(rbar or_min or_max pred, horizontal barwidth(.25)  lc(gs0) lw(0.025) fc("`medlo'*0.8")) 
    		(scatter pred or_obs, msymbol(O) mlcolor(gs0) mfcolor("gs16") msize(1.5) mlw(0.1))
    		,
    		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
    		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin))
    		ysize(12) xsize(16)
    
    		xlabel(.015625 0.03125 0.0625 0.125 0.25 0.5 1 2 4
                , labsize(2) nogrid labcolor(gs8))
    		xscale(log ) 
    		xtitle("Odds Ratio range (log scale)", margin(top) color(gs0) size(2)) 

    		ylabel(1(1)17
    		, notick valuelabel angle(0) labsize(1.9) labcolor("`gry'") nogrid glc(gs10) glw(0.15) glp(".")) 
    		ytitle(" ", axis(1)) 
    		yscale(noline reverse )

    		legend(off order(5 1 2 3 10) keygap(2) rowgap(1) linegap(0.45)
    		label(1 "Change due to age-" "specific mortality rates")  
    		label(2 "Change due to" "population aging") 
    		label(3 "Change due to" "population growth") 
    		label(5 "Change" "in deaths") 
    		label(10 "Sensitivity" "range") 
    		cols(5) position(6) size(2) symysize(2) color(gs8)
    		) 
    		name(equiplot1)
    	;
    #delimit cr
    graph export "`outputpath'/equiplot1.png", replace width(4000)
restore




** ODDS RATIO Percentage change 
preserve
    gen pred = _n 
    labmask pred , values(_varname)
    * drop p-values 
    drop if pred==2|pred==4|pred==6|pred==8|pred==10|pred==12|pred==14|pred==16|pred==18|pred==20|pred==22|pred==24|pred==26|pred==28|pred==30|pred==32|pred==34
    local removed = "hypertension lipids diabetes obesity heart chf stroke ckd asthma copd arthritis cancer liver"
    local removed = "v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14"
    foreach var of local removed {
            gen r`var' = abs( ( (`var' - v1)/v1 ) * 100)
            /// gen `var'_a = (v1 - `var')
    }
    keep v* rv* pred 
    reshape long v rv, i(pred) j(removed)
    label values removed removed_



    ** HEATPLOT 1
    ** Odds Ratio percentage change 
    #delimit ;
        heatplot rv i.pred i.removed if rv!=.
        ,
        
        color(OrRd , intensify(0.75 ))
        cuts(0 2.5 5 10 25 50 100)
        ///keylabels(all, range(1))
        keylabels(all, interval)
        p(lcolor(white) lalign(center) lw(0.1))
        discrete
        statistic(asis)
        /// missing(fc(gs12) lc(gs16) lw(0.05) )

        plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
        graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
        ysize(9) xsize(15)

        ylab(   1 "Gender" 
                2 "Age 20-29"
                3 "Age 30-39"
                4 "Age 40-49"
                5 "Age 50-59"
                6 "Age 60-69"
                7 "Age 70-79"
                8 "Hispanic"
                9 "Black"
                10 "Asian"
                11 "Multiple"
                12 "Education"
                13 "Income"
                14 "Poverty"
                15 "Insurance"
                16 "no place"
                17 ">1 place"
        , labs(2.75) notick nogrid glc(gs16) angle(0))
        yscale(reverse fill noline range(0(1)14)) 
        ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

        xlab(
            , labs(2.75) noticks nogrid glc(gs16) angle(45) format(%9.0f))
        xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
        xscale(alt noline) 

        title(" ", pos(11) ring(1) size(3.5))

        legend(size(2.75) position(2) ring(5) colf cols(1) lc(gs16)
            region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
            sub("% change", size(2.75))
        )
        name(heatmap1) 
        ;
    #delimit cr
    graph export "`outputpath'/heatmap1.png", replace width(4000)
restore



** HEATPLOT 2
** Odds Ratio percentage change 
** Showing Directional change (Stronger effect versus Weaker effect)
*preserve
    gen pred = _n 
    labmask pred , values(_varname)
    ** drop p-values 
    drop if pred==2|pred==4|pred==6|pred==8|pred==10|pred==12|pred==14|pred==16|pred==18|pred==20|pred==22|pred==24|pred==26|pred==28|pred==30|pred==32|pred==34
    local removed = "hypertension lipids diabetes obesity heart chf stroke ckd asthma copd arthritis cancer liver"
    local removed = "v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14"

    ** Generate ln() of odds ratio for linear scale. 0 = no effect 
    ** gen lv1 = ln(v1) 
    ** foreach var of local removed {
    **     gen l`var' = ln(`var')
    ** }
    ** Compare each value against the full multimorbidity model (v1)
    ** Convert to ORs > 1 in all cases 
    ** Any negative change is a weaker effect
    ** Any positive change is a stronger effect
    gen rv1 = (1/v1) if v1 < 1
    foreach var of local removed {
        gen r`var' = (1/`var') if `var' < 1
        gen c`var' = ( (r`var' - rv1)/rv1 ) * 100
    }
    
    reshape long v rv cv, i(pred) j(removed)
    label values removed removed_


    #delimit ;
        heatplot cv i.pred i.removed if cv!=.
        ,

        color(RdYlBu , reverse intensify(0.45 ))
        cuts(-100 -50 -25 -10 -5 0 5 10 25 50 100)
        ///keylabels(all, range(1))
        keylabels(all, interval)
        p(lcolor(white) lalign(center) lw(0.1))
        discrete
        statistic(asis)
        /// missing(fc(gs12) lc(gs16) lw(0.05) )

        plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
        graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
        ysize(9) xsize(15)

        ylab(   1 "Gender" 
                2 "Age 20-29"
                3 "Age 30-39"
                4 "Age 40-49"
                5 "Age 50-59"
                6 "Age 60-69"
                7 "Age 70-79"
                8 "Hispanic"
                9 "Black"
                10 "Asian"
                11 "Multiple"
                12 "Education"
                13 "Income"
                14 "Poverty"
                15 "Insurance"
                16 "no place"
                17 ">1 place"
        , labs(2.75) notick nogrid glc(gs16) angle(0))
        yscale(reverse fill noline range(0(1)14)) 
        ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

        xlab(
            , labs(2.75) noticks nogrid glc(gs16) angle(45) format(%9.0f))
        xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
        xscale(alt noline) 

        title(" ", pos(11) ring(1) size(3.5))

        legend(size(2.75) position(2) ring(5) colf cols(1) lc(gs16)
            region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
            sub("% change", size(2.75))
        )
        name(heatmap2) 
        ;
        #delimit cr
    graph export "`outputpath'/heatmap2.png", replace width(4000)
restore




** ------------------------------------------
** PDF of HeatMaps
** ------------------------------------------
putpdf begin, landscape pagesize(letter) font("Calibri Light", 10) margin(top,0.5cm) margin(bottom,0.25cm) margin(left,0.5cm) margin(right,0.25cm)

** PAGE 1. FIGURE
    putpdf paragraph ,  font("Calibri Light", 10)
    putpdf text ("Figure A. "), bold font("Calibri Light", 12)
    putpdf text ("Odds ratio range when removing one multimorbidity component at a time"), font("Calibri Light", 12)
    putpdf table t2 = (1,1), width(90%) halign(center) border(all,nil) 
    putpdf table t2(1,1)=image("`outputpath'/equiplot1.png")

** PAGE 2. FIGURE
putpdf pagebreak
    putpdf paragraph ,  font("Calibri Light", 10)
    putpdf text ("Figure B. "), bold font("Calibri Light", 12)
    putpdf text ("Odds Ratio percentage change for each model predictor when removing one multimorbidity component at a time"), font("Calibri Light", 12)
    putpdf table t2 = (1,1), width(90%) halign(center) border(all,nil) 
    putpdf table t2(1,1)=image("`outputpath'/heatmap1.png")

** PAGE 2. FIGURE
putpdf pagebreak
    putpdf paragraph ,  font("Calibri Light", 10)
    putpdf text ("Figure B. "), bold font("Calibri Light", 12)
    putpdf text ("Odds Ratio percentage change (with direction of change) for each model predictor when removing one multimorbidity component at a time"), font("Calibri Light", 12)
    putpdf table t2 = (1,1), width(90%) halign(center) border(all,nil) 
    putpdf table t2(1,1)=image("`outputpath'/heatmap2.png")

** Save the PDF
    local c_date = c(current_date)
    local date_string = subinstr("`c_date'", " ", "", .)
    putpdf save "`outputpath'/sensitivity-analysis", replace






** TABLE 4 - Observed regression as Word Table
use "`datapath/table4_data'", clear


** SAS command 
set linesize 180
** SAS command 
** model comornew (event="1")= Gender AgeRange Ethnicity Education HouseHoldIncome IncomePovRatio HasInsurance HasPlaceHealthcare /STB DF=INFINITY;
** svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or


** Sensitivity analysis of logistic regression
** We run the regression, removing each multimorbidity component in turn
** There are 13 components, so we have the ORIGINAL regression  (the observed estimate) and another 13 regressions
** So, we extract 14 estimates for each model predictor.
local outcome = "mm1_bin mm_htn_bin mm_hld_bin mm_dm_bin mm_ob_bin mm_mi_bin mm_chf_bin mm_str_bin mm_ckd_bin mm_asth_bin mm_copd_bin mm_arth_bin mm_can_bin mm_liv_bin"

#delimit ;
        postfile post2  gender genderp genderl genderu
                age20 age20p age20l age20u
                age30 age30p age30l age30u
                age40 age40p age40l age40u
                age50 age50p age50l age50u
                age60 age60p age60l age60u
                age70 age70p age70l age70u
                hisp hispp hispl hispu
                black blackp blackl blacku
                asian asianp asianl asianu 
                mult multp multl multu
                educ educp educl educu
                income incomep incomel incomeu
                pov povp povl povu
                insure insurep insurel insureu 
                noplace noplacep noplacel noplaceu
                mplace mplacep mplacel mplaceu
        using "`datapath'/table4", replace;
#delimit cr

        svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
        matrix mm1_bin = r(table)
        #delimit ;
        post post2  (mm1_bin[1,1])  (mm1_bin[4,1]) (mm1_bin[5,1])  (mm1_bin[6,1])
                    (mm1_bin[1,2])  (mm1_bin[4,2]) (mm1_bin[5,2])  (mm1_bin[6,2])
                    (mm1_bin[1,3])  (mm1_bin[4,3]) (mm1_bin[5,3])  (mm1_bin[6,3])
                    (mm1_bin[1,4])  (mm1_bin[4,4]) (mm1_bin[5,4])  (mm1_bin[6,4])
                    (mm1_bin[1,5])  (mm1_bin[4,5]) (mm1_bin[5,5])  (mm1_bin[6,5])
                    (mm1_bin[1,6])  (mm1_bin[4,6]) (mm1_bin[5,6])  (mm1_bin[6,6])
                    (mm1_bin[1,7])  (mm1_bin[4,7]) (mm1_bin[5,7])  (mm1_bin[6,7])
                    (mm1_bin[1,9])  (mm1_bin[4,9]) (mm1_bin[5,9])  (mm1_bin[6,9])
                    (mm1_bin[1,11]) (mm1_bin[4,11]) (mm1_bin[5,11]) (mm1_bin[6,11])
                    (mm1_bin[1,12]) (mm1_bin[4,12]) (mm1_bin[5,12]) (mm1_bin[6,12])
                    (mm1_bin[1,13]) (mm1_bin[4,13]) (mm1_bin[5,13]) (mm1_bin[6,13])
                    (mm1_bin[1,15]) (mm1_bin[4,15]) (mm1_bin[5,15]) (mm1_bin[6,15])
                    (mm1_bin[1,16]) (mm1_bin[4,16]) (mm1_bin[5,16]) (mm1_bin[6,16])
                    (mm1_bin[1,19]) (mm1_bin[4,19]) (mm1_bin[5,19]) (mm1_bin[6,19])
                    (mm1_bin[1,21]) (mm1_bin[4,21]) (mm1_bin[5,21]) (mm1_bin[6,21])
                    (mm1_bin[1,23]) (mm1_bin[4,23]) (mm1_bin[5,23]) (mm1_bin[6,23])
                    (mm1_bin[1,24]) (mm1_bin[4,24]) (mm1_bin[5,24]) (mm1_bin[6,24])
                    ;
        #delimit cr
postclose post2 
matrix list mm1_bin

use "`datapath'/table4", clear 
** Transpose and rename
xpose, clear varname

** Predictor indicator
egen pred = seq() , f(1) t(17) b(4)
egen type = seq() , f(1) t(4) 


#delimit ; 
label define pred_ 
1 "gender" 
2 "age20" 
3 "age30" 
4 "age40" 
5 "age50" 
6 "age60" 
7 "age70" 
8 "hisp" 
9 "black" 
10 "asian" 
11 "mult" 
12 "educ" 
13 "income" 
14 "pov"
15 "insure" 
16 "noplace"
17 "mplace";
#delimit cr 
label values pred pred_ 

label define type_ 1 "OR" 2 "p-value" 3 "low" 4 "high"
label values type type_ 
rename v1 val
format val %12.9f 
drop _varname 

tempfile or pval ll ul 
preserve
    keep if type==1
    rename val or 
    drop type
    save `or' , replace 
restore
preserve
    keep if type==2
    rename val pval 
    drop type
    save `pval' , replace 
restore
preserve
    keep if type==3
    rename val ll 
    drop type
    save `ll' , replace 
restore 
preserve 
    keep if type==4
    rename val ul
    drop type
    save `ul' , replace 
restore 
use `or', clear
merge 1:1 pred using `pval'
drop _merge 
merge 1:1 pred using `ll'
drop _merge 
merge 1:1 pred using `ul'
drop _merge 


	format or %5.2fc 
	format pval %5.3fc 
	format ll %5.2fc 
	format ul %5.2fc 

	** Begin Table 
	putdocx begin , font(calibri light, 10)
	putdocx paragraph 
		putdocx text ("Table "), bold
		putdocx text ("Predictors of multimorbidity"), 
		** Place data 
		putdocx table t4 = data("pred or ll ul pval"), varnames 
		** Line colors + Shadng
		putdocx table t4(2/17,.), border(bottom, single, "e6e6e6")
		putdocx table t4(18,.), border(bottom, single, "000000")
		putdocx table t4(1,.),  shading("e6e6e6")
		putdocx table t4(.,1),  shading("e6e6e6")
		** Column and Row headers
		putdocx table t4(1,1) = ("Predictor"),  font(calibri light,10, "000000")
		putdocx table t4(1,2) = ("Odds Ratio"),  font(calibri light,10, "000000")
		putdocx table t4(1,3) = ("Lower 95% limit"),  font(calibri light,10, "000000")
		putdocx table t4(1,4) = ("Upper 95% limit"),  font(calibri light,10, "000000")
		putdocx table t4(1,5) = ("p-value"),  font(calibri light,10, "000000")
		putdocx table t4(2,1) = ("Sex (female v male)"),  font(calibri light,10, "000000")
		putdocx table t4(3,1) = ("Age (20-29 v 80-89"),  font(calibri light,10, "000000")
		putdocx table t4(4,1) = ("Age (30-39 v 80-89"),  font(calibri light,10, "000000")
		putdocx table t4(5,1) = ("Age (40-49 v 80-89"),  font(calibri light,10, "000000")
		putdocx table t4(6,1) = ("Age (50-59 v 80-89"),  font(calibri light,10, "000000")
		putdocx table t4(7,1) = ("Age (60-69 v 80-89"),  font(calibri light,10, "000000")
		putdocx table t4(8,1) = ("Age (70-79 v 80-89"),  font(calibri light,10, "000000")
		putdocx table t4(9,1) = ("Hispanic v non-hispanic White"),  font(calibri light,10, "000000")
		putdocx table t4(10,1) = ("Black v non-hispanic White"),  font(calibri light,10, "000000")
		putdocx table t4(11,1) = ("Asian v non-hispanic White"),  font(calibri light,10, "000000")
		putdocx table t4(12,1) = ("Other v non-hispanic White"),  font(calibri light,10, "000000")
		putdocx table t4(13,1) = ("Education (high school v below high school"),  font(calibri light,10, "000000")
		putdocx table t4(14,1) = ("Income (below USD20k v USD20k and above"),  font(calibri light,10, "000000")
		putdocx table t4(15,1) = ("No poverty v poverty"),  font(calibri light,10, "000000")
		putdocx table t4(16,1) = ("Has insurance (no v yes)"),  font(calibri light,10, "000000")
		putdocx table t4(17,1) = ("No place for healthcare (v yes)"),  font(calibri light,10, "000000")
		putdocx table t4(18,1) = ("More than 1 place for healthcare (v yes"),  font(calibri light,10, "000000")

	** Save the Table
	putdocx save "`outputpath'/table4", replace 



** EXPLORING CHANGES IN HOUSEHOLD INCOME CLASSIFICATION
use "`datapath/table4_data'", clear

** HH income 35k 
///				1-4,13 = 'Less than $20,000' 	
///		/*		='$ 0 to $ 4,999' 
///				2 	='$ 5,000 to $ 9,999' 	
///				3 	='$10,000 to $14,999' 	
///				4  ='$15,000 to $19,999' 	*/
///				5-12,14,15 = 'More than $20,000'
///		/*		
///				5	='$20,000 to $24,999'		
///				6 	='$25,000 to $34,999' 	
///				7 	='$35,000 to $44,999' 	
///				8 	='$45,000 to $54,999' 		
///				9 	='$55,000 to $64,999' 	
///				10 ='$65,000 to $74,999' 	
///				12	='$20,000 and Over' 	
///				13 	='Under $20,000' 	
///				14 	='$75,000 to $99,999' 	
///				15 	='$100,000 and Over' 		
///				*/
///				77 	='Refused' 		
///				99 	='Dont know' 	
///				;

replace hincome=. if hincome==77 | hincome==99
gen hincome35 = hincome
gen hincome45 = hincome 
gen hincome55 = hincome 
gen hincome65 = hincome 
recode hincome35 (1 2 3 4 5 6 13 = 1) 
recode hincome35 (7 8 9 10 11 12 14 15 = 2) 
recode hincome45 (1 2 3 4 5 6 7 13 = 1) 
recode hincome45 (8 9 10 11 12 14 15 = 2) 
recode hincome55 (1 2 3 4 5 6 7 8 13 = 1) 
recode hincome55 (9 10 11 12 14 15 = 2) 
recode hincome65 (1 2 3 4 5 6 7 8 9 13 = 1) 
recode hincome65 (10 11 12 14 15 = 2) 
label define hincome35_   1 "less than 35k" 2 "more than 35k"
label define hincome45_   1 "less than 45k" 2 "more than 45k"
label define hincome55_   1 "less than 55k" 2 "more than 55k"
label define hincome65_   1 "less than 65k" 2 "more than 65k"
label values hincome35 hincome35_ 
label values hincome45 hincome45_ 
label values hincome55 hincome55_ 
label values hincome65 hincome65_ 

set linesize 180

** Primary regression 
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** Income cutpoint at USD 35k 
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.hincome35 i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** Income cutpoint at USD 45k 
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.hincome45 i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** Income cutpoint at USD 55k 
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.hincome55 i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** Income cutpoint at USD 65k 
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.hincome65 i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or



** EDUCATION

///     1	Less than 9th grade	
///     2	9-11th grade (Includes 12th grade with no diploma)	
///     3	High school graduate/GED or equivalent	
///     4	Some college or AA degree		
///     5	College graduate or above	

** Primary regression 
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** Education at 5 levels  
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education2 ib2.hincome35 i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or



** OBESITY
** Original Obesity (all at 30) 
svy: logit mm0_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or
** Obesity at 27.5 for Asian subgroup
svy: logit mm1_bin gender ib7.agroup ib3.ethnicity i.education ib2.householdincome i.incomepovratio2 i.hasinsurance i.hasplacehealthcare , or

