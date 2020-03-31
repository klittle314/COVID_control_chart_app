# This script is a front-end for shiny app that implements the control chart approach for exponentially growing data
# series by Provost et al. March 2020.
# Drafted by Kevin Little, Ph.D. with help from Mason DeCamillis, Lynda Finn, and Emily Jones

library(tidyverse)
library(readxl)
library(utils)
library(httr)
library(DT)
source("helper.R")

local <- FALSE

data_file <- 'data/ecdc_data.csv'

if (!local) {
  covid_data <- httr::GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", 
                          authenticate(":", ":", type="ntlm"),
                          write_disk(data_file,overwrite=TRUE))
}

df1 <- read_csv(data_file)
df1$dateRep <- as.Date(df1$dateRep, format = '%d/%m/%Y')

country_names <- unique(df1$countriesAndTerritories)
