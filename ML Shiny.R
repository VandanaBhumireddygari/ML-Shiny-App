# Import libraries
library(shiny)
library(shinythemes)
library(data.table)
library(RCurl)
library(randomForest)
library(dplyr)

####################################
# User interface                   #
####################################

ui <- fluidPage(theme = shinytheme("united"),
                
                # Page header
                headerPanel('Diabetes Prediction'),
                
                # Input values
                sidebarPanel(
                  HTML("<h3>Input parameters</h3>"),
                  
                  fileInput("file", "Upload CSV file"),
                  
                  selectInput("Polyuria", "Polyuria:",
                              choices = c("Yes", "No"),
                              selected = "No"),
                  
                  selectInput("Polydipsia", "Polydipsia:",
                              choices = c("Yes", "No"),
                              selected = "No"),
                  
                  sliderInput("Age", "Age:",
                              min = 20, max = 80,
                              value = 40),
                  
                  selectInput("Gender", "Gender:",
                              choices = c("Male", "Female"),
                              selected = "Male"),
                  
                  selectInput("partial_paresis", "Partial Paresis:",
                              choices = c("Yes", "No"),
                              selected = "No"),
                  
                  actionButton("submitbutton", "Submit", class = "btn btn-primary")
                ),
                
                mainPanel(
                  tags$label(h3('Status/Output')), # Status/Output Text Box
                  verbatimTextOutput('contents'),
                  tableOutput('tabledata'), # Prediction results table
                  tags$div(
                    HTML("
                        <h3>About</h3>
                        <p>Diabetes mellitus is a metabolic chronic disease where blood sugar (glucose) levels remain higher than normal levels in the human body. According to the International Diabetes Federation, the total number of people suffering from diabetes will rise to 643 million by 2030 and a further 783 million by 2045. The total number of casualties happened due to diabetes so far is 6.7 million which signifies the seriousness of this disease.</p>
                        <p>Some of the common factors responsible for diabetes are family history, physical inactivity due to work pressure, mode of working (work from home and hybrid mode of working), high-fat diet, cheap and unhealthy junk foods intake, high alcohol intake.</p>
                        <h4>Polyuria</h4>
                        <p>Polyuria is a medical condition where adults have a very frequent passage of large volumes of urine i.e., > 3 liters a day whereas the normal range is 1 to 2 liters a day.</p>
                        <p>The most common cause of polyuria in both adults and children is uncontrolled diabetes mellitus, resulting in osmotic diuresis which develops when glucose levels are so high that glucose is excreted in the urine resulting in a large volume of urine output.</p>
                        <h4>Polydipsia</h4>
                        <p>Polydipsia is defined as a medical condition of being thirsty all the time. It is also usually accompanied by temporary or prolonged dryness of the mouth. It is one of the initial signs of diabetes.</p>
                        <p>From the above distribution, it is clear that the presence of Polydipsia signifies strong chances of diabetes in comparison to its absence.</p>
                        <h4>Paresis</h4>
                        <p>Paresis involves loosening the strength of a muscle or group of muscles. It may also be referred to as partial or mild paralysis. Unlike paralysis, people with paresis can still move their muscles. These movements are just too weaker than normal.</p>
                        ")
                  )
                )
)

####################################
# Server                           #
####################################

server <- function(input, output, session) {
  
  # Reactive value to store the uploaded data
  uploaded_data <- reactiveVal(NULL)
  
  # Read the uploaded file
  observeEvent(input$file, {
    uploaded_data(read.csv(input$file$datapath))
  })
  
  # Reactive value to store the diabetes data
  diabetes_data <- reactiveVal(NULL)
  
  # Observe when uploaded_data changes and load diabetes_data
  observe({
    if (!is.null(uploaded_data())) {
      # Assume class variable is present in the uploaded data
      diabetes_data(uploaded_data() %>% mutate(class = ifelse(class == "Positive", 1, 0)))
    }
  })
  
  # Build model
  model_formula <- reactive({
    if (!is.null(diabetes_data())) {
      glm(class ~ Polyuria + Polydipsia + Age + Gender + partial.paresis,
          data = diabetes_data(),
          family = binomial)
    }
  })
  
  # Input Data
  datasetInput <- reactive({  
    
    # Extract input values from input elements
    # Create a data frame with the input values
    
    if (!is.null(model_formula())) {
      df <- data.frame(
        Polyuria = input$Polyuria,
        Polydipsia = input$Polydipsia,
        Age = as.numeric(input$Age),
        Gender = input$Gender,
        partial.paresis = input$partial_paresis,
        stringsAsFactors = FALSE)
      
      # Make predictions using the model_formula
      output <- predict(model_formula(), newdata = df, type = "response")
      # Make a binary prediction based on the threshold
      threshold <- 0.5
      prediction <- ifelse(output > threshold, "Diabetes", "No Diabetes")
      
      # Print the prediction
      print(prediction)
    }
    
  })
  
  # Status/Output Text Box
  output$contents <- renderPrint({
    if (input$submitbutton > 0) { 
      isolate("Calculation complete.") 
    } else {
      return("Server is ready for calculation.")
    }
  })
  
  # Prediction results table
  output$tabledata <- renderTable({
    if (input$submitbutton > 0 && !is.null(model_formula())) { 
      isolate(datasetInput()) 
    } 
  })
  
}

####################################
# Create the shiny app             #
####################################
shinyApp(ui = ui, server = server)

