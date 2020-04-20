# Provost_control_chart
Implementation of Provost control chart for exponential data
Add information about the use
This project implements a method based on control charts to view phases in daily reported deaths from COVID-19.  The code is R and deploys a user interface using Shiny technology.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

You need a current version of R (we developed this using R version 3.6.3 and RStudio version 1.2.5033).  We used the R package ggplot2 to construct the graphs; we are exploring using plotly as an alternative.  You also need familiarity with the Shiny package that enables the construction of the user-interface. You also need to be connected to the internet to enable update of data tables.

The code looks for current data in the data folder; if data are not current, the code will attempt to connect to web sites to obtain current data:

```
data_file_country <- paste0('data/country_data_', as.character(Sys.Date()), '.csv')
data_file_state   <- paste0('data/us_state_data_', as.character(Sys.Date()), '.csv')


if (!file.exists(data_file_country)) {
  covid_data <- httr::GET("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", 
                          authenticate(":", ":", type="ntlm"),
                          write_disk(data_file_country, overwrite=TRUE))
}

if (!file.exists(data_file_state)) {
  download.file(url = 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv',
                destfile = data_file_state)
}
```

### Installing

[Click here to download the latest version] (https://github.com/klittle314/Provost_control_chart/archive/master.zip) 

Make sure you have installed the following libraries and dependencies; these are shown at the top of the global.R file.  

```
library(tidyverse)
library(readxl)
library(utils)
library(httr)
library(DT)

```

End with an example of getting some data out of the system or using it for a little demo

## Test file

You can use the data file in the test_data folder to check the upload data function.   You should get this output:

![basic chart]
![log chart]
![calculation details]
