
version 16.0
clear all
set more off
//set maxvar 20000
set scheme s1color

timer on 2

local thisfile "1_asvab_pca"


global AVZ 	"/Users/wss2023/Dropbox/stata/NLSY/women_stem"
global MY_IN_PATH "$AVZ/data/"
global MY_DO_FILES "$AVZ/do/"
global MY_OUT_LOG "$AVZ/log/"
global MY_OUT_DATA "$AVZ/output_pure_applied_pca/"
global MY_OUT_TEMP "$AVZ/temp/"

cap log close
log using "${MY_OUT_LOG}`thisfile'", replace	



/*----------------------------------------------------*/
   /* [>   0.  data preparation   <] */ 
/*----------------------------------------------------*/
use ${MY_IN_PATH}asvab79.dta, clear
global xlist abl_social asvab_general_sci asvab_arith_reasoning asvab_word_know asvab_para_comp asvab_nmbr_oper asvab_coding_speed asvab_autoshop_info asvab_math_know asvab_mech_comp asvab_electr_info
global id id
//keep if race == 3 // keep the white



merge 1:1 id using "$AVZ/Deming_2017_SocialSkills_Replication/Data/nlsy/rosen-rotter-79.dta", ///
	assert(2 3) keep(3) nogenerate


egen abl_social=rowmean(rotter_std rosen_std)
label variable abl_social "using Deming2017's measure"





/* [> adjust by age <] */  
// create agegroup
replace birthyr = 1900 + birthyr

gen agegroup=0
local i = 0
forvalues j = 1957 (1) 1964 {
	replace agegroup=`i'+1 if birthyr==`j' & birthmon>=1 & birthmon<=3
	replace agegroup=`i'+2 if birthyr==`j' & birthmon>=4 & birthmon<=6
	replace agegroup=`i'+3 if birthyr==`j' & birthmon>=7 & birthmon<=9
	replace agegroup=`i'+4 if birthyr==`j' & birthmon>=10 & birthmon<=12
	local i = `i'+4
}  // end of forvalues j = 1 (1) n
assert agegroup~=0


foreach test in $xlist {
  bys agegroup: egen `test'_mean = mean(`test')
  bys agegroup: egen `test'_sd = sd(`test')
  replace `test' = (`test' - `test'_mean)/`test'_sd
  label var `test' "standardized `test' score - age adjusted"
  drop `test'_mean `test'_sd
}  // end of foreach test in varlist

merge 1:1 id using ${MY_IN_PATH}customweight_nlsy79_all/customweight_nlsy79_all.dta,assert(2 3) keep(3) nogenerate

keep $id $xlist asvab_wt sex cohort race weight_custom
save ${MY_OUT_TEMP}asvab79_pca.dta, replace






use ${MY_IN_PATH}asvab97.dta, clear
global xlist asvab_general_sci asvab_arith_reasoning asvab_word_know asvab_para_comp asvab_nmbr_oper asvab_coding_speed asvab_auto_info asvab_shop_info asvab_math_know asvab_mech_comp asvab_electr_info asvab_assemb_obj
global id id
//keep if race == 3 // keep the white



merge 1:1 id using "$AVZ/Deming_2017_SocialSkills_Replication/Data/nlsy/nlsy97_noncog.dta", ///
	assert(2 3) keep(3) nogenerate


gen abl_social = noncog_std
label variable abl_social "using Deming2017's measure"


/* foreach v of varlist $xlist {
  qui sum `v'
  replace `v' = (`v' - r(mean))/r(sd)
}  // end of foreach v in varlist  */
egen asvab_autoshop_info = rowmean(asvab_shop_info asvab_auto_info)
global xlist abl_social asvab_general_sci asvab_arith_reasoning asvab_word_know asvab_para_comp asvab_nmbr_oper asvab_coding_speed asvab_autoshop_info asvab_math_know asvab_mech_comp asvab_electr_info

/* [> adjust by age <] */  
// create agegroup

gen agegroup=0
local i = 0
forvalues j = 1980 (1) 1984 {
	replace agegroup=`i'+1 if birthyr==`j' & birthmon>=1 & birthmon<=3
	replace agegroup=`i'+2 if birthyr==`j' & birthmon>=4 & birthmon<=6
	replace agegroup=`i'+3 if birthyr==`j' & birthmon>=7 & birthmon<=9
	replace agegroup=`i'+4 if birthyr==`j' & birthmon>=10 & birthmon<=12
	local i = `i'+4
}  // end of forvalues j = 1 (1) n
assert agegroup~=0


foreach test in $xlist {
  bys agegroup: egen `test'_mean = mean(`test')
  bys agegroup: egen `test'_sd = sd(`test')
  replace `test' = (`test' - `test'_mean)/`test'_sd
  label var `test' "standardized `test' score - age adjusted"
  drop `test'_mean `test'_sd
}  // end of foreach test in varlist

