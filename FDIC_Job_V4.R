library(httr)
library(jsonlite)
library(stringr)
library(dplyr)
library(anytime)


####### API key obtained from USAJOBS, Im sure its fine if we share this #######################################################################
api_key <- "sG5swkh00UaEKj3O4+hPBVYptLx380Uk3fg9jRMFJbo=" ## Youre all good to use my key, just don't send me to jail 
Keyword <- ("FDIC") ## This will work for any agency, so we can sub in OCC

# API endpoint for job search
base_url <- "https://data.usajobs.gov/api/search"

# Specify the parameters for the job search
search_params <- list(
  "Keyword" = Keyword,
  "Page" = 1,
  "ResultsPerPage" = 1000
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

############################################################ Extract content and parse as JSON
json_content <- content(response, "text")
parsed_json <- fromJSON(json_content)
str(parsed_json)

################################################# Lets peel back the layers and try to understand what we have here  #####################################################################

str(parsed_json, max.level = 1)
str(parsed_json, max.level = 2)
str(parsed_json, max.level = 3)
str(parsed_json, max.level = 4)
str(parsed_json, max.level = 5)
str(parsed_json, max.level = 6)
str(parsed_json, max.level = 7)


######################################################### Function Attempting to flatten Parsed JSON Content ##################################################################
flatten_json <- function(y) {
  out <- list()
  
  flatten <- function(x, name = '') {
    if (is.list(x)) {
      for (a in seq_along(x)) {
        flatten(x[[a]], paste0(name, a, '_'))
      }
    } else {
      out[[substr(name, 1, nchar(name) - 1)]] <- x
    }
  }
  
  flatten(y)
  return(out)
}

# Apply flatten_json function
flattened_data <- flatten_json(parsed_json)
print(flattened_data)

####### I think I am going to have to manually peel this shit back, I am structuring our new data table now, creating an array/data frame called FDIC_Postings ###

Position_ID <- list()
Position_ID <- parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionID
Position_ID <- as.data.frame(Position_ID)
Position_Title <- list()
Position_Title <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionTitle)
Organization_Name <- list()
Organization_Name <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$OrganizationName)
Job_Summary <- list()
Job_Summary <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$UserArea$Details$JobSummary)
Location <- list()
Location <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionLocationDisplay)
Renumeration <- list()
Renumeration <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionRemuneration)


######################################################### Dig out salary range

Renumeration <- parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionRemuneration
Renumeration <- bind_rows(Renumeration)
Renumeration <- Renumeration %>% select(-RateIntervalCode, -Description) ## Drop unneccessary variables


##############################################################################################################################################################################
Low_Grade <- list()
Low_Grade <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$UserArea$Details$LowGrade)
High_Grade <- list()
High_Grade <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$UserArea$Details$HighGrade)
Post_Date <- list()
Post_Date <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PublicationStartDate)
Closed_Date <- list()
Closed_Date <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$ApplicationCloseDate)


####################################################### Create Master Data Set ###############################################################################################

FDIC_Postings <- bind_cols(Organization_Name,Location, Position_ID,Position_Title,Renumeration,Low_Grade, High_Grade,Post_Date,Closed_Date, Job_Summary)

###################################### Clean Up those ugly column names

new_names <- c("Organization","Location","Position ID","Position Title","Minimum Salary ($)","Maximum Salary ($)","Low Grade","High Grade","Posted On","Application Closes on","Description")
colnames(FDIC_Postings)[1:11] <- new_names


######################################################## Make sure variable structures are correct (They are not, so I am fixing) ##############################################

FDIC_Postings$`Minimum Salary ($)` <- as.numeric(FDIC_Postings$`Minimum Salary ($)`)
FDIC_Postings$`Maximum Salary ($)` <- as.numeric(FDIC_Postings$`Maximum Salary ($)`)
FDIC_Postings$`Low Grade` <- as.factor(FDIC_Postings$`Low Grade`) ## Convert structure to factor
FDIC_Postings$`High Grade`<- as.factor(FDIC_Postings$`High Grade`) ## Convert data structure to factor

### I need to clean up the posting date and closing date so they can correctly be formatted as dates
FDIC_Postings$`Posted On` <- sapply(strsplit(FDIC_Postings$`Posted On`, "T"), `[`, 1)
FDIC_Postings$`Application Closes on` <- sapply(strsplit(FDIC_Postings$`Application Closes on`, "T"), `[`, 1)
FDIC_Postings$`Posted On`<- as.Date(trimws(FDIC_Postings$`Posted On`))
FDIC_Postings$`Application Closes on` <- as.Date(trimws(FDIC_Postings$`Application Closes on`))


############################################# Test to see if everything has structured correctly thus far #############################################################
Average_Max_Salary_offered <- mean(FDIC_Postings$`Maximum Salary ($)`) #230152.7, so perfect, the data is structured how we need it

str(FDIC_Postings) ## We are golden up to this point 



