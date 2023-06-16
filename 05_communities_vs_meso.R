## check demarcation effect over formal communties
## dhemerson.costa@ipam.org.br

## load libraries
library(ggplot2)
library(sf)
library(ggrepel)
library(tools)
library(dplyr)

## avoid sci notate
options(scipen= 999)

## read data
data <- read.csv('./to-no-mapa-data.csv')

## get only forma cprotected areas
communities <- subset(data, territory == 'Community')

## get meso region raw table
meso_tab <- read.csv('./tab/areas-to-no-mapa-meso-erased.csv')

## get meso region vector (to match columns)
meso_vec <- read_sf('./vec/meso_regions.shp')

## standardize
meso_vec$CD_MESO <- as.character(meso_vec$CD_MESO)
meso_tab$CD_MESO <- as.character(meso_tab$CD_MESO)

## join
meso_tab <- as.data.frame(left_join(x= meso_tab, y= meso_vec, by= c('CD_MESO')))

## remove undesirable columns
meso_tab <- meso_tab[ , -which(names(meso_tab) %in% c("system.index",".geo", "AREA_KM2", "geometry"))]

## translate
## import mapbiomas dictionary
mapbiomas_dict <- read.csv('./dict/mapbiomas-dict-ptbr.csv', sep= ';')

## translate lulc class
## create recipe to translate mapbiomas classes
recipe <- as.data.frame(NULL)
## for each tenure id
for (l in 1:length(unique(meso_tab$class_id))) {
  ## for each unique value, get mean in n levels
  y <- subset(mapbiomas_dict, id == unique(meso_tab$class_id)[l])
  ## select matched class
  z <- subset(meso_tab, class_id == unique(meso_tab$class_id)[l])
  ## apply translation 
  z$class_level_0 <- gsub(paste0('^',y$id,'$'), y$mapb_0, z$class_id)
  z$class_level_1 <- gsub(paste0('^',y$id,'$'), y$mapb_1, z$class_id)
  z$class_level_1n <- gsub(paste0('^',y$id,'$'), y$mapb_1_2, z$class_id)
  z$class_level_2 <- gsub(paste0('^',y$id,'$'), y$mapb_2, z$class_id)
  z$class_level_3 <- gsub(paste0('^',y$id,'$'), y$mapb_3, z$class_id)
  z$class_level_4 <- gsub(paste0('^',y$id,'$'), y$mapb_4, z$class_id)
  ## bind into recipe
  recipe <- rbind(recipe, z)
}; rm(meso_tab, y, z, mapbiomas_dict)


## compuite native vegetation loss per meso region
meso_change <- as.data.frame(NULL)

for (i in 1:unique(length(recipe$NM_MESO))) {
  ## get meso i
  x <- subset(recipe, NM_MESO == unique(recipe$NM_MESO)[i])
  
  ## get native
  x <- subset(x, class_level_0 == 'Native vegetation')
  
  ## aggregate
  x <- aggregate(x=list(area= x$area), 
            by=list(NM_MESO = x$NM_MESO,
                    year= x$year,
                    SIGLA_UF = x$SIGLA_UF,
                    class_level_0 = x$class_level_0),
              FUN= 'sum')
  
  
  
  ## get first
  xi <- subset(x, year == 1985)
  ## get last
  xij <- subset(x, year == 2021)
  
  ## compute net-change
  xij$change <- xij$area - xi$area
  xij$relative_change <- round((xij$change / xi$area * 100), digits =1)
  
  ## bind
  meso_change <- rbind(meso_change, xij)
}; rm(x, xi, xij)

