/* SA 56558 - CONUP160121 "lot/Bin combination does not exist" (2026-10-08). READ ONLY.
   Cause: 4 of the 7 lots in the 342 LOST bin are stored WITH A LEADING SPACE; each has a
   no-space twin lot at 0.00. Typing the roll # without the space matches the empty twin.
   Run against P21.allsurfaces.com / P21 (Play has the space lots but no LOST bin for this item). */
DECLARE @item varchar(40) = 'CONUP160121';   -- also checked CONAP412121, CON88015121 (no leading space)
DECLARE @im int = (SELECT inv_mast_uid FROM inv_mast WHERE item_id = @item);

SELECT x.bin_cd, '[' + x.lot_cd + ']' AS lot_cd, LEN(x.lot_cd) AS len, DATALENGTH(x.lot_cd) AS dl,
       CONVERT(varchar(60), CONVERT(varbinary(30), x.lot_cd), 2) AS hx,   -- 20.. = leading space
       CAST(x.qty_linked AS decimal(38,12)) AS xref_qty,
       (SELECT STRING_AGG('[' + l.lot + ']=' + CAST(CAST(l.qty_on_hand AS decimal(38,12)) AS varchar(30)), '; ')
        FROM lot l
        WHERE l.inv_mast_uid = @im AND l.location_id = 342
          AND LTRIM(RTRIM(l.lot)) = LTRIM(RTRIM(x.lot_cd))) AS lot_variants   -- the twin shows here
FROM lot_bin_xref x
WHERE x.inv_mast_uid = @im AND x.location_id = 342 AND x.bin_cd = 'LOST' AND x.qty_linked <> 0;

SELECT 'inv_bin' AS s, b.bin, CAST(b.quantity AS decimal(38,12)) AS qty
FROM inv_bin b WHERE b.inv_mast_uid = @im AND b.location_id = 342 AND b.bin = 'LOST';

/* NOT RUN - widespread check (how many lots in Prod carry a leading/trailing space):
SELECT COUNT(*) AS lots_with_space, COUNT(DISTINCT inv_mast_uid) AS items
FROM lot WHERE lot <> LTRIM(RTRIM(lot)); */
