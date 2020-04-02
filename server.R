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
    
    data <- reactiveVal(value = df1)

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
        
        data(dplyr::bind_rows(data(), data_add))
        
        updateSelectInput(
            session = session,
            inputId = 'choose_country',
            choices = sort(unique(isolate(data()$countriesAndTerritories))))
        
        output$upload_confirm <- renderUI({
            list(
                tags$br(),
                
                h4('Data successfully added. Switch to Display tab to view.'))
        })
    })
    
    control_chart <- reactive({
        country_use <- input$choose_country
        buffer <- input$buffer
        baseline1 <- input$baseline_n
        start_date1 <- input$start_date
        list_use <- make_country_data(data=data(),
                                      country_name=country_use,
                                      buffer_days=buffer,
                                      baseline=baseline1,
                                      start_date=start_date1)
        data_use <- list_use[[1]]
        df_cchart <- list_use[[2]]
        lm_out <- list_use[[3]]
        
        # #choose caption depending on source
        # if(is.null(isolate(upload_message()))){
        #     caption1 <- sprintf('%s\n\nSource: https://opendata.ecdc.europa.eu/covid19/casedistribution/csv, %s',
        #                         input$chart_caption,
        #                         as.character(Sys.Date()))
        # } else caption1 <- paste0("My local file")
        # 
        caption1 <- sprintf('%s\n\nSource: https://opendata.ecdc.europa.eu/covid19/casedistribution/csv, %s',
                            input$chart_caption,
                            as.character(Sys.Date()))
        
        p0 <- ggplot(data=data_use,aes(x=dateRep,y=deaths_nudge))+
            theme_bw()+
            geom_point(size=rel(3.0),colour="blue")+
            geom_line()+
            labs(title=paste0(country_use," Daily New Deaths"), 
                 caption = caption1) +
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
            sprintf('%s_%s_days.png', input$choose_country, input$baseline_n)
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
