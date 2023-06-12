## check demarcation effect over formal communties
## dhemerson.costa@ipam.org.br

## load libraries
library(ggplot2)
library(sf)

## read data
data <- read.csv('./to-no-mapa-data.csv')

## get only forma cprotected areas
formal <- subset(data, territory == 'Protected Area')

## read creation date dataset
creation <- as.data.frame(read_sf('./vec/protected_areas_with_date_joined.shp'))

## join
x <- left_join(x= formal, y=creation, by=c('objectid' = 'OBJECTID'))

## insert only creation year 
formal$creation_year <- x$Ano_fim
rm(x, data)

## remove NA, 0
formal_filtered <- subset(formal, creation_year != 0)

## retain only files with at least 10 years of data before creation 
formal_filtered <- subset(formal, creation_year > 1995)

## get deforestation before and after creation 
## get protecteds areas
pa_names <- unique(formal_filtered$name)

## for each protected area
for (i in 1:length(pa_names)) {
  ## get pa x
  pa_i <- subset(formal_filtered, name == pa_names[i])
  
  ## compute changes inside and outside PAs
  for (j in 1:length(unique(pa_i$condition))) {
    ## subset per condition (within or buffer)
    pa_ij <- subset(pa_i, condition == unique(pa_i$condition)[j])
    
    ## segment into before and after
    pa_ij_before <- subset(pa_ij, year < unique(pa_ij$creation_year))
    pa_ij_after <- subset(pa_ij, year >= unique(pa_ij$creation_year))
    
    ## add temporal labels
    pa_ij_before$creation_label <- 'Before'
    pa_ij_after$creation_label <- 'After'
    
    ## get years before and after
    pa_ij_before$n_years <- length(unique(pa_ij_before$year))
    pa_ij_after$n_years <- length(unique(pa_ij_after$year))
    
    ## merge
    pa_ij <- rbind(pa_ij_before, pa_ij_after)
    rm(pa_ij_before, pa_ij_after)
    
    ## for each time-stamp (before and after)
    for (k in 1:unique(pa_ij$creation_label)) {
      
      ## get time-stamp k
      pa_ijk <- subset(pa_ij, creation_label == unique(pa_ij$creation_label)[k])
      
      ## get only native vegetation
      pa_ijk_n <- subset(pa_ijk, class_level_0 == 'Native vegetation')
      
      ## aggregate native vegetation before creation
      x <- aggregate(x= list(area= pa_ijk_n$area),
                     by= list(
                       year = pa_ijk_n$year), 
                     FUN= 'sum')
      
      ## compute native vegetation change 
      change <- subset(x, year == max(x$year))$area - subset(x, year == min(x$year))$area
      
      ## build table
      
     
      
      
    }
    
  }
  
}







