****************************************************
* FINAL PROJECT — ALL WEEKS, SIMULATED DATA ONLY
* 不需要任何外部檔案
****************************************************

clear all
set more off


****************************************************
* WEEK 2 — Budget Choice & Indifference (Real Estate Analyst)
****************************************************

* 參數設定
local T      = 16
local w      = 45
local V      = 15
local F      = 5
local k      = 2
local alpha  = 0.60

* ===== 找 baseline 最適點 =====
clear
set obs 17
gen H = _n - 1
gen L = `T' - H
gen C = cond(H==0, `V', `V' - `F' + (`w' - `k')*H)
gen U = `alpha'*ln(C) + (1-`alpha')*ln(L)

sort U
scalar optH = H[_N]
scalar optL = L[_N]
scalar optC = C[_N]

* ===== baseline 圖：預算線 + 無差異曲線 + 最適點 =====
clear
set obs 500
gen L = (_n-1)*(16/499)

gen C0 = `V' - `F' + (`w' - `k')*(16-L)
replace C0 = `V' if L==16

scalar Ustar = `alpha'*ln(optC) + (1-`alpha')*ln(optL)
gen Cind = exp((Ustar - (1-`alpha')*ln(L))/`alpha')

twoway ///
    (line C0 L, lcolor(blue)) ///
    (line Cind L, lcolor(red) lpattern(dash)) ///
    (scatter optC optL, mcolor(red) msymbol(circle) msize(large)) ///
    , ///
    title("Week 2 Baseline") ///
    xtitle("Leisure") ///
    ytitle("Consumption")

graph export "W2_baseline.png", replace


* ===== 工資 +10%（只畫兩條預算線） =====
clear
local w2 = `w'*1.1

set obs 500
gen L = (_n-1)*(16/499)

gen C_old = `V' - `F' + (`w' - `k')*(16-L)
replace C_old = `V' if L==16

gen C_new = `V' - `F' + (`w2' - `k')*(16-L)
replace C_new = `V' if L==16

twoway ///
    (line C_old L, lcolor(blue)) ///
    (line C_new L, lcolor(green)) ///
    , ///
    title("Week 2 Wage +10%") ///
    xtitle("Leisure") ///
    ytitle("Consumption")

graph export "W2_wage_increase.png", replace


* ===== 非勞動收入 +100（兩條預算線） =====
clear
local V2 = `V' + 100

set obs 500
gen L = (_n-1)*(16/499)

gen C_old = `V' - `F' + (`w' - `k')*(16-L)
replace C_old = `V' if L==16

gen C_new = `V2' - `F' + (`w' - `k')*(16-L)
replace C_new = `V2' if L==16

twoway ///
    (line C_old L, lcolor(blue)) ///
    (line C_new L, lcolor(orange)) ///
    , ///
    title("Week 2 Non-labor Income +100") ///
    xtitle("Leisure") ///
    ytitle("Consumption")

graph export "W2_income_increase.png", replace



****************************************************
* WEEK 3 — Wage Elasticity (模擬時間序列資料)
****************************************************

clear
set obs 120
gen date = tm(2015m1) + _n-1
format date %tm
tsset date

* 模擬就業與工資
set seed 12345
gen employment = 100 + rnormal(0,3) - 0.1*_n
gen wage       = 30 + 0.03*_n + rnormal(0,1)

* year-over-year 模擬 (這裡簡化用一階差分)
gen dE = ln(employment) - ln(l.employment)
gen dW = ln(wage)       - ln(l.wage)

drop if missing(dE, dW)

reg dE dW

twoway ///
    (scatter dE dW, mcolor(blue)) ///
    (lfit dE dW, lcolor(red)) ///
    , ///
    title("Week 3 Simulated Wage Elasticity") ///
    xtitle("Δ ln(wage)") ///
    ytitle("Δ ln(employment)")

graph export "W3_elasticity.png", replace



****************************************************
* WEEK 4 — Supply and Demand Shocks (五張圖)
****************************************************

* ===== Baseline =====
clear
set obs 200
gen emp = _n
gen demand = 200 - 0.15*emp
gen supply = 20  + 0.10*emp

twoway ///
    (line demand emp, lcolor(blue)) ///
    (line supply emp, lcolor(red)) ///
    , ///
    title("Week 4 Baseline") ///
    xtitle("Employment") ///
    ytitle("Wage")

graph export "W4_baseline.png", replace


* ===== Positive Demand Shock =====
clear
set obs 200
gen emp = _n
gen demand  = 200 - 0.15*emp
gen demand2 = 230 - 0.15*emp
gen supply  = 20  + 0.10*emp

twoway ///
    (line demand emp,  lcolor(blue)) ///
    (line demand2 emp, lcolor(blue) lpattern(dash)) ///
    (line supply emp,  lcolor(red)) ///
    , ///
    title("Week 4 Positive Demand Shock") ///
    xtitle("Employment") ///
    ytitle("Wage")

graph export "W4_demand_pos.png", replace


* ===== Negative Demand Shock =====
clear
set obs 200
gen emp = _n
gen demand  = 200 - 0.15*emp
gen demand2 = 160 - 0.15*emp
gen supply  = 20  + 0.10*emp

twoway ///
    (line demand emp,  lcolor(blue)) ///
    (line demand2 emp, lcolor(blue) lpattern(dash)) ///
    (line supply emp,  lcolor(red)) ///
    , ///
    title("Week 4 Negative Demand Shock") ///
    xtitle("Employment") ///
    ytitle("Wage")

graph export "W4_demand_neg.png", replace


* ===== Positive Supply Shock =====
clear
set obs 200
gen emp = _n
gen demand  = 200 - 0.15*emp
gen supply  = 20 + 0.10*emp
gen supply2 = 10 + 0.10*emp

twoway ///
    (line demand emp,  lcolor(blue)) ///
    (line supply emp,  lcolor(red)) ///
    (line supply2 emp, lcolor(red) lpattern(dash)) ///
    , ///
    title("Week 4 Positive Supply Shock") ///
    xtitle("Employment") ///
    ytitle("Wage")

graph export "W4_supply_pos.png", replace


* ===== Negative Supply Shock =====
clear
set obs 200
gen emp = _n
gen demand  = 200 - 0.15*emp
gen supply  = 20 + 0.10*emp
gen supply2 = 40 + 0.10*emp

twoway ///
    (line demand emp,  lcolor(blue)) ///
    (line supply emp,  lcolor(red)) ///
    (line supply2 emp, lcolor(red) lpattern(dash)) ///
    , ///
    title("Week 4 Negative Supply Shock") ///
    xtitle("Employment") ///
    ytitle("Wage")

graph export "W4_supply_neg.png", replace



****************************************************
* WEEK 8 — Mincer Regression (模擬截面資料)
****************************************************

clear
set obs 500
set seed 24680

* 模擬教育年數、年齡
gen yrschool = 10 + int(runiform()*8)   // 10~17 年
gen age      = 22 + int(runiform()*30)  // 22~51 歲

* 模擬工資：ln(wage) = 1 + 0.08*yrschool + 0.03*age + error
gen eps  = rnormal(0, .2)
gen lnw  = 1 + 0.08*yrschool + 0.03*age + eps
gen wage = exp(lnw)

gen exp  = age - yrschool - 6
gen exp2 = exp^2

reg lnw yrschool exp exp2

twoway ///
    (scatter lnw yrschool, mcolor(blue)) ///
    (lfit lnw yrschool,  lcolor(red)) ///
    , ///
    title("Week 8 Simulated Return to Education") ///
    xtitle("Years of Schooling") ///
    ytitle("ln(wage)")

graph export "W8_education.png", replace


****************************************************
* END
****************************************************
display "ALL DONE - CHECK YOUR PNG FILES IN WORKING FOLDER."
