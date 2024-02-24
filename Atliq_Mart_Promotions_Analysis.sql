use retail_events_db;
show tables;
SELECT * FROM dim_campaigns;
SELECT * FROM dim_products;
SELECT * FROM dim_stores;
SELECT * FROM fact_events;

SELECT
    A.product_code,
    P.product_name,
    A.base_price,
    A.promo_type
FROM
    fact_events A
LEFT JOIN
    dim_products P ON P.product_code = A.product_code
WHERE
    A.base_price > 500
    AND A.promo_type = "BOGOF"
GROUP BY
    A.product_code,
    P.product_name,
    A.base_price,
    A.promo_type;

SELECT
    city AS "City",
    COUNT(store_id) AS "No of Store"
FROM
    dim_stores
GROUP BY
    city
ORDER BY
    COUNT(store_id) DESC;

UPDATE fact_events
SET `quantity_sold(after_promo)` = `quantity_sold(after_promo)` * 2
WHERE promo_type = 'BOGOF';

ALTER TABLE fact_events
ADD COLUMN Revenue_Earned_Before_Promo DECIMAL(10, 2);

UPDATE fact_events
SET `Revenue_Earned_Before_Promo` = `base_price` * `quantity_sold(before_promo)`;

ALTER TABLE fact_events
ADD COLUMN Promo_Price INT(10);

UPDATE fact_events
SET `Promo_Price` = `base_price`;
				
UPDATE fact_events
SET `promo_price` = `promo_price` * 0.5
WHERE promo_type = 'BOGOF';


ALTER TABLE fact_events
ADD COLUMN Revenue_Earned_After_Promo DECIMAL(10, 2);

UPDATE fact_events
SET `Revenue_Earned_After_Promo` = `promo_price` * `quantity_sold(after_promo)`;

SELECT
    C.campaign_name As "Campaign_name",
    CONCAT(ROUND(SUM(Revenue_Earned_Before_Promo) / 1000000, 2), ' M') AS "Rev_Earned_Before Promotion",
    CONCAT(ROUND(SUM(Revenue_Earned_After_Promo) / 1000000, 2), ' M') AS "Rev_Earned_After Promotion"
FROM
    fact_events A
LEFT JOIN
    dim_campaigns C ON C.campaign_id = A.campaign_id
GROUP BY
    C.campaign_name;

SELECT 
    Category,
    `ISU %`,
    RANK() OVER (ORDER BY `ISU %` DESC) AS Ranking
FROM (
    SELECT 
        P.category, 
        ROUND((((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`))/ SUM(`quantity_sold(before_promo)`))* 100),2) AS "ISU %"
    FROM 
        fact_events A 
    LEFT JOIN 
        dim_products P ON P.product_code = A.product_code 
    WHERE 
        `campaign_id` = "CAMP_DIW_01"
    GROUP BY 
        P.category
) AS subquery;

SELECT 
    Product_name,
    Category,
    `IR %`,
    RANK() OVER (ORDER BY `IR %` DESC) AS Ranking
FROM (
    SELECT 
        P.product_name,
        P.category, 
        ROUND((((SUM(`Revenue_Earned_After_Promo`) - SUM(`Revenue_Earned_Before_Promo`)) / SUM(`Revenue_Earned_Before_Promo`)) * 100), 2) AS "IR %"
    FROM 
        fact_events A 
    LEFT JOIN 
        dim_products P ON P.product_code = A.product_code
    GROUP BY 
        P.product_name,
        P.category 
) AS subquery 
ORDER BY 
    Ranking ASC 
LIMIT 5;




