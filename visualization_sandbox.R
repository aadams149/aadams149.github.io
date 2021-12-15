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
  mutate(fips =
           str_pad(fips,
                   5,
                   pad = '0'),
         #Create a column with county names and state abbreviations together
         #(This is just for aesthetic benefit later.)
         place =
           paste0(name, ", ", state_full))

population_counties <-
  vroom('co-est2020.csv') %>%
  #Exclude state total populations
  filter(COUNTY != '000') %>%
  #Rename population for convenience
  rename('population' = POPESTIMATE2020) %>%
  #Create a fips column for easy merging
  mutate('fips' = paste0(STATE,COUNTY)) %>%
  select(fips, STNAME, population)

covid_filtered <-
  covid %>%
  filter(date == '2021-12-12') %>%
  left_join(
    population_counties,
    by = c('fips',
           'state' = 'STNAME')
  ) %>%
  mutate(
    cases_adjusted = 
      cases/population,
    deaths_adjusted = 
      deaths/population
  )

county_names <-
  counties %>%
  select(fips, 
         name,
         district)

covid_filtered <-
  covid_filtered %>%
  left_join(
    county_names,
    by = 'fips'
  )

district_data = data.frame()
for(ii in unique(covid_filtered$district)){
  if(!is.na(ii)){
    df_subset <-
      covid_filtered %>%
      filter(district == ii)
  
    newrow <-
      data.frame(
        date = unique(covid_filtered$date)[1],
        county = ii,
        state = unique(df_subset$state)[1],
        fips = shapefile[shapefile$distrct == ii,]$GEOID,
        cases = sum(df_subset$cases),
        deaths = sum(df_subset$deaths),
        population = sum(df_subset$population),
        cases_adjusted = sum(df_subset$cases)/sum(df_subset$population),
        deaths_adjusted = sum(df_subset$deaths)/sum(df_subset$population),
        name = ii,
        district = ii
      )
    district_data = rbind.data.frame(district_data,
                                     newrow)
  }
}

district_data = district_data %>%
  distinct() %>%
  drop_na() %>%
  filter(fips > 99000)


covid_filtered_all = rbind.data.frame(covid_filtered,
                                      district_data)

tmap_mode('view')

shapefile_districts <-
  shapefile %>%
  filter(in_dstr != 1) %>%
  left_join(covid_filtered_all,
            by = c('GEOID' = 'fips',
                   'distrct' = 'district')) %>%
  mutate(name_1 = 
           case_when(is.na(name_1) ~ name,
                     !is.na(name_1) ~ name_1))

shapefile_counties <-
  shapefile %>%
  filter(is_dstr != 1) %>%
  left_join(covid_filtered_all,
            by = c('GEOID' = 'fips',
                   'STNAME' = 'state',
                   'distrct' = 'district'))


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
  tm_shape(shapefile_districts) +
  tm_polygons(
    col = 'cases_adjusted',
    id = 'NAME',
    popup.vars = c('Jurisdiction: ' = 'name_1',
                   'Cases, Adjusted for Population: ' = 'cases_adjusted'),
    title = 'Cases, adjusted for population',
    border.col = 'black',
    border.alpha = 0.3,
    alpha = 0.4,
    group = 'Case Rates by Public Health District'
  ) 

map2 = map1 %>%
  tmap_leaflet() %>%
  leaflet::hideGroup("Case Rates by Public Health District")


map2