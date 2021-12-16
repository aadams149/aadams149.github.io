library(DT)
library(plotly)
library(sf)
library(tmap)
library(tidyverse)
library(vroom)

covid <-
  vroom(
    'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv'
  ) 

shapefile <-
  st_read('counties_with_mc_districts.shp')

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

population_counties <-
  vroom('co-est2020.csv') %>%
  #Exclude state total populations
  filter(COUNTY != '000') %>%
  #Rename population for convenience
  rename('population' = POPESTIMATE2020) %>%
  #Create a fips column for easy merging
  mutate('fips' = paste0(STATE,COUNTY)) %>%
  select(fips, STNAME, population)

vax_data <-
  vroom('vax_data.csv') %>%
  select(date = date,
         fips = fips,
         Series_Complete_Yes,
         Administered_Dose1_Recip) %>%
  mutate(date = 
           lubridate::mdy(as.character(date)))

county_names <-
  counties %>%
  select(fips, 
         name,
         district)


# main covid data -----------------------------------------------------

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

covid_all[c('deaths',
            'Series_Complete_Yes',
            'Administered_Dose1_Recip')][is.na(covid_all[c('deaths',
                                                           'Series_Complete_Yes',
                                                           'Administered_Dose1_Recip')])] <- 0

socmed <-
  counties %>%
  select(
    fips,
    twitter,
    twitterYN,
    facebookYN,
    socmed
  )

covid_all <-
  covid_all %>%
  left_join(
    socmed,
    by = 'fips'
  )

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

covid_mean_data[is.na(covid_mean_data)] <- 0

#write_csv(covid_mean_data, 'covid_mean_data.csv')


# Data Table ----------------------------------------------------------

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

counties1[is.na(counties1)] <- 'NA'

output_table <-
  DT::datatable(counties1)

#htmlwidgets::saveWidget(output_table, 'data_table.html')

# plotly line graph ---------------------------------------------------
library(plotly)

covid_mean_data <-
  vroom('covid_mean_data.csv')

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
    title = 'COVID-19 Metrics by County Health Department Social Media Presence',
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
      rangeslider = list(type = "date",
                         label = 'Date')))


htmlwidgets::saveWidget(as_widget(bigfig), "lineplot.html")
# tmap ----------------------------------------------------------------
covid_today <-
  covid_all %>%
  filter(date == max(date))

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

covid_today_full = rbind.data.frame(covid_today,
                                      district_data1)

tweets <-
  counties %>%
  select(
    fips,
    county = name,
    tweet_date,
    twitter,
    tweet,
    link,
    likes_count,
    retweets_count,
    replies_count
  ) %>%
  mutate(`Most Recent Tweet` =
              case_when(!is.na(tweet) ~ paste0("<a href = ", link,"/>",county," (",tweet_date,")","</a>"),
                         is.na(tweet) ~ 'No Available Tweets'))

tmap_mode('view')

shapefile_districts <-
  shapefile %>%
  filter(in_dstr != 1) %>%
  left_join(covid_today_full,
            by = c('GEOID' = 'fips',
                   'distrct' = 'district')) %>%
  left_join(tweets,
            by = c('GEOID' = 'fips')) %>%
  mutate(name_1 = 
           case_when(is.na(name_1) ~ name,
                     !is.na(name_1) ~ name_1),
         comp_vax_adjusted =
           case_when(comp_vax_adjusted >= 1 ~ 1,
                     comp_vax_adjusted < 1 ~ comp_vax_adjusted),
         first_dose_adjusted = 
           case_when(first_dose_adjusted >= 1 ~ 1,
                     first_dose_adjusted < 1 ~ comp_vax_adjusted)
         )

shapefile_counties <-
  shapefile %>%
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

rm(district_data)
rm(covid)
rm(covid_all)
rm(vax_data)


# map of counties -----------------------------------------------------
#(Maybe not include)

map1 <-
  tm_shape(shapefile_counties) +
  tm_polygons(
    col = 'cases_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name',
                   'Cases, Adjusted for Population: ' = 'cases_adjusted'),
    title = 'Cases, adjusted for population',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Case Rates by County'
  ) +
  tm_shape(shapefile_counties) +
  tm_polygons(
    col = 'deaths_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name',
                   'Deaths, Adjusted for Population: ' = 'deaths_adjusted'),
    title = 'Deaths, adjusted for population',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Death Rates by County'
  ) +
  tm_shape(shapefile_counties) +
  tm_polygons(
    col = 'comp_vax_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name',
                   'Proportion of County Fully Vaccinated: ' = 'comp_vax_adjusted'),
    title = 'Proportion Fully Vaccinated',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Vax Rates by County'
  ) +
  tm_shape(shapefile_counties) +
  tm_polygons(
    col = 'first_dose_adjusted',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name',
                   'Proportion of County, 1st Dose: ' = 'first_dose_adjusted'),
    title = 'Proportion, First Dose',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Dose 1 Rates by County'
  ) +
  tm_shape(shapefile_counties) +
  tm_polygons(
    col = 'socmed',
    id = 'name',
    popup.vars = c('Jurisdiction: ' = 'name',
                   'Social Media: ' = 'socmed',
                   'Most Recent Tweet: ' = 'Most Recent Tweet'),
    popup.format = list(html.escape = F),
    title = 'Social Media',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Health Department Social Media'
  ) 

#tmap_save(map1, 'counties_map.html')


# map of districts ----------------------------------------------------
rm(map1)

map2 <-  
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
    group = 'Case Rates'
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
    group = 'Death Rates'
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
    group = 'Complete Vaccination Rates'
  ) +
  # tm_shape(shapefile_districts) +
  # tm_polygons(
  #   col = 'first_dose_adjusted',
  #   id = 'name',
  #   popup.vars = c('Jurisdiction: ' = 'name_1',
  #                  'Proportion of County, 1st Dose: ' = 'first_dose_adjusted'),
  #   title = 'Proportion, First Dose',
  #   border.col = 'black',
  #   border.alpha = 0.3,
  #   alpha = 0.4,
  #   group = 'Dose 1 Rates'
  # ) +
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

#tmap_save(map2, 'district_map.html')
