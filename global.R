#This script is front-end for shiny app that implements the control chart approach for exponentially growing data
# series by Provost et al.
library(tidyverse)
library(readxl)
library(utils)
library(httr)
source("helper.R")

local <- TRUE

data_file <- 'data/ecdc_data.csv'

if (!local) {
  covid_data <- httr::GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", 
                          authenticate(":", ":", type="ntlm"),
                          write_disk(data_file))
}

df1 <- read_csv(data_file)
df1$dateRep <- as.Date(df1$dateRep)

country_names <- unique(df1$countriesAndTerritories)
