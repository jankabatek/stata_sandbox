*! version 1.1.0  03Dec2024 
cap program drop expandrank 
program define expandrank

	version 9
	
	syntax anything [if] [in], [ 				/// 
			Base(real 1) 		/// 
			Name(string) 		///
			ORDered 			///
			Sort(varlist)]		
			
	local N = _N
	local E `anything'
	
	if `"`if'`in'"'!="" marksample touse
	if "`name'"=="" 	local name rank
	if "`sort'"!="" {	
						sort `sort'
						local ordered ordered
					}	
	if "`ordered'"!="" 	local E = `E' + 1
	
	confirm new variable `name'
	
	cap confirm var `E'
	if _rc == 0 local evar evar
	if ("`evar'"=="evar") & (`"`if'`in'"'!="")  {
		n di as err "expandrank currently does not support expanding by variable values combined with if/in clauses."
		exit 198
	} 
	
	
quietly {  
	expand `E' `if' `in'
	
	if "`ordered'"=="" { 
		if "`evar'"=="" {
			whichtype_expr(`base' + `E' - 1)
			gen $TYPE_EXPRNK `name' = `base' + (_n>`N')*(1 + mod((_n-`N'-1),`E'-1)) 
			
			if `"`if'`in'"'!="" {
				replace `name' = . if `touse'==0
			}
		}
		else {
			sum `E', meanonly
			whichtype_expr(r(max))
			gen $TYPE_EXPRNK `name' = `base' in 1/`N'
			
			local n_start = `N' + 1
			forvalues i = 1/`N' {
				local n_end = `n_start' + round(`E'[`i']) - 2
				replace rank = (_n - `n_start' + 2) in  `n_start'/ `n_end'
				local n_start = `n_end' + 1
			}
		}
	}
	else {
		whichtype_expr(`base' +`E' - 2)
		gen $TYPE_EXPRNK `name' = `base' + (_n>`N')*(1 + mod((_n-`N'-1),`E'-1)) - 1
		
		if `"`if'`in'"'!="" {
			drop if _n <= `N' & `touse'==1
			replace `name' = . if `touse'==0
		}
		else {
			drop if _n <= `N'
		}
	}	
	
	if "`sort'"!="" sort `sort' `name'
}
end

cap program drop whichtype_expr 
program define whichtype_expr
version 9
	gettoken equal : 0, parse("=")
	if "`equal'" != "=" {
			local 0 `"= `0'"'
	}
	syntax =exp
	local number `exp'
	
	if `number' <= maxbyte() {
		local type byte
	}
	else if `number' <= maxint() {
		local type int
	} 
	else if `number' <= maxlong() {
		local type long
	} 
	else if `number' <= maxfloat() {
		local type float
	} 
	global TYPE_EXPRNK `type'
end
exit	

 
