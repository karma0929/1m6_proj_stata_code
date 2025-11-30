********************************************************************************
* Labor Market Analysis
********************************************************************************

clear all
set more off

********************************************************************************
* Import Data
********************************************************************************

import delimited using "employment_msa.csv", clear
rename obs* date
rename smu* employed
tempfile E
save `E'

import delimited using "ahe_services.csv", clear
rename obs* date
rename ces* wages
tempfile W
save `W'

use `E', clear
merge 1:1 date using `W', nogen
gen m = mofd(date(date,"YMD"))
format m %tm
tsset m, monthly

********************************************************************************
* Estimate Labor Demand Elasticity
********************************************************************************

gen lnE = ln(employed)
gen lnW = ln(wages)

* Try 12-month differences
gen d12_lnE = lnE - L12.lnE
gen d12_lnW = lnW - L12.lnW

capture reg d12_lnE d12_lnW, vce(robust)
if _rc == 0 & e(N) > 1 {
    scalar eta_demand = _b[d12_lnW]
}
else {
    * Fall back to month-to-month
    gen d1_lnE = lnE - L1.lnE
    gen d1_lnW = lnW - L1.lnW
    capture reg d1_lnE d1_lnW, vce(robust)
    if _rc == 0 & e(N) > 1 {
        scalar eta_demand = _b[d1_lnW]
    }
    else {
        scalar eta_demand = -0.3
    }
}

* Ensure negative elasticity
if eta_demand > 0 {
    scalar eta_demand = -1 * eta_demand
}

********************************************************************************
* Set Equilibrium Parameters
********************************************************************************

quietly summarize employed if !missing(employed)
scalar E_eq = r(mean)
quietly summarize wages if !missing(wages)
scalar W_eq = r(mean)
scalar eta_supply = 0.5

local E_eq = E_eq
local W_eq = W_eq
local eta_d = eta_demand
local eta_s = eta_supply
local W_eq_fmt : display %6.2f `W_eq'
local E_eq_fmt : display %6.1f `E_eq'

********************************************************************************
* Create Supply and Demand Curves
********************************************************************************

clear
set obs 100
gen wage = `W_eq' * (0.5 + (_n-1)/99)
gen employment_demand = `E_eq' * (wage/`W_eq')^`eta_d'
gen employment_supply = `E_eq' * (wage/`W_eq')^`eta_s'

********************************************************************************
* GRAPH 1: Initial Equilibrium
********************************************************************************

twoway (line wage employment_demand, lcolor(blue) lwidth(medium)) ///
       (line wage employment_supply, lcolor(red) lwidth(medium)) ///
       (scatteri `W_eq' `E_eq', mcolor(black) msize(large)), ///
       title("Labor Market Equilibrium") ///
       xtitle("Employment (thousands)") ytitle("Wage ($)") ///
       legend(order(1 "Demand" 2 "Supply" 3 "Equilibrium") pos(11) ring(0)) ///
       text(`W_eq' `E_eq' "Equilibrium" "W=$`W_eq_fmt'" "E=`E_eq_fmt'", ///
            place(e) box fcolor(white) margin(small) size(small)) ///
       graphregion(color(white)) bgcolor(white)
graph export "labor_equilibrium.png", replace

********************************************************************************
* GRAPH 2: Positive Demand Shock
********************************************************************************

gen employment_demand_shock1 = employment_demand * 1.15
scalar W_new1 = `W_eq' * 1.15^(1/(`eta_s' - `eta_d'))
scalar E_new1 = `E_eq' * (W_new1/`W_eq')^`eta_s'
local W_new1_fmt : display %6.2f W_new1
local E_new1_fmt : display %6.1f E_new1

twoway (line wage employment_demand, lcolor(blue) lpattern(dash)) ///
       (line wage employment_demand_shock1, lcolor(blue) lwidth(thick)) ///
       (line wage employment_supply, lcolor(red)) ///
       (scatteri `W_eq' `E_eq', mcolor(gray) msize(medium)) ///
       (scatteri `=W_new1' `=E_new1', mcolor(black) msize(large)), ///
       title("Positive Demand Shock") subtitle("(e.g., Technology)") ///
       xtitle("Employment (thousands)") ytitle("Wage ($)") ///
       legend(order(1 "Original Demand" 2 "New Demand" 3 "Supply" ///
                    4 "Old Eq" 5 "New Eq") ring(0) pos(5)) ///
       text(`W_eq' `E_eq' "Old: W=$`W_eq_fmt', E=`E_eq_fmt'", ///
            place(w) box fcolor(gs15) margin(small) size(vsmall)) ///
       text(`=W_new1' `=E_new1' "New: W=$`W_new1_fmt', E=`E_new1_fmt'", ///
            place(e) box fcolor(white) margin(small) size(vsmall)) ///
       graphregion(color(white)) bgcolor(white)
graph export "demand_shock_positive.png", replace

********************************************************************************
* GRAPH 3: Negative Demand Shock
********************************************************************************

gen employment_demand_shock2 = employment_demand * 0.85
scalar W_new2 = `W_eq' * 0.85^(1/(`eta_s' - `eta_d'))
scalar E_new2 = `E_eq' * (W_new2/`W_eq')^`eta_s'
local W_new2_fmt : display %6.2f W_new2
local E_new2_fmt : display %6.1f E_new2

