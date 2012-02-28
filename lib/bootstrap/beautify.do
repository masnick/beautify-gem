cap program drop beautify_init
prog beautify_init
  syntax , Filename(string) [Byvariable(string)]
  if `"`filename'"' == "" { // " syntax highlight fix
    di "You must include a filename."
    error 999
  }
  global BEAUTIFY_OUTFILE `"`filename'"' // " syntax highlight fix
  shell rm -rf "$BEAUTIFY_OUTFILE"

  if "`byvariable'" != "" {
    global BEAUTIFY_BYVAR "`byvariable'"
  }
end

cap prog drop beautify_check_init
prog beautify_check_init
  if "$BEAUTIFY_OUTFILE" == "" {
    di "You must run tablemaker_init first."
    error 999
  }
end

cap prog drop tabmultout
prog def tabmultout
  syntax varlist(min=1), Label(string) [by(varlist max=1)]
  beautify_check_init

  qui {
    cap file close outputfile
    file open outputfile using "$BEAUTIFY_OUTFILE", write append
  }
  if "`by'" == "" & "$BEAUTIFY_BYVAR" == "" {
    di "You must include a 'by' option or set the tablemaker byvariable in tablemaker_init."
    error 999
  }
  if "`by'" == "" {
    local by $BEAUTIFY_BYVAR
  }

  qui cap drop one
  qui gen one = 1

  di ""
  di ""
  di ""
  di "Multi-tab of `varlist':"

  // Get labels of "by" variable
  qui {
    tab `by'
    local nvar2 `r(r)'
    tabstat one, by(`by') s(n) save
    forvalues i = 1/`nvar2' {
      local colnames `colnames'||`r(name`i')'||,
      local byvarname_`i' `r(name`i')'
    }
  }


  // Get levels of "by" variable
  qui levelsof `by', local(levels_by)


  // Setup for row labels
  local rownames [


  // Loop through all the variables to be in the table
  foreach x of local varlist {

    // Save varlist var name to rownames
    local lab: var l `x'
    local rownames `rownames' ||`lab'||,

    // Detect continuous or binary (0/1)
    // Assume 0 = no and 1 = yes
    qui levelsof `x', local(is_binary)
    if "`is_binary'" == "0 1" {

      // Reset local variables for output
      local outcount
      local outtotal

      tab `x' `by', matcell(values)
      matlist values

      local counter 1
      foreach level_by of local levels_by {
        di "`x', for `byvarname_`counter'':"
        local tmp = values[2,`counter']
        local tmp2 = `tmp' + values[1,`counter']
        di "   count = `tmp'/`tmp2'"

        local outcount `outcount' `tmp',
        local outtotal `outtotal' `tmp2',

        local counter = `counter' + 1
      }

      foreach cleanup of any outcount outtotal {
        // Remove last character from local macros
        lstrfun len_var, strlen(`"`macval(`cleanup')'"') //" // syntax highlight fix
        local len_var = `len_var' - 1
        lstrfun `cleanup', substr(`"`macval(`cleanup')'"', 1, `macval(len_var)') //" // syntax highlight fix
        di "cleanup `cleanup': ``cleanup''"
      }

      local outvalues `outvalues' {||binary||: {||count||: [`outcount'], ||total||: [`outtotal'],
    }
    else {
      local counter 1

      // Reset local variables for output
      local outmean
      local outsd
      local outn

      // Summary stats for each level of "by"
      foreach level_by of local levels_by {
        qui sum `x' if `by' == `level_by'
        di "`x', for `byvarname_`counter'':"
        di "    Mean = `r(mean)'"
        di "      SD = `r(sd)'"
        di "       N = `r(N)'"

        local outmean `outmean' `r(mean)',
        local outsd `outsd' `r(sd)',
        local outn `outn' `r(N)',

        local counter = `counter' + 1
      }

      // Overall summary stats
      qui sum `x'
      di "`x', total:"
      di "    Mean = `r(mean)'"
      di "       N = `r(N)'"

      local outmean `outmean' ||`r(mean)'||,
      local outsd `outsd' ||`r(sd)'||,
      local outn `outn' `r(N)',

      foreach cleanup of any outmean outsd outn {
        // Remove last character from local macros
        lstrfun len_var, strlen(`"`macval(`cleanup')'"') //" // syntax highlight fix
        local len_var = `len_var' - 1
        lstrfun `cleanup', substr(`"`macval(`cleanup')'"', 1, `macval(len_var)') //" // syntax highlight fix
        di "cleanup `cleanup': ``cleanup''"
      }

      local outvalues `outvalues' {||continuous||: {||mean||: [`outmean'], ||sd||: [`outsd'], ||n||: [`outn'],

    }

    // Significance testing
    if `nvar2' > 2 {
      di "Oh no! Don't know what to do with more than 2 by var levels"
      error(1)
    }
    else {
      qui ttest `x', by(`by')
      di "       P = `r(p)'"

      local outvalues `outvalues' ||p||: ||`r(p)'||}},
    }
  }

  foreach cleanup of any outvalues rownames colnames {
    // Remove last character from local macros
    lstrfun len_var, strlen(`"`macval(`cleanup')'"') //" // syntax highlight fix
    local len_var = `len_var' - 1
    lstrfun `cleanup', substr(`"`macval(`cleanup')'"', 1, `macval(len_var)') //" // syntax highlight fix
    di "cleanup `cleanup': ``cleanup''"
  }

  // Finish up rownames & colnames
  local rownames `rownames']
  local colnames [`colnames']

  // Column names are the _value_ labels for the "by" variable
  // Row names are the _variable_ labels for each of the "varlist" variables
  // Values:
  //    binary: {count: [by1, by2], total: [by1, by2], p: 0.0001}
  //     cont.: {mean: [by1, by2, ..., total], sd: [by1, by2, ..., total], n: [by1, by2, ..., total], p: 0.0001}
  local output {||rownames||: `rownames', ||colnames||: `colnames', ||values||: [`outvalues'], ||sortby||: ||`label'||, ||type||: ||multi_tab||}

di "`output'"

  file write outputfile `"`output', "' // syntax highlighting fix "

  file close outputfile
end

cap program drop tab2out
program define tab2out
  syntax varlist(max=1), [by(varlist max=1) Label(string)]
  beautify_check_init
  qui {
    cap file close outputfile
    file open outputfile using "$BEAUTIFY_OUTFILE", write append
  }
  if "`by'" == "" & "$BEAUTIFY_BYVAR" == "" {
    di "You must include a 'by' option or set the tablemaker byvariable in tablemaker_init."
    error 999
  }
  if "`by'" == "" {
    local by $BEAUTIFY_BYVAR
  }
  if "`label'" == "" {
    local label "`varlist'"
  }
  di ""
  di ""
  di "Tabulation of `varlist' by `by'"
  di ""
  tab `varlist' `by', matcell(values) r col
  qui {
  local nvar1 `r(r)' // Number of rows
  local nvar2 `r(c)' // Number of columns

  local lab: var l `varlist' // Store variable label for varlist var
  local lab2: var l `by' // Store variable label for by var

  cap drop one
  gen one = 1

  // Get row names
  tabstat one, by(`varlist') s(n) save
  forvalues i = 1/`nvar1' {
    local rownames `rownames'||`r(name`i')'||,
  }
  lstrfun row_len_var, strlen(`"`macval(rownames)'"') //" // syntax highlight fix
  local row_len_var = `row_len_var' - 1
  lstrfun rownames, substr(`"`macval(rownames)'"', 1, `macval(row_len_var)') //" // syntax highlight fix
  local rownames [`rownames']

  // Get column names
  tabstat one, by(`by') s(n) save
  forvalues i = 1/`nvar2' {
    local colnames `colnames'||`r(name`i')'||,
  }
  lstrfun col_len_var, strlen(`"`macval(colnames)'"') //" // syntax highlight fix
  local col_len_var = `col_len_var' - 1
  lstrfun colnames, substr(`"`macval(colnames)'"', 1, `macval(col_len_var)') //" // syntax highlight fix
  local colnames [`colnames']

  // Get tabulation values
  forvalues i = 1/`nvar1' {
    local values `values' [
    local tmp ""
    forvalues j = 1/`nvar2' {
      local val = values[`i',`j']
      local tmp `tmp'`val',
    }
    local tmp = substr("`tmp'", 1, length("`tmp'")-1)
    local values `values'`tmp'],
  }
  local values = substr("`values'", 1, length("`values'")-1)

  // Simple statistics
  if `nvar1' == 2 & `nvar2' == 2 { // t-test for 2x2 table
    // Get value of first value for variable
    levelsof `varlist'
    local varlist_values = r(levels)
    local statval
    foreach v of any `varlist_values' {
      local statval `v'
      continue, break
    }
    di "statval is `statval'"
    cap drop __beautify_tmp_var
    recode `varlist' (`statval' = 1) (. = .) (else = 0), gen(__beautify_tmp_var)
    ttest __beautify_tmp_var, by(`by')
    local stattype Two-sample t test with equal variances
    local statresult `r(p)'
  }
  else if `nvar1' > 2 & `nvar2' == 2 { // Nx2 table where N > 2
    tab2 `varlist' `by', chi2
    local stattype Pearson's chi-squared
    local statresult `r(p)'
  }

  // Build output
  local output {||rownames||: `rownames', ||colnames||: `colnames', ||values||: [`values'], ||title||: [||`lab'||, ||`lab2'||], ||sortby||: ||`label'||, ||type||: ||tab2||, ||statistics||: {||type||: ||`stattype'||, ||result||: ||`statresult'||}}

  file write outputfile `"`output', "' // syntax highlighting fix "

  file close outputfile
  }

