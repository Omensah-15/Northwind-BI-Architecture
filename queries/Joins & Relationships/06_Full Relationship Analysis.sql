/*
Question:
Identify customers who have purchased products from all categories available in their country.
*/


WITH 
-- Get all categories available in each country
CountryCategories AS (
    SELECT DISTINCT 
        c.Country,
        cat.CategoryID
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories cat ON p.CategoryID = cat.CategoryID
),

-- Get categories each customer has purchased from
CustomerCategories AS (
    SELECT 
        c.CustomerID,
        c.CompanyName,
        c.Country,
        cat.CategoryID,
        COUNT(DISTINCT cat.CategoryID) as PurchasedCategoryCount
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories cat ON p.CategoryID = cat.CategoryID
    GROUP BY c.CustomerID, c.CompanyName, c.Country, cat.CategoryID
),

-- Count total categories available in each customer's country
CountryCategoryCounts AS (
    SELECT 
        Country,
        COUNT(DISTINCT CategoryID) as TotalCategoriesInCountry
    FROM CountryCategories
    GROUP BY Country
),

-- Count categories each customer has purchased
CustomerCategoryCounts AS (
    SELECT 
        CustomerID,
        CompanyName,
        Country,
        COUNT(DISTINCT CategoryID) as CustomerPurchasedCategories
    FROM CustomerCategories
    GROUP BY CustomerID, CompanyName, Country
)

-- Final query: Find customers who have purchased all categories available in their country
SELECT 
    ccc.CustomerID,
    ccc.CompanyName,
    ccc.Country,
    ccc.CustomerPurchasedCategories,
    cct.TotalCategoriesInCountry
FROM CustomerCategoryCounts ccc
JOIN CountryCategoryCounts cct ON ccc.Country = cct.Country
WHERE ccc.CustomerPurchasedCategories = cct.TotalCategoriesInCountry
ORDER BY ccc.Country, ccc.CompanyName;