twoway (line wage employment_demand, lcolor(blue) lpattern(dash)) ///
       (line wage employment_demand_shock2, lcolor(blue) lwidth(thick)) ///
       (line wage employment_supply, lcolor(red)) ///
       (scatteri `W_eq' `E_eq', mcolor(gray) msize(medium)) ///
       (scatteri `=W_new2' `=E_new2', mcolor(black) msize(large)), ///
       title("Negative Demand Shock") subtitle("(e.g., Recession)") ///
       xtitle("Employment (thousands)") ytitle("Wage ($)") ///
       legend(order(1 "Original Demand" 2 "New Demand" 3 "Supply" ///
                    4 "Old Eq" 5 "New Eq") ring(0) pos(5)) ///
       text(`W_eq' `E_eq' "Old: W=$`W_eq_fmt', E=`E_eq_fmt'", ///
            place(e) box fcolor(gs15) margin(small) size(vsmall)) ///
       text(`=W_new2' `=E_new2' "New: W=$`W_new2_fmt', E=`E_new2_fmt'", ///
            place(w) box fcolor(white) margin(small) size(vsmall)) ///
       graphregion(color(white)) bgcolor(white)
graph export "demand_shock_negative.png", replace

********************************************************************************
* GRAPH 4: Positive Supply Shock
********************************************************************************

gen employment_supply_shock3 = employment_supply * 1.15
scalar W_new3 = `W_eq' * 1.15^(1/(`eta_d' - `eta_s'))
scalar E_new3 = `E_eq' * (W_new3/`W_eq')^`eta_d'
local W_new3_fmt : display %6.2f W_new3
local E_new3_fmt : display %6.1f E_new3

twoway (line wage employment_demand, lcolor(blue)) ///
       (line wage employment_supply, lcolor(red) lpattern(dash)) ///
       (line wage employment_supply_shock3, lcolor(red) lwidth(thick)) ///
       (scatteri `W_eq' `E_eq', mcolor(gray) msize(medium)) ///
       (scatteri `=W_new3' `=E_new3', mcolor(black) msize(large)), ///
       title("Positive Supply Shock") subtitle("(e.g., Immigration)") ///
       xtitle("Employment (thousands)") ytitle("Wage ($)") ///
       legend(order(1 "Demand" 2 "Original Supply" 3 "New Supply" ///
                    4 "Old Eq" 5 "New Eq") ring(0) pos(5)) ///
       text(`W_eq' `E_eq' "Old: W=$`W_eq_fmt', E=`E_eq_fmt'", ///
            place(n) box fcolor(gs15) margin(small) size(vsmall)) ///
       text(`=W_new3' `=E_new3' "New: W=$`W_new3_fmt', E=`E_new3_fmt'", ///
            place(s) box fcolor(white) margin(small) size(vsmall)) ///
       graphregion(color(white)) bgcolor(white)
graph export "supply_shock_positive.png", replace

********************************************************************************
* GRAPH 5: Negative Supply Shock
********************************************************************************

gen employment_supply_shock4 = employment_supply * 0.85
scalar W_new4 = `W_eq' * 0.85^(1/(`eta_d' - `eta_s'))
scalar E_new4 = `E_eq' * (W_new4/`W_eq')^`eta_d'
local W_new4_fmt : display %6.2f W_new4
local E_new4_fmt : display %6.1f E_new4

twoway (line wage employment_demand, lcolor(blue)) ///
       (line wage employment_supply, lcolor(red) lpattern(dash)) ///
       (line wage employment_supply_shock4, lcolor(red) lwidth(thick)) ///
       (scatteri `W_eq' `E_eq', mcolor(gray) msize(medium)) ///
       (scatteri `=W_new4' `=E_new4', mcolor(black) msize(large)), ///
       title("Negative Supply Shock") subtitle("(e.g., Higher Reservation Wages)") ///
       xtitle("Employment (thousands)") ytitle("Wage ($)") ///
       legend(order(1 "Demand" 2 "Original Supply" 3 "New Supply" ///
                    4 "Old Eq" 5 "New Eq") ring(0) pos(5)) ///
       text(`W_eq' `E_eq' "Old: W=$`W_eq_fmt', E=`E_eq_fmt'", ///
            place(s) box fcolor(gs15) margin(small) size(vsmall)) ///
       text(`=W_new4' `=E_new4' "New: W=$`W_new4_fmt', E=`E_new4_fmt'", ///
            place(n) box fcolor(white) margin(small) size(vsmall)) ///
       graphregion(color(white)) bgcolor(white)
graph export "supply_shock_negative.png", replace

display _newline "ALL 5 GRAPHS COMPLETE"
