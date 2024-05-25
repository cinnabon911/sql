-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
SELECT sum(5*original_price) as sales, vendor_name, product_name FROM
(SELECT DISTINCT vendor_name, product_name, original_price
from vendor_inventory as vi LEFT JOIN vendor as v on vi.vendor_id = v.vendor_id
LEFT JOIN product p on vi.product_id = p.product_id) sub
CROSS JOIN customer
GROUP by vendor_name, product_name


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
CREATE TEMP TABLE product_units
as 
SELECT *, CURRENT_TIMESTAMP as snapshot_timestamp FROM product
WHERE product_qty_type = 'unit'


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
INSERT INTO product_units
VALUES (7, 'Apple Pie', '10"', 3, 'unit', CURRENT_TIMESTAMP)


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units
WHERE snapshot_timestamp = (
SELECT max(snapshot_timestamp)
FROM product_units
)



-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

UPDATE product_units 
SET current_quantity = (
SELECT latest_qty from 
(SELECT pu.product_id, coalesce(quantity, 0) latest_qty from product_units pu 
left join (SELECT v.market_date, v.product_id, v.quantity
from vendor_inventory as v INNER JOIN
(SELECT product_id, max(market_date) as maxdate
FROM vendor_inventory
group by product_id) as sub
on v.market_date = sub.maxdate and v.product_id = sub.product_id) as outsub
on pu.product_id = outsub.product_id) as sub2
WHERE sub2.product_id = product_units.product_id)

