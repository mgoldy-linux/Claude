**P21 Alert Customization**

New Order Alert: Extended Standard Cost Filter

March 11, 2026

# **Overview**

This document summarizes the customization work performed on the Prophet 21 (P21) ERP system to add an Extended Standard Cost filter to the New Order alert. The goal was to add a calculated cost threshold filter — (standard\_cost / pricing\_unit\_size \* unit\_quantity \* unit\_size) \> 500 — to an existing alert that already had seven filters defined.

## **Existing Alert Configuration**

The alert already had the following seven filters before our changes:

| Column | Operator | Value |
| :---- | :---- | :---- |
| New Order | equals | Yes |
| Line Item Profit Percentage | is less than | 5 |
| Total Amount | is greater than | 1000 |
| Corporate Address ID | does not equal | 1046538 |
| Product Group ID | is not one of | OCHARGE, SAMPLES, PAD |
| Customer ID | is not one of | 3021352, 3023035, 3023036 |
| Taker | does not contain | ESTORE |

# **Step 1: Identify the Alert Type UID**

The first step was to identify the correct alert\_type\_uid for the New Order (Order Entry) alert by querying the alert\_type table joined to code\_p21:

| SELECT at.alert\_type\_uid, at.view\_name, sc.code\_description FROM alert\_type at INNER JOIN code\_p21 sc ON sc.code\_no \= at.type\_cd WHERE at.view\_name \= 'oe\_OrderEntry' |
| :---- |

Result: Two records were returned:

| alert\_type\_uid | view\_name | code\_description |
| :---- | :---- | :---- |
| 12 | oe\_OrderEntry | Order Entry / Front Counter |
| 15 | oe\_OrderEntry | RMA Entry |

The correct alert\_type\_uid for the New Order alert is 12\.

# **Step 2: Modify the Alert View**

The calculated field uses inv\_loc.standard\_cost, which is not in the standard view columns. We confirmed that inv\_loc was already joined in the view p21\_view\_alert\_oe\_OrderEntry:

| INNER JOIN inv\_loc ON (inv\_loc.inv\_mast\_uid \= inv\_mast.inv\_mast\_uid)     AND (inv\_loc.location\_id \= oe\_line.source\_loc\_id) |
| :---- |

We then added the calculated column to the SELECT statement immediately before the FROM clause:

| \-- mg add for SA 37384 , CAST(COALESCE(inv\_loc.standard\_cost / NULLIF(oe\_line.pricing\_unit\_size, 0\)   \* oe\_line.unit\_quantity \* oe\_line.unit\_size, 0\)   AS DECIMAL(19,2)) 'extended\_standard\_cost' |
| :---- |

Note: NULLIF was used on pricing\_unit\_size to prevent division-by-zero errors. CAST AS DECIMAL(19,2) was used instead of p21\_fn\_MaskDecimal because the function was found to return DECIMAL(19,6) regardless of system settings.

# **Step 3: Register the Token**

After confirming the correct available\_areas and data\_type\_cd values by querying existing tokens on alert type 12, we registered the new token using the p21\_apply\_alert\_token stored procedure:

| DECLARE @return\_value int EXEC @return\_value \= \[dbo\].\[p21\_apply\_alert\_token\]     @alert\_type\_uid \= 12,     @token\_name \= N'extended\_standard\_cost',     @token\_available\_areas \= 32,     @token\_description \= N'Extended Standard Cost',     @token\_data\_type\_cd \= 851,     @token\_code\_group\_no \= null SELECT 'Return Value' \= @return\_value |
| :---- |

After registration, the description was updated manually because p21\_apply\_alert\_token was overriding the @token\_description parameter with the full formula text:

| UPDATE token SET description \= 'Extended Standard Cost' WHERE name \= 'extended\_standard\_cost' |
| :---- |

**Troubleshooting: Duplicate Tokens**

During registration, two duplicate tokens (UIDs 734 and 735\) were created from earlier attempts with incorrect parameters. These were cleaned up by deleting from child tables first:

| \-- Delete from child tables first DELETE FROM Alert\_implementation\_query WHERE column\_id IN (734, 735\) DELETE FROM alert\_type\_x\_token WHERE token\_uid IN (734, 735\) DELETE FROM token WHERE token\_uid IN (734, 735\) |
| :---- |

# **Step 4: Fix Decimal Formatting**

During testing the alert email showed raw 6-decimal values (e.g. qty: 5.000000, Price: 397.570000). Investigation showed this was caused by p21\_fn\_MaskDecimal returning DECIMAL(19,6) regardless of system settings due to its hardcoded return type.

The fix was to replace p21\_fn\_MaskDecimal with CAST AS DECIMAL in the view for the affected columns:

| Column | Before | After |
| :---- | :---- | :---- |
| order\_quantity | p21\_fn\_MaskDecimal(..., 'Qty') | CAST(... AS DECIMAL(19,3)) |
| unit\_price | p21\_fn\_MaskDecimal(..., 'Money') | CAST(... AS DECIMAL(19,2)) |
| extended\_standard\_cost | p21\_fn\_MaskDecimal(..., 'Money') | CAST(... AS DECIMAL(19,2)) |

# **Final Result**

The alert now has all original filters plus the new Extended Standard Cost filter:

| Column | Operator | Value |
| :---- | :---- | :---- |
| New Order | equals | Yes |
| Line Item Profit Percentage | is less than | 5 |
| Total Amount | is greater than | 1000 |
| Corporate Address ID | does not equal | 1046538 |
| Product Group ID | is not one of | OCHARGE, SAMPLES, PAD |
| Customer ID | is not one of | 3021352, 3023035, 3023036 |
| Taker | does not contain | ESTORE |
| Extended Standard Cost | is greater than | 500 |

# **Key Notes & Lessons Learned**

* inv\_loc is already joined in p21\_view\_alert\_oe\_OrderEntry via source\_loc\_id — no additional join was needed.

* p21\_apply\_alert\_token overrides the @token\_description parameter with the view column formula. Always update the description manually after registration.

* Token cleanup requires deleting from Alert\_implementation\_query and alert\_type\_x\_token before deleting from the token table due to foreign key constraints.

* p21\_fn\_MaskDecimal is hardcoded to return DECIMAL(19,6). Use CAST AS DECIMAL(19,X) directly in the view for reliable decimal precision in alert emails.

* Always test all changes in the Play/Dev database before applying to production.

* The correct available\_areas and data\_type\_cd values for new tokens should be confirmed by querying existing tokens on the same alert\_type\_uid.

# **Files Changed**

| Object | Change |
| :---- | :---- |
| dbo.p21\_view\_alert\_oe\_OrderEntry | Added extended\_standard\_cost column; fixed order\_quantity and unit\_price decimal precision |
| dbo.token | Registered new token extended\_standard\_cost (token\_uid 737\) |
| dbo.alert\_type\_x\_token | Linked token 737 to alert\_type\_uid 12 |

