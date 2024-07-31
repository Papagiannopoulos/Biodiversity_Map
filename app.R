
#Sys.setenv(LANG = "en")
Sys.setlocale("LC_TIME", "English")
#Libraries
library(shiny); library(shinydashboard); library(shinyWidgets); library(shinythemes); library(shinyjs); library(leaflet)
library(maps); #library(mapproj)
library(data.table); library(R.utils); library(readxl)
library(stringr)
library(tidyverse)
library(mapview); library(sf);
#library(countrycode)

#Import data
PL <- read_excel("Poland.xlsx")

##Data Processing
#To skip time avoid noise - Remove rows with same Scientific Name lat-long and event date
PL$key <- paste0(PL$scientificName,":",PL$latitudeDecimal,":",PL$longitudeDecimal,":",PL$eventDate)

#sum(table(PL$key)[table(PL$key) > 1])
PL <- PL[!duplicated(PL$key),]
PL <- PL[,match(c("id","occurrenceID", "scientificName", "vernacularName", "country","individualCount","lifeStage","kingdom",
                  "sex","longitudeDecimal","latitudeDecimal", "locality","eventDate"), names(PL))]

PL$vernacularName[is.na(PL$vernacularName)] <- paste0("No Vernacular Name Info ", PL$scientificName[is.na(PL$vernacularName)])
PL$kingdom[is.na(PL$kingdom)] <- "Uknown"
PL$locality <- str_remove_all(PL$locality, paste0(PL$country," - "))
PL$eventDate <- as.Date(PL$eventDate)
PL <- PL %>% arrange(scientificName, country, eventDate)

scientificName_init <- unique(PL$scientificName)
vernacularName_init <- unique(PL$vernacularName)
locations_init <- unique(sort(PL$locality))

#Create descriptive table for Shiny
data <- PL %>% group_by(locality,scientificName) %>% summarise("Vernacular Name" = unique(vernacularName),
                                                               "First Observed Date" = format(min(eventDate),"%d-%b-%Y"), "Last Observed Day" = format(max(eventDate),"%d-%b-%Y"),
                                                       "Minimun Observed Count" = min(individualCount), "Max Observed Count" = max(individualCount),
                                                       Kingdom = unique(kingdom))
#Create World Map
wmap <- map_data("world")
wmap <- wmap[wmap$region %in% "Poland",] 
worldplot <- ggplot()+
  geom_polygon(data=wmap, aes(x=long, y=lat, group = group), fill = "lightblue3")+
  coord_fixed(1.3)

#Create Shinny App
#Frontend
ui <- fluidPage(theme = shinytheme("united"),
  sidebarLayout(
    sidebarPanel(width = 2,
                 #Search Scientific Name
                 pickerInput("scientificName", "Scientific Name", choices = scientificName_init,
                             multiple = F,selected = scientificName_init[16],
                             options=pickerOptions(liveSearch=TRUE,liveSearchNormalize=TRUE,
                                                   liveSearchStyle="contains",
                                                   noneResultsText="No results found")),
                 #Search Vernacular Name
                 pickerInput("vernacularName","Vernacular Name",choices = vernacularName_init,
                             multiple = F, selected = unique(PL$vernacularName[PL$scientificName %in% scientificName_init[16]]),
                             options=pickerOptions(liveSearch=TRUE,liveSearchNormalize=TRUE,
                                                   liveSearchStyle="contains",
                                                   noneResultsText="No results found")),
                 pickerInput("location", "Location", choices = locations_init,
                             multiple = T, options=pickerOptions(liveSearch=TRUE,liveSearchNormalize=TRUE,
                                                   liveSearchStyle="contains",
                                                   noneResultsText="No results found"))), 
    mainPanel(width=10,fluidRow(tabsetPanel(tabPanel("Poland - Map of Biodiversity", uiOutput("headfoot_dynamic_map"),leafletOutput("dynamic_map", width = "99%", height = "780px")),
                                            tabPanel("Description",splitLayout(cellWidths = c("30%", "60%"),
                                                                               plotOutput("small_map"), plotOutput("TimeLines")),
                                                     uiOutput("text"),tableOutput("TimeTable"))))
              )
    )
)
#fluidRow(tabsetPanel(tabPanel("Map",plotOutput("Map"),textOutput("text")),tabPanel("Time Series", plotOutput("TimeLines"))))

