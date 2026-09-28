# Sakila SQL Business Analysis

## Project Overview

This project analyzes customer behavior, movie performance, and
store performance using the Sakila sample database.

The goal was to use SQL to answer business questions related to
customer value, rental demand, movie revenue, and store performance.

## Business Questions

The analysis investigates:

1. Who are the company's highest-spending customers?
2. Which customers spend more than the typical customer?
3. Which customers are unusually frequent renters?
4. Who are the company's overall most valuable customers?
5. Which movies are the most valuable?
6. Which movies have high demand relative to availability?
7. Which movie categories perform best?
8. How do the two Sakila stores compare?
9. Who are high-value but low-frequency customers?
10. Which movies are overperforming relative to their category?
11. Who are the top customers within each store?

## SQL Skills Demonstrated

- SELECT and filtering
- JOINs
- GROUP BY and aggregation
- Common Table Expressions (CTEs)
- Window functions
- Subqueries
- Ranking and segmentation
- Business metric calculation

## Key Findings
Customer value: 62 customers fell in the top 10% of total spend, 58 in the top 10% of rentals, and 63 in the top 10% of average spend per rental, but only 6 customers fell in the top 10% of all three categories. The store would benefit from adjusting prices accordingly to pull more customers who may fall in only one of these categories towards all three.

Movie demand: 49 films fall in the top 10% of rentals, but not in the top 10% of average payment or revenue. The store would benefit from raising prices on these films. Additionally, there are 54 films that have extremely high demand per copy (4.5 rentals per copy or more) that should have further inventory purchased. Finally, the Sports category of films brings in the most overall revenue, but only the 5th most average revenue per film. The store should consider raising prices on Sports films in order to capitalize on this demand. 

Store metrics: Store 1 is performing better across all metrics- it has more customers and rentals, and a higher revenue per store, per rental, and per customer. However, the discrepancy isn't huge; Store 1 accounts for 55% of total revenue and Store 2 accounts for 45%. Given how small the chasm between them is, Store 2 could benefit from slightly more support re: staff, inventory, etc., but is not in need of a serious intervention. 

Advanced analysis: There are four customers who qualify as high-value (75th percentile or above in total spend) but have low-frequency (lower than average) rental rates. The store should push email marketing especially towards these customers and similar customers to entice them to become more frequent renters.

## Tools

- MySQL
- MySQL Workbench
- SQL
- GitHub

## Database

This project uses the Sakila sample database provided by MySQL.
