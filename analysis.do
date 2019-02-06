qui cd H:\Dokumente_SOZ\Career_Tracker\CTC_Daten

use SNSF-CTC-18-19-M1.dta, clear


## Setup

***/
// required ssc packages: estout, fre, center, grstyle, coefplot, marktouse
about
version 15.1
clear all
set linesize 90
set type double
set more off
// Graph style
grstyle init
grstyle set plain, grid horizontal
grstyle set color Set1, select(2 1)
grstyle set color Set1, select(2 1) op(70): p#bar
grstyle set color Set1, select(2) op(70 100) inten(1 .5): histogram histogram_line
grstyle set margin "1 1 1 1"
grstyle set graphsize 4 6.5
use SNSF-CTC-18-19-M1_Data_2018_20_12.dta
/***

## Response rate

***/
gen byte rr0 = (reminder1==0 & status==3)   if status<. // before reminder 1
gen byte rr1 = (reminder2==0 & status==3)   if status<. // before reminder 2
gen byte rr2 = (reminder3==0 & status==3)   if status<. // before reminder 3
gen byte rr3 = (status==3)                  if status<. // overall
tabstat rr0 rr1 rr2 rr3, stat(count sum mean) columns(statistics)
/***

Graph of response rate over time

***/
preserve
gen days = hours(submitdate - clock("2018-10-02 09:53:00", "YMDhms"))/24
sort days
by days: gen p = _N
by days: keep if _n==1
replace p = sum(p)
replace p = p / p[_N]
fre reminder1date //2018-10-10 10:24 --> 8 days and 31min (8.02 days)
fre reminder2date //2018-10-17 16:56:00 --> 15 days and 7h 3min (15.29 days)
fre reminder3date //2018-10-22 14:11:00 --> 20 days and 4h 18min (20.18 days)
line p days, xlabel(0(2)28) xtitle(Days since invitation) ///
    ylab(0(.1)1) ytitle(Response rate) ///
    xaxis(1 2) xtitle("", axis(2)) xscale(axis(2) noline) ///
    xline(8.02 15.29 20.18) xlabel(8.02 `""1st" "reminder""' ///
        15.29 `""2nd" "reminder""' 20.18 `""3rd" "reminder""', axis(2) notick)
restore
webdoc graph responserate
/***

## Interview break-off

***/
fre highpage
/***

9 respondents who started the interview, did not complete it
(1.97\% of net sample, 2.13\% of all respondents who started the interview).

* 1 on page 4: What is your occupation?
* 1 on page 7: What is your current professional status?
* ...

**Why are the page numbers different than in Janine's Word file?**

## Sample selectivity by background characteristics

Note: Respondents who started the interview, but did not complete it, are counted as
non-respondents.

***/
gen byte response  = status==3 if status<.
fre response
gen age = 2018 - birth
center age, standardize
lab var c_age "Age (standardized)"
gen     origin = 1 if institution2cntry == "Switzerland"
replace origin = 2 if institution2cntry != "Switzerland" & institution2cntry!=""
replace origin = 3 if institution2cntry==""
lab def origin 1 "Swiss" 2 "Foreign" 3 "Unknown"
lab val origin origin
logit response c_age i.gndr i.instrument i.discipline_cat i.origin
margins, dydx(*) post
coefplot ., xline(0) base coefl(, wrap(25)) ///
    xti(Average marginal effects on response rate) ///
    headings(0.gndr           = "{bf:Gender}" ///
             0.instrument     = "{bf:Instrument}" ///
             1.discipline_cat = "{bf:Discipline}" ///
             1.origin         = "{bf:Research institution}" , nogap)
webdoc graph response
/***

## Relation between response and funding

***/
proportion funding if withdrawal!=1, over(response)
tab funding response, exact
local p `:di %9.3f r(p_exact)'
coefplot (., keep(Yes:*) swap) (., keep(No:*) swap), ///
    title("Difference in success rate: p = `p'") ///
    subti("(withdrawn applications excluded)") ///
    vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) nooffset ///
    order(1: 0:) legend(off) eqlab("Participants (N = 413)" "Non-participants (N = 42)", gap(.25)) ///
    rescale(100) coefl(Yes = "Funded" No = "Not funded") ylab(0(5)70) yti(Percent) ///
    xtick(2.625, notick grid) plotregion(margin(b=0))
