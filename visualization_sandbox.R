#Load required libraries
library(DT)
library(plotly)
library(rmapshaper)
library(sf)
library(tmap)
library(tidyverse)
library(vroom)

#Load COVID data from NYTimes
covid <-
  vroom(
    'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv'
  ) 

#Load shapefile I made for other project
shapefile <-
  st_read('counties_with_mc_districts.shp')

#Load social media data
counties <-
  read_csv('counties_with_tweets.csv') %>% 
  mutate(fips =
           as.character(fips)) %>%
  mutate(
    fips =
      str_pad(fips,
              5,
              pad = '0'),
    #Create a column with county names and state abbreviations together
    #(This is just for aesthetic benefit later.)
    place =
      paste0(name, ", ", state_full),
    #Create a column recording the presence of a facebook and/or twitter
    #(I ran into some issues trying to get tmap/leaflet to play nice
    #with multiple polygon sets, so this ended up being an adequate 
    #alternative solution)
    socmed = case_when(
      facebookYN == 1 & twitterYN == 1 ~ "Both Facebook and Twitter",
      facebookYN == 0 &
        twitterYN == 0 ~ "No Facebook or Twitter",
      facebookYN == 1 &
        twitterYN == 0 ~ "Facebook but no Twitter",
      facebookYN == 0 &
        twitterYN == 1 ~ "Twitter but no Facebook"
    )
  ) %>%
  rename(tweet_date = date)

#Load population data
population_counties <-
  vroom('co-est2020.csv') %>%
  #Exclude state total populations
  filter(COUNTY != '000') %>%
  #Rename population for convenience
  rename('population' = POPESTIMATE2020) %>%
  #Create a fips column for easy merging
  mutate('fips' = paste0(STATE,COUNTY)) %>%
  select(fips, STNAME, population)

#Load vaccination data
vax_data <-
  vroom('vax_data.csv') %>%
  select(date = date,
         fips = fips,
         Series_Complete_Yes,
         Administered_Dose1_Recip) %>%
  mutate(date = 
           lubridate::mdy(as.character(date)))

#Subset to county names
county_names <-
  counties %>%
  select(fips, 
         name,
         district)


# main covid data -----------------------------------------------------
#Merge data together
covid_all <-
  covid %>%
  left_join(
    vax_data,
    by = c('fips',
           'date')
  ) %>%
  left_join(
    county_names,
    by = 'fips'
  ) %>%
  left_join(
    population_counties,
    by = c('fips',
           'state' = 'STNAME')
  ) %>%
  drop_na(fips,
          name)
#Replace NAs with so plot doesn't have missing values
covid_all[c('deaths',
            'Series_Complete_Yes',
            'Administered_Dose1_Recip')][is.na(covid_all[c('deaths',
                                                           'Series_Complete_Yes',
                                                           'Administered_Dose1_Recip')])] <- 0
#Select social media variables
socmed <-
  counties %>%
  select(
    fips,
    twitter,
    twitterYN,
    facebookYN,
    socmed
  )
#Merge social media+covid stuff
covid_all <-
  covid_all %>%
  left_join(
    socmed,
    by = 'fips'
  )

#Adjust various metrics to be proportions of population
covid_all <-
  covid_all %>%
  mutate(
    cases_adjusted = 
      cases/population,
    deaths_adjusted = 
      deaths/population,
    comp_vax_adjusted = 
      Series_Complete_Yes/population,
    first_dose_adjusted = 
      Administered_Dose1_Recip/population
  )

# data for plotly -----------------------------------------------------

