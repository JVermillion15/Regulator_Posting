library(httr)
library(jsonlite)
install.packages("stringer")
library(stringer)


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
Renumeration <- list()
Renumeration <- as.data.frame(parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionRemuneration)
## I need to restructure this to match the other data
Renumeration <- gather(Renumeration,key="variable",value="value")
Renumeration$Max_Range <- 0 # Initlialize Empty Column to store Max
Renumeration$Min_Range <- 0 # Initialize Empty Column to store Min
# Use vectorized operations to fill columns
# Use vectorized operations to fill columns
# Function to fill MaximumRange and MinimumRange based on previous row values
# Load the stringr package for grepl function
library(stringr)

# Function to fill MaximumRange and MinimumRange based on specific row patterns
# Find indices where MaximumRange and MinimumRange occur
max_indices <- grep("^MaximumRange", Renumeration$Variable)
min_indices <- grep("^MinimumRange", Renumeration$Variable)

###################################################### Fill the values in MaximumRange and MinimumRange based on the identified indices
for (i in seq_along(max_indices)) {
  max_index <- max_indices[i]
  min_index <- min_indices[i]
  
  if (max_index > 1 && min_index > 1) {
    Renumeration$Value[max_index] <- Renumeration$Value[min_index - 2]
  }
}

# Print the resulting data frame
print(Renumeration)

######################################################### Filter Out Un-Needed Values for Variable

Renumeration <- parsed_json$SearchResult$SearchResultItems$MatchedObjectDescriptor$PositionRemuneration
Renumeration <- bind_rows(Renumeration)
Renumeration <- Renumeration %>% select(-RateIntervalCode, -Description) ## Drop unneccessary variables

####################################################### Create Master Data Set ###############################################################################################



FDIC_Postings <- cbind(Organization_Name,Location, Position_ID,Position_Title,Renumeration,Job_Summary)

##############################################################################################################################################################################
