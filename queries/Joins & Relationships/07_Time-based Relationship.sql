/*
Question:
Find customers who have consistently ordered from the same employee over multiple consecutive years.

Business Impact:
This analysis helps identify customers who have developed strong, lasting relationships with specific sales representatives, 
enabling targeted retention strategies, personalized account management, and recognition of high-performing employee-customer partnerships that drive loyalty and recurring revenue.

Approach:
*/

WITH customer_employee_years AS (
    -- Get distinct customer-employee pairs for each year
    SELECT DISTINCT
        o.CustomerID,
        o.EmployeeID,
        YEAR(o.OrderDate) AS order_year
    FROM Orders o
    WHERE o.OrderDate IS NOT NULL
),
consecutive_years AS (
    -- Find consecutive years for each customer-employee pair
    SELECT 
        CustomerID,
        EmployeeID,
        order_year,
        -- Create a group identifier for consecutive years
        order_year - ROW_NUMBER() OVER (
            PARTITION BY CustomerID, EmployeeID 
            ORDER BY order_year
        ) AS year_group
    FROM customer_employee_years
),
year_groups AS (
    -- Count the number of consecutive years in each group
    SELECT 
        CustomerID,
        EmployeeID,
        year_group,
        COUNT(*) AS consecutive_years_count,
        MIN(order_year) AS first_year,
        MAX(order_year) AS last_year
    FROM consecutive_years
    GROUP BY CustomerID, EmployeeID, year_group
    HAVING COUNT(*) >= 2  -- At least 2 consecutive years
),
customer_employee_summary AS (
    -- For each customer, find the maximum consecutive years with same employee
    SELECT 
        CustomerID,
        EmployeeID,
        MAX(consecutive_years_count) AS max_consecutive_years,
        first_year,
        last_year
    FROM year_groups
    GROUP BY CustomerID, EmployeeID, first_year, last_year
),
ranked_customers AS (
    -- Rank to prioritize the longest consecutive relationship per customer
    SELECT 
        c.CustomerID,
        c.CompanyName,
        ces.EmployeeID,
        e.FirstName + ' ' + e.LastName AS EmployeeName,
        ces.max_consecutive_years,
        ces.first_year,
        ces.last_year,
        ROW_NUMBER() OVER (
            PARTITION BY c.CustomerID 
            ORDER BY ces.max_consecutive_years DESC, ces.first_year
        ) AS rn
    FROM Customers c
    JOIN customer_employee_summary ces ON c.CustomerID = ces.CustomerID
    JOIN Employees e ON ces.EmployeeID = e.EmployeeID
)
-- Final result
SELECT 
    CustomerID,
    CompanyName,
    EmployeeID,
    EmployeeName,
    max_consecutive_years AS consecutive_years,
    first_year,
    last_year
FROM ranked_customers
WHERE rn = 1  -- Only show the longest consecutive period per customer
ORDER BY max_consecutive_years DESC, CustomerID;
