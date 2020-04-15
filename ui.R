#references for conditional view of update action button are 
#http://shiny.rstudio.com/articles/dynamic-ui.html and http://shiny.rstudio.com/articles/dynamic-ui.html
library(DT)
library(shinyBS)


shinyUI(navbarPage("COVID-19 Control Chart Application",
                   
                   tabPanel("Overview",
                            h3("Web App: COVID-19 Visualization"),
                            wellPanel(
                                tags$style(type="text/css", '#leftPanel { width:200px; float:left;}'),
                                
                                helpText("U.S. News and World Report 3-26-2020 uses the method implemented here"),
                                
                                a(href="https://www.usnews.com/news/healthiest-communities/articles/2020-03-26/coronavirus-pandemic-reaching-critical-tipping-point-in-america-analysis-shows",
                                "click to link to USNWR article"),
                                br(),
                                
                                helpText("Disclaimer:  App under construction, use with caution"),

                                helpText("attributes of graphs and calculations need formatting effort"),


                                helpText("Questions? Contact Kevin Little, Ph.D."),
                                br(),
                                
                                
                                # author info
                                shiny::hr(),
                                em(
                                    span("Created by "),
                                    a("Kevin Little", href = "mailto:klittle@iecodesign.com"),

                                    span("updated 14 April 2020  9:45pm CDT"),

                                    br(), br(),
                                
                                ),
                                
                                #NYTimes attribution language
                                helpText("U.S. data from from The New York Times, based on reports from state and local health agencies."),
                                a(href="https://www.nytimes.com/interactive/2020/us/coronavirus-us-cases.html", 
                                  "click to link to NYTimes U.S. tracking page")
                            )
                   ),
                   
                   tabPanel('Upload Data',
                     
                     h4('To upload your own data series, please create a CSV file with the following column names (case sensitive):'),
                     
                     tags$ul(
                       tags$li('date (MM/DD/YYYY format)'),
                       tags$li('cases'),
                       tags$li('deaths'),
                       tags$li('location'),
                     br(),
                     helpText('The current code will not handle NA values in the death series.  Zero values are fine.')
                     ),
                     
                     h5('Click',
                        tags$a('here', 
                               href = 'https://support.office.com/en-us/article/Import-or-export-text-txt-or-csv-files-5250ac4c-663c-47ce-937b-339e391393ba',
                               target = '_blank'),
                        'for help creating a CSV file in Excel.'),
                     
                     tags$br(),
                     
                     fileInput(
                       inputId = 'upload_data',
                       label   = 'Select data:',
                       accept  = c('text/csv', '.csv')),
                     
                     uiOutput('upload_message'),
                     
                     uiOutput('upload_confirm')
                     
                   ),
                   
                   tabPanel("Display",
                            
                            sidebarLayout(
                                sidebarPanel( 
                                    width=3,
                                    
                                    h4("Build a control chart by choosing location and adjusting options"),
                                    
                                    selectInput(
                                      inputId = 'data_source',
                                      label   = h5('Choose data source'),
                                      choices = c('US state-level NY Times data',
                                                  'Country-level ECDC data',
                                                  'User-uploaded data'),
                                      selected = 'Country-level ECDC data'),
                                    
                                    #drop down to select the Site Type
                                    # htmlOutput("selectSiteType"),
                                    # br(),
                                    
                                    #drop down to select the location
                                    selectInput(
                                        inputId  = 'choose_location',
                                        label    = h5("Choose location"),
                                        choices  = sort(country_names),
                                        selected = "United_States_of_America",
                                        width    = "100%"),
                                    
                                    #Numeric input for buffer
                                    # 
                                    numericInput("buffer", label = h5("Days beyond end of data series: extend curve and limits"), value = defBuffer, min=1),
                                    
                                    #br(),
                                    #Numeric input for baseline series length used to compute control limits
                                    #The default value should be chosen by code:  requires at least 8 days no more than 20
                                    numericInput("baseline_n", label = h5("Maximum days used to compute exponential growth line and limits"), value = defBaseline, min = 8),
                                    helpText(h6("If there are fewer days in the data series than the maximum, app calculates using all the data.")),
                                   #br(),
                                    
                                    # Checkbox that if checked, constrains control chart y-axis to the range of observed death counts, instead of the 
                                    # range of the projections. Helps view data series for countries with enough data that projections dominate
                                    # the observed series.
                                    checkboxInput(
                                      inputId = 'constrain_y_axis',
                                      label   = h5('Constrain y-axis limits to observed data (instead of projections)'),
                                      value   = TRUE),
                                    
                                    #Input date that marks the start of the limit calculations
                                    dateInput("start_date",label=h5("Custom start date for calculations instead of date of first death"),value=defStartdate),
                                    helpText(h6("Leave blank to allow the start date to be determined as date of first reported death")),
                                    #helpText(h6("The starting date 2019-12-31 tells the app to use all the available data.")),
                                    helpText(h6("You can choose a date after start of the series to focus the graph and calculations on a shorter date range.")),
                                   
                                   actionButton("reset", "Reset Defaults"),
                                   
                                    textAreaInput(
                                      inputId = 'chart_caption',
                                      label   = h5('Add caption to chart to comment on the data quality or implications'),
                                      value   = '',
                                      width   = '100%'),
                                   helpText(h6("Caption will be included in the downloaded image of the chart."))
                                    
                                ),
                                mainPanel(
                                  tabsetPanel(id = 'display-tab',type='tabs',  
                                    tabPanel("Basic Chart",
                                              
                                    uiOutput("message"),  
                                    
                                    plotOutput("control_chart",height="500px"),
                                             
                                    downloadButton(outputId = 'download_chart',
                                                   label = 'Download Chart'),
                                    
                                    tags$hr(),
                                    
                                   
                                    DT::dataTableOutput('data_table')
                                    ),
                                  tabPanel("Calculation Details",
                                           h4("explanation goes here with parameters"),
                                           h6("linear fit parameters to log deaths"),
                                           textOutput("parameters"),
                                           plotOutput("log_control_chart",height="300px"),
                                           
                                  downloadButton(outputId = 'download_logchart',
                                                 label = 'Download Chart')
                                           
                                    )
                                  )
                                )
                            )
                   )
            )
)