#Back-end
server <- function(input, output, session){
  
  #update name search methods (for figures) Scientific Name
  observeEvent(input$scientificName,{
    choice1 <- unique(PL$vernacularName[PL$scientificName %in% input$scientificName])
    updatePickerInput(session=session,
                      inputId = "vernacularName",label="Vernacular Name",
                      choices = vernacularName_init,
                      selected = choice1[1], clearOptions=F)
  }, ignoreInit = T, ignoreNULL = FALSE)
  
  #update name search methods (for figures) Vernacular
  observeEvent(input$vernacularName,{
    choice1 <- unique(PL$scientificName[PL$vernacularName %in% input$vernacularName])
    updatePickerInput(session=session,
                      inputId = "scientificName",label="Scientific Name",
                      choices = scientificName_init,
                      selected = choice1[1], clearOptions=F)
  }, ignoreInit = T, ignoreNULL = FALSE)
  
  #update name search methods (for Table)
  observeEvent(input$scientificName,{
    choice1 <- unique(PL$locality[PL$scientificName %in% input$scientificName])
    updatePickerInput(session=session,
                      inputId = "location",label="Location",
                      choices = choice1,
                      selected = choice1, clearOptions=T)
  }, ignoreInit = F, ignoreNULL = FALSE)
  
  R1 <- reactive({list(input$scientificName)})
  
  #Head foot of Interactive map
  output$headfoot_dynamic_map <- renderUI({
    tagList(unique(PL$country),"'s map presenting observed species from ",format(min(PL$eventDate),"%d-%b-%Y"),
            " to ", format(max(PL$eventDate),"%d-%b-%Y"),".",br(),
            "Data are from ",a("Global Biodiversity Information Facility.", href = "https://www.gbif.org/"),
            br(), br())
  }) 
  #Interactive Map Plot
  observeEvent(R1(), {
    PL_temp <- PL[(PL$scientificName %in% input$scientificName),]
    
    output$dynamic_map <- renderLeaflet({
      map <- mapview(PL_temp, xcol = "longitudeDecimal", ycol = "latitudeDecimal", crs = 4326, grid = FALSE, alpha = 0.5, zcol = "individualCount",
              color = "black", #col.regions = "pink", 
              legend = T,#at = unique(c(seq(0,10,5),seq(0,100,25),seq(0,10^3, 500), seq(0,10^4, 5000))), 
              map.types = mapviewGetOption("basemaps")[c(3,1,2,4,5)], layer.name = "Number of Counts")
      map@map
      #mapview2leaflet(map@map)
    })
  })
  
  #Map2 plot (Small map)
  observeEvent(R1(), {
    PL_temp <- PL[(PL$scientificName %in% input$scientificName),]
    output$small_map <- renderPlot({
      worldplot + geom_point(data = PL_temp, aes(x = longitudeDecimal, y = latitudeDecimal,
                                                 size = individualCount),#, color = locality),
                             color = "red") + theme_void() +labs(size = "Counts")
    })
  })
  
  #Time plot
  observeEvent(R1(), {
    PL_temp <- PL[(PL$scientificName %in% input$scientificName),]
    
    output$TimeLines <- renderPlot({
      ggplot(data = PL_temp, aes(x=eventDate, y=individualCount)) + 
        geom_point(size=5, color = "red3") + geom_smooth(se = F, stat = "smooth", lwd = 2, col = "black")+
        labs(x="", y="Number of Total Counts",
             title = paste0(input$scientificName, "'s time plot. Each dot is the number of counts at the respective date.
                            Black line (occures for >1 dots) presents the average count change throw the event years")) + 
        theme_classic()+scale_y_continuous(breaks = seq(0,max(PL_temp$individualCount),ifelse(max(PL_temp$individualCount) <= 10,1,floor(max(PL_temp$individualCount)/10))),
                                           limits = c(0,max(PL_temp$individualCount)*1.5))+
        theme(axis.text = element_text(size = 12, face = "bold"), axis.title = element_text(size = 12))
    })
  })
  
  R2 <- reactive({list(input$scientificName, input$location)})
  #Descriptive table
  observeEvent(R2(), {
    PL_temp <- data[((data$scientificName %in% input$scientificName)),]
    PL_temp <- arrange(PL_temp, locality)
    PL_temp <- PL_temp[PL_temp$locality %in% input$location,]
    
    output$TimeTable <- renderTable({
      PL_temp[,-match(c("scientificName","Vernacular Name"),names(PL_temp))]
    })
  })
  
  #Text Output ()
  observeEvent(R1(), {
    PL_temp <- PL[(PL$scientificName %in% input$scientificName),]
    text_dates <- ifelse(nrow(PL_temp) == 1,paste0("on ", format(max(PL_temp$eventDate),"%d-%b-%y"),"."),
                    paste0("from ",format(min(PL_temp$eventDate),"%d-%b-%y"),
                            " to ", format(max(PL_temp$eventDate),"%d-%b-%y"),"."))
    
    text_locations <- ifelse(length(unique(PL_temp$locality)) == 1, paste0(length(unique(PL_temp$locality)), " location"),
                    paste0(length(unique(PL_temp$locality)), " different locations"))
    
    location_observed <- unique(PL_temp$locality[which(PL_temp$individualCount %in% max(PL_temp$individualCount))])
    text_location_observed_max_count <- paste0(1:length(location_observed),") ",location_observed, collapse = ", ")
    
    output$text <- renderUI({
      tagList(br(),br(),h6(strong("Brief Description:")),
              "In the above map is presented ", strong(input$scientificName, style = "color:red; font-family:times")," (or ",
              strong(input$vernacularName, style = "color:red; font-family:times"), ").", br(),
              input$scientificName, " belongs to ", strong(paste0(PL_temp$kingdom[1]," kingdom")), " and have been observed in Poland in ", strong(text_locations), " ", strong(text_dates), br(), 
              "The highest counts were observed in", strong(text_location_observed_max_count), "and were ", strong(max(PL_temp$individualCount))," .",br(),
              " Attached (table) is presented a brief location-stratified information.",br(),
              "More related for ", input$scientificName, " can be found elsewere: ", a(PL_temp$occurrenceID[1], href = PL_temp$occurrenceID[1]),br(),
              "Data are from ",a("Global Biodiversity Information Facility.", href = "https://www.gbif.org/"),br(),
              "Latest update: 30-Jul-24",br(),br(),br())
      
    })
  })
}

#Run App
shinyApp(ui = ui, server = server)
                       