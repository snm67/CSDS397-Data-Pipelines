#!/bin/bash
#what is happening

# Ensure the script is run as root to install MySQL
if [ "$(whoami)" != "root" ]; then
  echo "Please run the script as root or use sudo"
  exit 1
fi

# 1. Install MySQL if not installed (for Ubuntu/Debian-based systems)
install_mysql() {
  echo "Checking if MySQL is installed..."
    apt-get update
    apt-get install -y mysql-server
    sudo service mysql restart
  
}

# 2. Create Database and Tables (Fresh Setup)
create_database_and_tables() {
  echo "Dropping existing database (if any)..."

  mysql -u root -e "
  DROP DATABASE IF EXISTS company;
  CREATE DATABASE company;
  USE company;

  -- Create employee_data_source table
  CREATE TABLE employee_data_source (
    Employee_ID INT,
    Name VARCHAR(255),
    Age INT,
    Department VARCHAR(255),
    Hiring_Date,
    Years_of_Experience INT,
    Country VARCHAR(255),
    Salary INT,
    Performance_Rating VARCHAR(255)
  );
  "
  mysql -u root -e " SET GLOBAL sql_mode = 'NO_ENGINE_SUBSTITUTION';"
}

# 3. Insert Data into Tables
insert_data() {
  echo "Inserting data into tables..."

  mysql -u root -e "
  USE company;

  -- Insert data into employee_data_source table
    LOAD DATA INFILE '/workspaces/CSDS397-Assignment-2/employee_data_source.csv'
    INTO TABLE employee_data_source
    FIELDS TERMINATED BY ',' -- Specify the delimiter
    ENCLOSED BY '"'          -- Specify optional enclosing character (if any)
    LINES TERMINATED BY '\n' -- Specify line terminator
    IGNORE 1 ROWS;           -- Skip the header row (if applicable)

    SELECT * FROM employees
  "
}

