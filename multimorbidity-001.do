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

** import excel using "`datapath'/NHANES.combined.xlsx", first 
** sample 10 
** save "`datapath'/nhanes-sample10", replace 

use "`datapath'/nhanes-sample10", clear
rename *, lower

** Restrict to participants 20 and older
rename ridageyr agey 
label var agey "Age in years"
order agey 
keep if agey >= 20

** Rename and order medical conditions
label var asthma "self reported asthma"
label var arthritis "self reported arthritis"
label var chf "self reported heart failure"
label var cad "self reported coronary artery disease"
label var mi "self reported myocardial infaction"
label var stroke "self reported stroke"
label var copd "self reported copd"
label var cancer "self reported cancer"
label var liverdiz "self reported liver disease"
label define _cond 1 "yes" 0 "no" , replace 
foreach var in asthma arthritis chf cad mi stroke copd cancer liverdiz {
	replace `var'=0 if `var'==2
	label values `var' _cond	
}
order asthma arthritis chf cad mi stroke copd cancer liverdiz, after(agey)

** Combined condition. Combined cad and mi 
label var cad_mi "Self-reported coronary artery diasese OR heart attack"
order cad_mi, after(mi) 

** Obesity 
label var obesity "BMI>=30 yes or no" 
replace obesity = 0 if obesity==2 
order obesity, after(liverdiz)

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
