
capture program drop plottwoway 
program define plottwoway, rclass
version 16 
syntax, FRame(string) [COMmand NODIAG YZero] 
	qui {
		** default colour palette
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
		local graph_syntax = ""
		local gr_counter = 0 
		
		** (1) STOCKTAKING *****************************************************
		** how many plots are stored eventually?
		local I = 0
		cap
		while _rc ==0 { 
			local I = `I' + 1 
			frame `frame': cap confirm var x_val`I'	
		}
		local I = `I'- 1
		
		
		** (2) CUSTOMIZATION *******************************************
		** global two-way options:
		frame `frame'_cust: local tw_op  = cust_two[1]
		frame `frame'_cust: local oth_op = cust_oth[1]
		
		** white background unless specified otherwise
		local 0 plotaux , `tw_op' 
		if `"`tw_op'"' != "" _parse expand cmd bg : 0 , common(graphregion())  
		if  "`bg_op'"  == "" local tw_op `tw_op' graphregion(fcolor(white) lcolor(white))
 
		** include zero on the y-axis (add to the global two-way options)
		if "`yzero'" != "" {
			** find the ideal step size for the ylabel option 
			local maxval = 0
			forvalues i = 1/`I' {
				frame `frame': qui sum x_val`i'
				if `maxval' < r(max) local maxval = r(max)			
			}
			local exp = floor(log10(`maxval'/4))
			local ystep	= floor((`maxval'/4)/(10^`exp'))*(10^`exp')
			local ymax = `ystep'*5			
			local tw_op `tw_op' ysc(r(0 `ymax'))
			if "`ylabel'"=="" local tw_op `tw_op' ylabel(0(`ystep')`ymax')  
		}	
		 
		** produce the two-way graph from data stored in `frame', using the customization options stored in `frame'_cust
		forvalues j = 1/`I'{	
			local gr_counter = `gr_counter' + 1
			
			** options applicable to all plot types:
			frame `frame'_cust: local output = cust_out[`j']
			frame `frame'_cust: local graph  = cust_gra[`j']
			frame `frame'_cust: local gs_op  = cust_opt[`j']
  
			
			** are we using default colors or user-defined?
			local 0 plotaux , `gs_op'
			if `"`gs_op'"' != "" _parse expand cmd col : 0 , common(LCoLor(string)) 
			if  "`col_op'" != "" { 
				tokenize `col_op', parse("()")
				local defcol `3'
			} 
			else{
				local defcol `p`j''
			}
 
			** append graph syntax to the twoway command	
			local graph_syntax `graph_syntax' (`graph' y_val`j' x_val`j', lcolor(`defcol') mcolor(`defcol') `gs_op')
			
			** CI options applicable to plotmeans & plotbetas:
			frame `frame'_cust: cap local rgraph= cust_rgr[`j']
			frame `frame'_cust: cap local ci_op = cust_oci[`j'] 
			
			** CI plotted if rgraph `j' is defined in `frame'_cust
			if "`rgraph'" !="" {
				local gr_counter = `gr_counter' + 1
				** transparency of ci area graphs
				if "`rgraph'" == "rarea" local r_op fcolor(`defcol'%15) lwidth(none)
				** legends for ci area graphs
				if "`ci_op'"  != "" 	 local r_op `r_op' legend(label(`gr_counter' "`ci_op'"))
				local graph_syntax `graph_syntax' (`rgraph' LCI_val`j' UCI_val`j' x_val`j' , `r_op' lcolor(`defcol'))
			}
		}  
		
		** default title of the y-axis (`output' type corresponding to the last plot)
		local 0  plotaux , `tw_op' 
		if `"`tw_op'"' != "" _parse expand cmd yt : 0 , common(YTitle(string)) 
		if `"`yt_op'"' == "" local tw_op `tw_op' ytitle(`output')

		** information for troubleshooting
		if "`nodiag'"=="" n di as text  						"  - output type:            "  "`output'" 	
		if "`nodiag'"=="" n di as text  						"  - graph type:             "  "`graph'"  	
		if "`nodiag'"=="" & `"`tw_op'"' != "" n di as text   	"  - twoway options:         " `"`tw_op'"'	
	    if "`nodiag'"=="" & `"`gs_op'"' != "" n di as text  	"  - graph-specific options: " `"`gs_op'"'	
		if "`command'" != "" n di  as text  "  - twoway graph command:   " as res `"frame `frame': twoway `graph_syntax', `nodraw' `tw_op' `oth_op'"'	
		** run the twoway command (sourced from the frame_pt): 
		frame `frame':  twoway `graph_syntax', `nodraw' `tw_op' `oth_op'  
		if "`command'" != "" return local cmd  frame `frame':  `graph_syntax', `nodraw' `tw_op' `oth_op'
	}		
end		


** COULD BE EXPANDED TO RECOGNIZE PLOTS WITH MULTIPLE OUTPUT TYPES AND SET THE DOUBLE AXES ACCORDINGLY