webdoc graph funding
/***

## Interview duration

***/
gen dur =  timesurvey/60
summarize dur if status==3, detail
local med `:di %9.1f r(p50)'
local mean `:di %9.1f r(mean)'
hist dur if status==3, xlabel(0(5)65) xti("Interview duration (in minutes)") fraction ///
    xline(`r(p50)') xline(`r(mean)', lp(dash)) ylabel(0(.05).3) ///
    text(.3 `=r(p50)-1' "Median = `med'", place(west)) ///
    text(.3 `=r(mean)+1' "Mean = `mean'", place(east))
webdoc graph duration
/***

## Sample composition and some descriptives

### Gender

***/
proportion gndr if status==3
coefplot ., vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0)) ylabel(0(.1).7) yline(.5) citype(logit) ///
    yti(Proportion)
webdoc graph gender
/***

### Age

***/
summarize age if status==3, detail
local med `:di %9.1f r(p50)'
local mean `:di %9.1f r(mean)'
hist age if status==3, discrete xti(Age)  fraction ///
    xline(`r(p50)') xline(`r(mean)', lp(dash)) ylabel(0(.05).2) ///
    text(.2 `=r(p50)-.3' "Median = `med'", place(west)) ///
    text(.2 `=r(mean)+.3' "Mean = `mean'", place(east))
webdoc graph age
/***

### Instrument

***/
proportion instrument if status==3
coefplot ., vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0)) ylabel(0(.1).7) citype(logit) ///
    coefl(_prop_1 = "Early Postdoc.Mobility" ///
          _prop_2 = "Postdoc.Mobility") ///
    yti(Proportion)
webdoc graph instrument
/***

### Discipline

***/
proportion discipline_cat if status==3
coefplot ., vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0)) ylabel(0(.05).45) citype(logit) ///
    coefl(_prop_1 = "Human and Social Sciences" ///
          _prop_2 = "Mathematics, Natural- and Engineering Sciences" ///
          _prop_3 = "Biology and Medicine", wrap(25)) ///
    yti(Proportion)
webdoc graph discipline
/***

### Country of research institute / country in which employed

***/
eststo origin: proportion origin if status==3
gen     country = 1 if emplcntry=="Switzerland" & empl==1
replace country = 2 if emplcntry!="Switzerland" & emplcntry!="" & empl==1
replace country = 3 if emplcntry=="" & empl==1
lab val country origin
eststo country: proportion country if status==3
coefplot origin || country ||, vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0)) ylabel(0(.1).7) citype(logit) ///
    yti(Proportion) bylabels("Country of research institution" "Country of employment")
webdoc graph country
/***

### Employment

***/
proportion empl if status==3
coefplot ., vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0)) ylabel(0(.1).8) citype(logit) ///
    coefl(No = "Not employed" Yes = "Employed") ///
    yti(Proportion) order(Yes No)
webdoc graph employment
/***

***/
fre notemplreas if status==3
/***

### Research activities

In your current job, do you conduct academic research?

***/
gen     research2 = 1 if inlist(research,1,2)
replace research2 = 2 if inlist(research,3,4)
proportion research2 if status==3
coefplot ., vertical recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0)) ylabel(0(.1)1) citype(logit) ///
    coefl(1 = "Yes" 2 = "No / Only in secondary job") ///
    yti(Proportion)
webdoc graph research
/***

In academic job: time spent on ...

***/
mean activity* if status==3
coefplot ., ///
    recast(bar) barw(.7) citop ciopts(recast(rcap))  ///
    plotregion(margin(l=0)) xlabel(0(10)100)  ///
    coefl(activityres   = "... research" ///
          activityteach = "... teaching" ///
          activityadmin = "... administrative duties" ///
          activityclin  = "... clinical activities" ///
          activityoth   = "... other activities") ///
    xti(Percentage)
webdoc graph activity
/***


## Aspirations and work values

### Aspired position in future career

***/
proportion aspiration if status==3
coefplot ., ///
    recast(bar) barw(.7) citop ciopts(recast(rcap))  ///
    plotregion(margin(l=0)) xlabel(0(.1).9) citype(logit) ///
    coefl(_prop_1 = "Full tenured professorship" ///
          _prop_2 = "Other leading management position" ///
          _prop_3 = "Other leading research position" ///
          _prop_4 = "Other permanent teaching position") ///
    xti(Proportion)