#Find average values for each group of social media
#(e.g. twitter only, facebook only, etc)
covid_mean_data = data.frame()
for (ii in unique(covid_all$date)){
  date_subset <-
    covid_all %>%
    filter(date == ii)
  date_row = data.frame()
  for(jj in unique(date_subset$socmed)){
    socmed_subset <-
      date_subset %>%
      filter(socmed == jj)
    
    newrow <-
      data.frame(
        date = unique(socmed_subset$date)[1],
        socmed = jj,
        mean_cases = mean(socmed_subset$cases, na.rm = TRUE),
        mean_deaths = mean(socmed_subset$deaths, na.rm = TRUE),
        mean_vaxxed = mean(socmed_subset$Series_Complete_Yes, na.rm = TRUE),
        mean_dose1 = mean(socmed_subset$Administered_Dose1_Recip, na.rm = TRUE),
        mean_cases_adj = mean(socmed_subset$cases_adjusted, na.rm = TRUE),
        mean_deaths_adj = mean(socmed_subset$deaths_adjusted, na.rm = TRUE),
        mean_compvax_adj = mean(socmed_subset$comp_vax_adjusted, na.rm = TRUE),
        mean_dose1_adj = mean(socmed_subset$first_dose_adjusted, na.rm = TRUE)
      )
    date_row = rbind.data.frame(date_row,
                                newrow)
    
  }
  covid_mean_data = rbind.data.frame(covid_mean_data,
                                     date_row)
}

#Replace missing values w/ 0 for plot
covid_mean_data[is.na(covid_mean_data)] <- 0

#WRITE TO CSV SO YOU DON'T HAVE TO DO THIS AGAIN
#write_csv(covid_mean_data, 'covid_mean_data.csv')


# Data Table ----------------------------------------------------------

#County-level summary table
counties1 <-
  counties %>%
  left_join(
    population_counties,
    by = c('fips',
           'state_full' = 'STNAME')
  ) %>%
  select(
    'County' = name,
    'State' = state_full,
    'District' = district,
    'Population' = population.y,
    'Facebook?' = facebookYN,
    'Twitter?' = twitterYN,
    'Twitter Account' = twitter,
    'Tweets During COVID-19' = tweets_COVID
  ) %>%
  mutate(
    `Facebook?` = 
      case_when(`Facebook?` == 1 ~ 'Yes',
                `Facebook?` == 0 ~ 'No'),
    `Twitter?` = 
      case_when(`Twitter?` == 1 ~ 'Yes',
                `Twitter?` == 0 ~ 'No'),
    Population = 
      as.character(Population),
    `Tweets During COVID-19` = 
      as.character(`Tweets During COVID-19`)
  )

#Fill in missing values with NA character string
counties1[is.na(counties1)] <- 'NA'

#Generate table
output_table <-
  DT::datatable(counties1)

#Output table
#htmlwidgets::saveWidget(output_table, 'data_table.html')

# plotly line graph ---------------------------------------------------

#Read in covid_mean_data if earlier code was not run
# covid_mean_data <-
#   vroom('covid_mean_data.csv')

#Create subplot of cases
fig1 <- covid_mean_data
fig1 <- fig1 %>% plot_ly(
  type = 'scatter',
  mode = 'lines',
  x = ~date, 
  y = ~mean_cases_adj, 
  color = ~socmed, 
  legendgroup = ~socmed
) %>%
  layout(
    yaxis = list(title = 'Avg. Case Rate')
  )
#Create subplot of deaths
fig2 <- covid_mean_data
fig2 <- fig2 %>% plot_ly(
  type = 'scatter',
  mode = 'lines',
  x = ~date, 
  y = ~mean_deaths_adj, 
  color = ~socmed, 
  legendgroup = ~socmed,
  showlegend = F
) %>%
  layout(
    yaxis = list(title = 'Avg. Death Rate')
  )
#Create subplot of full vaccinations
fig3 <- covid_mean_data
fig3 <- fig3 %>% plot_ly(
  type = 'scatter',
  mode = 'lines',
  x = ~date, 
  y = ~mean_compvax_adj, 
  color = ~socmed, 
  legendgroup = ~socmed,
  showlegend = F
) %>%
  layout(
    yaxis = list(title = 'Avg. Vaccination Rate')
  )
#Create subplot of 1st doses
fig4 <- covid_mean_data
fig4 <- fig4 %>% plot_ly(
  type = 'scatter',
  mode = 'lines',
  x = ~date, 
  y = ~mean_dose1_adj, 
  color = ~socmed, 
  legendgroup = ~socmed,
  showlegend = F
) %>%
  layout(
    yaxis = list(title = 'Avg. 1st Dose Rate')
  )

