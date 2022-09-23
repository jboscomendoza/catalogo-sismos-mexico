library(readr)
library(dplyr)
library(ggplot2)
library(stringr)
library(lubridate)
library(Hmisc)

# Requiere descarga del catálogo de sismos del Sistema Sismológico
# Nacional de México
# La versión en este archivo es del 2022-09-22
# http://www2.ssn.unam.mx:8080/catalogo/
sismos <- read_csv("SSNMX_catalogo_19000101_20220922_m40_99.csv", skip = 4)

sismos_df <- 
  sismos %>% 
  filter(!is.na(Magnitud)) %>% 
  select(Fecha, Magnitud, "Localizacion" = `Referencia de localizacion`) %>% 
  mutate(
    Periodo = lubridate::year(Fecha),
    Mes = lubridate::month(Fecha, label = TRUE),
    Mes_num = lubridate::month(Fecha),
    Entidad = stringr::str_extract(Localizacion, ".{4}$") %>% 
      stringr::str_remove_all("[[:punct:]]") %>% 
      stringr::str_squish()
  )  %>% 
  rename("Epicentro" = Localizacion) %>% 
  mutate(
    Magnitud_cats = Hmisc::cut2(Magnitud, cuts = seq(4, 9, by = 1)),
    Magnitud_cats = as.numeric(Magnitud_cats),
    Magnitud_cats = case_when(
      Magnitud_cats == 1 ~ "4 a 4.9",
      Magnitud_cats == 2 ~ "5 a 5.9",
      Magnitud_cats == 3 ~ "6 a 6.9",
      Magnitud_cats == 4 ~ "7 a 7.9",
      Magnitud_cats == 5 ~ "8 a 9"
    )
  ) 

write_csv(sismos_df, "sismos_df.csv")
