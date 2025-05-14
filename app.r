library(shiny)
library(recommenderlab)
library(Matrix)
library(dplyr)
library(ggplot2)

# Load and preprocess dataset
data("MovieLense")
MovieLense <- MovieLense[rowCounts(MovieLense) > 50, colCounts(MovieLense) > 100]

# UI
ui <- fluidPage(
  # Custom styles for cleaner UI
  tags$style(HTML("
    .main-container {
      padding: 20px;
    }
    .input-panel {
      background-color: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      height: 100%;
      min-height: 300px;
    }
    .recommendations-container {
      background-color: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin-top: 20px;
    }
    .rec-header {
      position: relative;
      padding-right: 40px;
    }
    .close-btn {
      position: absolute;
      top: 0;
      right: 0;
      background: none;
      border: none;
      font-size: 24px;
      color: #666;
      cursor: pointer;
      padding: 0 10px;
      line-height: 1;
    }
    .close-btn:hover {
      color: #dc3545;
    }
    .recommendation-content {
      margin: 20px 0;
    }
    .recommendation-plot {
      margin-top: 30px;
    }
    .text-center {
      text-align: center;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }
    th {
      background-color: #f8f9fa;
      padding: 12px;
      text-align: left;
      border-bottom: 2px solid #dee2e6;
    }
    td {
      padding: 12px;
      border-bottom: 1px solid #dee2e6;
    }
    tr:hover {
      background-color: #f8f9fa;
    }
    .btn-custom {
      background-color: #007bff;
      color: white;
      border: none;
      padding: 10px 20px;
      border-radius: 4px;
      cursor: pointer;
      transition: background-color 0.3s;
    }
    .btn-custom:hover {
      background-color: #0056b3;
    }
  ")),
  
  # App title
  titlePanel("🎬 Movie Recommender System (UBCF + IBCF) + Rating Input"),
  
  # Main container
  div(class = "main-container",
    # Input controls at top level
    fluidRow(
      column(4,
        div(class = "input-panel",
          selectInput("user", "Select User ID:", choices = rownames(MovieLense)),
          numericInput("num", "Number of Recommendations:", value = 5, min = 1, max = 20),
          radioButtons("algo", "Choose Algorithm:",
                     choices = c("User-Based Collaborative Filtering" = "UBCF",
                               "Item-Based Collaborative Filtering" = "IBCF"))
        )
      ),
      column(4,
        div(class = "input-panel",
          h4("⭐ Rate a Movie"),
          selectInput("movie_select", "Choose Movie to Rate:", 
                    choices = colnames(MovieLense)),
          sliderInput("rating_input", "Select Rating:", min = 1, max = 5, value = 3, step = 0.5),
          actionButton("rate_btn", "Submit Rating", icon = icon("star"), class = "btn-custom")
        )
      ),
      column(4,
        div(class = "input-panel",
          br(), br(),
          actionButton("go", "Get Recommendations", class = "btn-custom", style = "width: 100%"),
          br(), br(),
          helpText("Changes apply only in current session.")
        )
      )
    ),
    hr(),
    # Tabs for recommendations
    tabsetPanel(
      id = "tabs"  # ID for tab navigation
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Counter for recommendation tabs
  rec_counter <- reactiveVal(0)
  
  # Reactive rating matrix that updates when user rates
  user_matrix <- reactiveVal(MovieLense)
  
  # Observe and update user rating
  observeEvent(input$rate_btn, {
    mat <- user_matrix()
    mat[input$user, input$movie_select] <- input$rating_input
    user_matrix(mat)
    showNotification(paste("Rating submitted:", input$movie_select, "=", input$rating_input), type = "message")
  })
  
  # Generate recommendations
  recommendations <- eventReactive(input$go, {
    withProgress(message = 'Generating Recommendations...', value = 0, {
      matrix_now <- user_matrix()
      
      model <- if (input$algo == "UBCF") {
        Recommender(matrix_now, method = "UBCF")
      } else {
        Recommender(matrix_now, method = "IBCF")
      }
      
      pred <- predict(model, matrix_now[input$user, ], n = input$num, type = "topNList")
      recs <- as(pred, "list")[[1]]
      
      # Handle empty recommendations case
      if (length(recs) == 0) {
        return(data.frame(
          Rank = integer(0),
          Movie = character(0)
        ))
      }
      
      data.frame(Rank = seq_along(recs), Movie = recs)
    })
  })
  
  # Generate recommendations and create new tab
  observeEvent(input$go, {
    # Get recommendations first
    recs <- recommendations()
    
    # Only create new tab if we have recommendations
    if (nrow(recs) > 0) {
      # Increment counter
      rec_counter(rec_counter() + 1)
      current_count <- rec_counter()
      
      # Create new tab name
      new_tab_id <- paste0("📌 Recommendations ", current_count)
      
      # Add new tab with clean layout
      appendTab("tabs",
                tabPanel(new_tab_id,
                        fluidRow(
                          column(10, offset = 1,  # Center content with margins
                            div(class = "recommendations-container",
                              div(class = "rec-header",
                                h2(class = "text-center", "Top Recommended Movies"),
                                actionButton(paste0("close_tab_", current_count), "×", 
                                          class = "close-btn")
                              ),
                              br(),
                              div(class = "recommendation-content",
                                tableOutput(paste0("reclist", current_count))
                              ),
                              br(),
                              div(class = "recommendation-plot",
                                plotOutput(paste0("reclist_plot", current_count))
                              )
                            )
                          )
                        )),
                select = TRUE)
      
      # Handle close button click
      observeEvent(input[[paste0("close_tab_", current_count)]], {
        removeTab("tabs", new_tab_id)
      })
      
      # Generate recommendations for the new tab
      local({
        current_count <- current_count
        output[[paste0("reclist", current_count)]] <- renderTable({
          recs
        }, align = 'l', width = "100%")
        
        output[[paste0("reclist_plot", current_count)]] <- renderPlot({
          if (nrow(recs) > 0) {
            ggplot(recs, aes(x = Rank, y = Movie, fill = Rank)) +
              geom_bar(stat = "identity", show.legend = FALSE) +
              labs(x = "Rank", y = "Movie") +
              theme_minimal() +
              theme(
                plot.title = element_text(hjust = 0.5, size = 16),
                axis.title = element_text(size = 12),
                axis.text = element_text(size = 10)
              ) +
              scale_fill_viridis_c()
          }
        }, height = 400)
      })
    } else {
      # Show a notification if no recommendations are found
      showNotification(
        "No recommendations found. Try rating more movies or selecting a different algorithm.",
        type = "warning"
      )
    }
  })
}

# Launch app
shinyApp(ui = ui, server = server)
