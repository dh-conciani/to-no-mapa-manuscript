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

## get only forma cprotected areas
formal <- read.csv('./toRead/protected-areas.csv')

## retain only files with at least 10 years of data before creation 
formal_filtered <- subset(formal, Ano_fim > 1995)

## retain only files with at least 10 years of data before creation 
formal_filtered <- subset(formal_filtered, Ano_fim < 2012)

## ommit NM_MESO with NA
#formal_filtered <- formal_filtered[- which(is.na(formal_filtered$NM_MESO)) ,]

## get deforestation before and after creation 
## get protecteds areas
pa_names <- unique(formal_filtered$NOME)

## create empry recipe
recipe <- as.data.frame(NULL)

## for each protected area
for (i in 1:length(pa_names)) {
  ## get pa x
  pa_i <- subset(formal_filtered, NOME == pa_names[i])
  
  ## compute changes inside and outside PAs
  for (j in 1:length(unique(pa_i$condition))) {
    print(paste0('Processing ', pa_names[i], ' - ', unique(pa_i$condition)[j]))
    ## subset per condition (within or buffer)
    pa_ij <- subset(pa_i, condition == unique(pa_i$condition)[j])
    
    ## segment into before and after
    pa_ij_before <- subset(pa_ij, year < unique(pa_ij$Ano_fim))
    pa_ij_after <- subset(pa_ij, year >= unique(pa_ij$Ano_fim))
    
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
      
      ## normalize the loss by the ammount of vegetation  in the first year of the period
      rel_change <- round((change / x[1,]$area) * 100, digits=1)
      
      
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
        name = unique(pa_ijk$NOME),
        condition = unique(pa_ijk$condition),
        grupo = unique(pa_ijk$Categoria),
        NM_MESO = unique(pa_ijk$NM_MESO),
        creation_label = unique(pa_ijk$creation_label),
        native_change  = change,
        n_years = unique(pa_ijk$n_years),
        mean_native_change = change/unique(pa_ijk$n_years),
        perc_loss_period = rel_change
      ))
     
      ## bind into recipe
      recipe <- rbind(recipe, result_ijk)
    }
    
  }
  
}


## translate communiti names
recipe$grupo <- gsub('TI', 'Indigenous Land',
                   gsub('Quilombo', 'Quilombo',
                        gsub('RESEX', 'Sustainable Use',
                             gsub('RDS', 'Sustainable Use',
                                  recipe$grupo))))

## aggregate general
summary_1 <- aggregate(x= list(mean_native_change= as.numeric(recipe$mean_native_change)),
                  by= list(condition= recipe$condition,
                           creation_label= recipe$creation_label,
                           grupo = recipe$grupo),
                  FUN= 'sum')

## get changes summary
summary_1_changes <- as.data.frame(NULL)
for (i in 1:length(unique(summary_1$grupo))) {
  ## get group
  x <- subset(summary_1, grupo == unique(summary_1$grupo)[i])
  ## for each condition
  for (j in 1:length(unique(x$condition))) {
    y <- subset(x, condition == unique(x$condition)[j])
    
    ## multiple by -1 to get positive values
    y$mean_native_change <- y$mean_native_change * -1
    
    ## get absolute change
    y$change <-  subset(y, creation_label == 'After')$mean_native_change - 
      subset(y, creation_label == 'Before')$mean_native_change 
     
    ## get relative change
    y$relative_change <- round((y$change / subset(y, creation_label == 'Before')$mean_native_change) * 100, digits=1)
    
    ## store
    summary_1_changes <- rbind(summary_1_changes, y[1,])
  }
}

## plot
ggplot(data=summary_1, mapping= aes(x= grupo, y= (mean_native_change*-1)/1000, fill= creation_label)) +
  geom_bar(stat='identity', position= 'dodge', alpha= 0.7) +
  facet_wrap(~condition, scales= 'free_x') +
  xlab(NULL) +
  theme_bw() +
  coord_flip() +
  ylab('Mean annual deforestation (hectares x 1000)') +
  geom_text(aes(label = paste0(round((mean_native_change*-1)/1000, digits=1), 'Kha')), 
            position = position_dodge(width=1),
            vjust=1, hjust= 0.8) +
  scale_fill_manual('Protection formalization', values= c('skyblue1', 'salmon1'),
                    labels= c('After', 
                              'Before')) 
  #geom_text(data= summary_1_changes, mapping= aes(
  #  label = relative_change, y = 50
  #))

## search regional patterns
summary_2 <- aggregate(x= list(mean_native_change= as.numeric(recipe$mean_native_change)),
                       by= list(condition= recipe$condition,
                                creation_label= recipe$creation_label,
                                grupo = recipe$grupo,
                                NM_MESO = recipe$NM_MESO),
                       FUN= 'sum')


