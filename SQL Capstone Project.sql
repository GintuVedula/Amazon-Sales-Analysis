-- "Data Wrangling": inspection of data is done to make sure NULL values and missing values are detected 

SELECT * FROM amazon_db.amazon;
-- 1. Check nulls
DESCRIBE amazon_db.amazon;
-- The dataset does not contain any NULL values in any of the columns. Each column has zero NULL values
-- 2.  Change the column names and  Data Types for all columns 
ALTER TABLE amazon_db.amazon
CHANGE `Invoice ID` invoice_id VARCHAR(30),
CHANGE Branch branch VARCHAR(5),                          -- single word column does not need ''
CHANGE City city VARCHAR(30),                             -- single word column does not need ''
CHANGE `Customer type` customer_type VARCHAR(30),
CHANGE Gender gender VARCHAR(10),
CHANGE `Product line` product_line VARCHAR(100),
CHANGE `Unit price` unit_price DECIMAL(10, 2),
CHANGE Quantity quantity INT,
CHANGE `Tax 5%`  VAT FLOAT,
CHANGE Total  total DECIMAL(10, 4),
CHANGE Date date DATE,
CHANGE COLUMN `Time` `time` TIME,                             -- Time and time are reserved keywords in MySQL. use '' for both. TIMESTAMP datatype is invalid so used TIME
CHANGE `Payment` payment_method VARCHAR(30),
MODIFY `cogs` DECIMAL(10, 2),
CHANGE `gross margin percentage` gross_margin_percentage FLOAT,
CHANGE `gross income` gross_income DECIMAL(10, 4),
CHANGE Rating rating DECIMAL(3, 1)
;

-- "Feature Engineering":
	-- 1. Add a new column named timeofday to give insight of sales in the Morning, Afternoon and Evening. 
		ALTER TABLE amazon_db.amazon
		ADD COLUMN timeofday VARCHAR(10);
        
        SET SQL_SAFE_UPDATES = 0;                     -- Disable Safe Update Mode Temporarily
        SET SQL_SAFE_UPDATES = 1;                     -- turn safe updates Mode back again  after running UPDATE command
       
       UPDATE amazon_db.amazon
		SET timeofday = 
		CASE
			WHEN TIME(Time) BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
			WHEN TIME(Time) BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
			WHEN TIME(Time) BETWEEN '18:00:00' AND '23:59:59' THEN 'Evening'
			ELSE 'Night'
		END;
		
        
        -- 2. Add a new column named dayname that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri)
		ALTER TABLE amazon_db.amazon
        ADD COLUMN dayname VARCHAR(10);
        
        UPDATE amazon_db.amazon
		SET dayname = DATE_FORMAT(date, '%W');

		-- 3. Add a new column named monthname that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar)
        
		ALTER TABLE amazon_db.amazon
		ADD COLUMN monthname VARCHAR(10);

		UPDATE amazon_db.amazon
		SET monthname = DATE_FORMAT(date, '%M');


