# Provost Method:  Count plots across phases of COVID-19 infection
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
- find_start_date_Provost
    - Inputs:  input data frame, specified location, start date for analysis
    - Outputs: a list with date of first reported death, date of signal on c-control chart, center line for c-chart, upper control limit for c-chart 
- create_stages_Provost
   - Inputs:  input data frame, the list of dates from find_start_date_Provost, and the baseline days used to fit the regression model of log10 deaths
   - Outputs: output data frame, with a new column that describes the stage for each record
       - stage 1:  data before the date of first reported death
       - stage 2:  data starting with date of first reported death through the day before a special cause signal on the c-control chart
       - stage 3:  data starting with the date of a special cause signal on the c-control chart
       - stage 4:  data starting after the last day used to fit fit the regression model
            
- make_location_data  A function that calls find_start_date_Provost function and create_stages_Provost
  - Inputs:  input data frame, specified location, buffer days at end of observed data, baseline days used to fit the regression model of log10 deaths, and start date for analysis
  - Outputs:  data frame for specified location dates, deaths, and stages; data frame with fitted values and limits dervied from the regression model of log10 deaths; list of date of first death, date of special cause signal on c-chart, c-chart center line and upper control limit, linear model list from the regression fit.
  
  
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
