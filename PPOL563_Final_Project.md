# The Twitter Variant: Visualizing the Relationship between County Public Health Department Social Media Accounts and COVID-19 in the United States

## Alexander Adams

### PPOL563: Data Visualization for Data Science

#### Final Project


In times of public health crisis, it is essential that officials and science communicators are able to reach as many people as possible to inform them of mitigation and prevention measures, research updates, available resources, and new laws regarding individual or organizational activity. The emergence and spread of SARS-CoV-2 (the virus which causes COVID-19) presents an interesting and novel phenomenon; it is the first global pandemic during the social media age. Prior epidemics this century, like SARS in 2002, H1N1 flu in 2009, and Ebola in 2014, either happened when social media platforms were young and not widely used, or were geographically isolated or limited in spread by pathogen-specific factors. Public health communication in the United States faces an additional hurdle. The leader of one of the two major national political parties (and the immediate former president) actively and vocally opposed many of the suggestions offered by top-level health advisors, leading many in the country to become distrustful of government messaging around the virus. The polarization of discourse at the national level around COVID-19 means that local health officials could potentially function as more effective vectors of information. This is because a local health official could be a valued member of one's community, while national figures are inherently several degrees removed from the day-to-day actions and considerations of the average citizen. 

The aim of this analysis is to investigate if counties whose public health departments have social media accounts on one or both of two major platforms (Facebook and Twitter) have different outcomes with respect to COVID-19 than counties whose health departments do not have social media accounts. After manually entering the data for this data set, I coded each county (or county-equivalent jurisdiction) as either having a Facebook account for its public health department, a Twitter account, both, or neither. I then located and incorporated data on cases, deaths, completed vaccinations, and first doses administered. Those values were then divided by county population to produce proportions. Figure 1 shows the average rates of each metric, broken down by county health department social media presence. Clicking on one of the legend entries will hide the corresponding line on each subplot, and the slider at the bottom can be used to adjust the range of dates to any interval between January 21, 2020 and December 14, 2021.  

<div style="text-align: center;">
  <iframe src="lineplot.html" height="800" width="1200"></iframe>
</div>

(Figure 1. Line plot of COVID-19 outcomes.)

While all four groups of counties appear similar on Figure 1, there are small but notable gaps between them. Counties with no  health department social media presence consistenly have average case and death rates which are higher than those with Facebook or Twitter accounts, and the gap is largest between counties with both Facebook and Twitter pages for their health departmens and counties with neither.