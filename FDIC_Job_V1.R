library(httr)
library(jsonlite)



####### API key obtained from USAJOBS, Im sure its fine if we share this #######################################################################
api_key <- "sG5swkh00UaEKj3O4+hPBVYptLx380Uk3fg9jRMFJbo="
Keyword <- "FDIC"

# API endpoint for job search
base_url <- "https://data.usajobs.gov/api/search"

# Specify the parameters for the job search
search_params <- list(
  "Keyword" = Keyword,
  "Page" = 1,
  "ResultsPerPage" = 10
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

# Extract content and parse as JSON
json_content <- content(response, "text")
parsed_json <- fromJSON(json_content)
str(parsed_json)

## Lets peel back the layers and try to understand what we have here  #####################################################################

str(parsed_json, max.level = 1)
str(parsed_json, max.level = 2)
str(parsed_json, max.level = 3)
str(parsed_json, max.level = 4)
str(parsed_json, max.level = 5)
str(parsed_json, max.level = 6)
str(parsed_json, max.level = 7)


######################## Function Attempting to flatten Parsed JSON Content ##################################################################
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
Location <- Location[,1:3]

FDIC_Postings <- cbind(Organization_Name,Location, Position_ID,Position_Title,Job_Summary)

##########################################################################