webdoc graph aspiration
/***

### Important aspects for future career

***/
eststo tot:    mean imp* if status==3
eststo male:   mean imp* if status==3 & gndr==0
eststo female: mean imp* if status==3 & gndr==1
local mlabels
foreach v of varlist imp* {
    di as res _n ". ttest `v', by(gndr)"
    ttest `v', by(gndr) unequal
    if r(p)<.1 {
        local p `:di %9.3f r(p)'
        local mlabels `mlabels' `v' = 1 "{it:p} = `p'"
    }
}
coefplot (male,offset(.2)) (female, offset(-.2) mlabels(`mlabels')) ///
         (tot, if(@b>5) nokey), sort(3,d) xlabel(1(1)5) mlabgap(1) mlabt(small_label) ///
    coefl(impsecjob       = "secure job" ///
          impsalary       = "high salary" ///
          impcareerprosp  = "good career prospects" ///
          impprestige     = "prestigious institution" ///
          impcolleg       = "work with renowned colleagues" ///
          impinfra        = "good equipment/infrastructure" ///
          impcntry        = "same country as now" ///
          imppart         = "work part-time" ///
          impworklife     = "reconcile work and family life" ///
          impothact       = "reconcile work with other activities" ///
          impexp          = "work within area of expertise" ///
          impqualif       = "use specialist qualifications" ///
          impidea         = "put own ideas into practice" ///
          impview         = "do work corresponding to own views" ///
          impdevelop      = "develop further in subject area" ///
          impcareercont   = "continue academic career") ///
    legend(pos(0) bplace(se) cols(1)) ///
    xmtick(##2, grid notick) graphr(margin(r=10)) ///
    xlabel(1 `""1" "Not important at all""' 5 `""5" "Very important""', add)
webdoc graph important
/***

### Devotion to scientific work

***/
eststo tot:    mean science* if status==3
eststo male:   mean science* if status==3 & gndr==0
eststo female: mean science* if status==3 & gndr==1
local mlabels
foreach v of varlist science* {
    di as res _n ". ttest `v', by(gndr)"
    ttest `v', by(gndr) unequal
    if r(p)<.1 {
        local p `:di %9.3f r(p)'
        local mlabels `mlabels' `v' = 1 "{it:p} = `p'"
    }
}
coefplot (male,offset(.2)) (female, offset(-.2) mlabels(`mlabels')) ///
         (tot, if(@b>5) nokey), sort(3,d) xlabel(1(1)5) mlabgap(3) mlabt(small_label) ///
    coefl(, wrap(30)) legend(pos(0) bplace(se) cols(1)) xmtick(##2, grid notick) ///
    graphr(margin(r=7)) ///
    xlabel(1 `""1" "Do not agree at all""' 5 `""5" "Fully agree""', add)
webdoc graph science
/***


## Family situation

### Partner / marital status

***/
gen fstat = 1 if marital==1
replace fstat = 2 if fstat==1 & partner==1
replace fstat = 3 if marital==2
replace fstat = 4 if marital==6
replace fstat = 5 if inlist(marital,4,5)
proportion fstat if status==3
coefplot ., recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(l=0)) xlabel(0(.05).5) citype(logit) xti(Proportion) ///
    coefl(1 = "Single (without partner)"   ///
          2 = "Single (with partner)"      ///
          3 = "Married"                    ///
          4 = "Registered partnership"     ///
          5 = "Divorced/Widowed")
webdoc graph partner
/***

### Children

***/
eststo tot:   mean children if status==3
eststo fstat: mean children if status==3, over(fstat)
coefplot (tot \ fstat, drop(5)), aseq("_") ///
    recast(bar) barw(.7) citop ciopts(recast(rcap)) ///
    plotregion(margin(l=0)) xlabel(0(.05).55) citype(logit) xti(Proportion) ///
    coefl(children = "Overall" ///
          1 = "Single (without partner)"   ///
          2 = "Single (with partner)"      ///
          3 = "Married"                    ///
          4 = "Registered partnership")
