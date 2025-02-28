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

# Drop and create sales table
mysql -u root -e "
USE company;
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    product_name VARCHAR(100),
    order_date DATE,
    amount DECIMAL(10, 2),
    order_status VARCHAR(20)
);
"

# Insert sample data into sales
mysql -u root -e "
USE company;
INSERT INTO sales VALUES
(1, 101, 201, 'Product A', '2025-01-01', 150.00, 'Completed'),
(2, 102, 202, 'Product B', '2025-01-02', 200.50, 'Cancelled'),
(3, 103, 203, 'Product C', '2025-01-03', 300.00, 'Completed'),
(4, 104, 204, 'Product D', '2025-01-04', 50.75, 'Completed'),
(5, 101, 205, 'Product E', '2025-01-05', 120.25, 'Cancelled'),
(6, 101, 201, 'Product A', '2025-01-01', 150.00, 'Completed'),
(7, 102, 202, 'Product B', '2025-01-02', 200.50, 'Completed'),
(8, 103, 203, 'Product A', '2025-01-03', 300.00, 'Completed'),
(9, 104, 204, 'Product C', '2025-01-04', 50.75, 'Completed'),
(10, 101, 205, 'Product B', '2025-01-05', 120.25, 'Completed');
"


echo "Displaying data from sales table:"
mysql -u root -e "
USE company;
SELECT * FROM company.sales;
"

# Drop and create customers table
mysql -u root -e "
USE company;
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);
"

# Insert sample data into customers
mysql -u root -e "
USE company;
INSERT INTO customers VALUES
(101, 'Alice'),
(102, 'Bob'),
(103, 'Charlie'),
(104, 'David');
"

# Show data from customers table
echo "Displaying data from customers table:"
mysql -u root -e "
USE company;
SELECT * FROM company.customers;
"

# Drop and create Orders table
mysql -u root -e "
USE company;
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT
);
"

# Insert sample data into Orders table
mysql -u root -e "
USE company;
INSERT INTO orders VALUES
(1, 101, 201, '2025-01-01', 2),
(2, 102, 202, '2025-01-02', 1),
(3, 103, 203, '2025-01-03', 3),
(4, 101, 204, '2025-01-04', 5),
(5, 104, 205, '2025-01-05', 2);
"

# Show data from Orders table
echo "Displaying data from Orders table:"
mysql -u root -e "USE company;
SELECT * FROM company.orders;
"

# Drop and create Products table
mysql -u root -e "
USE company;
DROP TABLE IF EXISTS Products;
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);
"

# Insert sample data into Products table
mysql -u root -e "
USE company;
INSERT INTO Products VALUES
(201, 'Product A', 'Electronics'),
(202, 'Product B', 'Clothing'),
(203, 'Product C', 'Home Goods'),
(204, 'Product D', 'Electronics'),
(205, 'Product E', 'Clothing');
"

# Show data from Products table
echo "Displaying data from Products table:"
mysql -u root -e "
USE company;
SELECT * FROM company.Products;
"

# Drop and create Inventory table
mysql -u root -e "
USE company;
DROP TABLE IF EXISTS Inventory;
CREATE TABLE Inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT
);
"

# Insert sample data into Inventory table
mysql -u root -e "
USE company;
INSERT INTO Inventory VALUES
(201, 100),
(202, 50),
(203, 30),
(204, 80),
(205, 0);
"

# Show data from Inventory table
echo "Displaying data from Inventory table:"
mysql -u root -e "
USE company;
SELECT * FROM company.Inventory;
"


echo "Filtering"
mysql -u root -e "
USE company;
---- Data Filtering Example ----
SELECT * FROM sales WHERE order_status = 'Completed';
"

echo "Aggregation"
mysql -u root -e "
USE company;
-- ----  Aggregation Example ----
-- Aggregate total sales by product
SELECT product_name, SUM(amount) AS total_sales
FROM sales
WHERE order_status = 'Completed'
GROUP BY product_name
ORDER BY total_sales DESC;