merge 1:1 id using ${MY_IN_PATH}customweight_nlsy79_all/customweight_nlsy79_all.dta,assert(2 3) keep(3) nogenerate

keep $id $xlist asvab_wt sex cohort race weight_custom
save ${MY_OUT_TEMP}asvab97_pca.dta, replace






clear
append using ${MY_OUT_TEMP}asvab79_pca.dta ${MY_OUT_TEMP}asvab97_pca.dta

//keep if sex==
//replace asvab_wt = 1

// rename for sake of graphing
rename asvab_general_sci sci
rename asvab_arith_reasoning arith
rename asvab_word_know word
rename asvab_para_comp para
rename asvab_nmbr_oper number
rename asvab_coding_speed coding
rename asvab_autoshop_info auto
rename asvab_math_know math
rename asvab_mech_comp mech
rename asvab_electr_info elec
rename abl_social social

global xlist_pca sci arith word para number coding auto math mech elec
global xlist sci arith word para number coding auto math mech elec social

save ${MY_OUT_DATA}asvab_pca.dta, replace

/*----------------------------------------------------*/
   /* [>   1.  do PCA   <] */ 
/*----------------------------------------------------*/
* Principal component analysis (PCA)
use ${MY_OUT_DATA}asvab_pca.dta, clear

pca $xlist_pca // /* [fw=asvab_wt] */, comp(4)  blanks(.3)
//rotate, varimax blanks(.3) /* comp(5)  */
mat eigenvalues = e(Ev)
gen eigenvalues = eigenvalues[1,_n]
egen pct=total(eigenvalues) if !mi(eigenvalues)
replace pct=sum((eigenvalues/pct)*100) if !mi(eigenvalues)
g component=_n if !mi(eigenvalues)

twoway line pct component, sort ytitle("Cumulative % of Explained Variance") lcolor(red) ylabel(,angle(0)) ///
|| line eigenvalues component, sort yaxis(2) ytitle("Eigenvalues", axis(2)) lcolor(blue) yline(1, lwidth(medium) lcolor(cyan) axis(2)) ylabel(0(1)2 4 6 8, axis(2) angle(00)) ///
xlabel(1/10) xtitle(Number of Components) legend(order(1 "cummulative % of explained Var" 2 "eigenvalues")) ///
//title(Scree Plot of Eigenvalues after PCA)
graph export ${MY_OUT_DATA}asvab_scree_var.png, width(4500) height(3000) replace	

/* capture ssc inst pcacoefsave
pcacoefsave using audiopcaresults, replace
u audiopcaresults,clear
describe
capture ssc inst mylabels
mylabels 0(10)70, myscale(8 *@/100) local(yla)

twoway connected eigenvalue PC, sort ///
yaxis(1 2)                           ///
yla(`yla', ang(h) axis(1)) ytitle(% variance, axis(1))  ///
yla(, ang(h) axis(2)) xla(1/8) */















//pca $xlist, mineigen(1) 
use ${MY_OUT_DATA}asvab_pca.dta, clear

pca $xlist_pca /* [fw=asvab_wt] */, mineigen(1) 
rotate, varimax blanks(.3) /* comp(5)  */
loadingplot, components(2) combined imargin(0 0 0 0 0 0) mcolor(blue%70) mlabtextstyle(small_label) yline(0.3,lcolor(cyan)) xline(0.3,lcolor(cyan)) /* mlabsize(vsmall) */ title("2 PC's rotated")
graph export ${MY_OUT_DATA}asvab_loadings_2comp.png, width(9000) height(6000) replace	

pca $xlist_pca /* [fw=asvab_wt] */, comp(3)
rotate, varimax blanks(.3) /* comp(5)  */
loadingplot, components(3) combined imargin(0 0 0 0 0 0) mcolor(blue%70) mlabtextstyle(small_label) yline(0.3,lcolor(cyan)) xline(0.3,lcolor(cyan)) /* mlabsize(vsmall) */ title("3 PC's rotated")
graph export ${MY_OUT_DATA}asvab_loadings_3comp.png, width(9000) height(6000) replace	

pca $xlist_pca /* [fw=asvab_wt] */, comp(5)
rotate, varimax blanks(.3) /* comp(5)  */
loadingplot, components(5) combined imargin(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) mcolor(blue%70) mlabtextstyle(small_label) yline(0.3,lcolor(cyan)) xline(0.3,lcolor(cyan)) /* mlabsize(vsmall) */ title("5 PC's rotated")
graph export ${MY_OUT_DATA}asvab_loadings_5comp.png, width(9000) height(6000) replace	