# 4. Run Queries for Profiling
run_queries() {
  echo "Running analysis queries..."

  # Salary statistics
  echo "Salary Statistics:"
  mysql -u root -e "
  USE company;
  SELECT 
    COUNT(Salary) AS count,
    AVG(Salary) AS average,
    MIN(Salary) AS min,
    MAX(Salary) AS max,
    STDDEV_SAMP(Salary) AS stddev
  FROM employees;
  "

  # Invalid Zip Codes (non-numeric or not 5 digits)
  echo "Invalid Zip Codes:"
  mysql -u root -e "
  USE company;
  SELECT Employee_ID, Zip_Code
  FROM employees
  WHERE Zip_Code NOT REGEXP '^[0-9]{5}$';
  "

  # Employees with Empty Departments
  echo "Employees with Empty Departments:"
  mysql -u root -e "
  USE company;
  SELECT Employee_ID, Job_Title
  FROM employees
  WHERE Department_ID IS NULL;
  "

  # Duplicated Records
  echo "Duplicated Records:"
  mysql -u root -e "
  USE company;
  SELECT Employee_ID, Job_Title, COUNT(*) 
  FROM employees
  GROUP BY Employee_ID, Job_Title
  HAVING COUNT(*) > 1;
  "

  # Salary Outliers (below 1000 or above 1,500,000)
  echo "Salary Outliers:"
  mysql -u root -e "
  USE company;
  SELECT Employee_ID, Salary
  FROM employees
  WHERE Salary < 1000 OR Salary > 1500000;
  "

  # Employees Assigned to Invalid Departments
  echo "Employees Assigned to Invalid Departments:"
  mysql -u root -e "
  USE company;
  SELECT e.Employee_ID, e.Department_ID, e.Job_Title
  FROM employees e
  LEFT JOIN departments d ON e.Department_ID = d.Department_ID
  WHERE d.Department_ID IS NULL;
  "

  # Remove Duplicates (Assuming volume is low and in batch)
  echo "Remove Duplicates:"
  mysql -u root -e "
  USE company;
  CREATE TABLE employees_temp  SELECT DISTINCT * FROM employees;
  DROP TABLE employees;
  ALTER TABLE employees_temp RENAME TO employees;
  SELECT * FROM employees;
  "

  # Remove Employees with Empty Hiring Dates
  echo "Drop Records with Empty Hiring Dates:"
  mysql -u root -e "
  USE company;
  DELETE FROM employees
  WHERE hiring_date IS NULL;
  SELECT * FROM employees
  "

  # Correct Typographical Errors in Location
  echo "Correct Typographical Errors in Location (NY to New York, Claveland to Cleveland):"
  mysql -u root -e "
  USE company;
  UPDATE employees
  SET Location = 'New York'
  WHERE Location = 'NY';

  UPDATE employees
  SET Location = 'Cleveland'
  WHERE Location = 'Claveland';
  SELECT * from employees
  "

  # Standardize Hiring Dates (Convert all to 'YYYY-MM-DD' format) - This also does only work in non-strict mode.
  echo "Standardizing Hiring Dates to 'YYYY-MM-DD' format:"
  mysql -u root -e "
    USE company;
    UPDATE employees
    SET hiring_date = CASE
        WHEN STR_TO_DATE(hiring_date, '%Y-%m-%d') IS NOT NULL THEN DATE_FORMAT(STR_TO_DATE(hiring_date, '%Y-%m-%d'), '%Y-%m-%d')
        WHEN STR_TO_DATE(hiring_date, '%m-%d-%Y') IS NOT NULL THEN DATE_FORMAT(STR_TO_DATE(hiring_date, '%m-%d-%Y'), '%Y-%m-%d')
        WHEN STR_TO_DATE(hiring_date, '%d-%m-%Y') IS NOT NULL THEN DATE_FORMAT(STR_TO_DATE(hiring_date, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE hiring_date
    END;
    SELECT * FROM employees
  "


   # Function to handle outliers (values greater than 1,500,000 or less than 1,000)
  echo "Remove outliers "
  mysql -u root -e "
    USE company;
    DELETE FROM employees
    WHERE salary > 1500000 OR salary < 1000;
    SELECT * FROM employees
  "

  # Create Table with Constraints
  echo "Create Table with Constraints"
  mysql -u root -f -e "
  USE company;
  CREATE TABLE employee_w_constraints (
      Employee_ID INT UNIQUE,
      Job_Title VARCHAR(255),
      Salary INT,
      Years_of_Experience INT,
      Department_ID INT,
      Zip_Code VARCHAR(255),
      Location VARCHAR(255),
      hiring_date VARCHAR(255),
      CONSTRAINT chk_zip_code_format CHECK (Zip_Code RLIKE '^[0-9]{5}$'),
      CONSTRAINT chk_salary_range CHECK (Salary > 1000 AND Salary < 1500000 ),
      CONSTRAINT fk_department FOREIGN KEY (Department_ID) REFERENCES departments(Department_ID)
    );
  "
  
  echo "Try to insert record with invalid salary"
    mysql -u root -e "
    USE company;
    INSERT INTO employee_w_constraints (Employee_ID, Job_Title, Salary, Years_of_Experience, Department_ID, Zip_Code, Location, hiring_date) VALUES
    (1, 'Software Engineer', 0, 3, 1, '12345', 'NY', '2020-01-01');
    SELECT * FROM employee_w_constraints;
  "


  echo "Duplicated Record"
  mysql -u root -e "
  
      USE company;
            INSERT INTO employee_w_constraints (Employee_ID, Job_Title, Salary, Years_of_Experience, Department_ID, Zip_Code, Location, hiring_date) VALUES
      (1, 'Software Engineer', 10001, 3, 1, '12345', 'NY', '2020-01-01');
          SELECT * FROM employee_w_constraints;
  
    -- Insert duplicated record into employee_w_constraints table
        INSERT INTO employee_w_constraints (Employee_ID, Job_Title, Salary, Years_of_Experience, Department_ID, Zip_Code, Location, hiring_date) VALUES
      (1, 'Software Engineer', 10001, 3, 1, '12345', 'NY', '2020-01-01');
          SELECT * FROM employee_w_constraints;
  "


  echo "Invalid Zip Code"
  mysql -u root -e "
  
      USE company;
    -- Insert duplicated record into employee_w_constraints table
        INSERT INTO employee_w_constraints (Employee_ID, Job_Title, Salary, Years_of_Experience, Department_ID, Zip_Code, Location, hiring_date) VALUES
      (1, 'Software Engineer', 10001, 3, 1, 'ABC', 'NY', '2020-01-01');
          SELECT * FROM employee_w_constraints;
    "
  
  echo "Invalid Department"
  mysql -u root -e "
  
      USE company;
    -- Insert duplicated record into employee_w_constraints table
        INSERT INTO employee_w_constraints (Employee_ID, Job_Title, Salary, Years_of_Experience, Department_ID, Zip_Code, Location, hiring_date) VALUES
      (9, 'Software Engineer', 10001, 3, 9, '12345', 'NY', '2020-01-01');
          SELECT * FROM employee_w_constraints;
    "
  }

# Run the complete setup and analysis
install_mysql
create_database_and_tables
insert_data
run_queries

echo "Script completed successfully!"
