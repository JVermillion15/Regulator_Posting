library(httr)
library(jsonlite)
library(dplyr)
library(anytime)

# API key obtained from USAJOBS
api_key <- "sG5swkh00UaEKj3O4+hPBVYptLx380Uk3fg9jRMFJbo="  ## Please replace with your actual API key
####### User Search Input Parameters, please enter todays date #####################
Keywords <- c("FDIC","Treasury Department") # Enter various departments you would like added to the regulatory posting data set
Date <- "01-12-24" # Update with todays current date

# API endpoint for job search
base_url <- "https://data.usajobs.gov/api/search"

# Loop through each keyword
for (Keyword in Keywords) {
  # Specify the parameters for the job search
  search_params <- list(
    "Keyword" = Keyword,
    "Page" = 1,
    "ResultsPerPage" = 10000
  )
  
  # Headers for the API request
  headers <- c(
    "Host" = "data.usajobs.gov",
    "User-Agent" = "jvermillion@aba.com",
    "Authorization-Key" = api_key,
    "Accept" = "application/json"
  )
  
  # Make the API request
  response <- GET(
    url = base_url,
    query = search_params,
    add_headers(.headers = headers)
  )
  
  # Extract and parse JSON content
  parsed_json <- fromJSON(content(response, "text"), flatten = TRUE)
  
}

################################## Make sense of what we have, save what we want and format it to dataframes ########################################################

Position_ID <- list()
Position_ID <- parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.PositionID
Position_ID <- as.data.frame(Position_ID)
Position_Title <- list()
Position_Title <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.PositionTitle)
Organization_Name <- list()
Organization_Name <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.OrganizationName)
Job_Summary <- list()
Job_Summary <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.UserArea.Details.JobSummary)
Location <- list()
Location <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.PositionLocationDisplay)
Renumeration <- list()
Renumeration <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.PositionRemuneration)

Renumeration <- parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.PositionRemuneration
Renumeration <- bind_rows(Renumeration)
Renumeration <- Renumeration %>% select(-RateIntervalCode, -Description) ## Drop unneccessary variables

Low_Grade <- list()
Low_Grade <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.UserArea.Details.LowGrade)
High_Grade <- list()
High_Grade <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.UserArea.Details.HighGrade)
Post_Date <- list()
Post_Date <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.PublicationStartDate)
Closed_Date <- list()
Closed_Date <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor.ApplicationCloseDate)

####################################################### Create Master Data Set ###############################################################################################

Regulator_Postings <- bind_cols(Organization_Name,Location, Position_ID,Position_Title,Renumeration,Low_Grade, High_Grade,Post_Date,Closed_Date, Job_Summary)

###################################### Clean Up those ugly column names

new_names <- c("Organization","Location","Position ID","Position Title","Minimum Salary ($)","Maximum Salary ($)","Low Grade","High Grade","Posted On","Application Closes on","Description")
colnames(Regulator_Postings)[1:11] <- new_names

######################################################## Make sure variable structures are correct (They are not, so I am fixing) ##############################################

Regulator_Postings$`Minimum Salary ($)` <- as.numeric(Regulator_Postings$`Minimum Salary ($)`)
Regulator_Postings$`Maximum Salary ($)` <- as.numeric(Regulator_Postings$`Maximum Salary ($)`)
Regulator_Postings$`Low Grade` <- as.factor(Regulator_Postings$`Low Grade`) ## Convert structure to factor
Regulator_Postings$`High Grade`<- as.factor(Regulator_Postings$`High Grade`) ## Convert data structure to factor

### I need to clean up the posting date and closing date so they can correctly be formatted as dates
Regulator_Postings$`Posted On` <- sapply(strsplit(Regulator_Postings$`Posted On`, "T"), `[`, 1)
Regulator_Postings$`Application Closes on` <- sapply(strsplit(Regulator_Postings$`Application Closes on`, "T"), `[`, 1)
Regulator_Postings$`Posted On`<- as.Date(trimws(Regulator_Postings$`Posted On`))
Regulator_Postings$`Application Closes on` <- as.Date(trimws(Regulator_Postings$`Application Closes on`))

##### Change the structure of Organization to be a factor

Regulator_Postings$Organization <- as.character(Regulator_Postings$Organization)

# Assuming Regulator_Postings$Organization is your factor variable
par(mar = c(22, 4, 4, 2) + 0.1)
barplot(table(Regulator_Postings$Organization[1:140]), 
        main = paste("Regulatory Job Postings by Agency -", Date),
        ylab = "Job Postings", 
        col = "skyblue",
        las = 2)

########################## Write this pull to a csv ##########################################################################################
filename <- paste0("RegulatorPostings_",Date,".csv")
write.csv(Regulator_Postings,filename,row.names = FALSE)