#Combine subplots into big plot
bigfig <-
  subplot(
    fig1,
    fig2,
    fig3,
    fig4,
    shareX = TRUE,
    nrows = 4,
    titleY = TRUE
  ) %>%
  layout(
    title = 'COVID-19 and Social Media',
    xaxis = list(
      title = 'Date',
      rangeselector = list(
        buttons = list(
          list(
            count = 3,
            label = "3 mo",
            step = "month",
            stepmode = "backward"),
          list(
            count = 6,
            label = "6 mo",
            step = "month",
            stepmode = "backward"),
          list(
            count = 1,
            label = "1 yr",
            step = "year",
            stepmode = "backward"),
          list(
            count = 1,
            label = "YTD",
            step = "year",
            stepmode = "todate"),
          list(step = "all"))),
      #Add slider
      rangeslider = list(type = "date",
                         label = 'Date')))

#Save as html object
htmlwidgets::saveWidget(as_widget(bigfig), "lineplot.html")

# tmap ----------------------------------------------------------------
#Map will be cumulative, so I only need the data for the most recent date
covid_today <-
  covid_all %>%
  filter(date == max(date))

#Find mean values for health districts
district_data = data.frame()
for(ii in unique(covid_today$district)){
  if(!is.na(ii)){
    df_subset <-
      covid_today %>%
      filter(district == ii)
  
    newrow <-
      data.frame(
        date = unique(covid_today$date)[1],
        county = ii,
        state = unique(df_subset$state)[1],
        fips = shapefile[shapefile$distrct == ii,]$GEOID,
        cases = sum(df_subset$cases),
        deaths = sum(df_subset$deaths),
        Series_Complete_Yes = sum(df_subset$Series_Complete_Yes),
        Administered_Dose1_Recip = sum(df_subset$Administered_Dose1_Recip),
        population = sum(df_subset$population),
        twitter = unique(df_subset$twitter)[1],
        twitterYN = mean(df_subset$twitterYN),
        facebookYN = mean(df_subset$facebookYN),
        cases_adjusted = sum(df_subset$cases)/sum(df_subset$population),
        deaths_adjusted = sum(df_subset$deaths)/sum(df_subset$population),
        comp_vax_adjusted = sum(df_subset$Series_Complete_Yes)/sum(df_subset$population),
        first_dose_adjusted = sum(df_subset$Administered_Dose1_Recip)/sum(df_subset$population),
        name = ii,
        district = ii
      )
    district_data = rbind.data.frame(district_data,
                                     newrow)
  }
}

#Run this to drop unneeded rows
#CHECK: district_data1 should have 87 rows in it after this is run
district_data1 = district_data %>%
  distinct() %>%
  filter(fips > 99000) %>%
  mutate(
    facebookYN = 
      round(facebookYN),
    twitterYN = 
      round(twitterYN)
  ) %>%
  mutate(
    socmed = case_when(
      facebookYN == 1 & twitterYN == 1 ~ "Both Facebook and Twitter",
      facebookYN == 0 &
        twitterYN == 0 ~ "No Facebook or Twitter",
      facebookYN == 1 &
        twitterYN == 0 ~ "Facebook but no Twitter",
      facebookYN == 0 &
        twitterYN == 1 ~ "Twitter but no Facebook"
    )
  )

#bind counties to multicounty districts
covid_today_full = rbind.data.frame(covid_today,
                                      district_data1)

#extract tweet columns
tweets <-
  counties %>%
  select(
    fips,
    county = name,
    tweet_date,
    twitter,
    tweet,
    link
  ) %>%
  #Create html string for html escape in map
  mutate(`Most Recent Tweet` =
              case_when(!is.na(tweet) ~ paste0("<a href = ", link,"/>",county," (",tweet_date,")","</a>"),
                         is.na(tweet) ~ 'No Available Tweets'))

#Set tmap mode to view (did I do this earlier? doesn't matter, it's here)
tmap_mode('view')

#Simplify shapefile so memory is workable
shapefile_small <-
  rmapshaper::ms_simplify(shapefile, keep_shapes = TRUE)

