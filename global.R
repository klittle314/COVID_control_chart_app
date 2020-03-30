#This script is front-end for shiny app that implements the control chart approach for exponentially growing data
# series by Provost et al.
library(tidyverse)
library(readxl)
library(utils)
library(httr)
source("helper.R")

#download the dataset from the ECDC website to a local temporary file--not playing nice with Windows /
tf <- tempfile(fileext = '.csv')

covid_data <- httr::GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", 
                        authenticate(":", ":", type="ntlm"),
                        write_disk(tf))

df1 <- read_csv(tf)
df1$dateRep <- as.Date(df1$dateRep)

country_names <- unique(df1$countriesAndTerritories)