-- Business Questions To Answer:
	-- 1. What is the count of distinct cities in the dataset?
		SELECT 
		COUNT(DISTINCT city) AS distinct_city_count,
		GROUP_CONCAT(DISTINCT city ORDER BY city SEPARATOR ', ') AS city_names
		FROM amazon_db.amazon;
	-- 2. For each branch, what is the corresponding city?
		SELECT branch, city
		FROM amazon_db.amazon
		GROUP BY branch, city;

    -- 3.What is the count of distinct product lines in the dataset?
		SELECT COUNT(DISTINCT product_line) AS distinct_product_line_count
		FROM amazon_db.amazon;

    -- 4. Which payment method occurs most frequently?
		SELECT payment_method, COUNT(*) AS frequency
		FROM amazon_db.amazon
		GROUP BY payment_method
		ORDER BY frequency DESC
		LIMIT 1;

    -- 5. Which product line has the highest sales?
		SELECT product_line, SUM(total) AS total_sales
		FROM amazon_db.amazon
		GROUP BY product_line
		ORDER BY total_sales DESC
		;
        
    -- 6. How much revenue is generated each month?
		SELECT 
		monthname AS month, 
		SUM(total) AS total_revenue
		FROM amazon_db.amazon
		GROUP BY month
		ORDER BY total_revenue desc;

    -- 7. In which month did the cogs(cost of goods sold) reach its peak?
		SELECT 
		monthname AS month, 
		SUM(cogs) AS total_cogs
		FROM amazon_db.amazon
		GROUP BY month
		ORDER BY total_cogs DESC
		LIMIT 1;

    -- 8. Which product line generated the highest revenue?
		SELECT 
		product_line, 
		SUM(total) AS total_revenue
		FROM amazon_db.amazon
		GROUP BY product_line
		ORDER BY total_revenue DESC
		limit 1;

    -- 9. In which city was the highest revenue recorded?
		SELECT 
		city, 
		SUM(total) AS total_revenue
		FROM amazon_db.amazon
		GROUP BY city
		ORDER BY total_revenue DESC
		LIMIT 1;

    -- 10. Which product line incurred the highest Value Added Tax?
		SELECT 
		product_line, 
		SUM(vat) AS total_vat
		FROM amazon_db.amazon
		GROUP BY product_line
		ORDER BY total_vat DESC
		LIMIT 1;

    -- 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
			SELECT 
			product_line,
			SUM(total) AS total_sales,
			CASE 
				WHEN SUM(total) > (SELECT AVG(total_sales) 
									FROM (SELECT SUM(total) AS total_sales 
										  FROM amazon_db.amazon 
										  GROUP BY product_line) AS subquery) 
				THEN 'Good'
				ELSE 'Bad'
			END AS sales_status
		FROM amazon_db.amazon
		GROUP BY product_line;

    -- 12. Identify the branch that exceeded the average number of products sold.
			WITH BranchSales AS (
			SELECT 
				branch, 
				SUM(quantity) AS total_products_sold
			FROM amazon_db.amazon
			GROUP BY branch
		),
		AverageSales AS (
			SELECT 
				AVG(total_products_sold) AS avg_products_sold
			FROM BranchSales
		)
		SELECT 
			branch, 
			total_products_sold
		FROM BranchSales
		WHERE total_products_sold > (SELECT avg_products_sold FROM AverageSales);

    -- 13. Which product line is most frequently associated with each gender?
		WITH ProductLineCounts AS (
			SELECT 
				gender, 
				product_line,
				COUNT(*) AS count_per_line
			FROM amazon_db.amazon
			GROUP BY gender, product_line
		),
		RankedLines AS (
			SELECT
				gender,
				product_line,
				count_per_line,
				RANK() OVER (PARTITION BY gender ORDER BY count_per_line DESC) AS ranks
			FROM ProductLineCounts
		)
		SELECT 
			gender, 
			product_line,
			count_per_line
		FROM RankedLines
		WHERE ranks = 1;

    -- 14. Calculate the average rating for each product line.
		SELECT 
		product_line,
		AVG(rating) AS average_rating
		FROM amazon_db.amazon
		GROUP BY product_line
        ORDER BY average_rating DESC;

    -- 15. Count the sales occurrences for each time of day on every weekday.
		SELECT 
		dayname AS weekday,
		timeofday AS time_of_day,
		COUNT(*) AS sales_occurrences
		FROM amazon_db.amazon
		GROUP BY weekday, time_of_day
		ORDER BY weekday, time_of_day desc;

SELECT 
    dayname AS weekday,
    timeofday AS time_of_day,
    COUNT(*) AS sales_occurrences,
    SUM(COUNT(*)) OVER (PARTITION BY dayname) AS total_sales_day
