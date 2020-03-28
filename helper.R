#helper files

#NA functions
#LF trick
nudge_zero <- function(x){
  if(identical(x,0)){
    x <- 0.1
  }
  return(x)
}

#NA conversion
zero_NA <- function(x){
  if(identical(x,0)){
    x <- NA
  }
  return(x)
}

#function to subset master data set by country_name, start_date and pad by buffer_days
make_country_data <- function(data,country_name,start_date,buffer_days){
  df1_X <- data %>% filter(countriesAndTerritories == country_name) %>% arrange(dateRep)
  
  #determine when to start the series for U.S. March 1
  
  df1_X_deaths <- df1_X %>% filter(dateRep >= start_date)
  
 
  
  df1_X_deaths$deaths_nudge <- unlist(lapply(df1_X_deaths$deaths,zero_NA))
  
  df1_X_deaths$log_count_deaths <- log10(df1_X_deaths$deaths_nudge)
  df1_X_deaths$serial_day <- c(1:nrow(df1_X_deaths))
  
  data_use <- df1_X_deaths
  buffer <- buffer_days
  
  #create linear model
  #now compute the linear regression for the log10 counts
  lm_out <- lm(data=data_use,data_use$log_count_deaths ~ data_use$serial_day)
  
  #should handle the break in the series more elegantly
  
  cchart_df <- data.frame(data_use[!is.na(data_use$log_count_deaths),c("dateRep","serial_day")],
                          lm_out$residuals,c(NA,diff(lm_out$residuals)),lm_out$fitted.values)
  
  
  
  AvgMR <- mean(abs(cchart_df$lm_out.residuals))
  cchart_df$UCL <- lm_out$fitted.values+2.66*mean(AvgMR,na.rm=TRUE)
  cchart_df$LCL <- lm_out$fitted.values-2.66*mean(AvgMR,na.rm=TRUE)
  
  #buffer with buffer days beyond max date
  buffer_serial_day <- seq(from=max(cchart_df$serial_day)+1,to=max(cchart_df$serial_day)+buffer,by=1)
  predicted_value <- lm_out$coefficients[1]+ lm_out$coefficients[2]*buffer_serial_day
  buffer_dates <- seq.Date(from=max(cchart_df$dateRep)+1,to=max(cchart_df$dateRep)+buffer,by="day")
  buffer_df <- cbind.data.frame(buffer_dates,
                                buffer_serial_day,
                                rep(NA,buffer),
                                rep(NA,buffer),
                                predicted_value,
                                predicted_value +2.66*mean(AvgMR,na.rm=TRUE),
                                predicted_value - 2.66*mean(AvgMR,na.rm=TRUE))
  
  names(buffer_df) <- names(cchart_df)
  
  
  df_cchart <- rbind(cchart_df,buffer_df)
  
  df_cchart$predict <- 10^df_cchart$lm_out.fitted.values
  df_cchart$UCL_anti_log <- 10^df_cchart$UCL
  df_cchart$LCL_anti_log <- 10^df_cchart$LCL
  
  results_list <- list(data_use,df_cchart,lm_out)
  
}

#