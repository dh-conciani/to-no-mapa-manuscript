## translate tables from gee to a readable structure

## read libraries
library(sf)
library(dplyr)

## avoid sci notes
options(scipen= 9e3)

## read table
data <- read.csv('./tab/areas-to-no-mapa.csv')

## import mapbiomas dictionary
mapbiomas_dict <- read.csv('./dict/mapbiomas-dict-ptbr.csv', sep= ';')

## remove undesirable columns (gee residuals)
data <-  data[ , -which(names(data) %in% c("system.index",".geo"))]

## translate condition (within or buffer)
data$condition <- gsub(1, 'Within', 
                       gsub(2, 'Buffer zone', data$condition))

## translate lulc class
## create recipe to translate mapbiomas classes
recipe <- as.data.frame(NULL)
## for each tenure id
for (l in 1:length(unique(data$class_id))) {
  ## for each unique value, get mean in n levels
  y <- subset(mapbiomas_dict, id == unique(data$class_id)[l])
  ## select matched class
  z <- subset(data, class_id == unique(data$class_id)[l])
  ## apply translation 
  z$class_level_0 <- gsub(paste0('^',y$id,'$'), y$mapb_0, z$class_id)
  z$class_level_1 <- gsub(paste0('^',y$id,'$'), y$mapb_1, z$class_id)
  z$class_level_1n <- gsub(paste0('^',y$id,'$'), y$mapb_1_2, z$class_id)
  z$class_level_2 <- gsub(paste0('^',y$id,'$'), y$mapb_2, z$class_id)
  z$class_level_3 <- gsub(paste0('^',y$id,'$'), y$mapb_3, z$class_id)
  z$class_level_4 <- gsub(paste0('^',y$id,'$'), y$mapb_4, z$class_id)
  ## bind into recipe
  recipe <- rbind(recipe, z)
}; rm(data, y, z, mapbiomas_dict)

## read shapefile (to get names)
vec <- as.data.frame(read_sf('./vec/AP_MesoRegiao.shp'))

## get only interest colums
vec <- vec %>% select('OBJECTID', 'nome_uc', 'esfera', 'grupo', 'categoria', 'NM_MESO', 'SIGLA_UF')

## join tables
x <- left_join(x= recipe, y= vec, by= c('objectid' = 'OBJECTID'))

## exportar
write.csv(x, './to-no-mapa.csv')