pca $xlist_pca /* [fw=asvab_wt] */, comp(6)
rotate, varimax blanks(.3) /* comp(5)  */
loadingplot, components(6) combined imargin(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) mcolor(blue%70) mlabtextstyle(small_label) yline(0.3,lcolor(cyan)) xline(0.3,lcolor(cyan)) /* mlabsize(vsmall) */ title("6 PC's rotated")
graph export ${MY_OUT_DATA}asvab_loadings_6comp.png, width(9000) height(6000) replace	

//pca $xlist [fw=asvab_wt], comp(5)
//pca $xlist [fw=asvab_wt], mineigen(1) blanks(.3)
pca $xlist_pca /* [fw=asvab_wt] */, comp(4) blanks(.3)
//rotate, varimax 
rotate, varimax blanks(.3) /* comp(5)  */
//rotate, clear
// eigenvalues plot
screeplot, yline(1) ci(het) title("")
graph export ${MY_OUT_DATA}asvab_scree.png, width(4500) height(3000) replace	

// loadings plot
loadingplot, components(4) combined imargin(0 0 0 0 0 0) mcolor(blue%70) mlabtextstyle(small_label) yline(0.3,lcolor(cyan)) xline(0.3,lcolor(cyan)) /* mlabsize(vsmall) */ title("4 PC's rotated")
graph export ${MY_OUT_DATA}asvab_loadings_4comp.png, width(9000) height(6000) replace	











//rotate, promax
//rotate, promax blanks(.3) /* comp(5)  */


 
/*----------------------------------------------------*/
   /* [>   2.  do the KMO test   <] */ 
/*----------------------------------------------------*/
/* The Kaiser-Meyer-Olkin (KMO) measure of sampling adequacy takes values between 0 and 1,
with small values indicating that overall the variables have little in common to warrant a
principal components analysis and values above 0.5 are considered satisfactory for a principal
components analysis. */
estat kmo /* Note: the test is passed */
estat loadings
estat rotatecompare




/*----------------------------------------------------*/
   /* [>   3.  scatter plot of scores   <] */ 
/*----------------------------------------------------*/

/* scoreplot, components(4) 
scoreplot, mlabel(sex) */ // not helpful, because can't group by gender

predict score1 score2 score3 score4 score5 score6 score7, score
/*see it say "extra variables dropped", we know that this score is indeed rotated */


