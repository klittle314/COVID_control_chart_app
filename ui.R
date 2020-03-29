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
                                
                                br(),
                                helpText("Questions? Contact Kevin Little, Ph.D. or other contact information"),
                                br(),
                                
                                
                                # author info
                                shiny::hr(),
                                em(
                                    span("Created by "),
                                    a("Kevin Little", href = "mailto:klittle@iecodesign.com"),
                                    span("updated 28 Mar 2020"),
                                    br(), br()
                                )
                            )
                   ),
                   tabPanel("Display",
                            
                            sidebarLayout(
                                sidebarPanel( 
                                    h3("View HomeLAN Data by selecting a Measure"),
                                    
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
                                    numericInput("buffer", label = h3("Days beyond end of data series"), value = 10),
                                    
                                    br(),
                                    
                                    
                                    ),
                                mainPanel(
                                    plotOutput("control_chart",height="600px")
                                )
                            )
                   )
            )
)