/*
if Nightly report fails, must manually enter the date
*/
use P21;
---use P21Play;

if OBJECT_ID ('Special_Daily_Quotes_VW', 'V') is not null
drop view Special_Daily_Quotes_VW;
go

create view [dbo].[Special_Daily_Quotes_VW] AS
WITH cteOH(order_no, order_date, customer_id, ship2_CompanyName, taker, BranchID, TelNo, CustName, ZipCode, City, SState, email) 
AS 
(SELECT h.order_no, h.order_date, h.customer_id, h.ship2_name, h.taker, h.location_id, h.ship_to_phone, c.first_name + ' ' + c.last_name AS Expr1, 
                                                                                                                                                                                                                                                                                                                                        CASE WHEN ship2_zip IS NULL THEN 'No Zip' ELSE ship2_zip END AS Expr2, 
                                                                                                                                                                                                                                                                                                                                        CASE WHEN ship2_city IS NULL THEN 'No City' ELSE ship2_city END AS Expr3, 
                                                                                                                                                                                                                                                                                                                                        CASE WHEN ship2_state IS NULL THEN 'No State' ELSE ship2_state END AS Expr4, 
                                                                                                                                                                                                                                                                                                                                        COALESCE (c.email_address, a.email_address, 'No email address') AS Expr5
                                                                                                                                                                                                                                                                                                               FROM            dbo.oe_hdr AS h INNER JOIN
                                                                                                                                                                                                                                                                                                                                        dbo.contacts AS c ON h.contact_id = c.id
																																																																																		 INNER JOIN
                                                                                                                                                                                                                                dbo.address AS a ON c.id = a.id
WHERE(h.order_date BETWEEN '2023-11-08 18:00:00.00' AND '2023-11-09 18:00:00.00') AND 
                                                                                                                                                                                                                                                                                                                                        (h.projected_order = 'Y') AND (h.delete_flag = 'N')), cteLegacy(order_no, order_date, 
customer_id, legacy_id, ship2_CompanyName, taker, BranchID, TelNo, CustName, ZipCode, City, SState, email) AS
    (SELECT        ch.order_no, ch.order_date, cu.customer_id, cu.legacy_id, ch.ship2_CompanyName, ch.taker, ch.BranchID, ch.TelNo, ch.CustName, ch.ZipCode, ch.City, ch.SState, ch.email
      FROM            cteOH AS ch INNER JOIN
                                dbo.customer AS cu ON ch.customer_id = cu.customer_id), cteSR(order_no, order_date, customer_id, legacy_id, ship2_CompanyName, salesrep_id, taker, BranchID, TelNo, CustName, ZipCode, City, SState, email) 
