webuse citytemp2, clear

set more off

// Beautify setup
do beautify.do
beautify_init, filename("output.txt") byvariable("region")

tab2out agecat, l("agecat")

shell beautify stata --data output.txt --template template.yaml --output ./
