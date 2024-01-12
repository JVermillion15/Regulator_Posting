import requests
import json
import pandas as pd
from datetime import datetime

# API key obtained from USAJOBS
api_key = "sG5swkh00UaEKj3O4+hPBVYptLx380Uk3fg9jRMFJbo="  # Replace with your actual API key

# User Search Input Parameters
keywords = ["FDIC", "Treasury Department"]
date_str = "01-12-24"

# API endpoint for job search
base_url = "https://data.usajobs.gov/api/search"

# Initialize an empty list to store data
data_list = []

# Loop through each keyword
for keyword in keywords:
    # Specify the parameters for the job search
    search_params = {
        "Keyword": keyword,
        "Page": 1,
        "ResultsPerPage": 10000
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
    parsed_json = response.json()

    # Extract and parse JSON content
    search_results = parsed_json.get("SearchResult", {}).get("SearchResultItems", {}).get("MatchedObjectDescriptor", {})
    
    # Append data to the list
    data_list.extend(search_results)

# Create a DataFrame from the list
df = pd.DataFrame(data_list)

# Create Master Data Set
regulator_postings = df[["OrganizationName", "PositionLocationDisplay", "PositionID", "PositionTitle",
                         "PositionRemuneration", "UserArea.Details.LowGrade", "UserArea.Details.HighGrade",
                         "PublicationStartDate", "ApplicationCloseDate", "UserArea.Details.JobSummary"]]

# Clean up column names
new_names = ["Organization", "Location", "Position ID", "Position Title", "Minimum Salary ($)", "Maximum Salary ($)",
             "Low Grade", "High Grade", "Posted On", "Application Closes on", "Description"]
regulator_postings.columns = new_names

# Clean up variable structures
regulator_postings["Minimum Salary ($)"] = pd.to_numeric(regulator_postings["Minimum Salary ($)"])
regulator_postings["Maximum Salary ($)"] = pd.to_numeric(regulator_postings["Maximum Salary ($)"])
regulator_postings["Low Grade"] = regulator_postings["Low Grade"].astype("category")
regulator_postings["High Grade"] = regulator_postings["High Grade"].astype("category")

# Clean up date formats
regulator_postings["Posted On"] = pd.to_datetime(regulator_postings["Posted On"].str.split("T").str[0].str.strip())
regulator_postings["Application Closes on"] = pd.to_datetime(regulator_postings["Application Closes on"].str.split("T").str[0].str.strip())

# Bar plot example
regulator_postings["Organization"].value_counts().head(140).plot(kind="bar", color="skyblue", rot=0,
                                                                title=f"Regulatory Job Postings by Agency - {date_str}",
                                                                ylabel="Job Postings")

# Write to CSV
filename = f"RegulatorPostings_{date_str}.csv"
regulator_postings.to_csv(filename, index=False)
