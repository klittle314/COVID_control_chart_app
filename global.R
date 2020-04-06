# This script is a front-end for shiny app that implements the control chart approach for exponentially growing data
# series by Provost et al. March 2020.
# Drafted by Kevin Little, Ph.D. with help from Mason DeCamillis, Lynda Finn, and Emily Jones

library(tidyverse)
library(readxl)
library(utils)
library(httr)
library(DT)
source("helper.R")

data_file_country <- paste0('data/country_data_', as.character(Sys.Date()), '.csv')
data_file_state   <- paste0('data/us_state_data_', as.character(Sys.Date()), '.csv')

defStartdate <- NA
defBuffer <- 10
defBaseline <- 15

if (!file.exists(data_file_country)) {
  covid_data <- httr::GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", 
                          authenticate(":", ":", type="ntlm"),
                          write_disk(data_file_country, overwrite=TRUE))
}

if (!file.exists(data_file_state)) {
  download.file(url = 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv',
                destfile = data_file_state)
}

df_country <- read_csv(data_file_country)
df_country$dateRep <- as.Date(df_country$dateRep, format = '%d/%m/%Y')
country_names <- unique(df_country$countriesAndTerritories)

df_state <- read_csv(data_file_state)
#problems opening the NYT connection 4/4/2020.  Also, native date format is %Y-%m-%d  Manual file manip changes date format.
df_state$date <- as.Date(df_state$date,format='%m/%d/%Y')
state_names <- unique(df_state$state)
#rename state variable to countriesAndTerritories to keep code consistent with nations data set
colnames(df_state) <- c('dateRep', 'countriesAndTerritories', 'fips', 'cases', 'cum_deaths')
#compute deaths in the state table, reported are cum deaths--have to work by state
df_state <- df_state %>%group_by(countriesAndTerritories) %>% 
              mutate(lag_cum_deaths=lag(cum_deaths)) %>% mutate(deaths= cum_deaths-lag_cum_deaths)

