import pandas as pd
from datetime import datetime

# Creates and returns DataFrames for employee and department datasets.
def create_dataframes():
    # Department dataset
    departments_data = {
        'Department_ID': [1, 2, 3, 4, 5, 6],
        'Department_Name': ['Engineering', 'Data', 'Product', 'HR', 'Sales', 'Design']
    }

    # Employee dataset
    employees_data = {
        'Employee_ID': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 3],
        'Job_Title': [
            'Software Engineer', 'Data Scientist', 'Product Manager', 'Software Engineer',
            'Data Analyst', 'HR Manager', 'Sales Manager', 'Project Manager',
            'UX Designer', 'Operations Manager', 'Product Manager'
        ],
        'Salary': [0, 105000, 120000, 110000, 85000, 95000, 115000, 105000, 90000, 400000, 120000],
        'Years_of_Experience': [3, 4, 5, 4, 2, 6, 8, 3, 4, 7, 5],
        'Department_ID': [1, 2, 3, 9, 2, 4, 5, 3, 6, None, 3],
        'Zip_Code': ['12345', 'ABCDE', '23456', '98765', 'A1234', '54321', '1234X', '65432', '11111', '00000', '23456'],
        'Location': ['NY', 'New York', 'Claveland', 'San Francisco', 'New York', 'NY', 
                     'New York', 'New York', 'Cleveland', 'San Francisco', 'Claveland'], 
        'hiring_date': ['2020-01-01', '01-05-2019', '2018-12-15', '2022-07-15', '12-11-2021', '2020-05-10', 
                        '2021-08-20', '2019-03-10', '2020-11-05', None, '2018-12-15']  
    }

    employees_df = pd.DataFrame(employees_data)
    departments_df = pd.DataFrame(departments_data)

    return employees_df, departments_df
# Displays the original employee and department dataset.
def display_data(employees_df, departments_df):
    print("Original Employees Dataset:")
    print(employees_df, "\n")

    print("Original Departments Dataset:")
    print(departments_df, "\n")

# Displays the statistical summary for the 'Salary' column.
def display_salary_stats(employees_df):
    salary_stats = employees_df['Salary'].describe()
    print("Salary Statistics:")
    print(salary_stats, "\n")

# Validates employee zip codes and prints the invalid ones.
def identify_invalid_zip_codes(employees_df):
    invalid_zips = employees_df[~employees_df['Zip_Code'].str.match(r'^\d{5}$')]['Zip_Code']
    print("Invalid Zip Codes (Using Regex String Match):")
    print(invalid_zips, "\n")

# Displays employees who have no assigned department.
def display_empty_department_employees(employees_df):
    empty_department_employees = employees_df[employees_df['Department_ID'].isnull()][['Employee_ID', 'Job_Title']]
    print("Employees with Empty Departments:")
    print(empty_department_employees, "\n")

# Displays duplicated records in the employee dataset.
def display_duplicated_records(employees_df):
    duplicated_records = employees_df[employees_df.duplicated(keep=False)]
    print("Duplicated Records:")
    print(duplicated_records, "\n")

# Displays salary outliers.
def identify_salary_outliers(employees_df):
    salary_outliers = employees_df['Salary'].apply(lambda x: 'Yes' if x < 1000 or x > 1500000 else 'No')
    print("Salary Outliers:")
    print(salary_outliers, "\n")

# Identifies employees assigned to invalid departments (those not in the departments DataFrame).
def display_invalid_departments(employees_df, departments_df):
    invalid_departments = employees_df[~employees_df['Department_ID'].isin(departments_df['Department_ID'])]
    print("Employees Assigned to Invalid Departments:")
    print(invalid_departments[['Employee_ID', 'Department_ID', 'Job_Title']], "\n")

# Corrects typographical errors in the 'Location' column:
def correct_location(employees_df):
    """
    - Maps 'NY' to 'New York'.
    - Maps 'Claveland' with 'Cleveland'.
    """
    employees_df['Location'] = employees_df['Location'].replace({'NY': 'New York', 'Claveland': 'Cleveland'})
    print("Corrects typographical errors in the 'Location' column:")
    print(employees_df, "\n")
    return employees_df

# Standardizes the format of the hiring date to 'y-m-d'.
def standardize_hiring_date(employees_df): 
    def convert_to_standard_format(date_str):
        if pd.isnull(date_str):
            return date_str
        for fmt in ('%Y-%m-%d', '%m-%d-%Y', '%d-%m-%Y'):
            try:
                return datetime.strptime(date_str, fmt).strftime('%Y-%m-%d')
            except ValueError:
                continue
        return date_str 

    employees_df['hiring_date'] = employees_df['hiring_date'].apply(convert_to_standard_format)
    print("After standarizing date formats:")
    print(employees_df, "\n")
    return employees_df

# Removes duplicate records from the employee dataset and prints the results.
def drop_duplicates(employees_df):
    employees_df = employees_df.drop_duplicates(subset=['Employee_ID'])
    print("After dropping duplicates:")
    print(employees_df, "\n")
    return employees_df

# Remove records with empty hiring dates and prints the results.
def drop_empty_hiring_date(employees_df):
    employees_df = employees_df.dropna(subset=['hiring_date'])
    print("After dropping records with empty hiring date:")
    print(employees_df, "\n")
    return employees_df

# Removes outliers (values greater than 1,500,000 or less than 1,000)
def handle_outliers(employees_df, column_name):
    employees_df = employees_df[(employees_df[column_name] <= 1500000) & (employees_df[column_name] >= 1000)]
    print("After dropping records with values greater than 1,500,000 or less than 1,000")
    print(employees_df, "\n")

    return employees_df

def main():
    # Create dataframes
    employees_df, departments_df = create_dataframes()

    ## Profiling
    # Display original data and statistics
    display_data(employees_df, departments_df)
    display_salary_stats(employees_df)

    # Identify Invalid Zip Codes
    identify_invalid_zip_codes(employees_df)

    # Find employees with empty departments
    display_empty_department_employees(employees_df)

    # Identify duplicated records
    display_duplicated_records(employees_df)

    # Identify salary outliers
    identify_salary_outliers(employees_df)

    # Find employees with invalid department IDs
    display_invalid_departments(employees_df, departments_df)

    ## Cleaning
    # Correct location typographical errors
    employees_df = correct_location(employees_df)

    # Standardize 'hiring_date' format
    employees_df = standardize_hiring_date(employees_df)

    # Drop duplicates and records with empty hiring dates
    employees_df = drop_duplicates(employees_df)
    employees_df = drop_empty_hiring_date(employees_df)

    # Handle outliers
    employees_df=  handle_outliers(employees_df, 'Salary')
    
    # Final DataFrame display
    print("Final Employee Dataset:")
    print(employees_df, "\n")



if __name__ == "__main__":
    # Run the main function
    main()