SELECT
    order_id,
    product_name,
    order_date,
    amount,
    SUM(amount) OVER (PARTITION BY product_name ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sales
WHERE order_status = 'Completed'
GROUP BY order_id, product_name, order_date, amount
ORDER BY order_date, product_name;
"

echo "Joining"
mysql -u root -e "
USE company;
-- ----Joining Example ----
-- Join sales with customers to get customer names
SELECT  s.order_id, c.customer_name, s.product_name, s.amount
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.order_status = 'Completed';

SELECT 
    o.order_id,
    o.customer_id,
    p.product_name,
    o.quantity AS ordered_quantity,
    i.stock_quantity AS current_stock,
    (i.stock_quantity - o.quantity) AS remaining_stock,
    CASE 
        WHEN o.quantity <= i.stock_quantity THEN 'Fulfilled'
        ELSE 'Out of Stock'
    END AS order_status
FROM 
    orders o
INNER JOIN 
    Products p ON o.product_id = p.product_id
INNER JOIN 
    Inventory i ON o.product_id = i.product_id
ORDER BY 
    o.order_id;
"
echo "Other Transformations"
mysql -u root -e "
USE company;

SELECT 
    order_id,
    amount,
    CASE 
        WHEN amount < 100 THEN 'Low'
        WHEN amount BETWEEN 100 AND 300 THEN 'Medium'
        ELSE 'High'
    END AS sales_category
FROM sales;

SELECT 
    customer_id,
    SUM(CASE WHEN order_status = 'Completed' THEN amount ELSE 0 END) AS total_completed_sales,
    SUM(CASE WHEN order_status = 'Cancelled' THEN amount ELSE 0 END) AS total_cancelled_sales
FROM sales
GROUP BY customer_id;

SELECT 
    order_id, 
    LPAD(CAST(amount AS CHAR), 10, '0') AS amount_text
FROM sales;

SELECT
    customer_id,
    CONCAT(LEFT(customer_name, 1), REPEAT('*', LENGTH(customer_name) - 1)) AS masked_customer_name,
    LEFT(customer_name, 1) AS first_initial
FROM customers;

SELECT 
    order_id,
    order_date,
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month
FROM sales;

WITH customer_sales AS (
    SELECT customer_id, SUM(amount) AS total_sales
    FROM sales
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT customer_id, total_sales, 
       RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM customer_sales;
"

echo "Normalization Forms Example"
mysql -u root -e "
DROP DATABASE IF EXISTS university;
CREATE DATABASE university;
USE university;

CREATE TABLE StudentsUnnormalized (
    StudentId INT PRIMARY KEY,
    AdvisorName VARCHAR(255),
    AdvisorRoomId INT,
    ClassId1 INT,
    ClassId2 INT,
    ClassId3 INT,
    ClassId4 INT
);

INSERT INTO StudentsUnnormalized (StudentId, AdvisorName, AdvisorRoomId, ClassId1, ClassId2, ClassId3, ClassId4)
VALUES
(1, 'Joe', 1, 1, 2, 3, 4), -- Student 1
(2, 'Doe', 2, 5, 6, 7, NULL); -- Student 2

SELECT * FROM StudentsUnnormalized;

CREATE TABLE Students1NF (
    StudentId INT,
    AdvisorName VARCHAR(255),
    AdvisorRoomId INT,
    ClassId INT,
    PRIMARY KEY (StudentId, ClassId)
);


INSERT INTO Students1NF (StudentId, AdvisorName, AdvisorRoomId, ClassId)
VALUES
(1, 'Joe', 1, 1),
(1, 'Joe', 1, 2),
(1, 'Joe', 1, 3),
(1, 'Joe', 1, 4),
(2, 'Doe', 2, 5),
(2, 'Doe', 2, 6),
(2, 'Doe', 2, 7);

SELECT * FROM Students1NF;

CREATE TABLE StudentAdvisor2NF (
    StudentId INT,
    Advisor VARCHAR(255),
    AdvRoom INT,
    PRIMARY KEY (StudentId)
);

INSERT INTO StudentAdvisor2NF (StudentId, Advisor, AdvRoom)
VALUES
(1, 'Joe', 1), 
(2, 'Doe', 2); 


CREATE TABLE StudentClasses2NF (
    StudentId INT,
    ClassId INT,
    PRIMARY KEY (StudentId, ClassId)
);

INSERT INTO StudentClasses2NF (StudentId, ClassId)
VALUES
(1, 1), 
(1, 2), 
(1, 3), 
(1, 4), 
(2, 5), 
(2, 6), 
(2, 7);

SELECT * FROM StudentAdvisor2NF;
SELECT * FROM StudentClasses2NF;


CREATE TABLE StudentClasses3NF (
    StudentId INT,
    ClassId INT,
    PRIMARY KEY (StudentId, ClassId)
);

INSERT INTO StudentClasses3NF (StudentId, ClassId)
VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(2, 5),
(2, 6),
(2, 7);


CREATE TABLE StudentAdvisors3NF (
    StudentId INT,
    AdvisorId INT,
    PRIMARY KEY (StudentId, AdvisorId)
);

INSERT INTO StudentAdvisors3NF (StudentId, AdvisorId)
VALUES
(1, 1),
(2, 2);

CREATE TABLE Advisors3NF (
    AdvisorId INT,
    AdvisorName VARCHAR(255),
    AdvisorRoomId INT,
    PRIMARY KEY (AdvisorId)
);

INSERT INTO Advisors3NF (AdvisorId, AdvisorName, AdvisorRoomId)
VALUES
(1, 'Joe', 1), 
(2, 'Doe', 2); 

SELECT * FROM StudentClasses3NF;
SELECT * FROM StudentAdvisors3NF;
SELECT * FROM Advisors3NF;

SELECT 
    sc.StudentId,
    sc.ClassId,
    a.AdvisorName,
    a.AdvisorRoomId
FROM 
    StudentClasses3NF sc
JOIN 
    StudentAdvisors3NF sa ON sc.StudentId = sa.StudentId
JOIN 
    Advisors3NF a ON sa.AdvisorId = a.AdvisorId;
"