webdoc graph children
/***


***/
preserve
keep if status==3
keep ID child?
reshape long child, i(ID) j(nchild)
drop if child>=.
gen age = 2018-child
summarize age, detail
local med `:di %9.1f r(p50)'
local mean `:di %9.1f r(mean)'
hist age, discrete xti("Age of child (2018 - birth year)") fraction ///
    xline(`r(p50)') text(.205 `=r(p50)+.2' "Median = `med'", place(east)) ///
    xline(`r(mean)', lp(dash)) text(.19 `=r(mean)+.2' "Mean = `mean'", place(east))
restore
webdoc graph childage
/***

### Childcare responsibility

***/
gen     chcare = 1 if inlist(childcarediv,1,2)
replace chcare = 2 if inlist(childcarediv,3)
replace chcare = 3 if inlist(childcarediv,4,5)
proportion chcare if status==3, over(gndr)
coefplot (., keep(*:Male))  (., keep(*:Female)), swap vertical ///
    recast(bar) barw(.3) citop ciopts(recast(rcap)) ///
    plotregion(margin(b=0))  citype(logit) ylabel(0(.1).8) yti(Proportion) ///
    coefl(_prop_1 = "Respondent" _prop_2 = "Shared" _prop_3 = "Other parent")
webdoc graph childcare
/***

## Satisfaction with ...

***/
eststo male:   mean worklife lifesat if status==3 & gndr==0
eststo female: mean worklife lifesat if status==3 & gndr==1
local mlabels
foreach v of varlist worklife lifesat {
    di as res _n ". ttest `v', by(gndr)"
    ttest `v', by(gndr) unequal
    if r(p)<.1 {
        local p `:di %9.3f r(p)'
        local mlabels `mlabels' `v' = 1 "{it:p} = `p'"
    }
}
coefplot (male) (female, mlabels(`mlabels')), xlabel(1(1)5) mlabgap(6) mlabt(small_label) ///
    coefl(worklife = "... work-life balance" ///
          lifesat  = "... life in general") legend(pos(0) bplace(se) cols(1)) ///
    xmtick(##2, grid notick) graphr(margin(r=9)) ///
    xlabel(1 `""1" "Not satisfied at all""' 5 `""5" "Very satisfied""', add)
webdoc graph satisfaction
/***


## Funding success

***/
gen nonempl = empl==0 if empl<.
gen byte PhDprice =  phdprize==1 // set all other to zero
gen prof = aspiration==1 if aspiration<.
gen devotion = sciencecentr + sciencedemands + sciencecommitm + sciencemostimp
marktouse touse funding age gndr children prof devotion PhDprice nonempl origin ///
    instrument discipline_cat resubmission if status==3 & withdrawal!=1
center age      if touse, standardize gen(stdage)
center devotion if touse, standardize inplace
logit funding stdage i.gndr##i.children i.prof devotion i.PhDprice i.nonempl i.origin ///
     i.instrument i.discipline_cat i.resubmission if status==3 & withdrawal!=1
eststo model
margins, dydx(*) post
coefplot, drop(*.gndr *.children) xline(0) ///
    xtitle("Average marginal effects on funding success") nolabel ///
    coefl(stdage = "Age (standardized)" ///
          1.prof = "Aspiration: Professorship" ///
          devotion = "Devotion to science (std.)" ///
          1.PhDprice = "Won a PhD price" ///
          1.nonempl = "Currently not employed" ///
          2.origin = "Non-Swiss research institution" ///
          3.origin = "Research institution missing" ///
          1.instrument = "Postdoc.Mobility" ///
          2.discipline_cat = "Mathematics, Natural- and Engineering Sciences" ///
          3.discipline_cat = "Biology and Medicine" ///
          1.resubmission = "Resubmission" ///
          , wrap(30)) xlabel(-.5(.1).4)
webdoc graph funding1
/***

***/
est restore model
margins i.gndr#i.children, post
coefplot (., keep(*0.children) rename(*#0.children = "") lab(Without children)) ///
         (., keep(*1.children) rename(*#1.children = "") lab(With children)) ///
    , vertical recast(bar) citop ciopts(recast(rcap)) barw(.3) base(0) ///
    plotregion(margin(b=0)) ylabel(0(.05).7) yti("Predictive margins of funding success")
webdoc graph funding2
/***


***/
webdoc init, nologall
webdoc close
markdown SNSF-CTC-Presentation-2019-01-08.md, saving(SNSF-CTC-Presentation-2019-01-08.html) replace
// webdoc exit
