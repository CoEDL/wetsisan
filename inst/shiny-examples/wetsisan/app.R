
# App title ---------------------------------------------------------------

#This Shiny application proposes an interface to apply Boruta algorithm on csv files containing tokens (to predict) and predictors.
#The csv file in the input should be formatted so that each line corresponds to one observation, and columns should correspond to predictors/tokens
#This interface was designed specifically for linguistic data analysis, as part of the Centre of Excellence for the Dynamics of Languagee


library(shiny)
library(tidyverse)
library(shinythemes)
library(Boruta)


# Define UI for data upload app ----
ui <- fluidPage(theme = shinytheme("flatly"),
                
  #Importing Google fonts              
  tags$head(
    tags$link(rel="stylesheet", type = "text/css", href = "https://fonts.googleapis.com/css?family=Aldrich")
  ),
  
  # redefining styles to get coloured tabs and use custom font in header             
  tags$style(HTML("
    .tabbable > .nav > li > a                  {background-color: aqua;  color:black}
    .tabbable > .nav > li > a[data-value='Help'] {background-color:   #73c6b6  ; color:black}
    .tabbable > .nav > li > a[data-value='Load'] {background-color:    #7dcea0   ;   color:black}
    .tabbable > .nav > li > a[data-value='Pre-process'] {background-color:  #73c6b6  ;  color:black}
    .tabbable > .nav > li > a[data-value='Analyze'] {background-color:  #7dcea0  ; color:black}
    .tabbable > .nav > li > a[data-value='Visualize'] {background-color:  #73c6b6  ; color:black}
    .tabbable > .nav > li[class=active]    > a {background-color: black  ; color:white}
      
    h1 {
        font-family: 'Aldrich';
        font-weight: 500;
        line-height: 1.1;
        color:  #117a65 ;
    }
                  
  ")),
  
  
  
  # App title
  headerPanel(title = div(img(src='logo_ws.png',width=80), "Wetsisan")),

  
  
  # Panels corresponding to each step of the processing
  tabsetPanel(
    
    # Help section: General instructions on how to use the app ----
    tabPanel("Help",
      br(),
      p("Welcome to Wetsisan."),
      br(),
      p("Make sure your data is formatted as a CSV file, with rows corresponding to observations and columns corresponding to predictor/token values."),
      p("Then go through the panels one by one to Load, Preprocess, Analyze and Visualize the data.")
    ),
    
    # Load section: Loading an external file from csv ----
    tabPanel("Load",
      wellPanel(
        fluidRow(
          # Input: Select a file
          column(3,
            fileInput("file1", "Choose CSV File containing data",
                multiple = TRUE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv")),
    
      
          # Input: Checkbox if file has header
          checkboxInput("header", "Header", TRUE)
          ),
      
          # Input: Select separator
          column(3,
            radioButtons("sep", "Separator",
                   choices = c(Comma = ",",
                               Semicolon = ";",
                               Tab = "\t"),
                   selected = ",")
          ),
          
          # Input: Select quotes
          column(3,
            radioButtons("quote", "Quote",
                   choices = c(None = "",
                               "Double Quote" = '"',
                               "Single Quote" = "'"),
                   selected = '"')
      
          )
        )
      ),
      
      # Output: Displays the head of the data frame once loaded
      tableOutput("contents")
    ),

    # Pre-process section: Selecting the columns that contains the token and predictors ----  
    tabPanel("Pre-process",
  
      wellPanel(
        
        # Input: select the variable to predict
        selectInput("Y", "Choose the variable to predict:",NULL
        ),
    
        # Input : select all predictor columns
        checkboxGroupInput("predictors", "Choose the predictors:",NULL
        ),
        
        # Button : start preprocessing once the selection has been made
        actionButton("goButton", "Preprocess file")
      ),
      
      # Output: Displays the results of the preprocessing
      verbatimTextOutput("PreProcResult")
    ),
  
    # Analyze section: Run the Boruta algorithm ----
    tabPanel("Analyze",
  
      wellPanel(
        
        # Button: Run the Boruta algorithm
        actionButton("startfitting", "Start fitting random forest"),
        
        # Input: Choice to perform Tentative rough fix after Boruta or not (to make sure all the variables are either rejected or confirmed)
        checkboxInput("correction", "Perform a rough fix of tentative decisions", FALSE)
      ),
      
      # Output: Feedback on the current state of the Boruta
      textOutput("feedbackplot")
    ),
  
    # Visualize section: Plot variable importance an decisions ----
    tabPanel("Visualize",
      
      # Output: plots the results of the Boruta algorithm
      plotOutput("forestresults",width="60%"),
      
      # Download button (to download the plot as pdf)
      downloadButton(outputId = "down", label = "Download the plot")
    )
  )
)
    






# Define server logic to run the processing ----
server <- function(input, output,session) {
  
  # Reactive values to store the state of the app and the plot
  #App state: 0:start ; 1:data loaded ; 2:preprocessing done ; 3:boruta done
  app_state <- reactiveValues(state = 0,plot=0)
  
  
  
  
  
  # Data table display after loading ----
  output$contents <- renderTable({
    
    # input$file1 will be NULL initially. A value is required to display
    req(input$file1)
    
    #Read the file
    df <- read.csv(input$file1$datapath,
                   header = input$header,
                   sep = input$sep,
                   quote = input$quote)
    
    #Update choice selections for token and predictors (in the PreProcess section)
    updateSelectInput(session, "Y",
                      "Which column contains the token to predict ?",
                      choices = colnames(df)
    )
    
    updateCheckboxGroupInput(session,"predictors","Choose the predictors:",choices=colnames(df))
    
    #Update state of the app
    app_state$state<-1 
    
    #return the head of the table to display
    return(head(df))
  })
  
  
  
  
  # Results of the preprocessing stage (for user to verify before running algorithm) ----
  output$PreProcResult<-renderText({
    
    #Start when the prerocessing button is pressed
    req(input$goButton)
    
    #Check that a file has been loaded
    if(isolate(app_state$state)>=1){
      
      df <- read.csv(isolate(input$file1$datapath),
                   header = isolate(input$header),
                   sep = isolate(input$sep),
                   quote = isolate(input$quote))
      
      #Store the dependent variable (token) and predictor names
      dependent<-isolate(input$Y)
      preds <- isolate(input$predictors)
      
      #Extract the selected columns and keep only complete cases (no missing values)
      dfbis <- df[complete.cases(df[,preds]),c(dependent,preds)]
      dfbis<-subset(dfbis,dfbis[dependent]!="")
      
      #Update state of the app: preprocessing done
      app_state$state<-2
      
      #Print the variants, number of predictors and of observations
      return(paste(c("PREPROCESSING RESULTS:","\n","Variants: ",as.vector(unique(df[[dependent]])),"\n","Number of predictors: ",ncol(dfbis)-1,"\n","Number of observations :",nrow(dfbis))))
    }
    else{
      #If the player starts preprocessing before loading a file
      return("Load a file before running preprocessing")
    }
  })
  
  
  
  
  # Boruta algorithm to perform feature selection and hierarchization ----
  output$feedbackplot<-renderText({
    
    #Perform the action when the button in the Analyze section is pressed
    req(input$startfitting)
    
    #Check that the preprocessing stage has been done
    if(app_state$state>=2){
    
      #Displays progress bar (this step can take a while to process)
      withProgress(message = 'Processing Data', value = 0, {
    
        #First step: formatting the data based on the previous steps
        incProgress(1/3, detail = "Formatting Data")
        
        df <- read.csv(isolate(input$file1$datapath),
                   header = isolate(input$header),
                   sep = isolate(input$sep),
                   quote = isolate(input$quote))
    
        dependent<-isolate(input$Y)
        preds <- isolate(input$predictors)
    
        dfbis <- df[complete.cases(df[,c(preds,dependent)]),c(preds,dependent)]
        dfbis<-subset(dfbis,dfbis[dependent]!="")
        
        #Formula to be used in the Boruta function
        formula=paste("factor(",dependent,") ~.")
    
        #Second step: running Boruta algorithm
        incProgress(1/3, detail = "Running Boruta")
        
        
        boruta.object<-Boruta(as.formula(formula), data=dfbis,doTrace=0)
        #Perform a rough fix of tentative decisions if the option is ticked
        if(isolate(input$correction)){
          boruta.object<-TentativeRoughFix(boruta.object)
        }
        
        #Store the history of Boruta importance 
        history<-as.data.frame((boruta.object$ImpHistory))
        #Store the Boruta decisions on variables
        decision<-factor(boruta.object$finalDecision,levels = c("Confirmed", "Rejected", "Tentative"))
    
        #Third step: prepare the plot
        incProgress(1/3, detail = "Plotting Results")
    
        
        app_state$plot<-history%>%
          select(-shadowMean,-shadowMax,-shadowMin)%>%
          gather(predictor,measurement)%>%
          filter(measurement!=-Inf)%>%
          ggplot()+
            geom_boxplot(aes(x=reorder(predictor, measurement, mean),y=measurement,fill=decision[predictor]),outlier.shape = NA)+
            coord_flip()+
            theme_light()+
            theme(legend.position="bottom",axis.title.x=element_text(face='bold'),axis.title.y=element_text(face='bold'),axis.text.x=element_text(face='bold.italic'),axis.text.y=element_text(face='bold.italic'))+
            xlab('Predictors')+
            labs(fill='Feature Selection Decision')+
            ylab('Mean Decrease Accuracy estimates (Z-score)')+ 
            scale_fill_manual(values=c("#33cc33", "#ff5050", "#ffcc66"))
        
        #Update state of the app: Boruta done
        app_state$state<-3
      })
      
      return(paste("Boruta converged in ",round(boruta.object$timeTaken,1)," sec. Go to the Visualize tab"))
    }
  })
  
  
  
  
  
  # Displays the plot of Boruta results ----
  output$forestresults<-renderPlot({
    if(app_state$state==3){
      plot(app_state$plot)
    }
  })
  
  
  
  
  # Downloading the plot as a pdf ----
  output$down <- downloadHandler(
    
    filename =  function() {
      "plot.pdf"
    },
    # content is a function with argument file. content writes the plot to the device
    content = function(file) {
      pdf(file) # open the pdf device
      plot(app_state$plot) # draw the plot
      dev.off()  # turn the device off
    } 
  )
  
}






# Create Shiny app ----
shinyApp(ui, server)
