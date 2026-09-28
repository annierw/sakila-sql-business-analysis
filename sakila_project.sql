-- ============================================================
-- SAKILA BUSINESS ANALYSIS
-- Author: Annie Wion
-- Date: September 2026
--
-- Business Objective:
-- Analyze customer behavior, movie performance, and
-- store revenue using the Sakila database.
-- ============================================================

USE sakila;

-- ============================================================
-- 1. CUSTOMER ANALYSIS
-- ============================================================
-- Question 1: Who are the company's highest-spending customers?

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id)
SELECT 
    customer_id, 
    store_id, 
    customer_name, 
    city, 
    number_of_rentals, 
    total_spend, 
    ROUND((total_spend / number_of_rentals),2) avg_spend_per_rental
FROM customer_metrics
ORDER BY total_spend DESC
LIMIT 10;

-- Question 2: Which customers spend more than the typical customer? 

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id),
    customer_avg AS (
        SELECT *, ROUND(AVG(total_spend) OVER(), 2) average_spend
        FROM customer_metrics
    )
SELECT
    *, 
    CONCAT((ROUND(total_spend*100 / average_spend, 0)),'%') percent_of_avg
FROM customer_avg
WHERE total_spend > average_spend
ORDER BY total_spend DESC; 

-- Question 3: Which customers are unusually frequent renters?

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id),
    customer_percentiles AS (
        SELECT *, ROUND(PERCENT_RANK() OVER(ORDER BY number_of_rentals),2) percentile
        FROM customer_metrics
        ORDER BY number_of_rentals DESC
    )
SELECT *
FROM customer_percentiles
WHERE percentile >= 0.9;

-- Question 4: Who are the company's overall most valuable customers?

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id),
    customer_pct_avg AS (
        SELECT 
        *, 
        ROUND((total_spend / number_of_rentals),2) avg_spend_per_rental, 
        ROUND(PERCENT_RANK() OVER(ORDER BY number_of_rentals),2) rental_percentile, 
        ROUND(PERCENT_RANK() OVER(ORDER BY total_spend),2) spending_percentile,
        ROUND(PERCENT_RANK() OVER(ORDER BY ROUND((total_spend / number_of_rentals),2)),2) avg_spend_percentile
        FROM customer_metrics
    )
SELECT customer_id, store_id, customer_name, city, number_of_rentals, total_spend, avg_spend_per_rental
FROM customer_pct_avg
WHERE avg_spend_percentile >= 0.9 AND rental_percentile >= 0.9 AND spending_percentile >= 0.9
ORDER BY rental_percentile DESC, spending_percentile DESC, avg_spend_percentile DESC;

-- ============================================================
-- 2. MOVIE ANALYSIS
-- ============================================================

-- Question 5: Which movies are the most valuable?

WITH movie_metrics AS (
    SELECT 
        f.title, 
        COUNT(DISTINCT i.inventory_id) number_of_copies,
        SUM(p.amount) rental_revenue,
        COUNT(f.title) number_of_rentals,
        ROUND((SUM(p.amount) / COUNT(f.title)),2) avg_rental_payment,
        ROUND(PERCENT_RANK() OVER(ORDER BY SUM(p.amount)),2) revenue_percentile,
        ROUND(PERCENT_RANK() OVER(ORDER BY COUNT(f.title)),2) rental_percentile,
        ROUND(PERCENT_RANK() OVER(ORDER BY SUM(p.amount) / COUNT(f.title)),2) avg_payment_percentile
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY f.title, f.film_id)
SELECT title, number_of_copies, rental_revenue, number_of_rentals, avg_rental_payment
FROM movie_metrics
WHERE avg_payment_percentile >= 0.9 AND revenue_percentile >= 0.9 AND rental_percentile >= 0.9
ORDER BY rental_revenue DESC, number_of_rentals DESC, avg_rental_payment DESC;

-- Question 6: Which movies have high demand relative to availability?

WITH movie_metrics AS (
    SELECT 
        f.title, 
        COUNT(DISTINCT i.inventory_id) number_of_copies,
        COUNT(f.title) number_of_rentals,
        ROUND(COUNT(f.title) / COUNT(DISTINCT i.inventory_id),2) demand_per_copy
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.title, f.film_id)
SELECT *
FROM movie_metrics 
WHERE number_of_rentals > 5 AND demand_per_copy >= 4.5
ORDER BY demand_per_copy DESC;

