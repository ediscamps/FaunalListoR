
library(readxl)
library(dplyr)
library(shiny)
library(DT)
library(shinydashboard)
require(openxlsx)
library(tidyr)
library(tibble) #pour deframe
library(DBI)


# tabl <- readxl::read_xlsx("docsumo_test1.xlsx")
# colnames(tabl)[1] <- "taxon"
# 
# taxa_tofind <- tabl$taxon
# df_taxa_cleanname <- data.frame(previous_name = taxa_tofind, new_name = rep("",length(taxa_tofind)))


### extracting mammals from TAXREF inpn
# taxref <- read.csv("TAXREF18.0_ALL__24_01_2025_mammalia.csv", sep = ";")
# taxmam <- subset(taxref, select = c(LB_NOM, NOM_VERN, NOM_VERN_ENG))
# write.csv(taxmam, "TAXREF_mammalia.csv")

tax_theso <- readxl::read_xlsx("tax_theso.xlsx")
# BDA_sites <- readxl::read_xlsx("BDA_sites.xlsx")
# BDA_occup <- readxl::read_xlsx("BDA_occup.xlsx")

## connection a BDA
con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = "postgresql17a.db.huma-num.fr",
  dbname = "bdarcheo",
  port = 5432,
  user = "user_bdarcheo_read",
  password = "tjiA8sc5Ac_oQXk5nTDYR"
)

# BDA_sites <- DBI::dbGetQuery(con, 'SELECT * FROM "BDA"."sites"')
# BDA_occup <- DBI::dbGetQuery(con, 'SELECT * FROM "BDA"."occupations"')

ui_import <- fluidPage(
  tags$head(
    tags$style(HTML("hr {border-top: 3px solid #000000;}"))
  ),
  hr(),
  strong("Importing Data", style = "font-size:30px;"),
  br(),
  strong("To start, you need to import.xlsx file:"),br(),br(),
  
  fileInput("table_importedfile", "First, upload your data (.xlsx)", multiple = FALSE),
  em("If you just want to explore the app, you can import a test dataset:"), 
  checkboxInput("import_testdata", "Use test dataset instead of my own", value = FALSE),
  hr(),
  "You should provide a table with taxa as rows, and occupations (& quantification type) as columns.", br(),
  strong("Make sure that every column as a unique name"), "(for example Layer 1 NISP, Layer 1 MNI, Layer 2 NISP, etc.)",br(),
  strong("Make sure that every cell (e.g. NISP value) is a number, otherwise the information will be lost."),br(),
  hr(),
  
  
  DT::dataTableOutput("table_toimport")
  
)

ui_baseinfo <- fluidPage(
  actionButton("fetchBDA", "Click here to update BDA sites & occupations"),
  
  textOutput("text_next_id_faunalstudy"),
  br(),
  selectInput("selector_BDA_country", label ="Choose the country", 
              choices = "", 
              selected = "France"),
  selectInput("selector_BDA_sites", label ="Choose the site", choices = ""),
  textOutput("id_site"),
  "If the site you're looking for is not present in this list, please first add it at https://bda.huma-num.fr/",
  br(),br(),
  strong("List of occupations entered for this site in BDA"),
  DT::dataTableOutput("occup_BDA_table"),
  "If occupations (layers) included in the faunal lists are not present in the following table, please first add them at https://bda.huma-num.fr/",

  hr(),
  strong("Faunal lists already entered for this site"),
  DT::dataTableOutput("faunalstudiesentered"),
  # textOutput("faunalstudiesentered_text"),
  strong("Make sure you don't enter the same faunal study twice!"),
  hr(),
  
  
  
  radioButtons("faunalid_type", "Type of method used for identification:", 
               choiceNames = list("Morphological identifications", "ZooMS identifications"), 
               choiceValues = list("Morpho", "ZooMS"),
               selected = "Morpho"),
    
  checkboxGroupInput("quanti_type","Type of quantification unit(s) used in the faunal lists:", 
               choiceNames = list("Number of identified specimens (NISP)","Minimum number of individuals (MNI)","Presence/absence only"),
               choiceValues = list("NISP","MNI","Presence"),
               selected = "NISP"),

  textInput("ref", "Enter the bibliographic reference of the list here:"),
  numericInput("refYear", "Enter the year of the bibliographic reference here:",NA, min=1850,max=2050),
  # selectInput("excavationYears", "Enter the decade(s) during which the faunal remains were collected:", choices = c("unknown","before 1950","50-60s","50-60s","70-80s","80-90s","90-2000s","after 2000"), multiple = T),
  textInput("notes", "Notes / observations:"),
  DT::dataTableOutput("table_baseinfo")

)




  
### bine indiquer que TABLEAU NE DOIT PAS CONTENIR DE LIGNES "total", ni de somme par familles
## la premiere colonne contient le nom du taxon





