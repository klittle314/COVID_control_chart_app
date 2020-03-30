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

 
    control_chart <- reactive({
        country_use <- input$choose_country
        buffer <- input$buffer
        baseline1 <- input$baseline_n
        df <- df1
        list_use <- make_country_data(data=df,
                                      country_name=country_use,
                                      buffer_days=buffer,
                                      baseline=baseline1)
        data_use <- list_use[[1]]
        df_cchart <- list_use[[2]]
        lm_out <- list_use[[3]]
        
        p0 <- ggplot(data=data_use,aes(x=dateRep,y=deaths_nudge))+
            theme_bw()+
            geom_point(size=rel(3.0),colour="blue")+
            geom_line()+
            labs(title=paste0(country_use," Daily New Deaths"), 
                 caption = sprintf('%s\n\nSource: https://opendata.ecdc.europa.eu/covid19/casedistribution/csv, %s',
                                   input$chart_caption,
                                   as.character(Sys.Date()))) +
            xlab("Date")+
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
        
        p3
        
    })
    
    output$control_chart <- renderPlot({
        print(control_chart())
    })
    
    output$download_chart <- downloadHandler(
        filename = sprintf('%s_%s_days.png', input$choose_country, input$baseline_n),
        content = function(file) {
            
            png(file, width = 1000, height = 600)
                print(control_chart())
            dev.off(which=dev.cur())
        }
    )
})