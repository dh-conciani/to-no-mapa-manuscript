## check demarcation effect over formal communties
## dhemerson.costa@ipam.org.br

## load libraries
library(ggplot2)
library(sf)
library(ggrepel)

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

## ommit NM_MESO with NA
formal_filtered <- formal_filtered[- which(is.na(formal_filtered$NM_MESO)) ,]

## get deforestation before and after creation 
## get protecteds areas
pa_names <- unique(formal_filtered$name)


## create empry recipe
recipe <- as.data.frame(NULL)

## for each protected area
for (i in 1:length(pa_names)) {
  ## get pa x
  pa_i <- subset(formal_filtered, name == pa_names[i])
  
  ## compute changes inside and outside PAs
  for (j in 1:length(unique(pa_i$condition))) {
    print(paste0('Processing ', pa_names[i], ' - ', unique(pa_i$condition)[j]))
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
    for (k in 1:length(unique(pa_ij$creation_label))) {
      
      ## get time-stamp k
      pa_ijk <- subset(pa_ij, creation_label == unique(pa_ij$creation_label)[k])
      
      ## get only native vegetation
      pa_ijk_n <- subset(pa_ijk, class_level_0 == 'Native vegetation')
      
      ## skip wehn native vegetation does not exists
      if(nrow(pa_ijk_n) == 0) {
        next
      }
      
      ## aggregate native vegetation before creation
      x <- aggregate(x= list(area= pa_ijk_n$area),
                     by= list(
                       year = pa_ijk_n$year), 
                     FUN= 'sum')
      
      ## compute native vegetation change 
      change <- subset(x, year == max(x$year))$area - subset(x, year == min(x$year))$area
      
      ############## cmpute anthropogenic use increase
      #pa_ijk_ni <- subset(pa_ijk, class_level_0 == 'Anthropogenic use')
      
      ## aggregate native vegetation before creation
      #y <- aggregate(x= list(area= pa_ijk_ni$area),
      #               by= list(
      #                 year = pa_ijk_ni$year), 
      #               FUN= 'sum')
      
      ## compute native vegetation change 
      #change_ni <- subset(y, year == max(y$year))$area - subset(y, year == min(y$year))$area
      
      ## build table
      result_ijk <- as.data.frame(cbind(
        name = unique(pa_ijk$name),
        condition = unique(pa_ijk$condition),
        grupo = unique(pa_ijk$grupo),
        NM_MESO = unique(pa_ijk$NM_MESO),
        SIGLA_UF = unique(pa_ijk$SIGLA_UF),
        creation_label = unique(pa_ijk$creation_label),
        native_change  = change,
        n_years = unique(pa_ijk$n_years),
        mean_native_change = change/unique(pa_ijk$n_years)
      ))
     
      ## bind into recipe
      recipe <- rbind(recipe, result_ijk)
    }
    
  }
  
}

## aggregate general
summary_1 <- aggregate(x= list(mean_native_change= as.numeric(recipe$mean_native_change)),
                  by= list(condition= recipe$condition,
                           creation_label= recipe$creation_label,
                           grupo = recipe$grupo),
                  FUN= 'sum')


## plot
ggplot(data=summary_1, mapping= aes(x= grupo, y= (mean_native_change*-1)/1000, fill= creation_label)) +
  geom_bar(stat='identity', position= 'dodge', alpha= 0.6) +
  facet_wrap(~condition, scales= 'free_x') +
  xlab(NULL) +
  theme_bw() +
  coord_flip() +
  ylab('Desmatamento anual médio (hectares x 1000)') +
  geom_text(aes(label = round((mean_native_change*-1)/1000, digits=1)), 
            position = position_dodge(width=1),
            vjust=1) +
  scale_fill_manual('Periodo', values= c('skyblue1', 'salmon1'),
                    labels= c('Depois da formalização', 
                              'Antes da formalização'))









## plot before vs after
ggplot(data= subset(recipe, condition == 'Within'), mapping= aes(x= as.numeric(mean_native_change))) +
  geom_bar(stat='identity') +
  facet_grid(creation_label~grupo, scales= 'free') +
  theme_bw()


