## translate tables from gee to a readable structure

## read libraries
library(sf)
library(dplyr)

## avoid sci notes
options(scipen= 9e3)

######################## join protected areas table ##############################
## read table
protected_areas <- read.csv('./tab/col_8/protected-areas-lulcc.csv')

## insert territory type
protected_areas$territory <- 'Protected Area'

## read protected areas shapefile
vec <- as.data.frame(read_sf('./vec/new/toAssses/protected_areas_Assess.shp'))

## get only interest colums
vec <- vec %>% select('Ano_fim', 'NOME', 'Categoria', 'ID', 'NM_MESO')

## join tables
protected_areas <- na.omit(left_join(x= protected_areas, y= vec, by= c('objectid' = 'ID')))

## remove undesirable columns (gee residuals)
protected_areas <-  protected_areas[ , -which(names(protected_areas) %in% c("system.index",".geo"))]

## translate condition (within or buffer)
protected_areas$condition <- gsub(1, 'Within', 
                                gsub(2, 'Buffer zone', protected_areas$condition))

## translate mapbiomas classes
mapbiomas_dict <- read.csv('./dict/mapbiomas-dict-en-col8.csv', sep= ';')

## translate lulc class
## create recipe to translate mapbiomas classes
recipe <- as.data.frame(NULL)
## for each tenure id
for (i in 1:length(unique(protected_areas$class_id))) {
  ## for each unique value, get mean in n levels
  y <- subset(mapbiomas_dict, id == unique(protected_areas$class_id)[i])
  ## select matched class
  z <- subset(protected_areas, class_id == unique(protected_areas$class_id)[i])
  ## apply translation 
  z$class_level_0 <- gsub(paste0('^',y$id,'$'), y$mapb_0, z$class_id)
  z$class_level_1 <- gsub(paste0('^',y$id,'$'), y$mapb_1, z$class_id)
  z$class_level_1n <- gsub(paste0('^',y$id,'$'), y$mapb_1_2, z$class_id)
  z$class_level_2 <- gsub(paste0('^',y$id,'$'), y$mapb_2, z$class_id)
  z$class_level_3 <- gsub(paste0('^',y$id,'$'), y$mapb_3, z$class_id)
  z$class_level_4 <- gsub(paste0('^',y$id,'$'), y$mapb_4, z$class_id)
  ## bind into recipe
  recipe <- rbind(recipe, z)
}; rm(y, z)

## export table
write.csv(recipe, './toRead/protected-areas.csv')


##################### join communities table ##################################
communities <- read.csv('./tab/col_8/communities-lulcc.csv')

## insert territory type
communities$territory <- 'Community'

## read communities shapefile
vec <- as.data.frame(read_sf('./vec/communities.shp'))

## selecy only desired columns
vec <- vec %>% select('id_12', 'NM_MESO', 'SIGLA_UF', 'Comunidade')

## join tables
communities <- left_join(x= communities, y= vec, by= c('objectid' = 'id_12'))

## empty temp files
rm(vec)

## remove undesirable columns (gee residuals)
communities <-  communities[ , -which(names(communities) %in% c("system.index",".geo"))]

## translate condition (within or buffer)
communities$condition <- gsub(1, 'Within', 
                                gsub(2, 'Buffer zone', communities$condition))

## translate lulc class
## create recipe to translate mapbiomas classes
recipe <- as.data.frame(NULL)
## for each tenure id
for (i in 1:length(unique(communities$class_id))) {
  ## for each unique value, get mean in n levels
  y <- subset(mapbiomas_dict, id == unique(communities$class_id)[i])
  ## select matched class
  z <- subset(communities, class_id == unique(communities$class_id)[i])
  ## apply translation 
  z$class_level_0 <- gsub(paste0('^',y$id,'$'), y$mapb_0, z$class_id)
  z$class_level_1 <- gsub(paste0('^',y$id,'$'), y$mapb_1, z$class_id)
  z$class_level_1n <- gsub(paste0('^',y$id,'$'), y$mapb_1_2, z$class_id)
  z$class_level_2 <- gsub(paste0('^',y$id,'$'), y$mapb_2, z$class_id)
  z$class_level_3 <- gsub(paste0('^',y$id,'$'), y$mapb_3, z$class_id)
  z$class_level_4 <- gsub(paste0('^',y$id,'$'), y$mapb_4, z$class_id)
  ## bind into recipe
  recipe <- rbind(recipe, z)
}; rm(y, z)

## export table
write.csv(recipe, './toRead/communities.csv')

############### meso regions
## read table
meso <- read.csv('./tab/col_8/meso-pa-erased.csv')

## insert territory type
meso$territory <- 'Meso-region'

## read protected areas shapefile
#vec <- as.data.frame(read_sf('./vec/meso_regions.shp'))
vec <- as.data.frame(read_sf('./vec/new/meso/meso_brasil.shp'))

## selecy only desired columns
vec <- vec %>% select('CD_MESO', 'NM_MESO', 'SIGLA_UF')

## join tables
meso$CD_MESO <- as.character(meso$CD_MESO)
meso <- na.omit(left_join(x= meso, y= vec, by= c('CD_MESO' = 'CD_MESO')))

## empty temp files
rm(vec)

## remove undesirable columns (gee residuals)
meso <-  meso[ , -which(names(meso) %in% c("system.index",".geo"))]

## translate lulc class
## create recipe to translate mapbiomas classes
recipe <- as.data.frame(NULL)
## for each tenure id
for (i in 1:length(unique(meso$class_id))) {
  ## for each unique value, get mean in n levels
  y <- subset(mapbiomas_dict, id == unique(meso$class_id)[i])
  ## select matched class
  z <- subset(meso, class_id == unique(meso$class_id)[i])
  ## apply translation 
  z$class_level_0 <- gsub(paste0('^',y$id,'$'), y$mapb_0, z$class_id)
  z$class_level_1 <- gsub(paste0('^',y$id,'$'), y$mapb_1, z$class_id)
  z$class_level_1n <- gsub(paste0('^',y$id,'$'), y$mapb_1_2, z$class_id)
  z$class_level_2 <- gsub(paste0('^',y$id,'$'), y$mapb_2, z$class_id)
  z$class_level_3 <- gsub(paste0('^',y$id,'$'), y$mapb_3, z$class_id)
  z$class_level_4 <- gsub(paste0('^',y$id,'$'), y$mapb_4, z$class_id)
  ## bind into recipe
  recipe <- rbind(recipe, z)
}; rm(y, z)

## export table
write.csv(recipe, './toRead/meso-erased.csv')

## build cerrado 
x <- aggregate(x=list(area= recipe$area), by= list(
  class_id = recipe$class_id,
  year= recipe$year,
  class_level_0= recipe$class_level_0,
  class_level_1 = recipe$class_level_1,
  class_level_1n = recipe$class_level_1n,
  class_level_2 = recipe$class_level_2,
  class_level_3 = recipe$class_level_3,
  class_level_4 = recipe$class_level_4), FUN= 'sum')

## export table
write.csv(x, './toRead/cerrado-erased.csv')