FROM amazon_db.amazon
GROUP BY weekday, time_of_day
ORDER BY FIELD(weekday, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), time_of_day DESC;


    -- 16. Identify the customer type contributing the highest revenue.
		SELECT 
		customer_type, 
		SUM(total) AS total_revenue
		FROM amazon_db.amazon
		GROUP BY customer_type
		ORDER BY total_revenue DESC
		LIMIT 1;

    -- 17. Determine the city with the highest VAT percentage.
		SELECT 
		city, 
		AVG((vat / total) * 100) AS avg_vat_percentage
		FROM amazon_db.amazon
		GROUP BY city
		ORDER BY avg_vat_percentage DESC
		LIMIT 1;

    -- 18. Identify the customer type with the highest VAT payments.
    SELECT 
    customer_type, 
    SUM(vat) AS total_vat_payments
	FROM amazon_db.amazon
	GROUP BY customer_type
	ORDER BY total_vat_payments DESC
	LIMIT 1;

    -- 19. What is the count of distinct customer types in the dataset?
		SELECT 
		COUNT(DISTINCT customer_type) AS distinct_customer_type_count
		FROM amazon_db.amazon;

    -- 20. What is the count of distinct payment methods in the dataset?
		SELECT 
		COUNT(DISTINCT payment_method) AS distinct_payment_method_count
		FROM amazon_db.amazon;

	-- 21. Which customer type occurs most frequently?
		SELECT 
		customer_type, 
		COUNT(*) AS occurrence_count
		FROM amazon_db.amazon
		GROUP BY customer_type
		ORDER BY occurrence_count DESC
		LIMIT 1;

    -- 22. Identify the customer type with the highest purchase frequency.
			SELECT 
			customer_type, 
			COUNT(*) AS purchase_count
			FROM amazon_db.amazon
			GROUP BY customer_type
			ORDER BY purchase_count DESC
			LIMIT 1;

    -- 23. Determine the predominant gender among customers.
			SELECT 
			gender, 
			COUNT(*) AS gender_count
			FROM amazon_db.amazon
			GROUP BY gender
			ORDER BY gender_count DESC
			LIMIT 1;

    -- 24. Examine the distribution of genders within each branch.
			SELECT 
			branch, gender, 
			COUNT(*) AS gender_count
			FROM amazon_db.amazon
			GROUP BY branch, gender
			ORDER BY branch, gender;


    -- 25. Identify the time of day when customers provide the most ratings.
    
    SELECT 
    timeofday AS hour_of_day, 
    COUNT(rating) AS rating_count
	FROM amazon_db.amazon
	GROUP BY hour_of_day
	ORDER BY rating_count DESC
	LIMIT 1;

    -- 26. Determine the time of day with the highest customer ratings for each branch.
    WITH RatingsByHour AS (
    SELECT 
        branch, 
        timeofday AS hour_of_day, 
        COUNT(rating) AS rating_count
    FROM amazon_db.amazon
    GROUP BY branch, hour_of_day
)
SELECT 
    branch, 
    hour_of_day, 
    rating_count
FROM RatingsByHour
WHERE (branch, rating_count) IN (
    SELECT branch, MAX(rating_count)
    FROM RatingsByHour
    GROUP BY branch
);

    -- 27. Identify the day of the week with the highest average ratings.
    SELECT 
    dayname AS day_of_week, 
    AVG(rating) AS average_rating
	FROM amazon_db.amazon
	GROUP BY day_of_week
	ORDER BY average_rating DESC
	LIMIT 1;

    -- 28. Determine the day of the week with the highest average ratings for each branch.
    
    WITH AverageRatings AS (
    SELECT 
        branch, 
        dayname AS day_of_week, 
        AVG(rating) AS average_rating
    FROM amazon_db.amazon
    GROUP BY branch, day_of_week
),
RankedRatings AS (
    SELECT 
        branch,
        day_of_week,
        average_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY average_rating DESC) AS ranks
    FROM AverageRatings
)
SELECT 
    branch, 
    day_of_week, 
    average_rating
FROM RankedRatings
WHERE ranks = 1;

-- ====================================================================
