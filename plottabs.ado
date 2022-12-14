*! version 1.0.0  02Aug2022 
capture program drop plottabs
program define plottabs
	version 16
	
	** Plottabs-specific options defined here
	local pt_opts 		clear 				COMmand     		///
		FRame(string) 	GLobal 				GRaph(name)  		///
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
	if "`varlist'" != "" & "`over'" !="" n di as err "varname specified twice, using: `over'" 
	if "`varlist'" != "" & "`over'" =="" local over `varlist' 
	
	** define the default graph type to be plotted 
	if "`graph'" == "" local graph  line
	if "`output'"== "" local output frequency
	if "`frame'" == "" local frame  frame_pt 
 							 
	qui {
		** (1) FRAME INITIALIZATION (SAME FOR ALL PLOT COMMANDS) ***************
		
		** Done by the plotinit routine
		* if `clear': create the frame structure 
		* else: count the number of plots already in the frame structure
		plotinit `varlist', frame(`frame') `clear' `plotonly' replace(`replace')
		
		** the plot count is stored here:
		local i = r(i)
		
		** (3a) GENERATE PLOTTED DATA *******************************************
		if "`plotonly'" == ""  {	 	
			n di as result `i' " - tabulating values for a new graph" 
			
			** PT: tabulate command
			tab `over' `if' , matcell(plot_val`i') matrow(x_val`i')
			
			** PT: adjust the matcell data to conform with the chosen output type 
			local out = substr("`output'",1,3)  
			if "`out'"=="sha" {
				** conditional shares
				mat plot_val`i' =  plot_val`i'/r(N)
				local output Relative Share 
			}
			else if "`out'"=="cum" {
				** cummulative shares
				mat plot_val`i' =  plot_val`i'/r(N)
				local Nr = rowsof(plot_val`i')
				forvalues r = 2 / `Nr' { 	
					mat plot_val`i'[`r',1] = plot_val`i'[`r',1] + plot_val`i'[`r'-1,1]
				}			
				local output Cummulative Share	 
			}
			else { 
				if "`out'"!="fre" {
					n di as err "Unknown output type specified, reverting to frequencies"
				}
				local output Frequency
			} 
			
			** PT: multiply the cell values by a constant ?
			if "`times'" != "1"  mat plot_val`i' = plot_val`i' * `times'
 		
			** if replace is toggled, delete the data to be replaced
			if `replace' != -1 { 
				frame `frame': drop plot_val`replace'1
			}
		
			** for the 1st plot after `clear', store the data in frame_pt			
			frame `frame': svmat x_val`i' 
			frame `frame': svmat plot_val`i'
			
			** if we're storing some plots already, save an auxiliary file and 
			*  merge the new plot contents to the principal frame using x_val
			*  as the matching variable (this minimizes the memory requirements)
			/*
			if `i'>1 | (`i'==1 & `replace' != -1) {
				frame `frame'_aux: svmat x_val 
				frame `frame'_aux: svmat plot_val`i'
				frame `frame'_aux: tempfile aux
				frame `frame'_aux: save `aux', replace
				
				frame `frame': merge 1:1 x_val1 using `aux', nogen
				frame `frame': sort x_val1
				
				** PT: Cummulative shares adjustment (better visuals)
				if "`out'"=="cum" {
					frame `frame': for var plot_val*: replace X = 0 if _n ==1
					frame `frame': for var plot_val*: replace X = 1 if _n == _N
				}
			} 
			*/
			 
			frame `frame': rename x_val`i'1    x_val`i'
			frame `frame': rename plot_val`i'1 y_val`i'
			 
				
		}		
		** (3b) DO NOTHING WHEN PLOTTING ALREADY STORED DATA *****************
		else {	 
			n di as result "X - plotting already stored graphs"				
		}
			
		** (3) FURTHER CUSTOMIZATION (if new plot or replace is triggered)****** 
				
		** save custom graph options for new or replaced graphs
		if "`plotonly'" == "" | `replace' != -1  {	
			
			** assign descriptive labels to auxiliary plot variables?
			 
			if "`xtitle'" == "" {
				local xlbl : variable label `over'
				if "`xlbl'" == "" local xlbl "Grouping variable"
				frame `frame': label var x_val`i' "`xlbl'"
			}
			if "`plname'" == "" local plname "Plot `i'"
			frame `frame': label var y_val`i' "`plname'"
			 
			** save custom graph options for new or replaced graphs	
			if "`global'" == "" local in_i in `i'
			frame `frame'_cust: cap set obs `i' 
			frame `frame'_cust: replace cust_out = `"`output'"' `in_i'
			frame `frame'_cust: replace cust_gra = `"`graph'"'  `in_i'
			frame `frame'_cust: replace cust_opt = `"`gs_op'"'  `in_i'
			frame `frame'_cust: replace cust_two = `"`tw_op'"'   in 1
			frame `frame'_cust: replace cust_oth = `"`oth_op'"'  in 1 
		}
		else if "`tw_op'"!="" {
			frame `frame'_cust: replace cust_two = `"`tw_op'"'  in 1
		}
				
		** (4) TWO-WAY COMMAND *******************************************
		** create a twoway command syntax
		n plottwoway, frame(`frame') `command' `nodiag' `yzero'
		
	}
end
 	
        sysuse auto, clear
        plottabs mpg if foreign == 0, output(cummulative) connect(stairstep) plname(Domestic) clear
        plottabs mpg if foreign == 1, output(cummulative) connect(stairstep) plname(Foreign)
		
		**common support for cummulative graphs can be made by expanding the obs in frame_pt by 2, setting the x_values to min(x_cum) max(y_cum) and y_vals to 0 & 1, respectively.
  
			 