ui_corres <- fluidPage(
  
  #### import faunal lists as table with rows for taxa, columns for layers
  
  hr(),
  
  strong("FOR EACH ROW, select the appropriate corresponding taxon:"),br(),
  
  "Note that we recommend to use", em("Equus ferus"), "for wild horses and", em("Capra ibex/pyrenaica"), "for ibex",br(),br(),
  uiOutput("taxa_inputs"),
  # radioButtons("tax_searchtype","Type of taxa names to search for:",
  #              choiceNames = list("French common names","English common names","Binomial (Latin) nomenclature"),
  #              choiceValues = list("FRENCH","ENGLISH","LATIN")),br(),br(),
  hr(),
  
  strong("FOR EACH COLUMN, select the corresponding BDA occupation:"),br(),br(),
    uiOutput("occup_inputs"),
  hr(),
  strong("FOR EACH COLUMN, select the corresponding quantification types:"),br(),br(),
  
  uiOutput("quanti_inputs"),
  hr(),
  
  
  actionButton("importdata", "Confirm all the correspondances"),
  hr(),
  tabsetPanel(
    tabPanel("Table modified for importation", DT::dataTableOutput("table_modified"))
  ),
  actionButton("concatenatedata", "IF YOU ARE 100% OK WITH THE ABOVE, click here to import the data and restart the app")
  # downloadButton("export_table_modified", "Download as an Excel sheet")
)

ui_tables <- fluidPage(
  
  tabsetPanel(
    tabPanel("Sites in BDA", DT::dataTableOutput("table_BDA_sites")),
    tabPanel("Occupations in BDA", DT::dataTableOutput("table_BDA_occup")),
    tabPanel("BaseInfo in FaunalListoR", DT::dataTableOutput("table_FaunalListoR_baseinfo")),
    tabPanel("FaunalLists in FaunalListoR", DT::dataTableOutput("table_FaunalListoR_faunallists"))

    
    # tabPanel("Table modified for importation", DT::dataTableOutput("table_modified"))
  )
  
)


ui <- dashboardPage(
  
  dashboardHeader(title = "FaunalListoR"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Importing data", tabName = "tab_import"),
      menuItem("Basic information", tabName = "tab_baseinfo"),
      menuItem("Identifying correspondances", tabName = "tab_corres"),
      menuItem("Tables", tabName = "tab_tables"),
      # pickerInput("list_sidebar_group", "Groups to analyse:", choices = "", multiple = T,  options = list(  `actions-box` = TRUE, dropupAuto = FALSE, size = 10, windowPadding = "[100,0,0,0]")),
      # pickerInput("list_sidebar_taxa", "Taxa to analyse:", choices = "", multiple = T,  options = list(  `actions-box` = TRUE, dropupAuto = FALSE, size = 10, windowPadding = "[100,0,0,0]")), #options necessary to that it does not cause display probem with the top bar
      br()
    )
  ),
  dashboardBody(
    
    # controlling horizontal lines
    tags$head(
      tags$style(HTML("hr {border-top: 2px solid #000000;}"))
    ),
    
    tabItems(
      tabItem("tab_import",
              ui_import
      ),
      tabItem("tab_baseinfo",
              ui_baseinfo
      ),
      
      tabItem("tab_corres",
              ui_corres
      ),    
      tabItem("tab_tables",
              ui_tables
      )
      
      # tabItem("tab_cut",
      #         ui_tab_cut
      # ),
      # tabItem("rawdata",
      #         "rawtable",
      #         downloadButton("downloadCsv", "Download as CSV")
      )
    )
  )






