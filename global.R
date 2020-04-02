# This script is a front-end for shiny app that implements the control chart approach for exponentially growing data
# series by Provost et al. March 2020.
# Drafted by Kevin Little, Ph.D. with help from Mason DeCamillis, Lynda Finn, and Emily Jones

library(tidyverse)
library(readxl)
library(utils)
library(httr)
library(DT)
source("helper.R")

#set local to FALSE if you want to read in the Open Data Table from the EOC
local <- FALSE

data_file_country <- 'data/country_data.csv'
data_file_state   <- 'data/us_state_data.csv'

if (!local) {
  covid_data <- httr::GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", 
                          authenticate(":", ":", type="ntlm"),
                          write_disk(data_file_country, overwrite=TRUE))
  
  download.file(url = 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv',
                destfile = data_file_state)
}

df_country <- read_csv(data_file_country)
df_country$dateRep <- as.Date(df_country$dateRep, format = '%d/%m/%Y')
country_names <- unique(df_country$countriesAndTerritories)

df_state <- read_csv(data_file_state)
colnames(df_state) <- c('dateRep', 'countriesAndTerritories', 'fips', 'cases', 'deaths')
state_names <- unique(df_state$state)
