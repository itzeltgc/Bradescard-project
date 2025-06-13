library(shiny)
library(bslib)
library(bnlearn)
library(plotly)
library(dplyr)

data <- read.csv("data_graph.csv")

# Cargar el modelo con manejo de errores
tryCatch({
  bn_model <- readRDS("bayesian_network_model.rds")
}, error = function(e) {
  bn_model <<- NULL
})

ui <- page_sidebar(
  theme = bs_theme(bootswatch = "yeti"),
  title = "Reto Bradescard",
  sidebar = sidebar(
    selectInput(inputId = "org",
                label = "ORG",
                choices = c("Any" = "any", "CYA_PLCC", "CYA_TV", "Lob_TV", "Promoda_TV", "Promoda_PLCC",
                            "Bradescard_TV", "Shasa_TV", "Shasa_PLCC","GCC_TV", "GCC_PLCC", 
                            "Bodega_Aurrera_TV", "Suburbia_TV", "Suburbia_PLCC", "Bodega_Aurrera_PLCC")),
    selectInput(inputId = "comportamiento_cliente",
                label = "Comportamiento de cliente",
                choices = list(Activo = "cliente_activo", 
                               InactivoDeuda = "cliente_inactivo_con_deuda", 
                               InactivoNoDeuda = "cliente_inactivo_sin_deuda", "Any" = "any")),
    selectInput(inputId = "Grupo_Credito",
                label = "Grupo de Crédito",
                choices = c("Alto", "Medio-Alto", "Medio-Bajo", "Bajo", "Any" = "any")),
    selectInput(inputId = "max_morosidad", 
                label = "Días de atraso máximo",
                choices = c("alto_atraso_1", "alto_atraso_2", "atraso_aceptable", 
                            "critico_atraso_1", "critico_atraso_2", "extremo_atraso_2", "medio_atraso", "Any" = "any")),
    selectInput(inputId = "comportamiento_pago_total",
                label = "Meses con pago completo",
                choices = c("Any" = "any", "Alta", "Media", "Baja", "Nula")),
    selectInput(inputId = "comportamiento_pago_parcial",
                label = "Meses con pago parcial",
                choices = c("Any" = "any", "Alta", "Media", "Baja", "Nula")),
    selectInput(inputId = "comportamiento_pago_nulo",
                label = "Meses con pago nulo",
                choices = c("Any" = "any", "Alta", "Media", "Baja", "Nula")),
    br(),
    helpText("Nota: Seleccionar 'Any' excluye ese factor de la consulta bayesiana"),
    br(),
    actionButton("run_inference", "Identificar Clientes", class = "btn-primary")
  ),
  navset_underline(
    nav_panel(
      "Predicción de Pago",
      value_box("Probabilidad de pago", textOutput("prob_display"), showcase = icon("percent")),
      card(
        card_header("Porcentaje de pago"),
        plotlyOutput("pie_chart")
      ),
      card(
        card_header("Porcentaje de clientes en base a las características"),
        plotlyOutput("bar_plot")
      ),
      card(
        card_header("Factores Incluidos en la Consulta"),
        verbatimTextOutput("active_evidence"),
        verbatimTextOutput("inference_result")
      )
    ),
    nav_panel(
      "Red Bayesiana",
      card(
        card_header("¿Qué es?"),
        "Un modelo probabilístico caracterizado por su capcidad de responder a consultas, 
        o queries, probabilísticas en base a evidencia observada. Es útil pues permite estimar la probabilidad de pago en
        en base al perfil de cliente "
      ),
      card(
        card_header("Varibles"),
        "Con la información porporcionada por la organización se construyeron las siguientes variables:",
        tags$ul(
          tags$li(tags$strong("ORG: "), "La organización a la que pertenece el cliente."),
          tags$li(tags$strong("Comportamiento de cliente: "), "Cliente activo o inactivo, debe o no."),
          tags$li(tags$strong("Grupo Crédito: "), "Segmentadación de la variable nivel de crédito."),
          tags$li(tags$strong("Morosidad máxima: "), "El máximo de los últimos seis meses del atraso del cliente (en días)."),
          tags$li(tags$strong("Comportamiento Pago Total: "), "El número de meses en que el pago realizado es completo."),
          tags$li(tags$strong("Comportamiento Pago Parcial: "), "El número de meses en que el pago realizado es parcial"),
          tags$li(tags$strong("Comportamiento Pago Nulo: "), "El número de meses en que no hay pago.")
        )
      ),
      card(
        card_header("¿Cómo funciona?"),
        card_body(
          tags$p("Se realiza un diagrama que explica las relaciones de dependencia entre las variables, 
        este se entrena con los datos existentes para encontrar la probabilidad de que suceda el evento, el cliente paga este mes."),
          tags$img(src = "GABY.png"))
        
        )
    ),
    nav_panel(
      "Manual de uso",
      card(
        card_header("El proyecto"),
        card_body(tags$p("El proyecto busca comprender el comportamiento de los clientes a través de variables clave que
        reflejan patrones de uso, riesgo, y morosidad. Utilizando redes bayesianas, se identificaron
        relaciones de dependencia entre factores con los que se estima la ", tags$strong("probabilidad de pago"), 
        "dadas cierta evindencia histórica."),
        tags$p("Con lo cual, buscamos brindar la mayor libertad al usuario para la toma de decisiones y orientación
        en acciones estratégicas para la prevención de morosidad, recuperación o reactivación de cuentas."))
      ),
      card(
        card_header("¿Cómo usar?"),
        card_body(tags$p("Para crear predicciones basta con elegir las características deseadas. El resultado es la ", tags$strong("Predicción, "), 
        "el ", tags$strong("porcentaje de clientes "), "con esas características que si pagaron el último mes, y la porcentaje de clientes con esas carcterísticas en relación al total de clientes."))
      ),
      card(
        card_header("Consideraciones"),
        "En caso de que no existan clientes con esas características, la probabilidad de pago será cero. Esto porque no hay 
        evidencia respecto a esta clase de cliente."
      )
      
    )
  )
)

server <- function(input, output, session){
  
  # Función auxiliar para crear evidencia dinámica
  create_dynamic_evidence <- function(input_list) {
    evidence <- list()
    active_factors <- c()
    
    input_mapping <- list(
      "ORG" = input_list$org,
      "comportamiento_cliente" = input_list$comportamiento_cliente,
      "Grupo_Credito" = input_list$Grupo_Credito,
      "max_morosidad" = input_list$max_morosidad,
      "comportamiento_pago_total" = input_list$comportamiento_pago_total,
      "comportamiento_pago_parcial" = input_list$comportamiento_pago_parcial,
      "comportamiento_pago_nulo" = input_list$comportamiento_pago_nulo
    )
    
    # Solo incluir en evidencia los valores que no sean "any"
    for(var_name in names(input_mapping)) {
      if(input_mapping[[var_name]] != "any") {
        evidence[[var_name]] <- input_mapping[[var_name]]
        active_factors <- c(active_factors, paste(var_name, "=", input_mapping[[var_name]]))
      }
    }
    
    return(list(evidence = evidence, active_factors = active_factors))
  }
  
  inference_output <- eventReactive(input$run_inference, {
    
    # Verificar que el modelo existe
    if(is.null(bn_model)) {
      return(list(
        result = "ERROR: El modelo bayesiano no está disponible",
        factors = "Error de modelo"
      ))
    }
    
    # Crear evidencia dinámica
    dynamic_result <- create_dynamic_evidence(input)
    evidence_list <- dynamic_result$evidence
    active_factors <- dynamic_result$active_factors
    
    # Si no hay evidencia, hacer consulta marginal
    if(length(evidence_list) == 0) {
      tryCatch({
        prob <- cpquery(bn_model, 
                        Variable_objetivo == "sí", 
                        TRUE,
                        n = 100000)
        
        return(list(
          result = paste("Probabilidad marginal de pago (sin restricciones):", round(prob, 4)),
          factors = "Ningún factor específico"
        ))
        
      }, error = function(e) {
        return(list(
          result = paste("ERROR en consulta marginal:", e$message),
          factors = "Error"
        ))
      })
    }
    
    # Método directo con construcción manual de la expresión
    tryCatch({
      # Crear las condiciones como string
      conditions <- c()
      for(var_name in names(evidence_list)) {
        conditions <- c(conditions, paste0(var_name, " == '", evidence_list[[var_name]], "'"))
      }
      evidence_text <- paste(conditions, collapse = " & ")
      
      # Construir y evaluar la expresión completa
      query_expression <- paste0("cpquery(bn_model, Variable_objetivo == 'sí', ", evidence_text, ", n = 100000)")
      prob <- eval(parse(text = query_expression))
      
      return(list(
        result = paste("Probabilidad de pago del grupo:", round(prob, 4)),
        factors = paste(active_factors, collapse = "\n")
      ))
      
    }, error = function(e) {
      return(list(
        result = paste("ERROR en la consulta:", e$message),
        factors = "Error en procesamiento"
      ))
    })
  })
  
  output$inference_result <- renderPrint({
    result <- inference_output()
    cat(result$result)
  })
  
  output$active_evidence <- renderPrint({
    result <- inference_output()
    if(result$factors == "Ningún factor específico") {
      cat("Consulta marginal - todos los factores establecidos como 'Any'")
    } else if(result$factors == "Error en procesamiento" || result$factors == "Error de modelo") {
      cat("Error en el procesamiento de factores")
    } else {
      cat("Factores incluidos en la consulta:\n")
      cat(result$factors)
    }
  })
  
  output$prob_display <- renderText({
    result <- inference_output()
    
    if(grepl("ERROR", result$result)) {
      "Error"
    } else {
      # Extraer solo el número de probabilidad
      prob_num <- gsub(".*: ", "", result$result)
      paste0(round(as.numeric(prob_num) * 100, 1), "%")
    }
  })
  
  # Gráfica
  filtered_data <- eventReactive(input$run_inference, {
    if(is.null(data)) {
      return(NULL)
    }
    
    data_filtered <- data
    
    if (input$org != "any"){
      data_filtered <- data_filtered %>%
        filter(ORG == input$org)}
    
    if (input$comportamiento_cliente != "any"){
      data_filtered <- data_filtered %>%
        filter(comportamiento_cliente == input$comportamiento_cliente)}
    
    if (input$Grupo_Credito != "any"){
      data_filtered <- data_filtered %>%
        filter(Grupo_Credito == input$Grupo_Credito)}
    
    if (input$max_morosidad != "any"){
      data_filtered <- data_filtered %>%
        filter(max_morosidad == input$max_morosidad)}
    
    if (input$comportamiento_pago_total != "any"){
      data_filtered <- data_filtered %>%
        filter(comportamiento_pago_total == input$comportamiento_pago_total)}
    
    if (input$comportamiento_pago_parcial != "any"){
      data_filtered <- data_filtered %>%
        filter(comportamiento_pago_parcial == input$comportamiento_pago_parcial)}
    
    if (input$comportamiento_pago_nulo != "any"){
      data_filtered <- data_filtered %>%
        filter(comportamiento_pago_nulo == input$comportamiento_pago_nulo)}
    
    cat("Filas filtradas:", nrow(data_filtered), "\n")
    print(head(data_filtered))
    return(data_filtered)
  })
  
  output$pie_chart <- renderPlotly({
    # Usar el eventReactive
    filtered_df <- filtered_data()
    
    # Verificar que los datos base existen
    if(is.null(data)) {
      return(plot_ly() %>% 
               add_text(text = "Datos no disponibles", 
                        x = 0.5, y = 0.5, 
                        textfont = list(size = 16)) %>%
               layout(showlegend = FALSE, 
                      xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
                      yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)))
    }
    
    # Verificar datos filtrados
    if(is.null(filtered_df) || nrow(filtered_df) == 0) {
      return(plot_ly() %>% 
               add_text(text = "No hay observaciones que cumplan los criterios", 
                        x = 0.5, y = 0.5, 
                        textfont = list(size = 14)) %>%
               layout(showlegend = FALSE,
                      xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
                      yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)))
    }
    
    # Crear tabla de frecuencias para Variable_objetivo
    if("Variable_objetivo" %in% colnames(filtered_df)) {
      freq_table <- table(filtered_df$Variable_objetivo)
      
      # Crear el gráfico de pie
      colors <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728")
      
      plot_ly(labels = names(freq_table), 
              values = as.numeric(freq_table), 
              type = "pie",
              textinfo = "label+percent",
              textposition = "inside",
              marker = list(colors = colors[1:length(freq_table)],
                            line = list(color = "#FFFFFF", width = 2))) %>%
        layout(title = list(text = paste("Total de observaciones:", nrow(filtered_df)),
                            font = list(size = 14)),
               showlegend = TRUE,
               legend = list(orientation = "v", x = 1.02, y = 0.5))
    } else {
      return(plot_ly() %>% 
               add_text(text = "Variable_objetivo no encontrada en los datos", 
                        x = 0.5, y = 0.5, 
                        textfont = list(size = 14)) %>%
               layout(showlegend = FALSE,
                      xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
                      yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)))
    }
  })
  
  output$bar_plot <- renderPlotly({
    
    filtered_df <- filtered_data()
    
    if(is.null(data)) {
      return(plot_ly() %>% 
               add_text(text = "Datos no disponibles", 
                        x = 0.5, y = 0.5, 
                        textfont = list(size = 16)) %>%
               layout(showlegend = FALSE, 
                      xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
                      yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)))
    }
    
    # Calcular totales
    total_observaciones <- nrow(data)
    observaciones_filtradas <- if(is.null(filtered_df)) 0 else nrow(filtered_df)
    
    # Crear dataframe para la gráfica
    comparison_data <- data.frame(
      Categoria = c("Total de Observaciones", "Observaciones Filtradas"),
      Cantidad = c(total_observaciones, observaciones_filtradas),
      Porcentaje = c(100, round((observaciones_filtradas/total_observaciones)*100, 1))
    )
    
    # Crear gráfica de barras
    p <- plot_ly(comparison_data, 
                 x = ~Categoria, 
                 y = ~Cantidad,
                 type = "bar",
                 marker = list(color = c("#1f77b4", "#ff7f0e"),
                               line = list(color = "#FFFFFF", width = 2)),
                 text = ~paste("N:", Cantidad, "<br>", Porcentaje, "%"),
                 textposition = "auto",
                 hovertemplate = paste(
                   "<b>%{x}</b><br>",
                   "Cantidad: %{y}<br>",
                   "Porcentaje: %{text}<br>",
                   "<extra></extra>"
                 )) %>%
      layout(
        title = list(
          text = "Comparación: Total vs Observaciones Filtradas",
          font = list(size = 16)
        ),
        xaxis = list(
          title = "",
          tickangle = -45
        ),
        yaxis = list(
          title = "Número de Observaciones"
        ),
        showlegend = FALSE,
        margin = list(b = 100, t = 60)
      )
    
    return(p)
  })
}

shinyApp(ui = ui, server = server)