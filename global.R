#This script is front-end for shiny app that implements the control chart approach for exponentially growing data
# series by Provost et al.
library(tidyverse)
library(readxl)
library(utils)
library(httr)
source("helper.R")

#main_wd <- getwd()
#temp_dir <- paste0(main_wd,"/data")
#setwd(temp_dir)
#download the dataset from the ECDC website to a local temporary file--not playing nice with Windows /
#GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", authenticate(":", ":", type="ntlm"), 
    #write_disk(tf <- tempfile(fileext = ".csv")))


#setwd(main_wd)
#read the Dataset sheet into “R”. The dataset will be called df1

#data <- read_csv("data/tf.csv")

df1 <- read_excel("data/Copy of COVID-19-geographic-disbtribution-worldwide.xlsx")
df1$dateRep <- as.Date(df1$dateRep)

country_names <- unique(df1$countriesAndTerritories)
