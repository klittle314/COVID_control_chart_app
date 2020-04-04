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
            
            'There was a problem reading your file. Please confirm that it is in CSV format, and that you selected the correct file.'
            
        } else if (!all(c('date', 'cases', 'deaths', 'location') %in% colnames(upload_data()))) {
            
            missing_cols <- setdiff(c('date', 'cases', 'deaths', 'location'), colnames(upload_data()))
            paste0('Columns missing from CSV file: ', paste0(missing_cols, collapse = ', '))
            
        } else {
            
            output$upload_confirm <- renderUI({
                
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
            
            'Data successfully uploaded and parsed.'
        }
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
        
        df_upload(data_add)
        
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
        else if (input$data_source == 'User-uploaded data')           isolate(df_upload())
    })
    
    observe({
        req(display_data()) 
        
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
        start_date1 <- input$start_date
        list_use <- make_location_data(data=data1,
                                       location_name=location_use,
                                       buffer_days=buffer,
                                       baseline=baseline1,
                                       start_date=start_date1)
        
        return(list_use)
    })
    
    control_chart <- reactive({
        location_use <- input$choose_location
        buffer <- input$buffer
        baseline1 <- input$baseline_n
        data_use <- make_data()[[1]]
        df_cchart <- make_data()[[2]]
        #lm_out <- make_data()[[3]]
        p0 <- ggplot(data=data_use,aes(x=dateRep,y=deaths_nudge))+
            theme_bw()+
            geom_point(size=rel(3.0),colour="blue")+
            geom_line()+

            labs(title=paste0(location_use," Daily New Deaths"), 
                 caption = control_chart_caption()) +
            xlab("")+

            ylab("Deaths per day")+
            xlim(min(data_use$dateRep),max(data_use$dateRep)+buffer)+
            theme(axis.text.x=element_text(size=rel(1.5)))+
            theme(axis.text.y=element_text(size=rel(1.5)))+
            theme(axis.title.x=element_text(size=rel(1)))+
            theme(axis.title.y=element_text(size=rel(1),angle=0,vjust=0.5))+
            theme(title=element_text(size=rel(1.5))) +
            theme(plot.caption = element_text(hjust = 0))
        
        p3 <- p0 + geom_line(data=df_cchart,aes(x=dateRep,y=predict),linetype="solid",colour="red")+
            geom_line(data=df_cchart,aes(x=dateRep,y=UCL_anti_log),linetype="dotted")+
            geom_line(data=df_cchart,aes(x=dateRep,y=LCL_anti_log),linetype="dotted")
        
        #retrict to the values used in the linear fit to plot the log chart
        df_cchart1 <- df_cchart %>% filter(serial_day <= baseline1)
        
        p_log <- ggplot(data=df_cchart1,aes(x=dateRep,y=log_count_deaths))+
                theme_bw()+
                geom_point(size=rel(2.5),colour="blue")+
                geom_line()+
                labs(title=paste0(location_use,"Log10 Daily New Deaths"),
                     subtitle="Limits based on Individuals Shewhart chart calculations using regression residuals")+
                ylab("Log10(Deaths)")+
                xlab("")+
                theme(axis.title.y=element_text(angle=0,vjust=0.5))+
                geom_line(data=df_cchart1,aes(x=dateRep,y=lm_out.fitted.values))+
                geom_line(data=df_cchart1,aes(x=dateRep,y=UCL),linetype="dotted")+
                geom_line(data=df_cchart1,aes(x=dateRep,y=LCL),linetype="dotted")
                
                
        
        return(list(p0,p3,p_log))
        
    })
    
    output$control_chart <- renderPlot({
        #FIX REQUIRED 4/2/2020
        #put conditional test:  plot just the data and message about short series, object control_chart()[[1]]
        #if series OK, then display control_chart()[[2]]
        #if no data, print message
        print(control_chart()[[2]])
    })
    
    output$log_control_chart <- renderPlot({
        #FIX REQUIRED 4/2/2020
        #put conditional test:  plot just the data and message about short series, object control_chart()[[1]]
        #if series OK, then display control_chart()[[2]]
        #if no data, print message
        print(control_chart()[[3]])
    })
    
    output$download_chart <- downloadHandler(
        filename = function() {
            sprintf('%s_%s_days.png', input$choose_location, input$baseline_n)
        },
        content = function(file) {
            
            png(file, width = 1000, height = 600)
                print(control_chart())
            dev.off(which=dev.cur())
        }
    )
    
    output$data_table <- DT::renderDataTable({
        req(make_data())
       #df_out <- make_data()[[2]][,c(1,2,3,9,11,10)]
        df_out <- make_data()[[2]][,c("dateRep","serial_day","deaths",
                                      "predict","LCL_anti_log","UCL_anti_log")]
        names(df_out) <- c("Date Reported","Serial Day","Deaths","Predicted Deaths","Lower Limit","Upper Limit")
        df_out$'Predicted Deaths' <- round(df_out$'Predicted Deaths',0)
        df_out$'Lower Limit' <- round(df_out$'Lower Limit',0)
        df_out$'Upper Limit' <- round(df_out$'Upper Limit',0)
        DT::datatable(df_out,
                      rownames=FALSE)
    })
    
    #add parameters to the calculations page
    output$parameters <- renderPrint({
        req(make_data())
        #require conditional check: if lm object NULL then print message no linear model fitted
        #if lm_object used, then summarize the number of records used, the intercept and slope
        #possibly can show the linear plot on the log scale
        print("values from fitting a straight line by least squares to log10(deaths)")
        intercept <- make_data()[[3]][[1]][1]
        print(intercept)
        slope <- make_data()[[3]][[1]][2]
        print(slope)
        print("more stuff goes here")
        
        
    })
    
 })