-- Question 7: Which movie categories perform best?

WITH movie_metrics AS (
    SELECT 
        f.title, 
        COUNT(DISTINCT i.inventory_id) number_of_copies,
        SUM(p.amount) rental_revenue,
        COUNT(f.title) number_of_rentals,
        c.name category
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY f.title, f.film_id, c.name),
    category_metrics AS (
        SELECT
            category,
            RANK() OVER(ORDER BY SUM(rental_revenue) DESC) rev_ranked,
            RANK() OVER(ORDER BY ROUND(SUM(rental_revenue) / COUNT(title),2) DESC) avg_rev_ranked,
            COUNT(title) movies_per_category,
            SUM(rental_revenue) revenue_per_category,
            SUM(number_of_rentals) rentals_per_category,
            ROUND(SUM(rental_revenue) / COUNT(title),2) avg_revenue_per_film
        FROM movie_metrics
        GROUP BY category
    )
SELECT *
FROM category_metrics
ORDER BY rev_ranked, avg_rev_ranked;

-- ============================================================
-- 3. STORE ANALYSIS
-- ============================================================

-- Question 8: How do the two stores compare?

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id),
    store_metrics AS (
        SELECT 
            store_id, 
            COUNT(customer_id) customers_per_store,
            SUM(number_of_rentals) rentals_per_store,
            SUM(total_spend) revenue_per_store,
            ROUND(SUM(total_spend) / SUM(number_of_rentals),2) rev_per_rental,
            ROUND(SUM(total_spend) / COUNT(customer_id),2) rev_per_customer,
            CONCAT(ROUND(SUM(total_spend)*100 / SUM(SUM(total_spend)) OVER(),0),'%') pct_of_total_rev
        FROM customer_metrics
        GROUP BY store_id
    )
SELECT *
FROM store_metrics;

-- ============================================================
-- 4. ADVANCED ANALYSIS
-- ============================================================

-- Question 9: Who are high-value but low-frequency customers?

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id),
    customer_quartiles AS (
        SELECT
            *,
            NTILE(4) OVER(ORDER BY total_spend DESC) quartile,
            AVG(number_of_rentals) OVER() avg_rentals
        FROM customer_metrics
    )
SELECT customer_id, store_id, customer_name, city, number_of_rentals, total_spend
FROM customer_quartiles 
WHERE quartile = 1 AND number_of_rentals < avg_rentals;

-- Question 10: Which movies are overperforming relative to their category?

WITH movie_metrics AS (
    SELECT 
        f.title, 
        SUM(p.amount) rental_revenue,
        c.name category,
        ROUND(AVG(SUM(p.amount)) OVER(PARTITION BY c.name),2) avg_category_rev
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY f.title, f.film_id, c.name),
    category_metrics AS (
        SELECT
            category,
            COUNT(title) movies_per_category,
            SUM(rental_revenue) revenue_per_category,
            ROUND(SUM(rental_revenue) / COUNT(title),2) avg_revenue_per_film
        FROM movie_metrics
        GROUP BY category
    )
SELECT *
FROM movie_metrics
WHERE rental_revenue >= avg_category_rev * 2
ORDER BY category;

-- Question 11: Who are the top customers within each store?

WITH customer_metrics AS (
    SELECT 
        c.customer_id, 
        c.store_id, 
        CONCAT(c.first_name,' ',c.last_name) customer_name, 
        city.city, 
        COUNT(r.rental_id) number_of_rentals, 
        SUM(p.amount) total_spend
    FROM customer c
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id),
    store1 AS (
        SELECT *, RANK() OVER(ORDER BY total_spend DESC) "rank"
        FROM customer_metrics
        WHERE store_id = 1
        ORDER BY total_spend DESC
        LIMIT 5
    ),
    store2 AS (
        SELECT *, RANK() OVER(ORDER BY total_spend DESC) "rank"
        FROM customer_metrics
        WHERE store_id = 2
        ORDER BY total_spend DESC
        LIMIT 5
    )
SELECT * FROM store1
UNION ALL
SELECT * FROM store2;

