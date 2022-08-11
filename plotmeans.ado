*! version 1.0.0  02Aug2022 
capture program drop plotmeans 
program define plotmeans
	version 16
	
	** Plottabs-specific options defined here
	local pt_opts 		clear 				COMmand     		///
		FRame(string) 	GLobal 				GRaph(name)  		NODiag ///
		PLOTonly   		PLName(string) 		REPlace(integer -1) ///
		OUTput(string) 	TIMes(real 1)  		YZero
	
	** All native twoway options specified here...
	local tw_opts 		 noDRAW 			NAME(string) 		///
		SCHeme(passthru) COPYSCHeme 		noREFSCHeme 		/// 
		FXSIZe(passthru) FYSIZe(passthru)	PLAY(string asis)	/// 
		TItle(string)    SUBtitle(string) 	CAPtion(string)		///
		NOTE(string)     LEGend(string)							///
		T1title(string)  T2title(string) 	B1title(string)		///
		B2title(string)  L1title(string) 	L2title(string)		///
		R1title(string)  R2title(string)						///
		XLabels(string)  YLabels(string)  	TLabels(string)		///
		XTICks(string)   YTICks(string)   	TTICks(string)		///
		XMLabels(string) YMLabels(string) 	TMLabels(string)	///
		XMTicks(string)  YMTicks(string)  	TMTicks(string)		/// 
		XTitle(string)   YTitle(string)   	TTitle(string)		///
		XOptions(string) YOptions(string)						///
		XSIZe(passthru)  YSIZe(passthru)						///
		BY(string asis)  SAVing(string asis) GRAPHREGION(string)					
		
	syntax [varname(default=none max=1)] [if] [in], [over(varname)] [ `pt_opts' `tw_opts' * ] 		
 	
	** extract all twoway graphing options that are shared by all graph types 
	*  and store them in `tw_op' (declared by _parse)
	local 0 pt_aux_var `0' 									//   
	_parse expand cmd tw : 0 , common(`tw_opts')  
  
	** extract all the remaining (*) options (not included in pt_opts + my_opts + graph_opts) and 
	*  assume that these are all graph-specific options (e.g., lpattern, msymbol, etc.)
	*  TBD: _rc check whether these are actually graph-specific  options
	local gs_op `options' 	
	
	** deal with alternative varname declarations:
	if "`varlist'" != "" & "`plotonly'" == ""  confirm var `over'
	if "`over'"    != "" & "`plotonly'" ==""   confirm var `varlist'
	
	** define the default graph type to be plotted 
	if "`graph'"== "" local graph = "line"
 		 					 
	qui {
		** (1) FRAME INITIALIZATION ********************************************		
		** find out current frame 
		frame pwf
		local frame_orig = r(currentframe)
		
		** define the stem word for frames used by plottab (frame_pt by default)
		if "`frame'" == ""  local frame frame_pt
		
		** create the main output frame, and erase its data if `clear'
		cap frame create `frame'  
		if "`clear'" != "" frame `frame': clear 	
			
		** create a frame that stores the current plot only (`frame'_aux) 
		cap frame create `frame'_aux
		frame `frame'_aux: clear 	
		
		** create a frame that stores customized graphing options (`frame'_cust)
		cap frame create `frame'_cust
		if "`clear'" != "" frame `frame'_cust: clear 
		
		** (2) GATHER PRELIMINARY INFORMATION ********************************** 	
		** if only clearing the already-plotted data, skip everything below
		if "`clear'"!= "" & "`over'" =="" {
			n di as result `"  - clearing data from frame "`frame'""'
			exit
		}
		
		** check whether plotted variable(s) exist (nullifies _rc for the rest)
		if "`plotonly'" == "" cap confirm var `over'
		if "`plotonly'" != "" frame `frame': cap confirm var x_val1
		
		** how many graphs are stored already?
		local i = 0
		while _rc ==0 {
			local i = `i' + 1
			frame `frame': cap confirm var plot_val`i'1
			*n di `i'
		}
		 
		** is the graph new or replacing one that is already stored?
		if `replace' != -1 { 
			frame `frame': cap confirm var plot_val`replace'1
			if _rc !=0 {
			   * may be some branching depending on the value of `rc'
			   n di "{err}Data for graph `i' not found!"
			   exit  
			}
			local i = `replace' 
		}
		
		** (3a) GENERATE PLOTTED DATA *******************************************
		if "`plotonly'" == ""  {	 	
			if "`nodiag'"=="" n di as result `i' " - tabulating values for a new graph" 
 		
			** get the plotted categories (xval) 
			tab `over' `if' `in', matrow(x_val)
			
			** PLOTMEANS works with factorized `over' variable -> check whether it is factorizable		
				** first check whether it consist of integer/whole numbers only
				local intcheck = 1
				cap confirm byte variable `over'
				if _rc != 0 {
					cap confirm int variable `over'
					if _rc != 0 { 					
						cap confirm long variable `over'
						if _rc != 0 { 
							local intcheck = 0						
						}
					}
				}
				** if `over' is string or float, create a temporary grouping variable 
				if `intcheck' == 0{
					if "`nodiag'"=="" n di as text "  - note:" as err " Variable `over' either contains non-integer values or it is not compressed to the optimal storage type (to correct this, run: compress `over'). Non-integer conditioning variables require more computing time."	
					tempvar overtemp
					cap which ftools
					if _rc == 0 {
						fegen `overtemp' = group(`over')
					}
					else { 
						di as err "To optimize speed, install the ftools package [ssc install ftools]" 
						egen `overtemp' = group(`over')		
					}
					local factor_ov overtemp 
				}
				** if `over' contains whole numbers only, check whether its minimum is below zero 
				else{
					mata: st_numscalar("min_xv",min(st_matrix("x_val")))
					** if yes, create a temporary variable containing `over' values shifted to positive integers
					if min_xv < 0 {
						tempvar overtemp
						gen `overtemp' = `over' - min_xv 
						local factor overtemp 
					}
					else{
						local factor_ov over   
					}
				}
				
			** get the plotted means (by OLS with factorzized `over' variable `factor_ov')  
			reg `varlist' ibn.``factor_ov'' `if' `in', nocons 
	 
			
			mat RES = r(table)
			mat plot_val`i' = RES[1,1...]' 		
			
			** multiply the cell values by a constant ?
			if "`times'" != "1"  mat plot_val`i' = plot_val`i' * `times'
 		
			** if replace is toggled, delete the data to be replaced
			if `replace' != -1 { 
				frame `frame': drop plot_val`replace'1
			}
		
			** for the 1st plot after `clear', store the data in frame_pt
			if `i'==1 & `replace' == -1 { 
				frame `frame': svmat x_val 
				frame `frame': svmat plot_val`i'
				
				frame `frame'_cust: gen cust_gra = "" 
				frame `frame'_cust: gen cust_opt = "" 
				frame `frame'_cust: gen cust_two = ""
				frame `frame'_cust: gen cust_oth = ""
				frame `frame'_cust: label variable cust_gra "Graph type corresponding to _n-th plot"
				frame `frame'_cust: label variable cust_opt "Graphing options specific to _n-th plot"
				frame `frame'_cust: label variable cust_two "Global two-way options specified by the user"
				frame `frame'_cust: label variable cust_two "Other two-way options specified by the program "	
			}
			
			** if we're storing some plots already, save an auxiliary file and 
			*  merge the new plot contents to the principal frame using x_val
			*  as the matching variable (this minimizes the memory requirements)
			if `i'>1 | (`i'==1 & `replace' != -1) {
				frame `frame'_aux: svmat x_val 
				frame `frame'_aux: svmat plot_val`i'
				frame `frame'_aux: tempfile aux
				frame `frame'_aux: save `aux', replace
				
				frame `frame': merge 1:1 x_val1 using `aux', nogen
				frame `frame': sort x_val1
				
 
			} 
				
			** PS: specify axis titles  
			if "`ytitle'" == "" {
				local ylbl : variable label `varlist'
				if "`ylbl'" == "" local ylbl `varlist'
				local oth_op `oth_op' ytitle("`ylbl'")
			} 
			if "`xtitle'" == "" {
				local xlbl : variable label `over'
				if "`xlbl'" == "" local xlbl "Grouping variable"
				frame `frame': label var x_val1 "`xlbl'"
			}
				
		}		
		** (3b) DO NOTHING WHEN PLOTTING ALREADY STORED DATA *****************
		else {	 
			if "`nodiag'"=="" n di as result "X - plotting already stored graphs"				
		}
		
		** (4) STOCKTAKING *****************************************************
		** how many graphs are stored eventually?
		local I = 0
		cap
		while _rc ==0 { 
			local I = `I' + 1 
			frame `frame': cap confirm var plot_val`I'1	
		}
		local I = `I'- 1
		
		
		** (5) FURTHER CUSTOMIZATION *******************************************
		** include zero on the y-axis?
		if "`yzero'" != "" {
			** find the ideal step size for the ylabel option 
			local maxval = 0
			forvalues iz = 1/`I' {
				frame `frame': qui sum plot_val`iz'1
				if `maxval' < r(max) local maxval = r(max)			
			}
			local exp = floor(log10(`maxval'/4))
			local ystep	= floor((`maxval'/4)/(10^`exp'))*(10^`exp')
			local ymax = `ystep'*5			
			local tw_op `tw_op' ysc(r(0 `ymax'))
			if "`ylabel'"=="" local tw_op `tw_op' ylabel(0(`ystep')`ymax')  
		}	
		 		
		** save custom graph options for new or replaced graphs
		if "`plotonly'" == "" | `replace' != -1  {	
			if "`global'" == "" local in_i in `i'
			frame `frame'_cust: cap set obs `i' 
			frame `frame'_cust: replace cust_gra = `"`graph'"' `in_i'
			frame `frame'_cust: replace cust_opt = `"`gs_op'"' `in_i'
			frame `frame'_cust: replace cust_two = `"`tw_op'"'  in 1
			frame `frame'_cust: replace cust_oth = `"`oth_op'"' in 1 
			
			** assign descriptive labels to auxiliary plot variables?
			if "`plname'" == "" local plname "Plot `i'"
			frame `frame': label var plot_val`i'1 "`plname'"
		}
		else if "`tw_op'"!="" {
			frame `frame'_cust: replace cust_two = `"`tw_op'"'  in 1
		}
				
		** (6) TWO-WAY COMMAND *******************************************
		** create a twoway command syntax
		local graph_syntax = ""
		forvalues j = 1/`I'{	
			frame `frame'_cust: local graph = cust_gra[`j']
			frame `frame'_cust: local gs_op = cust_opt[`j']
			local graph_syntax `graph_syntax' (`graph' plot_val`j'1 x_val1, `groptions' `gs_op' )
		}
		local graph_syntax twoway `graph_syntax'
		frame `frame'_cust: local tw_op  = cust_two[1]
		frame `frame'_cust: local oth_op = cust_oth[1]

		** information for troubleshooting
		if "`nodiag'"=="" n di as text  						"  - output type:            "  "`output'" 	
		if "`nodiag'"=="" n di as text  						"  - graph type:             "  "`graph'"  	
		if "`nodiag'"=="" & `"`tw_op'"' != "" n di as text      "  - twoway options:         " `"`tw_op'"'	
	    if "`nodiag'"=="" & `"`gs_op'"' != "" n di  as text     "  - graph-specific options: " `"`gs_op'"'	
		if "`command'" != "" n di  as text                      "  - twoway graph command :  " `"frame `frame':  `graph_syntax', `format' `nodraw' `tw_op' "'	
		** run the twoway command (sourced from the frame_pt): 
		frame `frame':  `graph_syntax', `format' `nodraw' `tw_op' `oth_op' 
	}
end
/*
sysuse nlsw88.dta, clear
plotmeans ttl_exp if union == 0, over(age) graph(connect)  clear
plotmeans ttl_exp if union == 1, over(age) graph(connect)  
 
 *TBD confirm over is integer. If not, recode.
gen agex = age-100
plotmeans ttl_exp if union == 1, over(agex) graph(connect) nod
*/