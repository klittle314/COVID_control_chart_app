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
    
    control_chart <- reactive({
        location_use <- input$choose_location
        buffer <- input$buffer
        baseline1 <- input$baseline_n
        start_date1 <- input$start_date
        list_use <- make_location_data(data=display_data(),
                                      location_name=location_use,
                                      buffer_days=buffer,
                                      baseline=baseline1,
                                      start_date=start_date1)
        data_use <- list_use[[1]]
        df_cchart <- list_use[[2]]
        lm_out <- list_use[[3]]
        
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
        
        return(list(p3,df_cchart))
        
    })
    
    output$control_chart <- renderPlot({
        print(control_chart()[[1]])
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
        req(control_chart())
        df_out <- control_chart()[[2]][,c(1,2,3,9,11,10)]
        names(df_out) <- c("Date Reported","Serial Day","Deaths","Predicted Deaths","Lower Limit","Upper Limit")
        df_out$Deaths <- 10^df_out$Deaths
        df_out$'Predicted Deaths' <- round(df_out$'Predicted Deaths',0)
        df_out$'Lower Limit' <- round(df_out$'Lower Limit',0)
        df_out$'Upper Limit' <- round(df_out$'Upper Limit',0)
        DT::datatable(df_out,
                      rownames=FALSE)
    })
    
 })
