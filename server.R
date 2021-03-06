source("global.R")
shinyServer(function(input, output, session) {
    
    print('Sys.info():')
    print(Sys.info())
    print('.Platform():')
    print(.Platform)
    print('R.version.string:')
    print(R.version.string)
    print('sessionInfo():')
    print(sessionInfo())
    
    df_upload <- reactiveVal(value = NULL)

    upload_data <- reactive({
        req(input$upload_data)
        
        try({
            read.csv(input$upload_data$datapath,
                     header = TRUE,
                     stringsAsFactors = FALSE)
        })
    })
    
    upload_message <- reactive({
        if ('try-error' %in% class(upload_data())) {
            
            msg <- 'There was a problem reading your file. Please confirm that it is in CSV format, and that you selected the correct file.'
          
            upload_confirm <- NULL
            
        } else if (!all(c('date', 'cases', 'deaths', 'location') %in% colnames(upload_data()))) {
            
            missing_cols <- setdiff(c('date', 'cases', 'deaths', 'location'), colnames(upload_data()))
            msg <- paste0('Columns missing from CSV file: ', paste0(missing_cols, collapse = ', '))
            
            upload_confirm <- NULL
            
        } else if (any(is.na(as.Date(upload_data()$date, format='%m/%d/%Y')))) {
            
            msg <- 'Please confirm date format is MM/DD/YYYY'
          
            upload_confirm <- NULL
          
        } else {
            
            upload_confirm <- renderUI({
                
                list(
                    tags$br(),
                    
                    h4('Preview'),
                    
                    DT::renderDataTable(
                        datatable(upload_data(),
                                  rownames = FALSE)),
                    
                    actionButton(
                        inputId = 'upload_confirm',
                        label   = 'Confirm'))
            })
            
            msg <- 'Data successfully uploaded and parsed. Scroll to bottom of table to click Confirm to complete the data entry.'
        }
      
        output$upload_confirm <- upload_confirm
      
        msg
    })
    
    output$upload_message <- renderUI({
        req(upload_message())
        
        h5(upload_message())
    })
    
    observeEvent(input$upload_confirm, {
        req(upload_data())
        
        data_add <- upload_data()[c('date', 'cases', 'deaths', 'location')]
        colnames(data_add) <- c('dateRep', 'cases', 'deaths', 'countriesAndTerritories')
        
        data_add$dateRep <- as.Date(data_add$dateRep, format = '%m/%d/%Y')
        
        data_add <- rbind(isolate(df_upload()), data_add)
        
        data_add <- unique(data_add)
        
        df_upload(data_add)
       
        updateSelectInput(
          session = session,
          inputId = 'data_source',
          selected = 'User-uploaded data')

        output$upload_confirm <- renderUI({
            list(
                tags$br(),
                
                h4('Data successfully added. Switch to Display tab to view.'))
          
        }) 
    })
    
    observeEvent(input$reset, {
      updateDateInput(session, "start_date",
                        value = defStartdate)
      
      updateNumericInput(session, "buffer",
                        value = defBuffer)
      
      updateNumericInput(session, "baseline_n",
                        value = defBaseline)
    })
    
    display_data <- reactive({
        req(input$data_source)
     
        if (input$data_source == 'Country-level ECDC data')           df_country
        else if (input$data_source == 'US state-level NY Times data') df_state
        else if (input$data_source == 'User-uploaded data')           df_upload()
    })
    
    observe({
        req(display_data(), df_upload()) 
      
        selected <- isolate(input$choose_location)
        choices  <- sort(unique(display_data()$countriesAndTerritories))
        
        if (!(selected %in% choices)) selected <- choices[1]
        
        updateSelectInput(
            session = session,
            inputId = 'choose_location',
            choices = choices,
            selected = selected)
    })
    
    control_chart_caption <- reactive({
        req(input$data_source)
        
        if (input$data_source == 'Country-level ECDC data')           data_source <- 'https://opendata.ecdc.europa.eu/covid19/casedistribution/csv'
        else if (input$data_source == 'US state-level NY Times data') data_source <- 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv'
        else if (input$data_source == 'User-uploaded data')           data_source <- 'User-uploaded data file'
        
        sprintf('%s\n\nSource: %s, %s',
                input$chart_caption,
                data_source,
                as.character(Sys.Date()))
       
    })
    
    #make a list that has a frame of the original data, a frame to construct the limit chart, and the linear model
    make_data <- reactive({
       
        location_use <- input$choose_location
        data1 <- display_data()
        buffer <- input$buffer
        baseline1 <- input$baseline_n
        start_date_user <- input$start_date
        
        list_use <- make_location_data(data=data1,
                                       location_name=location_use,
                                       buffer_days=buffer,
                                       baseline=baseline1,
                                       start_date=start_date_user)
      
        return(list_use)
    })
    
    
    #Note do not use req(make_data()) as all of the values could be NULL or NA.
    #Revision of the construction of the charts
    control_chartNEW <- reactive({
      location_use <- input$choose_location
      buffer <- input$buffer
      baseline1 <- input$baseline_n
      title1 <- paste0(location_use," Daily Reported Deaths")
      caption_use <- control_chart_caption()
      constrain_y_axis <- input$constrain_y_axis
      
      make_data <- make_data()
      # df_no_fit <- make_data()$df1_X
      # df_fit <- make_data()$df_exp_fit
      # lm_fit <- make_data()$lm_out
      # first_death_date <- make_data()$date_cutoffs$first_death
      # exp_growth_date <- make_data()$date_cutoffs$c_chart_signal
      # c_chart_CL <- make_data()$date_cutoffs$CL
      # c_chart_UCL <- make_data()$date_cutoffs$UCL
    
      
      chart_list <- make_charts(location_use=location_use,buffer=buffer,
                                make_data=make_data,title1=title1,caption_use=caption_use,
                                constrain_y_axis = constrain_y_axis)
      
      #contents of chart_list:  message_out, p_out1, p_out2 
})
   
    
   
    output$control_chart <- renderPlot({
        
        req(control_chartNEW())
        
        if(control_chartNEW()$message_out != "No reported deaths") {
              print(control_chartNEW()$p_out1)
        }
    })
    
    output$log_control_chart <- renderPlot({
        
        req(control_chartNEW())
      
        if(control_chartNEW()$message_out == "c-chart and exponential fit") {
              print(control_chartNEW()$p_out2)
        }
    })
    
    output$download_chart <- downloadHandler(
      filename = function() {
            sprintf('%s_%s_days.png', input$choose_location, input$baseline_n)
        },
        content = function(file) {
            
            png(file, width = 1000, height = 600)
                print(control_chartNEW()$p_out1)
            dev.off(which=dev.cur())
        }
    )
    
    data_for_table <- reactive({
      #make the stuff that I want to use goes here
      message_out <- control_chartNEW()$message_out
      if(message_out %in% use_raw_table_messages) {
        df_out <- make_data()$df1_X[,c("dateRep","cases","deaths")]
        
        names(df_out) <- c("Date Reported", "Cases","Deaths")
        
      } else if(message_out %in% use_new_expo_table_messages) {
        df_out <- make_data()$df_exp_fit[,c("dateRep","serial_day","deaths",
                                            "predict","LCL_anti_log","UCL_anti_log")]
        names(df_out) <- c("Date Reported","Serial Day","Deaths","Predicted Deaths","Lower Limit","Upper Limit")
        df_out$'Predicted Deaths' <- round(df_out$'Predicted Deaths',0)
        df_out$'Lower Limit' <- round(df_out$'Lower Limit',0)
        df_out$'Upper Limit' <- round(df_out$'Upper Limit',0)
        
      } else {
        
        df_out <- NULL
      }
      
      return(df_out)
    })
    
    output$message <- renderUI({
         h4(control_chartNEW()$message_out)
    })
       
   output$message2 <- renderUI({
        h4(control_chartNEW()$message_out)
   })
     
    output$data_table <- DT::renderDataTable({
        req(data_for_table())
       
      DT::datatable(data_for_table(),
                    rownames=FALSE)
    })
    
   
    parameters_for_table <- reactive({
      req(make_data())
      # df_no_fit <- make_data()$df1_X
      # df_fit <- make_data()$df_exp_fit
      # lm_fit <- make_data()$lm_out
      # first_death_date <- make_data()$date_cutoffs$first_death
      # exp_growth_date <- make_data()$date_cutoffs$c_chart_signal
      # c_chart_CL <- make_data()$date_cutoffs$CL
      # c_chart_UCL <- make_data()$date_cutoffs$UCL
      count_rows_fit <- nrow(make_data()$df1_X %>% filter(stage_data == "Exponential growth and fit"))
      
      df_out <- make_computation_table(nobs_raw=nrow(make_data()$df1_X),
                                       nobs_fit=nrow(make_data()$df_exp_fit),
                                       first_death_date=make_data()$date_cutoffs$first_death,
                                       c_chart_signal=make_data()$date_cutoffs$c_chart_signal,
                                       lm_fit=make_data()$lm_out,
                                       baseline_fit=min(input$baseline_n,count_rows_fit,na.rm=TRUE))
      
      
    })
    
    output$parameter_table <- DT::renderDataTable({
      req(parameters_for_table())
      
      DT::datatable(parameters_for_table(),
                    rownames=FALSE)
    })
    
    #add parameters to the calculations page
    output$parameters <- renderPrint({
        #req(make_data())
        #require conditional check: if lm object NULL then print message no linear model fitted
        #if lm_object used, then summarize the number of records used, the intercept and slope
        #possibly can show the linear plot on the log scale
        print("values from fitting a straight line by least squares to log10(deaths)")
        intercept <- make_data()$lm_out$coefficients[1]
        print(intercept)
        slope <- make_data()$lm_out$coefficients[2]
        print(slope)
        print("more stuff goes here")
        print(control_chartNEW()$message_out)
        
        
    })
    
    #download log chart
    output$download_logchart <- downloadHandler(
      filename = function() {
        sprintf('%s_%s_days_log10plot.png', input$choose_location, input$baseline_n)
      },
      content = function(file) {
        
        png(file, width = 1000, height = 600)
        print(control_chartNEW()$p_out2)
        dev.off(which=dev.cur())
      }
    )
    
    output$log_chart_tab <- renderUI({
      req(control_chartNEW()$message_out)
      
      if (control_chartNEW()$message_out == 'c-chart and exponential fit') {
        list(
          plotOutput("log_control_chart",height="500px", width="750px"),
          
          downloadButton(outputId = 'download_logchart',
                         label = 'Download Chart')
        )
      } else {
        h5('Not enough data to display log chart.')
      }
      
    })
    
 })

