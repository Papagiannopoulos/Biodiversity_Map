## R Shiny - Biodiversity dashboard assignment (2021) 

#### Aim: Build a Shiny app that visualizes Poland’s observed species on the map and their frequency.

Description: The data were used was biodiversity dataset from the Global Biodiversity Information Facility (available here). After loading the data (line: 14), the first step was to perform data processing were:
1)	Removed extra rows with the same scientific name, latitudes, longitudes and event date (lines: 18-19).
2)	Kept only necessary features (line: 20).
3)	Replaced missing values of Vernacular Name and Kingdom with informative string values (line: 23-34).
4)	Performed feature engineering (line: 25-27).
5)	Created necessary values for the shinyapp (lines: 29-31). 

The second step was to create the app using Shiny package.
First, tab will visualize an interactive map, while the second tab should give a brief description for every species selection regarding their timelines, counts, locations and event dates. In both tabs will be three search bars (Two with Scientific and Vernacular name search; One with location search).
Users should be able to search for species by their Vernacular Name and Scientific Name, while description table should react with the correspoding location search. Search field should return matching names and after selection the app displays its observations on the map (first tab) giving a brief description (second tab).

Classical figures were constructed using “ggplot” and the interactive map using “mapview” package. All analysis were performed using R version 4.4.1 (2024-06-14 ucrt) in Windows environment.

#### Executing program
The code exists on github (Papagiannopoulos/Biodiversity_data) while the app is in the shinyapps.io (https://cpapagiannopoulos.shinyapps.io/Poland_biodiversity/ ).

#### Reproducibility
Users who would like to rerun the process should download the code and biodiversity data. Then should align the code with the path where the biodiversity data exists in their folders. Finally, install every package that weren’t before and run the code.
