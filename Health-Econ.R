# ============================================================
# Delhi Environmental Health Economics Dashboard
# Professional Light Edition — Inter & Roboto Stack
# ============================================================

library(shiny)
library(ggplot2)
library(dplyr)
library(plotly)
library(DT)
library(scales)
library(tidyr)

# ============================================================
# DATA DEFINITIONS
# ============================================================

districts <- c("All Delhi", "Central Delhi", "East Delhi", "New Delhi", "North Delhi", "North-East Delhi", "North-West Delhi", "Shahdara", "South Delhi", "South-East Delhi", "South-West Delhi", "West Delhi")
seasons <- c("Summer (Heat Stress)", "Post-Monsoon (High AQI)", "Winter (Smog Season)", "Monsoon (Baseline)")
health_conditions <- c("Respiratory Diseases", "Cardiovascular Diseases", "Heat Stroke / Hyperthermia", "Asthma & COPD", "Eye & Skin Irritation", "Mental Health", "Kidney Disease", "Infectious Diseases")
mitigation_strategies <- c("Odd-Even Vehicle Rule", "Construction Activity Ban", "Water Sprinkling Operations", "Complete EV Transition", "Stubble Burning Restrictions", "Anti-Smog Guns", "Industrial Emission Controls")

base_costs <- data.frame(
  condition = health_conditions,
  base_cost = c(420, 380, 85, 310, 95, 140, 110, 200),
  heat_multiplier = c(1.3, 1.5, 3.2, 1.4, 1.6, 1.4, 1.7, 1.3),
  aqi_multiplier = c(2.8, 2.1, 0.6, 3.1, 2.4, 1.9, 1.5, 1.8),
  winter_multiplier = c(3.5, 2.6, 0.4, 3.8, 2.9, 2.2, 1.7, 2.1),
  monsoon_mult = c(1.0, 1.0, 0.7, 1.0, 1.0, 1.0, 1.2, 1.4)
)

district_weights <- c("All Delhi"=1.0, "Central Delhi"=0.065, "East Delhi"=0.11, "New Delhi"=0.035, "North Delhi"=0.09, "North-East Delhi"=0.115, "North-West Delhi"=0.135, "Shahdara"=0.095, "South Delhi"=0.1, "South-East Delhi"=0.075, "South-West Delhi"=0.1, "West Delhi"=0.08)

mitigation_effects <- list(
  "Odd-Even Vehicle Rule" = c(0.08,0.07,0.02,0.10,0.08,0.03,0.02,0.04),
  "Construction Activity Ban" = c(0.12,0.06,0.01,0.14,0.10,0.02,0.01,0.03),
  "Water Sprinkling Operations" = c(0.09,0.04,0.05,0.08,0.12,0.03,0.01,0.02),
  "Complete EV Transition" = c(0.22,0.18,0.03,0.25,0.20,0.08,0.04,0.08),
  "Stubble Burning Restrictions" = c(0.18,0.12,0.01,0.20,0.15,0.06,0.03,0.07),
  "Anti-Smog Guns" = c(0.07,0.04,0.02,0.07,0.09,0.02,0.01,0.02),
  "Industrial Emission Controls" = c(0.13,0.10,0.01,0.14,0.11,0.05,0.04,0.05)
)

# ============================================================
# THEME & HELPERS
# ============================================================

theme_delhi_light <- function() {
  theme_minimal(base_family = "Inter") +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      panel.grid.major = element_line(color = "#F1F5F9", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      axis.text = element_text(family = "Roboto", color = "#64748B", size = 9),
      axis.title = element_text(color = "#1E293B", face = "bold", size = 10),
      legend.title = element_blank(),
      legend.text = element_text(color = "#475569", size = 9)
    )
}

light_ggplotly <- function(gg) {
  ggplotly(gg, tooltip = "text") %>%
    layout(
      paper_bgcolor = "white", plot_bgcolor = "white",
      font = list(family = "Inter, sans-serif", color = "#1E293B"),
      legend = list(bgcolor = "rgba(255,255,255,0.8)", bordercolor = "#E2E8F0"),
      margin = list(t = 40, b = 40, l = 40, r = 40)
    ) %>% config(displaylogo = FALSE)
}

