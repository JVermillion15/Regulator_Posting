
import requests
import pandas as pd

# API key obtained from USAJOBS
api_key = "sG5swkh00UaEKj3O4+hPBVYptLx380Uk3fg9jRMFJbo="
keyword = "FDIC"

# API endpoint for job search
base_url = "https://data.usajobs.gov/api/search"

# Specify the parameters for the job search
search_params = {
    "Keyword": keyword,
    "Page": 1,
    "ResultsPerPage": 10
}

# Headers for the API request
headers = {
    "Host": "data.usajobs.gov",
    "User-Agent": "jvermillion@aba.com",
    "Authorization-Key": api_key,
    "Accept": "application/json"
}

# Make the API request
response = requests.get(base_url, params=search_params, headers=headers)

# Extract content and parse as JSON
json_content = response.json()

# Display the parsed JSON
print(json_content)

# Function attempting to flatten parsed JSON content
def flatten_json(y):
    out = {}

    def flatten(x, name=''):
        if isinstance(x, dict):
            for a in x:
                flatten(x[a], name + a + '_')
        else:
            out[name[:-1]] = x

    flatten(y)
    return out

# Apply flatten_json function
flattened_data = flatten_json(json_content)
print(flattened_data)

# Creating a DataFrame called FDIC_Postings
position_id = json_content['SearchResult']['SearchResultItems'][0]['MatchedObjectDescriptor']['PositionID']
position_title = json_content['SearchResult']['SearchResultItems'][0]['MatchedObjectDescriptor']['PositionTitle']
organization_name = json_content['SearchResult']['SearchResultItems'][0]['MatchedObjectDescriptor']['OrganizationName']
job_summary = json_content['SearchResult']['SearchResultItems'][0]['MatchedObjectDescriptor']['UserArea']['Details']['JobSummary']
location = json_content['SearchResult']['SearchResultItems'][0]['MatchedObjectDescriptor']['PositionLocationDisplay']

data = {
    'Position_ID': position_id,
    'Position_Title': position_title,
    'Organization_Name': organization_name,
    'Job_Summary': job_summary,
    'Location': location
}

fdic_postings = pd.DataFrame(data)
print(fdic_postings)
