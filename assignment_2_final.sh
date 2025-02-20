#!/bin/bash

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
    Hiring_Date VARCHAR(255),
    Years_of_Experience INT,
    Country VARCHAR(255),
    Salary INT,
    Performance_Rating VARCHAR(255)
  );

  -- Create flagged table for flawed records
  CREATE TABLE flagged_records (
    Employee_ID INT,
    Name VARCHAR(255),
    Age INT,
    Department VARCHAR(255),
    Hiring_Date VARCHAR(255),
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

  # Put CSV file  in the correct location with proper permissions
  cp employee_data_source.csv /var/lib/mysql-files/
  chmod 644 /var/lib/mysql-files/employee_data_source.csv

  mysql -u root -e "
  USE company;

    LOAD DATA INFILE '/var/lib/mysql-files/employee_data_source.csv'
    INTO TABLE employee_data_source
    FIELDS TERMINATED BY ',' -- Specify the delimiter
    LINES TERMINATED BY '\n' -- Specify line terminator
    IGNORE 1 ROWS;           -- Skip the header row 

    -- SELECT * FROM employee_data_source
  "
}

# 4. Data Cleansing
data_cleansing() {
  echo "Running analysis queries..."

  echo "Verifying CSV data exists"
  mysql -u root -e "
    USE company;
    SELECT * FROM employee_data_source;
  "

  echo "Removing duplicate records"
  mysql -u root -e "
    USE company;
    
    CREATE TABLE employees_temp SELECT DISTINCT * FROM employee_data_source;
    DROP TABLE employee_data_source;
    ALTER TABLE employees_temp RENAME TO employee_data_source;

  "

  echo "Standardizing data formats"
  mysql -u root -e "
    USE company;
    
    UPDATE employee_data_source
    SET Hiring_Date = REPLACE(Hiring_Date, '/', '-');

  "

  echo "Fixing typographic errors in Country and Department fields"
  mysql -u root -e "
    USE company;
    
    -- country typos
    UPDATE employee_data_source SET Country = 'Zorathia' WHERE Country = 'zorathia';
    UPDATE employee_data_source SET Country = 'Vorastria' WHERE Country = 'vorastria';
    UPDATE employee_data_source SET Country = 'Mordalia' WHERE Country = 'mOrDaLia';
    UPDATE employee_data_source SET Country = 'Hesperia' WHERE Country = 'hEspErIa';
    UPDATE employee_data_source SET Country = 'Hesperia' WHERE Country = 'HESPErIA';
    UPDATE employee_data_source SET Country = 'Tavlora' WHERE Country = 'tavlora';
    UPDATE employee_data_source SET Country = 'Xanthoria' WHERE Country = 'Xanth0ria';
    UPDATE employee_data_source SET Country = 'Vorastria' WHERE Country = 'VorasTrIa';
    UPDATE employee_data_source SET Country = 'Tavlora' WHERE Country = 'TAVlora';
    UPDATE employee_data_source SET Country = 'Glarastan' WHERE Country = 'GlArAstAn';
    UPDATE employee_data_source SET Country = 'Luronia' WHERE Country = 'LURoNIA';
    UPDATE employee_data_source SET Country = 'Vorastria' WHERE Country = 'VorasTrIa';
    UPDATE employee_data_source SET Country = 'Zorathia' WHERE Country = 'zoRaThIa';
    UPDATE employee_data_source SET Country = 'Vorastria' WHERE Country = 'vOrAsTrIa';
    UPDATE employee_data_source SET Country = 'Tavlora' WHERE Country = 'lurOnIa';
    UPDATE employee_data_source SET Country = 'Hesperia' WHERE Country = 'HESperia';
    UPDATE employee_data_source SET Country = 'Xanthoria' WHERE Country = 'xANTHoria';
    UPDATE employee_data_source SET Country = 'Drivania' WHERE Country = 'drIvAnIa';
    UPDATE employee_data_source SET Country = 'Luronia' WHERE Country = 'LurOnIa';
    UPDATE employee_data_source SET Country = 'Drivania' WHERE Country = 'DrIVANIA';

    -- dept typos
    UPDATE employee_data_source SET Department = 'Customer Support' WHERE Department = 'Cust Support';
    UPDATE employee_data_source SET Department = 'HR' WHERE Department = 'H R';
    UPDATE employee_data_source SET Department = 'Finance' WHERE Department = 'Fin';
    UPDATE employee_data_source SET Department = 'Sales' WHERE Department = 'sales';
    UPDATE employee_data_source SET Department = 'HR' WHERE Department = 'Hr';
    UPDATE employee_data_source SET Department = 'R&D' WHERE Department = 'RnD';
    UPDATE employee_data_source SET Department = 'IT' WHERE Department = 'It';
    UPDATE employee_data_source SET Department = 'Logistics' WHERE Department = 'logistics';
    UPDATE employee_data_source SET Department = 'Customer Support' WHERE Department = 'customer support';
    UPDATE employee_data_source SET Department = 'Operations' WHERE Department = 'operations';
    UPDATE employee_data_source SET Department = 'IT' WHERE Department = 'it';
    UPDATE employee_data_source SET Department = 'HR' WHERE Department = 'hr';
    UPDATE employee_data_source SET Department = 'R&D' WHERE Department = 'r&d';
    UPDATE employee_data_source SET Department = 'Logistics' WHERE Department = 'Lgistics';
    UPDATE employee_data_source SET Department = 'Finance' WHERE Department = 'finance';
    UPDATE employee_data_source SET Department = 'Sales' WHERE Department = 'Slaes';
    UPDATE employee_data_source SET Department = 'Marketing' WHERE Department = 'Marketng';
    UPDATE employee_data_source SET Department = 'Operations' WHERE Department = 'Oprations';
    UPDATE employee_data_source SET Department = 'Legal' WHERE Department = 'Legl';

    -- show the new table with fixed typos, duplicates, date formats
    SELECT * FROM employee_data_source;

  "

  echo "Flagging salary outliers"
  mysql -u root -e "
    USE company;
    
    INSERT INTO flagged_records 
    SELECT * FROM employee_data_source
    WHERE salary > 1500000 OR salary < 1000;

  "

  echo "Flagging records with missing values"
  mysql -u root -e "
    USE company;

    INSERT INTO flagged_records 
    SELECT * FROM employee_data_source
    WHERE Name NOT LIKE '%_%' OR Country NOT LIKE '%_%' OR Performance_Rating NOT LIKE '%_%';

    CREATE TABLE employees_temp SELECT DISTINCT * FROM flagged_records;
    DROP TABLE flagged_records;
    ALTER TABLE employees_temp RENAME TO flagged_records;

    SELECT * FROM flagged_records;

  "
  
  }

# Run the complete setup and analysis
install_mysql
create_database_and_tables
insert_data
data_cleansing

echo "Script completed successfully!"
