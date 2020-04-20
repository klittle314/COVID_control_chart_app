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

## Structure of the Shiny app
The core files are
1. global.R  This file loads the data from external websites for country and U.S. state/territory COVID daily data.  It also does minimal editing of the data frames to assure common names.  For the U.S. state/territory file, it convets cumulative deaths into deaths reported daily.
2. ui.R  This file defines the Shiny user interface.
3. server.R  This file provides the reactive functions that take default and user-defined inputs to create summary charts and tables.
4. helper.R  This file contains the core functions.   In addition to several small auxiliary functions, the main functions are:


## Test file

You can use the data file in the test_data folder to check the upload data function. You should see screens like these:
*Upload data*
![upload data](https://github.com/klittle314/Provost_control_chart/blob/master/screen_shots/2020-04-20_Data%20Load.jpg)

*Basic Chart*
![basic chart](https://github.com/klittle314/Provost_control_chart/blob/master/screen_shots/2020-04-20_basic%20chart.jpg)

*Log Chart*
![log chart](https://github.com/klittle314/Provost_control_chart/blob/master/screen_shots/2020-04-20_log%20chart.jpg)

*Calculations*
![calculation details](https://github.com/klittle314/Provost_control_chart/blob/master/screen_shots/2020-04-20_basic%20calculations.jpg)

## Contributing
We have not yet set up a process to incorporate changes into the code.   Check back soon!

## Authors
Kevin Little outlined the basic design and wrote most of the core functions; Mason DeCammillis built subtantial parts of the Shiny interface; Emily Jones contributed functionality and participated with Lynda Finn in design critique.
