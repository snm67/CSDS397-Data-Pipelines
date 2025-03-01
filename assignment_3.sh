#!/bin/bash
# Ensure the script is run as root to install MySQL
if [ "$(whoami)" != "root" ]; then
  echo "Please run the script as root or use sudo"
  exit 1
fi

#!/bin/bash

sudo service mysql restart

# Drop and create the database
mysql -u root -e "
DROP DATABASE IF EXISTS company;
CREATE DATABASE company;
USE company;
"

# Drop and create employee_data_source table
mysql -u root -e "
USE company;
DROP TABLE IF EXISTS employee_data_source;
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
"

# Insert data into employee_data_source
echo "Inserting data into tables..."

  # Put CSV file  in the correct location with proper permissions
  cp employee_data_clean.csv /var/lib/mysql-files/
  chmod 644 /var/lib/mysql-files/employee_data_clean.csv

  mysql -u root -e "
  USE company;

    LOAD DATA INFILE '/var/lib/mysql-files/employee_data_clean.csv'
    INTO TABLE employee_data_source
    FIELDS TERMINATED BY ',' -- Specify the delimiter
    LINES TERMINATED BY '\n' -- Specify line terminator
    IGNORE 1 ROWS;           -- Skip the header row 

    SELECT * FROM employee_data_source
  "

  echo "Average Salary by Department"

  mysql -u root -e "
  USE company;
    CREATE TABLE salary_to_department_analysis AS
    SELECT Department, AVG(Salary) AS average_salary
    FROM employee_data_source
    GROUP BY Department;

    SELECT * FROM salary_to_department_analysis
  "

  echo "Average Salary by Years of Experience"

  mysql -u root -e "
  USE company;
    CREATE TABLE salary_to_tenuere_analysis AS
    SELECT Years_of_Experience, AVG(Salary) AS average_salary
    FROM employee_data_source
    GROUP BY Years_of_Experience;

    SELECT * FROM salary_to_tenuere_analysis ORDER BY Years_of_Experience
  "

echo "Average Salary by Performance Rating"

  mysql -u root -e "
  USE company;
    CREATE TABLE performance_by_salary_analysis AS
    SELECT TRIM(REPLACE(Performance_Rating, CHAR(13), '')) AS Performance, AVG(Salary) AS average_salary
    FROM employee_data_source
    GROUP BY Performance;

    SELECT * FROM performance_by_salary_analysis
  "

echo "Salary Range by Performance"

mysql -u root -e "
  USE company;
  CREATE TABLE salary_range_by_performance AS
    SELECT TRIM(REPLACE(Performance_Rating, CHAR(13), '')) AS Performance, MAX(Salary) AS max_salary, MIN(Salary) AS min_salary
    FROM employee_data_source
    GROUP BY Performance;

    SELECT * FROM salary_range_by_performance
"


echo "Total Salary per Experience Level"

mysql -u root -e "
  USE company;
  CREATE TABLE total_salary_by_experience AS
    SELECT Years_of_Experience, SUM(Salary) AS total_salary
    FROM employee_data_source
    GROUP BY Years_of_Experience;


    SELECT * FROM total_salary_by_experience ORDER BY Years_of_Experience
"

echo "Employee Count by Years of Experience"

mysql -u root -e "
  USE company;
  CREATE TABLE employee_distribution_by_experience AS
    SELECT Years_of_Experience, COUNT(Employee_ID) AS employee_count
    FROM employee_data_source
    GROUP BY Years_of_Experience;

    SELECT * FROM employee_distribution_by_experience ORDER BY Years_of_Experience
"