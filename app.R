library(shiny)
library(dplyr)
library(ggplot2)
library(RColorBrewer)


# Data ####
sismos <- read.csv("sismos_df.csv")
sismos[["Mes"]] <- factor(sismos[["Mes"]])
sismos[["Mes"]] <- reorder(sismos[["Mes"]], sismos[["Mes_num"]])

paleta <- brewer.pal(5, "Purples")

# Funs ####
tabla_sismos <- function(datos, rango_periodo, rango_magnitud){
  datos <- 
    datos %>% 
    filter(between(Periodo, rango_periodo[1], rango_periodo[2])) %>% 
    filter(between(Magnitud, rango_magnitud[1], rango_magnitud[2])) 
  
  bind_rows(
    datos %>% 
      count(Magnitud_cats, name = "Conteo"),
    datos %>% 
      mutate(Magnitud_cats = "Total") %>% 
      count(Magnitud_cats, name = "Conteo")
  ) %>% 
    rename("Magnitud" = Magnitud_cats)
}

plot_sismos <- function(datos, grupo, rango_periodo, rango_magnitud) {
  datos <- 
    datos %>% 
    filter(between(Periodo, rango_periodo[1], rango_periodo[2])) %>% 
    filter(between(Magnitud, rango_magnitud[1], rango_magnitud[2])) %>% 
    count(Periodo, .data[[grupo]], name = "Conteo")
  
  ggplot(datos) +
    aes(Periodo, .data[[grupo]], fill = Conteo) +
    geom_tile(color = "#999999") +
    scale_fill_gradient(low = paleta[1], high = paleta[5]) +
    
    scale_x_continuous(
      breaks = seq(1900, 2050, by = 2),
      minor_breaks = 1900:2050,
      expand = c(0, 0)
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 90, vjust = .4)
    )
}

plot_acumulados <- function(datos, grupo, rango_periodo, rango_magnitud) {
  datos <- 
    datos %>% 
    filter(between(Periodo, rango_periodo[1], rango_periodo[2])) %>% 
    filter(between(Magnitud, rango_magnitud[1], rango_magnitud[2])) %>% 
    count(.data[[grupo]], Magnitud_cats, name = "Conteo") 
  
  ggplot(datos) +
    aes(.data[[grupo]], Conteo, fill = Magnitud_cats) +
    geom_col(color = "#999999", position = position_stack(reverse = TRUE)) +
    scale_y_continuous(expand = c(0, 0)) +
    scale_fill_manual(name = "Magnitud", values = paleta) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      panel.grid.minor.y = element_blank()
    )
}


# UI ####
# Componentes 
slider_periodo <- sliderInput(
  inputId = "periodo", label = "Periodo", 
  value = c(1985, 2022), 
  min = 1900, max = 2022, 
  step = 1, sep = ""
)

slider_magnitud <- sliderInput(
  inputId = "magnitud", label = "Magnitud", 
  value = c(6, 8.5), 
  min = 4, max = 9, 
  step = .5, sep = ""
)


# Page
ui <- fixedPage(
  theme = bslib::bs_theme(bootswatch = "pulse"),
  title = "Catálogo de sismos: México, 1900-2022",
  fluidRow(
    column(12, h1("Catálogo de sismos: México, 1900-2022"))
  ),
  fluidRow(
    column(6, slider_periodo),
    column(6, slider_magnitud),
  ),
  fluidRow(
    column(4, 
           column(12, h4("Conteo de sismos")),
           column(12, tableOutput("totalEventos"))
    ),
    column(8, 
           column(12, h4("Sismos de mayor magnitud")),
           column(12, tableOutput("tablaSismo"))
    )
  ),
  fluidRow(
    column(12, h4("Sismos por mes del año")),
    column(12, plotOutput("sismosPlot", height = "425px")),
    column(12, plotOutput("acumPlot", height = "275px"))
  ),
  fluidRow(
    column(12, h4("Epicentro de sismos por entidad")),
    column(12, plotOutput("epicentroPlot", height = "425px")),
    column(12, plotOutput("acumentPlot", height = "275px"))
  ),
  fluidRow(
    column(12, 
           HTML("<p style='font-size:.75em;'>
                Fuente: <a href='http://www2.ssn.unam.mx:8080/catalogo/'>http://www2.ssn.unam.mx:8080/catalogo/</a></br>
                Código de este dashboard: <a href='https://github.com/jboscomendoza/catalogo-sismos-mexico'>hhttps://github.com/jboscomendoza/catalogo-sismos-mexico</a></p>")),
  )
)


# Server ####
server <- function(input, output) {
  output$totalEventos <- renderTable({
    tabla_sismos(sismos, input$periodo, input$magnitud)
  })
  
  output$tablaSismo <-  renderTable({  
    sismos %>% 
      filter(between(Periodo, input$periodo[1], input$periodo[2])) %>% 
      filter(between(Magnitud, input$magnitud[1], input$magnitud[2])) %>% 
      top_n(5, Magnitud) %>% 
      select(Fecha, Magnitud, Epicentro) %>% 
      arrange(desc(Magnitud))
  })
  
  output$sismosPlot <- renderPlot({
    plot_sismos(sismos, "Mes", input$periodo, input$magnitud)
  })
  
  output$epicentroPlot <- renderPlot({
    plot_sismos(sismos, "Entidad", input$periodo, input$magnitud)
  })
  
  output$acumPlot <- renderPlot({
    plot_acumulados(sismos, "Mes", input$periodo, input$magnitud)
  })
  
  output$acumentPlot <- renderPlot({
    plot_acumulados(sismos, "Entidad", input$periodo, input$magnitud)
  })
}


# Run ####
shinyApp(ui = ui, server = server)
