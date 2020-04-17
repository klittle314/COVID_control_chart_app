library(geofacet)
library(png)
library(tidyr)

#Suggested Citation:												
  #Table 1. Annual Estimates of the Resident Population for the United States, Regions, States, and Puerto Rico: April 1, 2010 to July 1, 2019 (NST-EST2019-01)												
#Source: U.S. Census Bureau, Population Division												
#Release Date: December 2019												

library(readxl)
#you need to get table of U.S. population, this is referring to file in my local directory.  It has 2 cols:  state name and pop size
StatePopJuly2019 <- read_excel("~/COVID 2020/Provost_control_chart/StatePopJuly2019.xlsx")

#for some reason the US Census file put periods in front of each state's name so I had to remove.  '.' is a reserved character
# in strings, hence I needed to 'escape' it with backslashes.
StatePopJuly2019$State <- gsub("\\.","",StatePopJuly2019$State)

df_state0 <- df_state

names(df_state0)[2] <- "State"
df_state1 <- df_state0 %>% filter(fips <=56) #to remove the territories and Puerto Rico from the NYTimes dataset

df_state_use <- left_join(df_state1,StatePopJuly2019,by=c("State"))

df_state_use$deaths_per_ht <- 100000*df_state_use$deaths/df_state_use$Pop_July_2019

caption1 <- c('US state-level NY Times data, https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv')

ptest <- ggplot(data=df_state_use,aes(y=deaths_per_ht,x=dateRep))+
            theme_bw()+
            theme(panel.grid.minor=element_line(linetype="blank"))+
            geom_point(size=rel(0.1),shape=46,colour='blue')+
            ylab("")+
            xlab("")+
            theme(strip.text=element_text(size=6))+
            theme(axis.text.y=element_text(size=7))+
            theme(axis.text.x=element_text(size=8))+
            labs(title="New Daily Deaths per 100,000 population (July 2019 US Census estimate)",
                 caption=caption1)+
            #geom_smooth(method="loess")+
            facet_geo(~State,grid="us_state_grid2",label="name")
            
         
ptest        
caption1 <- c('US state-level NY Times data, https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv')
ptest2 <- ggplot(data=df_state_use,aes(y=deaths_per_ht,x=dateRep))+
  theme_bw()+
  #geom_point(size=rel(0.1))+
  ylab("")+
  xlab("")+
  theme(strip.text=element_text(size=7))+
  theme(axis.text.y=element_text(size=7))+
  theme(axis.text.x=element_text(size=8))+
  labs(title="New Daily Deaths per 100,000 pop",
       caption=caption1)+
  geom_smooth(method="loess")+
  facet_geo(~State,grid="us_state_grid2",label="name")
 

ptest2

head(us_state_grid2)
head(df_state_use)
