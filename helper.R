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
  #note that this parameter is NOT the same as the baseline parameter chosen by the user
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
          CL <- NA
          C_UCL <- NA
          stop <- TRUE
        }
      }
      
    } else {
      start_date1 <- NA
      CL <- NA
      C_UCL <- NA
    }
  } else {
    start_date0 <- NA
    start_date1 <- NA
    CL <- NA
    C_UCL <- NA
  }

  #pass the key dates and C-chart information
  list(
    first_death = start_date0,
    c_chart_signal = start_date1,
    CL_out = CL,
    C_UCL_out = C_UCL)

}

#new function to label stages, MDEC created 4-7-2020
create_stages <- function(data1,date_cutoffs){
  data_stages <- list()
  
  # if date_cutoffs$first_death is NA (no deaths), stage1 is the whole data.frame df1_X
  if (is.na(date_cutoffs$first_death)) stage1 <- data1
  else stage1 <- data1 %>% filter(dateRep < date_cutoffs$first_death)
  
  stage1$stage <- 'Pre-deaths'
  data_stages$stage1 <- stage1
  
  # If there has been a death, stage 2 is df1_X starting on the day of the first death,
  # and must be at least 8 days
  if (!is.na(date_cutoffs$first_death)) {
    stage2 <- data1 %>% filter(dateRep >= date_cutoffs$first_death)
    
    # Must be at least 8 records long
    if (nrow(stage2) >= 8) {
      
      # If c_chart_signal is observed, cut off stage2 before that date.
      if (!is.na(date_cutoffs$c_chart_signal)) {
        stage2 <- stage2 %>% filter(dateRep < date_cutoffs$c_chart_signal)
      }
      
      stage2$stage <- 'Deaths observed before c-chart signal'
      
      data_stages$stage2 <- stage2
    }
  }
  
  # If there has been a c-chart signal observed, stage 3 begins with that date and is at 
  # least 8 subsequent days with deaths > 0, up to 20 (determined by value of baseline argument).
  if (!is.na(date_cutoffs$c_chart_signal)) {
    stage3 <- data1 %>% filter(dateRep >= date_cutoffs$c_chart_signal) 
    
    stage3_check <- stage3 %>% filter(deaths > 0)
    
    if (nrow(stage3_check) >= 8) {
      
      stage3 <- head(stage3, baseline)
      
      stage3$stage <- 'Exponential growth and fit'
      
      data_stages$stage3 <- stage3
    }
  }
  
  # If there has been a c-chart signal observed, and there's data after the c-chart signal
  # start plus baseline period, make that stage 4  NEED TO ACCOUNT FOR ZEROS IN STAGE 3
  if (!is.na(date_cutoffs$c_chart_signal)) {
      #count the number of records that have 0 in the death series for stage 3  
      count_zeros <- length(stage3$deaths[identical(stage3$deaths,0)])
      
      stage4 <- data1 %>% filter(dateRep >= date_cutoffs$c_chart_signal + baseline + count_zeros)
    
    if(nrow(stage4)> 0) {
      stage4$stage <- 'Observations after exponential limits established'
      
      data_stages$stage4 <- stage4
    }
  }
  
  data_out <- dplyr::bind_rows(data_stages)
}