########################## SERVER SIDE






server <- function(input, output, session) {
  
  FaunalListoR_baseinfo <- reactive(read_excel("FaunalListoR_data.xlsx", sheet = "BaseInfo"))
  FaunalListoR_faunallists <- reactive(read_excel("FaunalListoR_data.xlsx", sheet = "FaunalLists"))
  
  BDA_sites_reactive <- reactive(DBI::dbGetQuery(con, 'SELECT * FROM "BDA"."sites"'))
  BDA_occup_reactive <- reactive(DBI::dbGetQuery(con, 'SELECT * FROM "BDA"."occupations"'))
  
  # observe({
  # BDA_sites <- BDA_sites_reactive()
  # BDA_occup <- BDA_occup_reactive()
  # })
  
  observeEvent(input$fetchBDA, {
    BDA_sites <- DBI::dbGetQuery(con, 'SELECT * FROM "BDA"."sites"')
    BDA_occup <- DBI::dbGetQuery(con, 'SELECT * FROM "BDA"."occupations"')
    session$reload()
  }) ## ne marche pas bien, tout passer en reactive ?
  
  

  
  
  
  #creating empty containers
  df_importedfile <- reactiveVal(NULL)
  excel_filename <- NULL
  list_taxa_tofind <- reactiveVal(NULL)
  list_taxa_modified <- reactiveVal(NULL)
  list_occup_tofind <- reactiveVal(NULL)
  list_occup_BDA_withid <- reactiveVal(NULL)
  list_occup_BDA_withsequences <- reactiveVal(NULL)
  list_occup_modified <- reactiveVal(NULL)
  list_quanti_types <- reactiveVal(NULL)
  df_modifiedtable <- reactiveVal(NULL)
  df_baseinfo <- reactiveVal(NULL)
  df_faunalstudiesentered <- reactiveVal(NULL)
  
  BDA_selectsites <- reactive(
    BDA_sites_reactive() %>%
      filter(pays == input$selector_BDA_country) %>%
      dplyr::select("nom_site","id_sites") %>%
      arrange(nom_site) %>%
      deframe() #pour creer une named list
  )
  
  country_list <- reactive(
    unique(BDA_sites_reactive()$pays)
  )
    
  observe({
    updateSelectInput(
      session,
      "selector_BDA_country",
      choices = country_list(),
    )
  })
  
  
  
  id_selectedsite <- reactive(
    BDA_sites_reactive() %>%
      filter(id_sites == input$selector_BDA_sites) %>%
      dplyr::select("id_sites")%>%
      pull()
  )
  
  # getting the site name ## all of this is necessary because of duplicates in site names
  name_selectedsite <- reactive(
    BDA_sites_reactive() %>%
      filter(id_sites == input$selector_BDA_sites) %>%
      dplyr::select("nom_site")%>%
      pull()
  )

  
  output$id_site <- renderText(c("BDA ID number of the site:", id_selectedsite()))
  
  next_id_faunalstudy <- reactive(
    max(FaunalListoR_faunallists()$id_faunalstudy)+1
  )
  
  output$text_next_id_faunalstudy <- renderText(c("The next number available for id_faunalstudy is:", next_id_faunalstudy()))
  
  
  df_baseinfo <- reactive(
    data.frame(id_faunalstudy = next_id_faunalstudy(),
               site = name_selectedsite(),
               id_site = id_selectedsite(),
               ref = input$ref,
               refYear = input$refYear,
               faunalid_type = input$faunalid_type,
               quanti_type = paste(input$quanti_type, collapse =";"),
               # excavationYears = paste(input$excavationYears, collapse=";"),
               notes = input$notes)
  )
  
  
  output$table_baseinfo = DT::renderDT({
    df_baseinfo()
  })

  output$table_BDA_sites = DT::renderDT({
    BDA_sites_reactive()
  })
  output$table_BDA_occup = DT::renderDT({
    BDA_occup_reactive()
  })
  output$table_FaunalListoR_baseinfo = DT::renderDT({
    FaunalListoR_baseinfo()
  })
  output$table_FaunalListoR_faunallists = DT::renderDT({
    FaunalListoR_faunallists()
  })
  
  ### creating list of occupations for given site, and list of faunal lists previously entered
  observeEvent(input$selector_BDA_sites, {
    x <- BDA_occup_reactive() %>%
      filter(id_sites %in% id_selectedsite()) %>%
      dplyr::select("sequence","num_couche","id_occupations") %>%
      mutate(num_couche=replace(num_couche, is.na(num_couche), "no name in BDA")) %>% ##used to prevent bugs with NAs values
      mutate(sequence=replace(sequence, is.na(sequence), "no name in BDA"))##used to prevent bugs with NAs values
    
    list_occup_BDA_withsequences(x)
    
    y <- BDA_occup_reactive() %>%
      filter(id_sites %in% id_selectedsite()) %>%
      dplyr::select("num_couche","id_occupations") %>%
      mutate(num_couche=replace(num_couche, is.na(num_couche), "no name in BDA")) ##used to prevent bugs with NAs values

    y <- deframe(y) #pour creer une named list

    list_occup_BDA_withid(y)
    
    baseinfo <- data.frame(FaunalListoR_baseinfo())

    z <- baseinfo %>%
      filter(id_site == input$selector_BDA_sites)

    df_faunalstudiesentered(z)

    
  })

  
  ### updating list of sites in ui
  observe({
      updateSelectInput(session, "selector_BDA_sites",
                        choices = BDA_selectsites())
    })
  
  ### updating list of occup in ui
  observe({
   updateSelectInput(session, "selector_BDA_occup",
                     choices = list_occup_BDA_withid())
  })

  output$occup_BDA_table <- renderDT(list_occup_BDA_withsequences())
  
  output$faunalstudiesentered <- renderDT(df_faunalstudiesentered())
  # output$faunalstudiesentered_text <- renderText(as.character(df_faunalstudiesentered()))
  
  
  #
  observe({
    if (!is.null(input$table_importedfile)){
      excel_filename <- input$table_importedfile$datapath
    }
    
    if (input$import_testdata == "TRUE"){
      excel_filename <- "TestData.xlsx"
    }
    
    if (!is.null(excel_filename)){
      dataFile <- read_excel(excel_filename, sheet=1)
      list_occup_tofind(as.matrix(colnames(dataFile[,-1])))
      colnames(dataFile)[1] <- "taxon_original" 
      dat <- data.frame(dataFile)
      list_taxa_tofind(as.matrix(dataFile$taxon_original))
      df_importedfile(dat)
    }
    
  })
  
  output$table_toimport = DT::renderDT({
    df_importedfile()
  }, options = list(pageLength = 50, scrollX = TRUE))

  
  
  ######## creating the inputs for the taxa
  output$taxa_inputs <- renderUI({
    taxa_tofind <- list_taxa_tofind()
    pvars <- length(taxa_tofind)
    if (pvars > 0) {
      div(
        lapply(seq(pvars), function(i) {
          onetaxtofind <- taxa_tofind[i]
          ### finding correspondences for taxon and creating list
          
            tax_corres <- tax_theso %>% 
              filter(row_number() %in% grep(onetaxtofind, paste(tax_theso$LATIN, tax_theso$FRENCH, tax_theso$ENGLISH))) %>%
              dplyr::select(LATIN) %>%
              as.matrix()
# 
#           
#           if(input$tax_searchtype == "LATIN"){
#             tax_corres <- tax_theso %>% 
#               filter(row_number() %in% grep(onetaxtofind, paste(tax_theso$LATIN, tax_theso$FRENCH))) %>%
#               dplyr::select(LATIN) %>%
#               as.matrix()
#           }
#           if(input$tax_searchtype == "FRENCH"){
#             tax_corres <- tax_theso %>% 
#               filter(row_number() %in% grep(onetaxtofind, tax_theso$FRENCH)) %>%
#               dplyr::select(LATIN) %>%
#               as.matrix()
#           }
#           if(input$tax_searchtype == "ENGLISH"){
#             tax_corres <- tax_theso %>% 
#               filter(row_number() %in% grep(onetaxtofind, tax_theso$ENGLISH)) %>%
#               dplyr::select(LATIN) %>%
#               as.matrix()
#           }
          
            
            if(nrow(tax_corres) > 0){
            first_corres <- as.character(tax_corres[1,])
            print(tax_corres)
            }
            
            if(nrow(tax_corres) == 0){
              first_corres <- "NO CORRESPONDANCE FOUND"
            }
            
            selectizeInput(inputId = paste0("taxinput_", i),label = taxa_tofind[i], choices = tax_theso$LATIN, options=list(create=TRUE),
                           
                           
                           selected = case_when(    ##########CETTE PARTIE PERMET D'ATTRIBUER PAR DEFAUT LE Taxon le plus probable pour certains cas
                             "Equus caballus" %in% tax_corres ~ "Equus ferus",
                             onetaxtofind == "Equus caballus" ~ "Equus ferus",
                             "Capra ibex" %in% tax_corres ~ "Capra ibex/pyrenaica",
                             "Rupicapra rupicapra" %in% tax_corres ~ "Rupicapra sp.",
                             "Cervus elaphus" %in% tax_corres ~ "Cervus elaphus",
                             # onetaxtofind == "Megaloceros giganteus" ~ "Megaloceros giganteus", #not working?
                             # taxa_tofind[i] == "Mégacéros" ~ "Megaloceros giganteus", #not working?
                             .default = first_corres
                           )
            )
            
          
        })
      )
    }
  })
  
  
  ######## creating the inputs for the occupations of columns
  output$occup_inputs <- renderUI({
    occup_tofind <- list_occup_tofind()
    occup_BDA <- list_occup_BDA_withid()
    pvars <- length(occup_tofind)
    if (pvars > 0) {
      div(
        lapply(seq(pvars), function(i) {

          selectizeInput(inputId = paste0("occupinput_", i),label = occup_tofind[i], choices = occup_BDA, selected = NULL, options = list(placeholder = 'BDA has no occupations for this site, this will not work!'))
          
            })
      )
    }
  })

  # ######## creating the inputs for the quanti types of columns
  output$quanti_inputs <- renderUI({
    occup_tofind <- list_occup_tofind()
    pvars <- length(occup_tofind)
    if (pvars > 0) {
      div(
        lapply(seq(pvars), function(i) {

          radioButtons(inputId = paste0("quantiinput_", i),label = occup_tofind[i], inline = T, choices = c("NISP","MNI","Presence"), selected = 
                         case_when(
                           "NISP" %in% input$quanti_type ~ "NISP",
                           input$quanti_type == "MNI" ~ "MNI",
                           input$quanti_type == "Presence" ~ "Presence",
                           .default = "NISP")
                       )
        })
      )
    }
  })
  
  

  
  
  
  ######## importing the data with the button

  observeEvent(input$importdata, {
    
    # getting the new taxa names from the inputs
    taxa_tofind <- list_taxa_tofind()
    if (!is.null(taxa_tofind)) {
      list_tax_inputs <- grep("taxinput_", names(input), value=TRUE)
        x <- data.frame(
          "taxon_unified" = unlist(reactiveValuesToList(input)[list_tax_inputs])
        )
      list_taxa_modified(as.vector(x))
    }
    
    # pasting the new taxa names
    bigtable <- cbind(list_taxa_modified(), df_importedfile())
    # getting the new occup names from the inputs
    occup_tofind <- list_occup_tofind()
    
    if (!is.null(occup_tofind)) {
      list_occup_inputs <- grep("occupinput_", names(input), value=TRUE)
      x <- data.frame(
        "occup_unified" = unlist(reactiveValuesToList(input)[list_occup_inputs])
      )
      list_occup_modified(as.vector(x))
    }
    
    # getting the quanti types
    if (!is.null(occup_tofind)) {
      list_quanti_inputs <- grep("quantiinput_", names(input), value=TRUE)
      x <- data.frame(
        "quanti_type" = unlist(reactiveValuesToList(input)[list_quanti_inputs])
      )
      list_quanti_types(as.vector(x))
    }
    
    # getting the occup names
    tabl_occupid <- enframe(list_occup_BDA_withid()) %>%
      rename(occup_unified = name, occup_id = value) %>%
      select(occup_id, occup_unified)
    

    # creating correspondences between original and new occup names, plus quanti types
    old_occupnames <- colnames(bigtable)[-c(1,2)]
    tabl_occupnames <- data.frame(cbind(old_occupnames, unlist(list_occup_modified()), unlist(list_quanti_types()))) %>%
      mutate(across(2, as.numeric)) #converting ids to numeric
    colnames(tabl_occupnames) <- c("occup_original","occup_id","quanti_type")
    tabl_occupnames <- tabl_occupnames %>%
      left_join(tabl_occupid)

    # merging everything together
    longtable <- bigtable %>%
      pivot_longer(cols = 3:ncol(bigtable)) %>%
      mutate(id_faunalstudy = next_id_faunalstudy()) %>%
      rename(occup_original = name) %>%
      left_join(tabl_occupnames, by =join_by(occup_original)) %>%
      select(id_faunalstudy, taxon_unified, taxon_original, occup_id, occup_unified, occup_original, value, quanti_type) %>%
      mutate(across(7, as.integer)) %>% #converting values to integer
      filter(value > 0) %>% #removing empty values
      arrange(occup_id, taxon_unified)
      
      df_modifiedtable(longtable)
          
  })
  

  
  output$table_modified = DT::renderDT({
    df_modifiedtable()
  }, options = list(pageLength = 50, scrollX = TRUE))
  

  
  ### CONCATENATING FAUNAL LISTOR DATA
  observeEvent(input$concatenatedata, {
    x <- rbind(FaunalListoR_baseinfo(), df_baseinfo())
    y <- rbind(FaunalListoR_faunallists(), df_modifiedtable())
    write.xlsx(
      list(x,
           y
      )
      
      , file = "FaunalListoR_data.xlsx", sheetName = c("BaseInfo", "FaunalLists"), rowNames = F, colNames = TRUE, overwrite = T)
    session$reload()
    })  
  
  
  
  
  
  
  
  
  
  # #exporting table modified
  # output$export_table_modified <- downloadHandler(
  #   filename = function() {"FaunalListoR_data.xlsx"},
  #   content = function(file) {
  #     req(!is.null(df_modifiedtable()))
  #     write.xlsx(
  #       list(FaunalListoR_baseinfo(),
  #            FaunalListoR_faunallists()
  #       )
  #       
  #       , file, sheetName = c("BaseInfo", "FaunalLists"), rowNames = TRUE, colNames = TRUE)
  #     
  #   }
  # )  
  
  
  
  

  
  

} ### end server 

#  Run the application 
shinyApp(ui = ui, server = server)














