
#Requirements
required_packages <- c('readxl','tidyverse',"stringr", 'ggplot2',
                       'shiny','shinyWidgets','leaflet','shinythemes',
                       'maps','mapview')

# Install missing packages
installed_packages <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!pkg %in% installed_packages) {
    install.packages(pkg)
  }
}