end




cap program drop tab1out
program define tab1out
  syntax varlist(max=1), Label(string)
  beautify_check_init
  qui {
    cap file close outputfile
    file open outputfile using "$BEAUTIFY_OUTFILE", write append
  }
  di ""
  di ""
  di "Tabulation of `varlist'"
  di ""
  tab `varlist', matcell(values)
  qui {
  local nvar1 `r(r)'
  local lab: var l `varlist'

  cap drop one
  gen one = 1

  tabstat one, by(`varlist') s(n) save
  forvalues i = 1/`nvar1' {
    local rownames `rownames'||`r(name`i')'||,
  }
  local rownames = substr("`rownames'", 1, length("`rownames'") - 1)
  local rownames [`rownames']


  mat l values

  local values [
  forvalues i = 1/`nvar1' {
    local tmp = values[`i',1]
    local values `values'`tmp',
  }
  local values = substr("`values'", 1, length("`values'")-1)
  local values `values']

  local output {||rownames||: `rownames', ||values||: `values', ||title||: [||`lab'||], ||sortby||: ||`label'||, ||type||: ||tab1||}


  file write outputfile `"`output', "' // syntax highlighting fix "
  file close outputfile
  }


end

// required:
which lstrfun
cap prog drop floatsummary
prog floatsummary
  syntax varlist(max=1) [if], Label(str) [by(varlist max=1)]
  beautify_check_init

if "`by'" == "" & "$BEAUTIFY_BYVAR" == "" {
    di "You must include a 'by' option or set the tablemaker byvariable in tablemaker_init."
    error 999
  }
  if "`by'" == "" {
    local by "$BEAUTIFY_BYVAR"
  }

  qui {
  cap file close outputfile


  cap drop one
  gen one = 1

  tab `by', matcell(values)
  local nvar2 `r(r)'



  tabstat one, by(`by') s(n) save
  forvalues i = 1/`nvar2' {
    local colnames `colnames'||`r(name`i')'||,
  }
  lstrfun col_len_var, strlen(`"`macval(colnames)'"') //" // syntax highlight fix
  local col_len_var = `col_len_var' - 1
  lstrfun colnames, substr(`"`macval(colnames)'"', 1, `macval(col_len_var)') //" // syntax highlight fix
  local colnames [`colnames',||Total||]


  local lab2: var l `by'

    if "`if'" == "" {
      local if2 "if"
    }
    else {
      local if2 "`if' &"
    }
  }
  foreach v in `varlist' {
    qui {
    file open outputfile using "$BEAUTIFY_OUTFILE", write append
    local values ""

    capture confirm string variable `v'
    if !_rc {
        local byquotechar `"""'
    }
    else {
        local byquotechar `""'
    }

    local values [
    levelsof `by', clean
    local byvals = r(levels)
    }
    di ""
    di ""
    di "Summary of `varlist' by `by'"
    di ""
    foreach byvalue of any `byvals' {
      di ""
      di ""
      di "`if2' `by' == `byquotechar'`byvalue'`byquotechar'"
      sum `v' `if2' `by' == `byquotechar'`byvalue'`byquotechar', d
      qui local values `values'||`r(N)'||, ||`r(mean)'||, ||`r(sd)'||, ||`r(p50)'||, ||`r(min)'||, ||`r(max)'||,
    }

    // Get the summary stats for the "totals" column

    di ""
    di ""
    di "Summary of `varlist' - total"
    sum `v' `if', d
    qui local values `values'||`r(N)'||, ||`r(mean)'||, ||`r(sd)'||, ||`r(p50)'||, ||`r(min)'||, ||`r(max)'||,

    qui {
    lstrfun len_var, strlen(`"`macval(values)'"') //" // syntax highlight fix
    local len_var = `len_var' - 1
    lstrfun values, substr(`"`macval(values)'"', 1, `macval(len_var)') //" // syntax highlight fix
    di "`values'"
    local values `values']

        di "`values'"

    local lab: var l `v'

    // Simple statistics
    if `nvar2' == 2 {
      ttest `varlist' `if', by(`by')
      local stattype Two-sample t test with equal variances
      local statresult `r(p)'
    }

    local output {||colnames||: `colnames', ||values||: `values', ||title||: [||`lab'||, ||`lab2'||], ||sortby||: ||`label'||, ||type||: ||sum||, ||statistics||: {||type||: ||`stattype'||, ||result||: ||`statresult'||}}

    file write outputfile `"`output', "' // syntax highlighting fix "

    file close outputfile
  }
}

end


