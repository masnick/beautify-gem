webuse citytemp2, clear

set more off

// Beautify setup
do beautify.do
beautify_init, filename("output.txt") byvariable("region")

tab1out agecat, l("agecat")

tab2out agecat, l("agecat_region")

floatsummary tempjan, l("tempjan")

keep if inlist(region, 1, 2)
// Currently, tabmultout is limited to only two levels in the byvariable
tabmultout temp*, l("mult")

shell source /Users/max/.zshrc && beautify stata --data output.txt --template template.yaml --output ./
