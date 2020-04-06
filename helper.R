#helper files

#NA functions

#LF trick  function
nudge_zero <- function(x){
  if(identical(x,0)){
    x <- 0.1
  }
  return(x)
}

#function to do NA conversion
zero_NA <- function(x){
  if(identical(x,0)){
    x <- NA
  }
  return(x)
}

#function to find index that marks first sequence of length_use values.  Default length = 8 per Lloyd Provost 30 March 2020 
index_test <- function(x,index,length_use=8){
  x_check <- x[index:(index+length_use - 1)]
  if(all(x_check>0)){
    use_seq <- TRUE
    index_use <- index
  } else {
    use_seq <- FALSE
    index_use <- index + 1
  }
  return(list(use_seq,index_use))
}

#function to take data frame, e.g. states df or countries df, a name for the country or state and returns a data 
#frame with three columns (1 row):  the "Date_of_first_death","date_of_c-chart_signal","shift_rule_signal"
#Shift rule signal is TRUE or FALSE

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
  # df_out <- cbind.data.frame(as.Date(start_date0),as.Date(start_date1),Rule_shift)
  # names(df_out) <- c("Date_of_first_death","date_of_c-chart_signal","shift_rule_signal")
  # return(df_out)
  dates_out <- c(start_date0,start_date1)
}


#function to subset master data set by location_name, start_date and pad by buffer_days
make_location_data <- function(data,location_name,buffer_days,baseline,start_date){
  
  start_info <- find_start_date
  
  df1_X <- data %>% filter(countriesAndTerritories == location_name) %>% arrange(dateRep)
  dates_of_deaths <- df1_X$dateRep[which(df1_X$deaths>0)]
  start_date0 <- dates_of_deaths[1]
  
  ##if 
  ##catch failure:  if data do not yield series with non zero deaths, then exit with message##
  
  df1_X_deaths <- df1_X %>% filter(dateRep >= start_date0)
  

  #per Provost discussion, you can simply add 1 to deaths uniformly in the series.  
  #KL note:  setting value to NA for a zero after an initial 8 non-zero values. Need to fix logic
  #       e.g. Wisconsin has a string of deaths the embedded 0's in the series.  
  #   Is the option to add 1 to all deaths or just to deaths with zero?
  #df1_X_deaths$deaths_nudge <- unlist(lapply(df1_X_deaths$deaths,zero_NA))
  #df1_X_deaths$deaths_nudge <- df1_X_deaths$deaths + 1
  df1_X_deaths$deaths <- df1_X_deaths$deaths + 1
  
  #series_length:  number of sequential records used to find the start point
  series_length=8
  
  if((length(start_date)==0) && nrow(df1_X_deaths) > series_length){
  #if default 12/31/2019 start date, determine initial start to the series:  date of first death(s) 

  #find starting index of the series that has length_use=8 death values greater than 0
  #These needs some error handling
    i <- 1
    index_fail = TRUE
    while(index_fail) {
      index_check <- index_test(df1_X_deaths$deaths,i,length_use=series_length)
      if(index_check[[1]]) {
        index <- index_check[[2]]
        index_fail <- FALSE
      } else i <- i + 1
    }
    
    #subset the data file so it starts with the sequence of 8 non-negative deaths
    df1_X_deaths <- df1_X_deaths[index:nrow(df1_X_deaths),]

  } else {
    #take only data records starting with deaths, don't allow prior dates
    df1_X_deaths <- df1_X_deaths %>% filter(dateRep >= max(as.Date(start_date),as.Date(start_date0))) 
  } 
 
  #per Provost discussion, you can simply add 1 to deaths uniformly in the series.  
  #KL note:  setting value to NA for a zero after an initial 8 non-zero values.
  #df1_X_deaths$deaths_nudge <- unlist(lapply(df1_X_deaths$deaths,zero_NA))
  df1_X_deaths$deaths_nudge <- df1_X_deaths$deaths # fix this 4/2/20....temp because I increment above
  
  df1_X_deaths$log_count_deaths <- log10(df1_X_deaths$deaths_nudge)
  df1_X_deaths$serial_day <- c(1:nrow(df1_X_deaths))
  
  
  data_use_cc <- df1_X_deaths[df1_X_deaths$serial_day <= baseline,]
  buffer <- buffer_days
  
  #create linear model
  #now compute the linear regression for the log10 counts 
  #lm_out <- lm(data=data_use_cc,log_count_deaths ~ serial_day)
  lm_out <- lm(data=data_use_cc,data_use_cc$log_count_deaths ~ data_use_cc$serial_day)
  
  #should handle the break in the series more elegantly if we use the 'replace embedded 0 with NA" rule
  
  cchart_df <- data.frame(data_use_cc[!is.na(data_use_cc$log_count_deaths),c("dateRep","serial_day","deaths","log_count_deaths")],
                          lm_out$residuals,c(NA,diff(lm_out$residuals)),lm_out$fitted.values)
  names(cchart_df)[5] <- "differences"
  
  AvgMR <- mean(abs(cchart_df$differences),na.rm=TRUE)
  cchart_df$UCL <- lm_out$fitted.values + 2.66*AvgMR
  cchart_df$LCL <- lm_out$fitted.values - 2.66*AvgMR
  
  
  #buffer with buffer days beyond max date
  buffer_serial_day <- seq(from=max(df1_X_deaths$serial_day)+1,to=max(df1_X_deaths$serial_day)+buffer,by=1)
  predicted_value <- lm_out$coefficients[1]+ lm_out$coefficients[2]*buffer_serial_day
  buffer_dates <- seq.Date(from=max(df1_X_deaths$dateRep)+1,to=max(df1_X_deaths$dateRep)+buffer,by="day")
  buffer_df <- cbind.data.frame(buffer_dates,
                                buffer_serial_day,
                                rep(NA,buffer),
                                rep(NA,buffer),
                                rep(NA,buffer),
                                rep(NA,buffer),
                                predicted_value,
                                predicted_value + 2.66*AvgMR,
                                predicted_value - 2.66*AvgMR)
  
  names(buffer_df) <- names(cchart_df)
  
  #fill out the data table if not all observations are used to compute the control limits
  if(max(df1_X_deaths$serial_day) > baseline){
    df_check <- df1_X_deaths[df1_X_deaths$serial_day > baseline,]
  
    check_predicted_value <- lm_out$coefficients[1]+ lm_out$coefficients[2]*df_check$serial_day
    
    df_check_out <- cbind.data.frame(df_check[,c("dateRep","serial_day","deaths")],
                                     rep(NA,nrow(df_check)),
                                     rep(NA,nrow(df_check)),
                                     rep(NA,nrow(df_check)),
                                     check_predicted_value,
                                     check_predicted_value + 2.66*AvgMR,
                                     check_predicted_value - 2.66*AvgMR)
    names(df_check_out) <- names(cchart_df)
    df_cchart <- rbind(cchart_df,df_check_out,buffer_df)
  } else df_cchart <- rbind(cchart_df,buffer_df)
  
  df_cchart$predict <- 10^df_cchart$lm_out.fitted.values
  df_cchart$UCL_anti_log <- 10^df_cchart$UCL
  df_cchart$LCL_anti_log <- 10^df_cchart$LCL
  
  #df1_X_deaths is the dataframe with observed deaths, possibly truncated by user selection of Start Date for calculations
  #df_cchart is the dataframe that has observations and additional 'buffer' days, contains predicted values and limit values
  #lm_out is the linear model fitted to the log(deaths_nudge).
  results_list <- list(df1_X_deaths,df_cchart,lm_out)
  
}

#