#Make shapefile subset of just districts+counties not in districts
shapefile_districts <-
  shapefile_small %>%
  filter(in_dstr != 1) %>%
  left_join(covid_today_full,
            by = c('GEOID' = 'fips',
                   'distrct' = 'district')) %>%
  left_join(tweets,
            by = c('GEOID' = 'fips')) %>%
  mutate(name_1 = 
           case_when(is.na(name_1) ~ name,
                     !is.na(name_1) ~ name_1),
         #Cap proportions bc some counties are weird (Chattahoochee, GA)
         comp_vax_adjusted =
           case_when(comp_vax_adjusted >= 1 ~ 1,
                     comp_vax_adjusted < 1 ~ comp_vax_adjusted),
         first_dose_adjusted = 
           case_when(first_dose_adjusted >= 1 ~ 1,
                     first_dose_adjusted < 1 ~ comp_vax_adjusted)
         )

#Same as before but just counties, not districts
shapefile_counties <-
  shapefile_small %>%
  filter(is_dstr != 1) %>%
  left_join(covid_today_full,
            by = c('GEOID' = 'fips',
                   'STNAME' = 'state',
                   'distrct' = 'district')) %>%
  left_join(tweets,
            by = c('GEOID' = 'fips')) %>%
  mutate(
         comp_vax_adjusted =
           case_when(comp_vax_adjusted >= 1 ~ 1,
                     comp_vax_adjusted < 1 ~ comp_vax_adjusted),
         first_dose_adjusted = 
           case_when(first_dose_adjusted >= 1 ~ 1,
                     first_dose_adjusted < 1 ~ comp_vax_adjusted))

#Remove some large and now unneeded objects
rm(district_data)
rm(covid)
rm(covid_all)
rm(vax_data)

# map of counties -----------------------------------------------------
#(Maybe not include)

#Create district-level map of 4 different COVID indicators
map1 <-
  tm_shape(shapefile_districts) +
  tm_polygons(
    col = 'cases_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name_1',
                   'Cases, Adjusted for Population: ' = 'cases_adjusted'),
    title = 'Cases, adjusted for population',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Case Rates by District',
    palette = '-magma'
  ) +
  tm_shape(shapefile_districts) +
  tm_polygons(
    col = 'deaths_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name_1',
                   'Deaths, Adjusted for Population: ' = 'deaths_adjusted'),
    title = 'Deaths, adjusted for population',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Death Rates by District',
    palette = '-magma'
  ) +
  tm_shape(shapefile_districts) +
  tm_polygons(
    col = 'comp_vax_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name_1',
                   'Proportion of County Fully Vaccinated: ' = 'comp_vax_adjusted'),
    title = 'Proportion Fully Vaccinated',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Vax Rates by District',
    palette = '-magma'
  ) +
  tm_shape(shapefile_districts) +
  tm_polygons(
    col = 'first_dose_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name_1',
                   'Proportion of County, 1st Dose: ' = 'first_dose_adjusted'),
    title = 'Proportion, First Dose',
    border.col = 'black',
    border.alpha = 0.3,
    alpha =
      0.4,
    group = 'Dose 1 Rates by District',
    palette = '-magma'
  ) +
  tm_shape(shapefile_districts) +
  tm_polygons(
    col = 'socmed',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name_1',
                   'Social Media: ' = 'socmed',
                   'Most Recent Tweet: ' = 'Most Recent Tweet'),
    popup.format = list(html.escape = F),
    title = 'Social Media',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Health District Social Media'
  ) 

#Run this. It'll probably still throw a warning but w/e
tmap_options(check.and.fix = TRUE)
#Save map as html
tmap_save(map1, 'counties_map.html')


# map of districts ----------------------------------------------------
#(I DIDN'T ACTUALLY USE ANY OF THIS CODE)
#Maps are big so dump if done
# rm(map1)
# 
# #Plot map of social media
# map2 <-  
#   #Layer 1: counties
#   tm_shape(shapefile_counties) +
#   tm_polygons(
#     col = 'socmed',
#     id = 'name',
#     popup.vars = c('Jurisdiction: ' = 'name_1',
#                    'Social Media: ' = 'socmed',
#                    'Most Recent Tweet: ' = 'Most Recent Tweet'),
#     popup.format = list(html.escape = F),
#     title = 'Social Media',
#     border.col = 'black',
#     border.alpha = 0.3,
#     alpha = 0.4,
#     group = 'County Health Dept. Social Media'
#   ) +
#   #Layer 2: districts
#   
# 
# #Save map as html
# tmap_save(map2, 'district_map.html')
