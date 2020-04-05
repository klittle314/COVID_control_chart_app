#function to take data frame, e.g. states df or countries df, a name for the country or state and returns a data 
#frame with three columns (1 row):  the "Date_of_first_death","date_of_c-chart_signal","shift_rule_signal"
#Shift rule signal is TRUE or FALSE
library(dplyr)

find_start_date <- function(data,location_name,start_date=NA){
  df1_X <- data %>% filter(countriesAndTerritories == location_name) %>% arrange(dateRep)
  Rule_shift <- NA  
  #bound the length of the calculations, no more than cc_length records used to compute center line and upper limit
  cc_length <- 20
  if(any(df1_X$deaths >0,na.rm=TRUE)) {
    dates_of_deaths <- df1_X$dateRep[which(df1_X$deaths>0)]
    start_date0 <- dates_of_deaths[1]
    
    ##catch failure:  if data do not yield series with non zero deaths, use NA value of dates as condition##
    df1_X_deaths <- df1_X %>% filter(dateRep >= start_date0)
    #df1_X_deaths <- df1_X %>% filter(dateRep >= as.Date("2020-01-01"))
    #df1_X_deaths <- df1_X %>% filter(dateRep >= start_date0-10)
    
    if(nrow(df1_X_deaths) > 7) {
      #j is index of start of the current 8 values in the test series, used to identify shift signal
      j <- 1
      i <- 7
      stop <- FALSE
      while(!stop) {
        test_series0 <- df1_X_deaths %>% filter(dateRep >= start_date0 & dateRep <= start_date0+i) %>% pull(deaths)
        test_series_shift <- test_series0[j:(i+1)]
        #fix the limits at cc_length if series has that many records
        if(j <= cc_length - i){
          CL <- mean(test_series0)
          C_UCL <- CL + 3*sqrt(CL)
        } else {
          CL <-mean(test_series0[1:cc_length])
          C_UCL <- CL + 3*sqrt(CL)
        }
        Rule_1 <- any(which(test_series0 > max(1,C_UCL)))
        Rule_shift = length(which(test_series_shift > CL)) >=8
        if(Rule_1){
          index_start <- which.max(test_series0> max(1,C_UCL))
          start_date1 <- df1_X_deaths$dateRep[index_start]
          stop <- TRUE
        } else if(Rule_shift){
          start_date1 <- df1_X_deaths$dateRep[i+1] 
          stop <- TRUE
        } else if(nrow(df1_X_deaths) > i) {
          j <- j+1 
          i <- i+1
        } else {
          start_date1 <- NA
          stop <- TRUE
        }
      }
      
    } else start_date1 <- NA
    
  } else {
    start_date0 <- NA
    start_date1 <- NA
  }
  #forcing the dates to be date objects else may be interpreted as integer if values are NA
  df_out <- cbind.data.frame(as.Date(start_date0),as.Date(start_date1),Rule_shift)
  names(df_out) <- c("Date_of_first_death","date_of_c-chart_signal","shift_rule_signal")
  return(df_out)
}

##########How to make data frame of the all the states or all the countries
state_out <- lapply(state_names,find_start_date,data=df_state,start_date=NA)
dates_out <- do.call(rbind,state_out)
names(dates_out) <- c("date_of_first_death","date_Cchart_signal","Rule_shift")
dates_for_states20 <- cbind.data.frame(state_names,dates_out)

world_out <- lapply(country_names,find_start_date,data=df_country,start_date=NA)
dates_out <- do.call(rbind,world_out)
names(dates_out) <- c("date_of_first_death","date_Cchart_signal", "Rule_shift")
dates_for_world20 <- cbind.data.frame(country_names,dates_out)

library(openxlsx)
write.xlsx(dates_for_states20,paste0("dates_for_states_20_Ruleshift_",Sys.Date(),".xlsx"),overwrite=TRUE)
write.xlsx(dates_for_world20,paste0("dates_for_world_20_Ruleshift_",Sys.Date(),".xlsx"),overwrite=TRUE)