#function to subset master data set by location_name, start_date and pad by buffer_days
make_location_data <- function(data,location_name,buffer_days,baseline,start_date){
  
  #create an object that will have data frames, dates of stages and the linear model fit
  data_results_list <- list()
    
  #initialize two list entries that are conditionally calculated by the rest of the function
    data_results_list$df_exp_fit <- NULL
    data_results_list$lm_out <- NULL
    
  
  df1_X <- data %>% filter(countriesAndTerritories == location_name) %>% arrange(dateRep)
  #dates_of_deaths <- df1_X$dateRep[which(df1_X$deaths>0)]
  
  date_cutoffs <- find_start_date(data = df1_X, location_name = location_name, start_date = start_date)
  
  data_results_list$date_cutoffs <- date_cutoffs
   
  df1_X <- create_stages(data=df1_X,date_cutoffs=date_cutoffs)
  
  df1_X$deaths_nudge <- df1_X$deaths
  browser()
  #filter the data to just the deaths series
  df1_X <- df1_X %>% filter(stage != "Pre-deaths")
  
  data_results_list$df1_X <- df1_X
  
  #if there are data in stage 2, then we will plot those data in run chart if <= 8 records and no control chart signal
  #if there are data in stage 3, we need to calculate the information
  #check if any embedded zeros in stage 3:  we will convert zero to NA on supposition that a zero in this phase represents missing data
  #create a new variable deaths_nudge to represent the adjusted death series
  ################# Allow over-ride of the calculated start_date by the user chosen start_date.#################
  exp_fit_min_length <- 8
  
  
  
  #Build the linear model of there are sufficient records and calculate the anti logs of prediction and limits
   if(!is.na(date_cutoffs$c_chart_signal) )  { 
      df1_X_exp_fit <- df1_X %>% filter(stage=='Exponential growth and fit')
      
      #check for sufficient stage 3 values to calculate the exponential growth control limits
      
      if(nrow(df1_X_exp_fit)> exp_fit_min_length) {
            #replace any deaths_nudge value = 0 with NA
            df1_X_exp_fit$deaths_nudge <- unlist(lapply(df1_X_exp_fit$deaths_nudge,zero_NA))
            
            df1_X_exp_fit$log_10_deaths <- log10(df1_X_exp_fit$deaths_nudge)
            
            df1_X_exp_fit$serial_day <- c(1:nrow(df1_X_exp_fit))
            
            #allow the use of a different baseline, user defined input
            df1_X_exp_fit <- df1_X_exp_fit %>% filter(serial_day <= baseline)
            
            lm_out <- lm(data=df1_X_exp_fit,df1_X_exp_fit$log_10_deaths ~ df1_X_exp_fit$serial_day)
            
            data_results_list$lm_out <- lm_out
            
            #update the df1_X component of the output list?  Leave any 0 value in the df?
            
            #should make a prediction for the NA values-- find the value and insert
            cchart_df <- data.frame(df1_X_exp_fit[!is.na(df1_X_exp_fit$log_10_deaths),c("dateRep","serial_day","deaths","log_10_deaths")],
                                    lm_out$residuals,c(NA,diff(lm_out$residuals)),lm_out$fitted.values)
            
            names(cchart_df)[5] <- "differences"
            
            AvgMR <- mean(abs(cchart_df$differences),na.rm=TRUE)
            
            cchart_df$UCL <- lm_out$fitted.values + 2.66*AvgMR
            
            cchart_df$LCL <- lm_out$fitted.values - 2.66*AvgMR
            
            df_exp_fit <- cchart_df
            
            
          #check for any values in stage 4; compute them
          
          if(any(df1_X$stage=='Observations after exponential limits established')) {
             df1_X_post_fit <- df1_X %>% filter(stage=='Observations after exponential limits established')
             browser() #check the serial day values what is the max?  Error in df output, jump in serial day from 27 to 101??
             nrows_post_fit <- nrow(df1_X_post_fit)  
             
             start_index <- max(df1_X_exp_fit$serial_day)+1
             
             df1_X_post_fit$serial_day <- seq(from=start_index, length.out=nrows_post_fit,by=1)
             
             df1_X_post_fit$log_10_deaths <- log10(df1_X_post_fit$deaths)
             
             check_predicted_value <- lm_out$coefficients[1]+ lm_out$coefficients[2]*df1_X_post_fit$serial_day
             
             df_post_fit_out <- cbind.data.frame(df1_X_post_fit[,c("dateRep","serial_day","deaths","log_10_deaths")],
                                              rep(NA,nrows_post_fit),
                                              rep(NA,nrows_post_fit),
                                              check_predicted_value,
                                              check_predicted_value + 2.66*AvgMR,
                                              check_predicted_value - 2.66*AvgMR)
             
             names(df_post_fit_out) <- names(df_exp_fit)
             
             df_exp_fit <- rbind.data.frame(df_exp_fit,df_post_fit_out)
            }
          #now add the buffer
            #buffer with buffer days beyond max date
            serial_day_buffer_start <- nrow(df_exp_fit)
            
            buffer_dates <- seq.Date(from=max(df_exp_fit$dateRep)+1,to=max(df_exp_fit$dateRep)+buffer_days,by="day")
            
            buffer_serial_day <- seq(from=serial_day_buffer_start+1,to=serial_day_buffer_start+buffer_days,by=1)
            
            predicted_value <- lm_out$coefficients[1]+ lm_out$coefficients[2]*buffer_serial_day
            
            buffer_df <- cbind.data.frame(buffer_dates,
                                          buffer_serial_day,
                                          rep(NA,buffer_days),
                                          rep(NA,buffer_days),
                                          rep(NA,buffer_days),
                                          rep(NA,buffer_days),
                                          predicted_value,
                                          predicted_value + 2.66*AvgMR,
                                          predicted_value - 2.66*AvgMR)
            
            names(buffer_df) <- names(df_exp_fit)
            
            df_exp_fit <- rbind.data.frame(df_exp_fit,buffer_df)
            
            df_exp_fit$predict <- 10^df_exp_fit$lm_out.fitted.values
            
            df_exp_fit$UCL_anti_log <- 10^df_exp_fit$UCL
            
            df_exp_fit$LCL_anti_log <- 10^df_exp_fit$LCL
            
            data_results_list$df_exp_fit <- df_exp_fit
      }
      
   }  
 
  
   #make conditional:   output is df_X1, date_cutoffs, AND lm_out could be NULL and df_exp_fit could be NULL
  return(data_results_list)
}
 