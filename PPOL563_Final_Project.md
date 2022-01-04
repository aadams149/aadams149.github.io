layout: page
title: "PPOL563 Final Project"
permalink: /PPOL563_Final_Project/

# The Twitter Variant: Visualizing the Relationship between County Public Health Department Social Media Accounts and COVID-19 in the United States
## Alexander Adams
### PPOL563: Data Visualization for Data Science
#### Final Project

___
A version of this document hosted on GitHub Pages can be found [here](https://aadams149.github.io/PPOL563_Final_Project).

___

---Executive Summary---

National public health messengers have become politicized during the COVID-19 pandemic, creating a vaccuum for local public health messengers to communicate information about the virus and its spread. Surveys of public trust find that Americans trust their local governments more than they trust the federal government. Many local governments have social media accounts on various platforms, in order to reach wider audiences and more effectively reach their citizens. The visualizations presented here indicate that counties whose public health departments have Facebook or Twitter accounts have, on average, lower rates of COVID-19 cases and deaths and higher rates of COVID-19 vaccination than counties whose public health departments do not have Facebook or Twitter accounts.  

___

In times of public health crisis, it is essential that officials and science communicators are able to reach as many people as possible to inform them of mitigation and prevention measures, research updates, available resources, and new laws regarding individual or organizational activity. The emergence and spread of SARS-CoV-2 (the virus which causes COVID-19) presents an interesting and novel phenomenon; it is the first global pandemic during the social media age. Prior epidemics this century, like SARS in 2002, H1N1 flu in 2009, and Ebola in 2014, either happened when social media platforms were young and not widely used, or were geographically isolated or limited in spread by pathogen-specific factors. Public health communication in the United States faces an additional hurdle. The leader of one of the two major national political parties (and the immediate former president) actively and vocally opposed many of the suggestions offered by top-level health advisors, leading many in the country to become distrustful of government messaging around the virus. The polarization of discourse at the national level around COVID-19 means that local health officials could potentially function as more effective vectors of information. This is because a local health official could be a valued member of one's community, while national figures are inherently several degrees removed from the day-to-day actions and considerations of the average citizen. Recent surveys have found a 20-point gap between self-reported trust of local government and trust in the federal government (Kettl, 2020). Other studies of the efficacy of social media messaging around public health find that recipients trust messaging from organizations more than messaging from individuals (Freberg, 2012). Local public health departments exist at the confluence of these two factors, and so are uniquely positioned to potentially influence public health outcomes. 

The aim of this analysis is to investigate if counties whose public health departments have social media accounts on one or both of two major platforms (Facebook and Twitter) have different outcomes with respect to COVID-19 than counties whose health departments do not have social media accounts. After manually entering the data for this data set, I coded each county (or county-equivalent jurisdiction)[^1] as either having a Facebook account for its public health department, a Twitter account, both, or neither. I then located and incorporated data on cases, deaths, completed vaccinations, and first doses administered. Those values were then divided by county population to produce proportions. Figure 1 shows the average rates of each metric, broken down by county health department social media presence. 

[^1]: There are four other types of local jurisdictions which are equivalent to counties. Two of them are essentially state-specific alternate names for counties: Louisiana calls its "counties" <i>parishes</i>, while Alaska calls <i>its</i> "counties" boroughs (and in some cases, census areas). The District of Columbia is also, in geographic terms at least, functionally a state with one county whose borders are the same as the state. Finally, there are incorporated cities, which are assigned their own FIPS code and are governed at the same level as counties. Baltimore is one such city, as is Los Angeles. Virginia, for some reason, has a large number of such cities.

Of the 3,143 counties in the United States, 800 have both Facebook and Twitter accounts for their health departments. 1,375 have Facebook pages but not Twitter accounts, 136 have Twitter accounts but not Facebook pages, and 908 have neither. These are the groups represented in Figure 1 below.

Clicking on one of the legend entries will hide the corresponding line on each subplot, and the slider at the bottom can be used to adjust the range of dates to any interval between January 21, 2020 and December 14, 2021.  

<p align="center">
  <iframe src="lineplot.html" height="800" width="800"></iframe>
</p>


While all four groups of counties appear similar on Figure 1, there are small but notable gaps between them. Counties with no  health department social media presence consistently have average case and death rates which are higher than those with Facebook or Twitter accounts, and the gap is largest between counties with both Facebook and Twitter pages for their health departments and counties with neither. 

However, some counties whose health departments lack social media presences are represented online in other ways. In many parts of the country, particularly in rural states such as Idaho, Nebraska, and Kentucky, groups of adjacent counties are organized into multi-county public health districts, and these multi-county districts often have social media accounts. For the purposes of this project, counties in these organized districts are coded as having health department social media accounts, and are included in the relevant groups. The map below shows which counties and districts have which social media accounts. As part of the data collection process, I used the `twint` module for Python to scrape tweets from health department twitter accounts. Some accounts were unable to be scraped or had no available tweets, but I was able to retrieve a large number of tweets. For many of the counties and districts which have twitter accounts, clicking on them will produce a pop-up which includes a link to that account's most recent tweet.

Counties which are part of multi-county health districts have been consolidated into those districts. The icon in the top-left corner can be used to select and de-select different layers of the map. For the best viewing experience, select one layer at a time. To see which counties are contained within a multi-county district, select the "Health District Social Media" layer and click on the district.

<p align="center">
  <iframe src="counties_map.html" height="800" width="800"></iframe>
</p>

(Figure 2. Choropleth map of COVID-19 metrics across U.S. counties and multi-county health districts.)
 

<p align="center">
  <iframe src="district_map.html" height="800" width="800"></iframe>
</p>

(Figure 3. Map of health of health department social media across U.S. counties and multi-county health districts.)

___

County health departments having social media accounts may have had a small impact on the COVID-19 health outcomes in those counties, but there could be other factors responsible for differential outcomes as well. Arguably the most significant factor in predicting COVID-19 outcomes across the United States is partisanship. Democrats and Republicans have responded to the pandemic in different ways, and even the best public health messaging from trusted local officials may be unable to counteract strongly-signaled partisan stances (Gollwitzer et al., 2020, Morris, 2021). It is also possible that counties whose public health departments have social media accounts are simply wealthier or better-resourced than their counterparts, and the presence of a social media account is merely capturing part of the effect of having a more robust and active local health department (and since local governments are funded by taxes, and Democrats are more likely to support tax increases or generally higher tax rates than Republicans, this too could be a mediator for partisanship). When I set out to begin this project, I expected to find that counties with large populations would be more likely than smaller counties to have social media accounts, but this is largely not the case. Indeed, one of the biggest trends I observed in the course of making the map above is that there is no immediately obvious trend. With respect to social media presences, many major, highly populated counties have health department social media, like Maricopa County, Arizona (Phoenix), Harris County, Texas (Houston), and King County, Washington (Seattle). Others, like Clark County, Nevada (Las Vegas), Bernalillo County, New Mexico (Albuquerque), and Gwinnett County, Georgia (suburb of Atlanta), have neither a Facebook account or a Twitter profile. Additionally, 475 counties (many of which are rural) are in multi-county districts, like Cherry County, Nebraska, which is part of Nebraska's North Central Health District and has a population density of less than 1 person per square mile. 

Even if a local health department's capacity to influence the public health of its community through widely used social media platforms is minimal, having and operating those accounts should still be considered best practice for government communication. As the nature of media communications evolves and larger shares of the population receive their news primarily or exclusively through social media channels, the presence and operation of these accounts can serve as a bulwark against misinformation surrounding disease outbreaks, especially in times of crisis or uncertainty. 

The table below displays data for all 3,143 counties and county-equivalent jurisdictions in the United States. The column "Tweets During COVID-19" displays the number of tweets a twitter account has posted since the World Health Organization declared COVID-19 a pandemic on March 10, 2020.

<p align="center">
  <iframe src="data_table.html" height="800" width="800"></iframe>
</p>

___

All data elements in this piece were made in R. The line plot was made using `Plotly` for R, the choropleth map was made using the `tmap` package, and the data table was made using the `DT` package. The data used to make these elements can be found at
<a>'https://github.com/aadams149/aadams149.github.io/tree/PPOL563-Final-Project'</a>, and the file `visualization_sandbox.R` in that repository contains all the code necessary to replicate these visualizations.

___

The data used to produce this project came from the following sources:

-Data on COVID-19 cases and deaths: [https://github.com/nytimes/covid-19-data](https://github.com/nytimes/covid-19-data)

-Data on COVID-19 vaccination rates and first doses administered:
[https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-County/8xkx-amqh](https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-County/8xkx-amqh)

-Data on county public health department social media: Collected by Alexander Adams

-U.S. counties shapefile: U.S. Census Bureau, accessed through `tigris` package for R, modified by Alexander Adams

___


Citations:

Freberg, K. (2012). Intention to comply with crisis messages communicated via social media. Public Relations Review, 38(3), 416-421.

Gollwitzer, A., Martel, C., Brady, W. J., Parnamets, P., Freedman, I. G., Knowles, E. D., & Van Bavel, J. J. (2020). Partisan differences in physical distancing are linked to health outcomes during the COVID-19 pandemic. Nature human behaviour, 4(11), 1186-1197.

Kettl, D.F. (2020), States Divided: The Implications of American Federalism for COVID-19. Public Admin Rev, 80: 595-602. https://doi.org/10.1111/puar.13243

Morris, D. S. (2021). Polarization, partisanship, and pandemic: The relationship between county-level support for Donald Trump and the spread of Covid-19 during the spring and summer of 2020. Social Science Quarterly, 102(5), 2412-2431.

___
