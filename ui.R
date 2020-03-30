#references for conditional view of update action button are 
#http://shiny.rstudio.com/articles/dynamic-ui.html and http://shiny.rstudio.com/articles/dynamic-ui.html
library(DT)
library(shinyBS)


shinyUI(navbarPage("COVID-19 Control Chart Application",
                   
                   tabPanel("Overview",
                            h3("Web App: HomeLAN Community Data and Display"),
                            wellPanel(
                                tags$style(type="text/css", '#leftPanel { width:200px; float:left;}'),
                                helpText("Link or other info goes here"),
                                a(href="https://www.usnews.com/news/healthiest-communities/articles/2020-03-26/coronavirus-pandemic-reaching-critical-tipping-point-in-america-analysis-shows",
                                "link to USNWR article"),
                                br(),
                                helpText("Disclaimer:  App under construction, use with caution"),
                                helpText("Questions? Contact Kevin Little, Ph.D. or other contact information"),
                                br(),
                                
                                
                                # author info
                                shiny::hr(),
                                em(
                                    span("Created by "),
                                    a("Kevin Little", href = "mailto:klittle@iecodesign.com"),
                                    span("updated 29 Mar 2020"),
                                    br(), br()
                                )
                            )
                   ),
                   tabPanel("Display",
                            
                            sidebarLayout(
                                sidebarPanel( 
                                    h3("Construct Control Chart by selecting a country"),
                                    
                                    #drop down to select the Site Type
                                    # htmlOutput("selectSiteType"),
                                    # br(),
                                    
                                    #drop down to select the Measure
                                    selectInput(
                                        inputId = 'choose_country',
                                        label = h4("Choose country to create control chart"),
                                        choices = sort(country_names),
                                        selected="United_States_of_America",
                                        width="100%"),
                                    
                                    #Numeric input for buffer
                                    # Copy the line below to make a number input box into the UI.
                                    numericInput("buffer", label = h4("Days beyond end of data series"), value = 10, min=1),
                                    
                                    br(),
                                    #Numeric input for baseline series length used to compute control limits
                                    #The default value should be chosen by code:  requires at least 8 days no more than 20
                                    numericInput("baseline_n", label = h4("Days used to compute baseline"), value = 15, min = 8, max = 30),
                                    
                                    textAreaInput(
                                      inputId = 'chart_caption',
                                      label   = h4('Add caption to chart:'),
                                      value   = '',
                                      width   = '100%')
                                    
                                ),
                                mainPanel(
                                    plotOutput("control_chart",height="500px"),
                                    
                                    downloadButton(outputId = 'download_chart',
                                                   label = 'Download Chart')
                                    
                                )
                            )
                   )
            )
)