AS
    (SELECT        cl.order_no, cl.order_date, cl.customer_id, CASE WHEN legacy_id IS NULL THEN ' ' ELSE legacy_id END AS Expr1, cl.ship2_CompanyName, csr.salesrep_id, cl.taker, cl.BranchID, cl.TelNo, cl.CustName, cl.ZipCode, cl.City, 
                                cl.SState, cl.email
      FROM            cteLegacy AS cl INNER JOIN
                                dbo.oe_hdr_salesrep AS os ON cl.order_no = os.order_number INNER JOIN
                                dbo.customer_salesrep AS csr ON cl.customer_id = csr.customer_id AND os.salesrep_id = csr.salesrep_id
      WHERE        (os.primary_salesrep = 'Y')), cteOLinePrice(order_no, order_date, customer_id, legacy_id, ship2_CompanyName, salesrep_id, taker, BranchID, TelNo, CustName, ZipCode, City, SState, email, customer_part_number, 
inv_mast_uid, product_group_id, qty_ordered, unit_price, extended_price) AS
    (SELECT        sr.order_no, sr.order_date, sr.customer_id, sr.legacy_id, sr.ship2_CompanyName, sr.salesrep_id, sr.taker, sr.BranchID, sr.TelNo, sr.CustName, sr.ZipCode, sr.City, sr.SState, sr.email, l.customer_part_number, 
                                l.inv_mast_uid, l.product_group_id, CAST(l.qty_ordered AS int) AS Expr1, CAST(l.unit_price AS decimal(10, 2)) AS Expr2, CAST(l.extended_price AS decimal(10, 2)) AS Expr3
      FROM            cteSR AS sr INNER JOIN
                                dbo.oe_line AS l ON sr.order_no = l.order_no), cteItemDesc(order_no, order_date, customer_id, legacy_id, ship2_CompanyName, salesrep_id, taker, BranchID, TelNo, CustName, ZipCode, City, SState, email, 
customer_part_number, item_desc, product_group_id, qty_ordered, unit_price, extended_price) AS
    (SELECT        cop.order_no, cop.order_date, cop.customer_id, cop.legacy_id, cop.ship2_CompanyName, cop.salesrep_id, cop.taker, cop.BranchID, cop.TelNo, cop.CustName, cop.ZipCode, cop.City, cop.SState, cop.email, 
                                cop.customer_part_number, i.item_desc, cop.product_group_id, cop.qty_ordered, cop.unit_price, cop.extended_price
      FROM            cteOLinePrice AS cop INNER JOIN
                                dbo.inv_mast AS i ON cop.inv_mast_uid = i.inv_mast_uid), cteAddSRName(SalesManager, order_no, order_date, customer_id, legacy_id, ship2_CompanyName, salesrep_id, SalesRepName, taker, BranchID, TelNo, 
CustName, ZipCode, City, SState, email, customer_part_number, item_desc, product_group_id, qty_ordered, unit_price, extended_price) AS
    (SELECT        CASE WHEN cid.salesrep_id = 1004 THEN 'Michael Moonan' WHEN cid.salesrep_id = 1005 THEN 'LMS House Account' WHEN cid.salesrep_id = 1006 THEN 'IPTCI HOUSE CORPORATE' WHEN cid.salesrep_id IN (18353, 
                                40391) THEN 'George Dib' WHEN cid.salesrep_id IN (1017, 1021, 1025, 1026, 1029, 34446, 36840) THEN 'Scott Kuhn' WHEN cid.salesrep_id IN (1020, 1022, 1023, 1024, 1032, 1033, 1038, 1039, 1040, 10654, 10659, 34445) 
                                THEN 'Ryan Linke' ELSE 'No Mgr Assigned' END AS Expr1, cid.order_no, cid.order_date, cid.customer_id, cid.legacy_id, cid.ship2_CompanyName, cid.salesrep_id, 
                                c2.first_name + ' ' + c2.last_name + ' (' + cid.salesrep_id + ')' AS Expr2, cid.taker, cid.BranchID, cid.TelNo, cid.CustName, cid.ZipCode, cid.City, cid.SState, cid.email, cid.customer_part_number, cid.item_desc, 
                                cid.product_group_id, cid.qty_ordered, cid.unit_price, cid.extended_price
      FROM            cteItemDesc AS cid INNER JOIN
                                dbo.contacts AS c2 ON cid.salesrep_id = c2.id)
    SELECT        cSR.SalesManager, cSR.order_no, CONVERT(varchar(2), DATEPART(MONTH, cSR.order_date)) + '/' + CONVERT(varchar(2), DATEPART(day, cSR.order_date)) + '/' + CONVERT(varchar(4), DATEPART(YEAR, cSR.order_date)) 
                              AS order_date, cSR.customer_id, cSR.legacy_id, a.name AS CompanyName, cSR.ship2_CompanyName, cSR.salesrep_id, cSR.SalesRepName, cSR.taker, cSR.BranchID, cSR.TelNo, cSR.CustName, cSR.ZipCode, cSR.City, 
                              cSR.SState, cSR.email, cSR.customer_part_number, cSR.item_desc, cSR.product_group_id, cSR.qty_ordered, cSR.unit_price, cSR.extended_price
     FROM            cteAddSRName AS cSR INNER JOIN
                              dbo.address AS a ON cSR.customer_id = a.id

go 

grant select on object::Special_Daily_Quotes_VW to p21_application_role
grant select on object::Special_Daily_Quotes_VW to PxxiUser
grant select on object::Special_Daily_Quotes_VW to [PTIDOM\P21Users]


