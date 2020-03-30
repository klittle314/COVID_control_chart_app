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
            geom_point(size=rel(2.0),colour="blue")+
            geom_line()+
            labs(title=paste0(country_use," Daily New Deaths"), caption="Source: https://ourworldindata.org/coronavirus-source-data, 27 Mar 2020")+
            xlab("Date")+
            xlim(min(data_use$dateRep),max(data_use$dateRep)+buffer)
        
        p3 <- p0 + geom_line(data=df_cchart,aes(x=dateRep,y=predict),linetype="solid",colour="red")+
            geom_line(data=df_cchart,aes(x=dateRep,y=UCL_anti_log),linetype="dotted")+
            geom_line(data=df_cchart,aes(x=dateRep,y=LCL_anti_log),linetype="dotted")
        
        p3
        
    })
    
    output$control_chart <- renderPlot({
        print(control_chart())
    })
})