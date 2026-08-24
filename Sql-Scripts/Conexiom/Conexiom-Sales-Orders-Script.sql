--Conexiom Sales Orders
; WITH cte1 AS ( 
SELECT 
oeh . customer_id 
, c . customer_name 
, COUNT ( oeh . order_no ) AS total_orders 
, SUM ( oel_drv . order_lines ) AS total_lines 
FROM oe_hdr oeh WITH ( NOLOCK )
JOIN ( SELECT oel . order_no 
, SUM ( oel . extended_price ) AS order_amt 
, COUNT ( oel . line_no ) AS order_lines 
FROM oe_line oel WITH ( NOLOCK ) 
GROUP BY oel . order_no 
) AS oel_drv ON oeh . order_no = oel_drv . order_no 
LEFT JOIN customer c WITH ( NOLOCK ) ON oeh . customer_id = c . customer_id 
WHERE ( oeh . order_date >= DATEADD ( YEAR ,- 1 , CURRENT_TIMESTAMP ) AND oeh . order_date <= CURRENT_TIMESTAMP ) 
GROUP BY oeh . customer_id 
, c . customer_name 
), 
cte2 AS ( 
SELECT CONCAT ( '(' , cte1 . customer_id , ') ' , cte1 . customer_name ) AS customer 
, cte1 . total_orders
, cte1 . total_lines 
FROM cte1
) 
SELECT * 
FROM cte2 
ORDER BY total_orders DESC
