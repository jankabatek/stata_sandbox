{smcl}
{* *! version 1.2.2  15may2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[P] timer" "help timer"}{...}
{viewerjumpto "Syntax" "tictoc##syntax"}{...}
{viewerjumpto "Description" "tictoc##description"}{...} 
{viewerjumpto "Examples" "tictoc##examples"}{...}
{viewerjumpto "Contact" "tictoc##contact"}{...}
{title:Title}

{phang}
{bf:plottabs} {hline 2} Plot conditional frequencies or shares (a visual equivalent of {it:{help tabulate oneway}}) 


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:plott:abs} [{it:{help varname}}] {ifin}
[, options]

{p 8 17 2}where {it:{help varname}} is the conditioning variable. 

{synoptset 20}{...}
{p2col:{it:options}}Description{p_end}
{p2line} 
{p2col:{it:Basic options}}{p_end}
{p2col:{cmdab:ov:er(}{it:{help varname}})}an alternative way to specify the conditioning variable{p_end}
{p2col:{cmdab:out:put(}{it:output_type})}specify the {it:output_type} to be plotted: {cmdab:fre:quency}(default)/{cmdab:sha:re}/{cmdab:cum:mulative}{p_end}
{p2col:{cmdab:gr:aph(}{it:graph_type})}specify the {it:{help twoway}} {it:graph_type}: {bf:line}(default)/{bf:bar}/{bf:connected}/{bf:scatter}/etc.{p_end}

{p2col:{it:Memory/data management}}{p_end}
{p2col:{cmdab:fr:ame(}{it:frame_name})}specify the name of the {it:{help frame}} that stores the plotted data (default is {it:frame_pt}){p_end}
{p2col:{cmdab:cl:ear}}clear all plotted data stored in {it:frame_name}{p_end}
{p2col:{cmdab:rep:lace(}{it:#}{cmd:)}}replace plot # in the {it:frame_name} (when storing/visualizing multiple plots at once){p_end}
{p2col:{cmdab:plot:only}}display the plots already stored in the {it:frame_name}{p_end}

{p2col:{it:Plot customization}}{p_end}
{p2col:{cmdab:com:mand}}print out a {it:{help twoway}} command that reproduces the graph (useful for finer customization){p_end}
{p2col:{cmdab:gl:obal}}apply the same customization options to all plots in the memory{p_end}
{p2col:{cmdab:pln:ame(}{it:plot_name})}name the current plot (useful when visualizing multiple plots at once){p_end}
{p2col:{cmdab:yz:ero}}a shorthand for placing zero on the y-axis{p_end}
INCLUDE help gr_twopt
{p2col:{it:{help connect_options}}}change look of lines or connecting method{p_end}
{p2col:{it:{help scatter##marker_options:marker_options}}}change look of
       markers (color, size, etc.){p_end}
INCLUDE help gr_baropt

{p2col:{it:Other options}}{p_end}
{p2col:{cmdab:nod:raw}}do not display the plotted data (useful when looping/overlaying many plots){p_end}
{p2col:{cmdab:tim:es(}{it:real})}multiply the plotted values by a constant (useful for normalizations){p_end}
{p2line}
{p2colreset}{...}
{p 4 6 2}
{it:{help varname}} needs to be specified (one way or the other) to produce a new plot. It does not need to be specified when displaying plots that are already stored in the memory (using the option {cmdab:plot:only}).


{marker description}{...}
{title:Description}

{pstd}
{bf:plottabs} is a command that visualizes conditional frequencies and shares (i.e., the output of {it:{help tabulate oneway}} commands). 

{pstd}
{bf:plottabs} avoids time-consuming memory operations performed by native graphing commands. By leveraging the data {it:{help frame}} environment, it proves extremely fast in large datasets (up to {bf:300-times faster} than native commands).
 
{pstd}
{bf:plottabs} can be called sequentially. The plotted data is stored in a dedicated data frame (see {it:Memory/data management options}), which allows users to create complex visualizations that combine multiple conditional plots.

{pstd}
In terms of customization, you can select your preferred {it:{help twoway}} {it:graph_type}, and adjust it further using the {it:{help twoway_options}} and other options specific to the given {it:graph_type}. 

{marker examples}{...}
{title:Examples}

    Basic use:

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. plottabs mpg, graph(bar)}{p_end}

    {hline}
    Comparing cummulative shares for two groups:

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. plottabs mpg if foreign == 0, output(cummulative) connect(stairstep) plname(Domestic)}{p_end}
{phang2}{cmd:. plottabs mpg if foreign == 1, output(cummulative) connect(stairstep) plname(Foreign)}{p_end}

    {hline}
    Plot data management

{phang2}* display the two plots from the previous example:{p_end}
{phang2}{cmd:. plottabs, plotonly}{p_end}

{phang2}* replace the second plot by another one:{p_end}
{phang2}{cmd:. plottabs mpg if headroom>3, replace(2)}{p_end}

{phang2}* adjust the customization options of the second plot:{p_end}
{phang2}{cmd:. plottabs, plotonly replace(2) connect(stairstep) plname("Headroom > 3")}{p_end}

{phang2}* do the last two steps with one command:{p_end}
{phang2}{cmd:. plottabs mpg if headroom>3, replace(2) connect(stairstep) plname("Headroom > 3")}{p_end}

{phang2}* clear the plot data from memory and create a new plot:{p_end}
{phang2}{cmd:. plottabs mpg, clear graph(bar)}{p_end}

{phang2}* create another plot in a different data frame:{p_end}
{phang2}{cmd:. plottabs headroom, graph(bar) frame(frame_hr)}{p_end}

{phang2}* display each of the two plots (both are stored in memory):{p_end}
{phang2}{cmd:. plottabs, plotonly}{p_end}
{phang2}{cmd:. plottabs, plotonly frame(frame_hr)}{p_end}

{marker frames}{...}
{title:Frames}

{pstd}
Plotted data are stored in a dedicated frame. The default name of this frame is {it:frame_pt}, but it can also be specified using the option {cmdab:fr:ame(}{it:frame_name}). To work with the plottabs data, switch to the respective frame:

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. plottabs mpg if foreign == 0, output(cummulative) connect(stairstep) plname(Domestic)}{p_end}
{phang2}{cmd:. plottabs mpg if foreign == 1, output(cummulative) connect(stairstep) plname(Foreign)}{p_end}

{phang2}{cmd:. frame change frame_pt}{p_end}
{phang2}{cmd:. browse}{p_end}

{pstd}
The customization options are stored in a separate frame ({it:frame_name}_cust):

{phang2}{cmd:. frame change frame_pt_cust}{p_end}
{phang2}{cmd:. browse}{p_end}

{pstd}
To switch back to the default frame and plot more data:

{phang2}{cmd:. frame change default}{p_end}

{pstd}
Note that, once specified, the custom {it:frame_name} needs to be repeated every time you want to add data to the {it:frame_name}. If no {it:frame_name} is specified, {bf:plottabs} will add the data to the frame {it:frame_pt} instead.

{phang2}{cmd:. plottabs mpg if foreign == 0, frame(frame_pt2) graph(bar)}{p_end}
{phang2}{cmd:. plottabs mpg if foreign == 1, frame(frame_pt2) graph(bar)}{p_end}
{phang2}{cmd:. frame frame_pt2: browse}{p_end}

{marker contact}{...}
{title:Contact}

{phang2}Jan Kabátek, The University of Melbourne{p_end}
{phang2}j.kabatek@unimelb.edu.au{p_end} 
 