compute_costs <- function(season, district, selected_mitigations, conditions) {
  mult_col <- switch(season,
                     "Summer (Heat Stress)" = "heat_multiplier",
                     "Post-Monsoon (High AQI)" = "aqi_multiplier",
                     "Winter (Smog Season)" = "winter_multiplier",
                     "Monsoon (Baseline)" = "monsoon_mult"
  )
  w <- district_weights[district]
  df <- base_costs %>% filter(condition %in% conditions) %>%
    mutate(seasonal_cost = base_cost * .data[[mult_col]] * w * 11)
  
  if (length(selected_mitigations) > 0) {
    red_mat <- sapply(selected_mitigations, function(m) mitigation_effects[[m]][match(df$condition, health_conditions)])
    total_red <- if (is.null(dim(red_mat))) red_mat else apply(red_mat, 1, function(x) 1 - prod(1 - x))
    total_red <- pmin(total_red, 0.85)
  } else { total_red <- rep(0, nrow(df)) }
  
  df %>% mutate(reduction_fraction = total_red, mitigated_cost = seasonal_cost * (1 - total_red), savings = seasonal_cost - mitigated_cost)
}

# ============================================================
# UI
# ============================================================

ui <- fluidPage(
  tags$head(
    tags$link(href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=Roboto:wght@400;700&display=swap", rel = "stylesheet"),
    tags$style(HTML("
      :root {
        --bg: #F8FAFC; --surface: #FFFFFF; --border: #E2E8F0;
        --accent: #2563EB; --success: #059669; --text: #1E293B; --muted: #64748B;
      }
      body { background: var(--bg); color: var(--text); font-family: 'Inter', sans-serif; font-size: 14px; }
      .app-header { background: white; border-bottom: 1px solid var(--border); padding: 20px 35px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
      .app-title { font-size: 22px; font-weight: 800; color: #0F172A; }
      .app-title span { color: var(--accent); }
      .main-layout { display: flex; min-height: calc(100vh - 80px); }
      .sidebar { width: 320px; background: #F1F5F9; border-right: 1px solid var(--border); padding: 25px; }
      .content { flex-grow: 1; padding: 30px; overflow-y: auto; }
      .kpi-card { background: white; border: 1px solid var(--border); border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
      .kpi-val { font-size: 24px; font-weight: 700; color: var(--accent); margin: 5px 0; }
      .kpi-label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted); }
      .plot-card { background: white; border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 25px; }
      .btn-primary { background: var(--accent) !important; border: none !important; font-weight: 600; width: 100%; padding: 12px; margin-top: 15px; }
      .form-group label { font-weight: 600; color: var(--text); font-size: 13px; }
      .nav-tabs { border-bottom: 2px solid var(--border); }
      .nav-tabs > li > a { font-weight: 600; color: var(--muted); border: none !important; }
      .nav-tabs > li.active > a { color: var(--accent) !important; border-bottom: 2px solid var(--accent) !important; background: transparent !important; }
    "))
  ),
  
  div(class = "app-header",
      div(class = "app-title", "Delhi Environmental", tags$span("Health Economics"), "Analytics")
  ),
  
  div(class = "main-layout",
      div(class = "sidebar",
          selectInput("district", "Select District", choices = districts),
          selectInput("season", "Environmental Stressor", choices = seasons, selected = "Winter (Smog Season)"),
          checkboxGroupInput("conditions", "Health Metrics", choices = health_conditions, selected = health_conditions),
          checkboxGroupInput("mitigations", "Active Strategies", choices = mitigation_strategies),
          sliderInput("aqi_mult", "Manual AQI Intensity", min = 0.5, max = 3.0, value = 1.0, step = 0.1, post = "x"),
          actionButton("update", "Update Analysis", class = "btn-primary")
      ),
      
      div(class = "content",
          uiOutput("kpi_row"),
          br(),
          tabsetPanel(
            tabPanel("Economic Impact", br(),
                     div(style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;",
                         div(class="plot-card", plotlyOutput("bar_comparison", height = "350px")),
                         div(class="plot-card", plotlyOutput("savings_bar", height = "350px"))
                     ),
                     div(class="plot-card", plotlyOutput("heatmap", height = "350px"))
            ),
            tabPanel("Detailed Data", br(),
                     div(class="plot-card", DTOutput("table"))
            )
          )
      )
  )
)

# ============================================================
# SERVER
# ============================================================

server <- function(input, output, session) {
  
  data <- eventReactive(input$update, {
    req(input$conditions)
    df <- compute_costs(input$season, input$district, input$mitigations, input$conditions)
    df %>% mutate(seasonal_cost = seasonal_cost * input$aqi_mult, mitigated_cost = mitigated_cost * input$aqi_mult, savings = seasonal_cost - mitigated_cost)
  }, ignoreNULL = FALSE)
  
  output$kpi_row <- renderUI({
    df <- data()
    div(style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px;",
        div(class="kpi-card", div(class="kpi-label", "Gross Impact"), div(class="kpi-val", paste0("₹", round(sum(df$seasonal_cost)), " Cr"))),
        div(class="kpi-card", div(class="kpi-label", "Mitigated Cost"), div(class="kpi-val", style="color:var(--success)", paste0("₹", round(sum(df$mitigated_cost)), " Cr"))),
        div(class="kpi-card", div(class="kpi-label", "Economic Savings"), div(class="kpi-val", paste0("₹", round(sum(df$savings)), " Cr"))),
        div(class="kpi-card", div(class="kpi-label", "Reduction %"), div(class="kpi-val", paste0(round(mean(df$reduction_fraction)*100, 1), "%")))
    )
  })
  
  output$bar_comparison <- renderPlotly({
    df_long <- data() %>% pivot_longer(cols = c(seasonal_cost, mitigated_cost), names_to = "type", values_to = "cost")
    gg <- ggplot(df_long, aes(x = cost, y = reorder(condition, cost), fill = type, text = paste(condition, ": ₹", round(cost,1), "Cr"))) +
      geom_col(position = "identity", alpha = 0.7, width = 0.6) +
      scale_fill_manual(values = c("mitigated_cost" = "#059669", "seasonal_cost" = "#94A3B8"), labels = c("Mitigated", "Gross")) +
      labs(title = "Gross vs Mitigated Costs", x = "INR Crores", y = NULL) + theme_delhi_light()
    light_ggplotly(gg)
  })
  
  output$savings_bar <- renderPlotly({
    gg <- ggplot(data(), aes(x = savings, y = reorder(condition, savings), fill = savings, text = paste("Saved: ₹", round(savings,1), "Cr"))) +
      geom_col(width = 0.6) + scale_fill_gradient(low = "#BFDBFE", high = "#2563EB") +
      labs(title = "Savings by Condition", x = "INR Crores Saved", y = NULL) + theme_delhi_light()
    light_ggplotly(gg)
  })
  
  output$heatmap <- renderPlotly({
    sc <- c("Summer (Heat Stress)"="heat_multiplier", "Post-Monsoon (High AQI)"="aqi_multiplier", "Winter (Smog Season)"="winter_multiplier", "Monsoon (Baseline)"="monsoon_mult")
    hm <- expand.grid(condition=input$conditions, season=names(sc), stringsAsFactors=F) %>% 
      rowwise() %>% mutate(cost = { bc <- base_costs[base_costs$condition==condition,]; bc$base_cost * bc[[sc[[season]]]] * district_weights[input$district] * 11 })
    gg <- ggplot(hm, aes(x=season, y=condition, fill=cost)) + geom_tile(color="white") +
      scale_fill_gradient(low="#F1F5F9", high="#2563EB") + labs(title="Seasonal Risk Heatmap", x=NULL, y=NULL) + theme_delhi_light()
    light_ggplotly(gg)
  })
  
  output$table <- renderDT({
    datatable(data() %>% select(condition, seasonal_cost, mitigated_cost, savings) %>% mutate(across(where(is.numeric), round, 2)), 
              options = list(pageLength = 10, dom = 't'), rownames = FALSE)
  })
}

shinyApp(ui, server)