## plot
ggplot(data=summary_2, mapping= aes(x= NM_MESO, y= (mean_native_change*-1)/1000, fill= creation_label)) +
  geom_bar(stat='identity', position= 'dodge', alpha= 0.9) +
  facet_grid(grupo~condition, scales= 'free') +
  xlab(NULL) +
  theme_bw() +
  coord_flip() +
  ylab('Desmatamento anual médio (hectares x 1000)') +
  geom_text(aes(label = round((mean_native_change*-1)/1000, digits=1)), 
            position = position_dodge(width=1),
            vjust=1, size=2) +
  scale_fill_manual('Periodo', values= c('skyblue1', 'salmon1'),
                    labels= c('Depois da formalização', 
                              'Antes da formalização'))


## get changes summary
summary_2_changes <- as.data.frame(NULL)
for (i in 1:length(unique(summary_1$grupo))) {
  ## get group
  x <- subset(summary_2, grupo == unique(summary_2$grupo)[i])
  ## for each condition
  for (j in 1:length(unique(x$condition))) {
    y <- subset(x, condition == unique(x$condition)[j])
    
    ## for each region
    for (k in 1:length(unique(y$NM_MESO))) {
      z <- subset(y, NM_MESO == unique(y$NM_MESO)[k])
      
      ## multiple by -1 to get positive values
      z$mean_native_change <- z$mean_native_change * -1
      
      ## get absolute change
      z$change <-  subset(z, creation_label == 'After')$mean_native_change - 
        subset(z, creation_label == 'Before')$mean_native_change 
      
      ## get relative change
      z$relative_change <- round((z$change / subset(z, creation_label == 'Before')$mean_native_change) * 100, digits=1)
      
      ## store
      summary_2_changes <- rbind(summary_2_changes, z[1,])
    }
  }
}


## insert negative/positive labels
summary_2_changes$signal <- sapply(summary_2_changes$change, function(x) x < 0)

# Remove the minus sign from numbers with FALSE operators
summary_2_changes$relative_change2 <- ifelse(summary_2_changes$signal == FALSE, 
                                             abs(summary_2_changes$relative_change), 
                                             summary_2_changes$relative_change)


## plot changes
ggplot(data= summary_2_changes, mapping= aes(x= reorder(NM_MESO, change), y= change, fill= signal)) +
  geom_bar(stat='identity', alpha=0.7) +
  scale_fill_manual('Veg. loss', values=c('red', 'forestgreen'), labels=c('Increase', 'Decrease')) +
  coord_flip() +
  facet_grid(grupo~condition, scales= 'free') +
  theme_bw() +
  geom_hline(yintercept=0, col= 'gray') +
  xlab(NULL) +
  ylab('Changes in annual native vegetation net-balance (after - before) in hectares') +
  geom_text(mapping=aes(y= 0,label= paste0(round(change, digits=0), ' ha ', '(', round(relative_change2, digits=0), '%)')),
            size= 3)


## make the ranking per area
summary_3_changes <- as.data.frame(NULL)
## for each area
for (i in 1:length(unique(recipe$name))) {
  ## get area i
  x <- subset(recipe, name == unique(recipe$name)[i])
  
  ## for each grupo 
  for (j in 1:length(unique(x$condition))) {
    y <- subset(x, condition == unique(x$condition)[j])
    
    ## multiple by -1 to get positive values
    y$mean_native_change <- as.numeric(y$mean_native_change) * -1
    
    ## get absolute change
    y$change <-  subset(y, creation_label == 'After')$mean_native_change - 
      subset(y, creation_label == 'Before')$mean_native_change 
    
    ## get relative change
    y$relative_change <- round((y$change / subset(y, creation_label == 'Before')$mean_native_change) * 100, digits=1)
    
    ## store
    summary_3_changes <- rbind(summary_3_changes, y[1,])
    
  }
}

## GET TOP 8 (four geatest and lowest) for each group of protecteds areas
recipe2 <- as.data.frame(NULL)
for (i in 1:length(unique(summary_3_changes$grupo))) {
  ## get only within 
  x <- subset(summary_3_changes, condition == 'Within' & grupo == unique(summary_3_changes$grupo)[i])
  
  ## get top 10 changes
  y <- x[order(-x$change), ] [1:4 ,]
  z <- x[order(x$change), ] [1:4 ,]
  
  ## bind negative and positive
  zi <- rbind(y, z)
  
  ## select 
  zij <- summary_3_changes[summary_3_changes$name %in% zi$name, ]
  
  ## store
  recipe2 <- rbind(recipe2, zij)
}

## plot
ggplot(data= recipe2, mapping= aes(x= reorder(name, change), y= change, fill= NM_MESO)) +
  geom_bar(stat='identity') +
  #scale_fill_manual('Region', values=c('#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#800080', '#FFA500',
  #                                     '#008000', '#FFC0CB', '#808080', '#800000', '#FFFF80')) +
  coord_flip() +
  facet_grid(grupo~condition, scales= 'free') +
  theme_bw() +
  geom_text(y= 0 , mapping=aes(label= paste0(round(change, digits=0), ' ha')), size=4) +
  ylab('Changes in annual native vegetation net-balance (after - before) in hectares') +
  xlab(NULL) +
  geom_hline(yintercept=0, col= 'red', linetype= 'dashed')

