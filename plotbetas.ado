*! version 1.0.0  02Aug2022 
capture program drop plotbetas 
program define plotbetas
	version 16
	
	** Plotb-specific options defined here
	local pt_opts 		CI(real 95)       clear 				COMmand     	///
		FRame(string) 	GLobal 				GRaph(name)  		///
		PLOTonly   		PLName(string) 		REPlace(integer -1) ///
		NOCI            NODIAG 				OUTput(string) 		RGRaph(name)        ///
		TIMes(real 1)  		///
		XSHift(real 0)  YSHift(real 0)      YZero
	
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
				 
		local p1      navy
		local p2      maroon
		local p3      forest_green
		local p4      dkorange
		local p5      teal
		local p6      cranberry
		local p7      lavender
		local p8      khaki
		local p9      sienna
		local p10     emidblue
		local p11     emerald
		local p12     brown
		local p13     erose
		local p14     gold
		local p15     bluishgray
		
	syntax [varlist(fv)] [if] [in], [ `pt_opts' `tw_opts' * ] 		
 	
	** extract all twoway graphing options that are shared by all graph types 
	*  and store them in `tw_op' (declared by _parse)
	local 0 pt_aux_var `0' 	 				   
	 
	_parse expand cmd tw : 0 , common(`tw_opts')  
  
	** extract all the remaining (*) options (not included in pt_opts + my_opts + graph_opts) and 
	*  assume that these are all graph-specific options (e.g., lpattern, msymbol, etc.)
	*  TBD: _rc check whether these are actually graph-specific  options
	local gs_op `options' 	
	 	
	** check if `varlist' is a factorized variable, or a list of non-factorized variables
	if "`plotonly'" == "" {
		cap _fv_check_depvar `varlist'
		if _rc != 0 {
		    local factor = 1
		    fvexpand `varlist'
			local varlist = r(varlist)
		}		
		else{
			local factor = 0
		}
	} 
 
	** define defaults: 
	if "`graph'"== "" local graph = "line"
	if "`rgraph'"== "" local rgraph = "rarea"
	if "`frame'" == ""  local frame frame_pt
 							 
	qui {
		** (1) FRAME INITIALIZATION (SAME FOR ALL PLOT COMMANDS) ***************
		
		** Done by the plotinit routine
		* if `clear': create the frame structure 
		* else: count the number of plots already in the frame structure
		plotinit `varlist', frame(`frame') `clear' `plotonly' replace(`replace')
		
		** the plot count is stored here:
		local i = r(i)
		
		** (2a) GENERATE PLOTTED DATA *******************************************
		
		if "`plotonly'" == ""  {	 	
			n di as result `i' " - tabulating values for a new graph" 
 		
			** PB: min max and number of columns
			if "`constraint'" =="" { 
				qui sum `varlist'
				local min = r(min)
				local max = r(max)
			}
			else {
				tokenize "`constraint'"
				local min = `1'
				local max = `2'
			}
			local cols = 4
			if "`noci'" !="" {
				local cols  = 2 
			}
			
			** PB: define matrix of results
			mat PL = J(1,`cols',.)
			 
			** PB: populate the matrix of results
			local ii = 0
			qui foreach var in `varlist' {   
				if `factor'==1 {
					** determine the value of the factorized variable:
					local pos = strpos("`var'","i") + 1
					local length = strpos("`var'",".") - `pos'
					*n di "`pos'" " " "`length'" " " "`var'"
					local ii =  real(substr("`var'",`pos',`length'))
					*n di "`ii'"  
					** deal with ibn's
					if `ii'==. {
						local pos_suffix = `pos' + `length' - 2
						if substr("`var'",`pos_suffix',2) == "bn" local ii =  real(substr("`var'",`pos',`length'-2))
					}
					
				}
				else{
					** or just start from 1 (for non-factorized variables):
				    local ii = `ii' + 1
				}					
				cap qui di _b[`var']
				if _rc ==0 { 
					if "`noci'" =="" {
						** get degrees of freedom & inverse t-stat for confidence level `ci'
						local df = e(df_r)
						local invt = invt(`df',0.`ci')
						** derive the CI for the given coefficient
						local LC = _b[`var'] - `invt'*_se[`var']
						local UC = _b[`var'] + `invt'*_se[`var']
						mat PL = [PL \ `ii' , _b[`var'], `LC', `UC' ]
					}
					else { 
						mat PL = [PL \ `ii' , _b[`var']]
					}
				} 
			}  
			
			** PB: if replace is toggled, delete the data to be replaced
			if `replace' != -1 { 
				frame `frame': drop plot_val`replace'*
			}
			
			**PB: turn the matrix into variables
			frame `frame': svmat PL, names(plot_val`i')
			
			**PB: optionally, adjust the plot variables
			qui{
				if "`xshift'"   !=""  frame `frame':  replace plot_val`i'1 = plot_val`i'1 + `xshift'
				if "`dropzero'" !=""  frame `frame':  for var plot_val`i'*: replace X = . if X ==0	 
				if "`times'" 	!="1" frame `frame':  for var plot_val`i'*:  replace X = X * `times'
				if "`yshift'"   !=""  frame `frame':  for var plot_val`i'*:  replace X = X + `yshift'			 
			}
			
			** PB: rename the plot variables
			frame `frame': rename plot_val`i'1 x_val`i'
			frame `frame': rename plot_val`i'2 y_val`i'
			if "`noci'" ==""{
				frame `frame': rename plot_val`i'3 LCI_val`i'
				frame `frame': rename plot_val`i'4 UCI_val`i'
			}
							 	
		}		
		** (2b) SKIP DATA GENERATION WHEN PLOTTING ALREADY STORED DATA *********
		else {	 
			n di as result "X - plotting already stored graphs"				
		}
		 
		** (3) FURTHER CUSTOMIZATION (if new plot or replace is triggered)******
		** labels, legends and saving
		if "`plotonly'" == "" | `replace' != -1  {		
		
			** assign descriptive labels to auxiliary plot variables?
			if "`plname'" != "" local plname `plname',
			if "`plname'" == "" local plname " "
			frame `frame': label var x_val`i' "`plname' Regressors"
			frame `frame': label var y_val`i' "`plname' Estimates"
			frame `frame': cap label var LCI_val`i' "`plname' `ci'% CI, LB"
			frame `frame': cap label var UCI_val`i' "`plname' `ci'% CI, UB"
			
			local output "Coefficient Estimates"
			
			** default legend for CIs
			_parse expand cmd leg : 0 , common(legend())
			if `"`leg_op'"'== "" & "`noci'" =="" {	
				local ci_op  "`plname' `ci'% Confidence Interval"
			}
			if `"`leg_op'"'!= "" {
				local gs_op `gs_op' `leg_op'
			}
				 				
			** save custom graph options for new or replaced graphs	
			if "`global'" == "" local in_i in `i'
			frame `frame'_cust: cap set obs `i' 
			frame `frame'_cust: replace cust_out = `"`output'"' `in_i'
			frame `frame'_cust: replace cust_gra = `"`graph'"'  `in_i'
			frame `frame'_cust: replace cust_opt = `"`gs_op'"'  `in_i' 
			frame `frame'_cust: replace cust_two = `"`tw_op'"'   in 1
			frame `frame'_cust: replace cust_oth = `"`oth_op'"'  in 1 
			if "`noci'" ==""{			
				frame `frame'_cust: replace cust_rgr = `"`rgraph'"' `in_i' 
				frame `frame'_cust: replace cust_oci = `"`ci_op'"'  `in_i'
			}
		}
		else if "`tw_op'"!="" {
			frame `frame'_cust: replace cust_two = `"`tw_op'"'  in 1
		}
				 
		** (4) TWO-WAY COMMAND *******************************************
		** create a twoway command syntax  
		n plottwoway, frame(`frame') `command' `nodiag' `yzero'
	}
end

sysuse nlsw88.dta, clear
reg   ttl_exp age race, nocons
plotb age race, graph(connect)  clear command  

reg   ttl_exp ibn.age race, nocons  
plotb ibn.age, gr(scatter) rgr(rcap)  clear command 
plotb ibn.age,    clear  command  plname(Full) 

reg   ttl_exp ibn.age race if _n < 300 , nocons
plotb ibn.age , plname(Mini) command  lcolor(orange)   
 
 
 *TBD confirm varlist is integer. If not, recode.
 
 * if not factor, assign labels
 
 ** what to do with x-axis?
 */