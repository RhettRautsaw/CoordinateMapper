#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(leaflet.extras)
library(leaflet.extras2)
library(htmltools)
library(RColorBrewer)

#brPal <- colorRampPalette(c("#543005","#8C510A","#BF812D","#DFC27D","#F6E8C3","#F5F5F5","#C7EAE5","#80CDC1","#35978F","#01665E","#003C30"))
brPal <- colorRampPalette(brewer.pal(8,"Dark2"))
pal <- brPal(255)

# Define UI for application that draws a histogram
ui <- navbarPage("Coordinate Mapper", id="nav",

    tabPanel("Interactive Map",
        div(class="outer",
            # Include custom styles and javascript
            tags$head(includeCSS("styles.css"), includeScript("gomap.js")),
            # If not using custom CSS, set height of leafletOutput to a number instead of percent
            leafletOutput("map", width="100%", height="100%"),
            
            absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                width = 550, style = "overflow-y: scroll;",
                
                h3("Input Data"),
                textAreaInput(inputId = "data", label = h5("Sample\tCategory\tLatitude\tLongitude"), width='500px', height='500px',
                    value = paste0("KW1547\tAgkistrodon_conanti\t28.2663\t-82.5496\nAp07\tAgkistrodon_piscivorus_leucostoma\t31.5337\t-92.5046")),
                
                actionButton("update", "Update"),
            )
        )
    )
)


# Server
server<-function(input, output, session) {
    
    output$map<-renderLeaflet({
        leaflet() %>% 
            addProviderTiles(providers$Esri.WorldTerrain, group="Terrain") %>%
            addProviderTiles(providers$Esri.WorldStreetMap, group="Open Street Map") %>%
            addWMSTiles('http://ows.mundialis.de/services/service?', layers='TOPO-WMS', group="Topography") %>%
            addProviderTiles(providers$Esri.WorldImagery, group="Satellite") %>%
            addTiles(
              urlTemplate = "https://tiles.stadiamaps.com/tiles/{variant}/{z}/{x}/{y}{r}.png?api_key={apikey}",
                attribution = paste(
                  '&copy; <a href="https://stadiamaps.com/" target="_blank">Stadia Maps</a> ' ,
                  '&copy; <a href="https://stamen.com/" target="_blank">Stamen Design</a> ' ,
                  '&copy; <a href="https://openmaptiles.org/" target="_blank">OpenMapTiles</a> ' ,
                  '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>'),
                group="Boundaries",
                options = tileOptions(variant='stamen_toner_lines', apikey = '743f0610-5457-407d-8120-245f3252c7ff')
            ) %>%
            addTiles(
              urlTemplate = "https://tiles.stadiamaps.com/tiles/{variant}/{z}/{x}/{y}{r}.png?api_key={apikey}",
                attribution = paste(
                  '&copy; <a href="https://stadiamaps.com/" target="_blank">Stadia Maps</a> ' ,
                  '&copy; <a href="https://stamen.com/" target="_blank">Stamen Design</a> ' ,
                  '&copy; <a href="https://openmaptiles.org/" target="_blank">OpenMapTiles</a> ' ,
                  '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>'),
                group="Labels",
                options = tileOptions(variant='stamen_toner_labels', apikey = '743f0610-5457-407d-8120-245f3252c7ff')
            ) %>%
            #addProviderTiles(providers$Stadia.StamenTonerLines, group="Boundaries") %>%
            #addProviderTiles(providers$Stadia.StamenTonerLabels, group="Labels") %>%
            addLayersControl(
                baseGroups=c("Terrain","Open Street Map","Topography", "Satellite"),
                overlayGroups=c("Boundaries","Labels"),
                options=layersControlOptions(collapsed=F, position="bottomleft")
            ) %>%
            hideGroup(c("Labels")) %>%
            addScaleBar(position = c("topleft"), options = scaleBarOptions()) %>% 
            addEasyprint(options=easyprintOptions(exportOnly = T, sizeModes = list("A4Landscape")))
    })
    
    observeEvent(input$update, {
        pointsData<-read.table(text=input$data, header=FALSE, sep="\t", col.names = c("Sample","Category","Latitude","Longitude"))
        
        sp_factpal<-colorFactor(pal,levels=sort(unique(pointsData$Category)), ordered=T, reverse=T)
        
        leafletProxy("map")%>%
            clearMarkers() %>% clearGroup("points") %>%
            addCircleMarkers(data=pointsData,
                             lng=~as.numeric(Longitude),
                             lat=~as.numeric(Latitude),
                             radius = 8,
                             color = ~sp_factpal(Category),
                             stroke = T, fillOpacity = 0.8,
                             #clusterOptions = markerClusterOptions(),
                             label = ~htmlEscape(Sample),
                             group = "points") %>%
            addLegend(position = "topleft", pal=sp_factpal, values = sort(unique(pointsData$Category)), layerId = "points") %>%
            fitBounds(min(pointsData$Longitude, na.rm = T)-1,
                      min(pointsData$Latitude, na.rm =T)-1,
                      max(pointsData$Longitude, na.rm =T)+5,
                      max(pointsData$Latitude, na.rm =T)+1)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