forvalues j = 1 (1) 4 {
	separate score`j', by(sex) veryshortlabel 
}  // end of forvalues j = 1 (1) n
separate social, by(sex) veryshortlabel 







foreach yr in 79 97 {
	cap graph drop graph*
	scatter score2? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph12) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph13) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph14) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph15) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph21) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph23) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph24) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph25) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph31) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score2? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph32) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph34) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph35) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph41) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score2? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph42) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph43) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph45) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("Social", size(medsmall)) name(graph51) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score2? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("Social", size(medsmall)) name(graph52) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("Social", size(medsmall)) name(graph53) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("Social", size(medsmall)) name(graph54) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	graph combine graph21 graph31 graph41 graph51 ///
				  graph12 graph32 graph42 graph52 ///
				  graph13 graph23 graph43 graph53 ///
				  graph14 graph24 graph34 graph54 ///
				  graph15 graph25 graph35 graph45 ///
				  ,  imargin(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) holes(1 7 13 19 25) title("Cognitive (PCA) and Noncognitive Scores, Cohort `yr'")
	graph export ${MY_OUT_DATA}asvab_score_social`yr'_F_over_M.png, width(4500) height(3000) replace	
}  // end of foreach yr in varlist



















foreach yr in 79 97 {
	cap graph drop graph*
	scatter score22 score21 score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph12) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score32 score31 score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph13) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score42 score41 score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph14) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social2 social1 score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph15) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score12 score11 score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph21) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score32 score31 score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph23) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score42 score41 score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph24) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social2 social1 score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph25) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score12 score11 score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph31) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score22 score21 score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph32) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score42 score41 score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph34) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social2 social1 score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph35) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score12 score11 score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph41) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score22 score21 score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph42) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score32 score31 score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph43) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social2 social1 score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph45) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score12 score11 social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("Social", size(medsmall)) name(graph51) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score22 score21 social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("Social", size(medsmall)) name(graph52) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score32 score31 social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("Social", size(medsmall)) name(graph53) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score42 score41 social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(magenta%30 green%30) mlcolor(magenta%0 green%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("Social", size(medsmall)) name(graph54) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	graph combine graph21 graph31 graph41 graph51 ///
				  graph12 graph32 graph42 graph52 ///
				  graph13 graph23 graph43 graph53 ///
				  graph14 graph24 graph34 graph54 ///
				  graph15 graph25 graph35 graph45 ///
				  ,  imargin(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) holes(1 7 13 19 25) title("Cognitive (PCA) and Noncognitive Scores, Cohort `yr'")
	graph export ${MY_OUT_DATA}asvab_score_social`yr'_M_over_F.png, width(4500) height(3000) replace	
}  // end of foreach yr in varlist




/* 

foreach yr in 79 97 {
	cap graph drop graph*
	scatter score2? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph12) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph13) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph14) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score1 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 1 - Verb", size(medsmall)) name(graph15) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph21) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph23) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph24) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score2 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 2 - Math", size(medsmall)) name(graph25) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph31) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score2? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph32) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph34) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score3 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 3 - Mech", size(medsmall)) name(graph35) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph41) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score2? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph42) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph43) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter social? score4 if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("Social", size(medsmall)) xtitle("PC 4 - Admin", size(medsmall)) name(graph45) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	scatter score1? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 1 - Verb", size(medsmall)) xtitle("Social", size(medsmall)) name(graph51) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score2? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 2 - Math", size(medsmall)) xtitle("Social", size(medsmall)) name(graph52) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score3? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 3 - Mech", size(medsmall)) xtitle("Social", size(medsmall)) name(graph53) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))
	scatter score4? social if cohort == `yr', yline(0,lcolor(cyan)) xline(0,lcolor(cyan)) mcolor(green%30 magenta%30) mlcolor(green%0 magenta%0) msize(small small) ytitle("PC 4 - Admin", size(medsmall)) xtitle("Social", size(medsmall)) name(graph54) legend(order(1 "male" 2 "female") size(medsmall) symxsize(*0.5) symys(*.3))

	graph combine graph21 graph31 graph41 graph51 ///
				  graph12 graph32 graph42 graph52 ///
				  graph13 graph23 graph43 graph53 ///
				  graph14 graph24 graph34 graph54 ///
				  graph15 graph25 graph35 graph45 ///
				  ,  imargin(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) holes(1 7 13 19 25) title("Cognitive (PCA) and Noncognitive Scores, Cohort `yr'")
	graph export ${MY_OUT_DATA}asvab_score_social`yr'.png, width(4500) height(3000) replace	
}  // end of foreach yr in varlist



 */






* Scatter plots of the loadings 

/* 
rename asvab_general_sci science
rename asvab_arith_reasoning arith
rename asvab_word_know word
rename asvab_para_comp paragraph
rename asvab_nmbr_oper number
rename asvab_coding_speed coding
rename asvab_autoshop_info autoshop
rename asvab_math_know math
rename asvab_mech_comp mech
rename asvab_electr_info elec */


* Average interitem covariance
alpha $xlist



rename score1 pc1_verb
rename score2 pc2_math
rename score3 pc3_mech
rename score4 pc4_admin
rename score11 pc1_verb_m
rename score12 pc1_verb_f
rename score21 pc2_math_m
rename score22 pc2_math_f
rename score31 pc3_mech_m
rename score32 pc3_mech_f
rename score41 pc4_admin_m
rename score42 pc4_admin_f
rename social1 social_m
rename social2 social_f


label define l_cohort 79 "cohort 79"  97 "cohort 97" 
label values cohort l_cohort


label define l_race 1 "Hispanic" 2 "Black" 3 "NHNB"
label values race l_race






save ${MY_OUT_DATA}asvab_pca.dta, replace	
export delimited using ${MY_OUT_DATA}asvab_pca.csv, nolabel replace





log close

set more on
timer off 2

timer list


/*


use ${MY_IN_PATH}asvab97.dta, clear
global xlist asvab_general_sci asvab_arith_reasoning asvab_word_know asvab_para_comp asvab_nmbr_oper asvab_coding_speed asvab_auto_info asvab_shop_info asvab_math_know asvab_mech_comp asvab_electr_info asvab_assemb_obj
global id id

keep if race == 3

foreach v of varlist $xlist {
  qui sum `v'
  replace `v' = (`v' - r(mean))/r(sd)
}  // end of foreach v in varlist 

egen asvab_autoshop_info = rowmean(asvab_shop_info asvab_auto_info)
global xlist asvab_general_sci asvab_arith_reasoning asvab_word_know asvab_para_comp asvab_nmbr_oper asvab_coding_speed asvab_autoshop_info asvab_math_know asvab_mech_comp asvab_electr_info


replace asvab_wt = 1

* Principal component analysis (PCA)
//pca $xlist, mineigen(1) 
pca $xlist [fw=asvab_wt], mineigen(1) 
//pca $xlist [fw=asvab_wt], comp(5)
//pca $xlist [fw=asvab_wt], mineigen(1) blanks(.3)
pca $xlist [fw=asvab_wt], comp(5) blanks(.3)
estat kmo
//rotate, varimax 
rotate, varimax blanks(.3) /* comp(5)  */
rotate, clear

rotate, promax
rotate, promax blanks(.3) /* comp(5)  */ */
