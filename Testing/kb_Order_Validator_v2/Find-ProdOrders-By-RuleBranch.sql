/*======================================================================================
  Find-ProdOrders-By-RuleBranch.sql            READ-ONLY. Run against PROD (P21).

  Classifies real Prod orders created AFTER the BRR refresh (2026-08-25) by which branch
  of asi_Order_Validator_t2 their CURRENT state would trigger on a re-save.

  WHY POST-REFRESH ORDERS
    BRR is a snapshot of Prod as of 2026-08-25, so these orders do NOT exist in BRR. They
    are therefore safe to use as test *specifications* -- recreate the shape in BRR rather
    than expecting the order number to be there.

  WHY MOST WILL CLASSIFY AS PASS
    kb_Order_Validator_v2 is live in Prod, so an order that would have blocked mostly never
    got saved in the first place. The blocking rows this finds are orders whose state
    CHANGED after the save that created them (a line removed, a note deleted, a date moved).
    That is exactly the population a re-save test needs, so a small count here is expected
    and is not a bug in this query.

  MIRRORS THE ENGINE'S ORDERED CHAIN -- first match wins. Kept deliberately parallel to
  OrderValidationEngine.Validate() so the two can be diffed by eye.
======================================================================================*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @since date = '2026-08-26';   -- day after the BRR refresh

;WITH hdr AS (
    SELECT h.order_no, h.date_created, h.requested_date, h.freight_code_uid,
           h.packing_basis, h.customer_id, h.address_id AS ship_to_id,
           h.carrier_id, h.order_type, h.rma_flag, h.cancel_flag,
           h.delete_flag
    FROM   oe_hdr h
    WHERE  h.date_created >= @since
      AND  h.delete_flag = 'N'
      AND  ISNULL(h.rma_flag,'N')    <> 'Y'     -- skip conditions, same as the adapter
      AND  ISNULL(h.cancel_flag,'N') <> 'Y'
      /* The adapter's third skip is the DataWindow's `quote` field, which has no direct
         oe_hdr column (quote_locked_flag / quote_submitted_flag / quote_type are the only
         candidates, and quote_type is blank on all 18,882 rows in this window). Quotes are
         therefore effectively absent from this pool and the filter is omitted rather than
         guessed at. If a candidate order turns out to be a quote, the rule will skip it and
         the test case is simply void -- it will not produce a wrong verdict. */
),
/* Line-level rollup. QtyOpen mirrors the adapter: qty_ordered when the line qualifies
   (open, not complete, not a bundle), otherwise 0. */
ln AS (
    /* oe_line has no item_id -- it carries inv_mast_uid. The DataWindow field the adapter
       reads (oe_order_item_id) resolves to inv_mast.item_id, so join to get it. */
    SELECT l.order_no,
           item_id  = im.item_id,
           ext      = ISNULL(l.extended_price,0),
           qty_open = CASE WHEN ISNULL(l.qty_ordered,0) > 0
                            AND ISNULL(l.complete,'N') <> 'Y'
                            AND ISNULL(im.product_type,'') <> 'B'
                           THEN l.qty_ordered ELSE 0 END,
           is_freight = CASE WHEN im.item_id IN ('FREIGHT CHARGE','UPS CHARGE','SPEEDEE CHARGE')
                             THEN 1 ELSE 0 END,
           /* "counted" items = the kb_view_item_classifications_loc100 replacement:
              anything whose default product group is not OCHARGE. */
           is_counted = CASE WHEN pg.product_group_id IS NOT NULL
                              AND pg.product_group_id NOT IN ('OCHARGE') THEN 1 ELSE 0 END
    FROM   oe_line l
    JOIN   hdr ON hdr.order_no = l.order_no
    LEFT   JOIN inv_mast im      ON im.inv_mast_uid = l.inv_mast_uid
    LEFT   JOIN product_group pg ON pg.product_group_id = im.default_product_group
    WHERE  ISNULL(l.delete_flag,'N') = 'N'
),
agg AS (
    SELECT order_no,
           line_count      = COUNT(*),
           freight_present = MAX(is_freight),
           freight_open    = SUM(CASE WHEN is_freight=1 THEN qty_open ELSE 0 END),
           freight_ext     = SUM(CASE WHEN is_freight=1 THEN ext ELSE 0 END),
           order_total     = SUM(CASE WHEN is_counted=1 THEN ext ELSE 0 END),
           counted_open    = SUM(CASE WHEN is_counted=1 THEN qty_open ELSE 0 END)
    FROM   ln GROUP BY order_no
),
nte AS (
    SELECT n.order_no,
           freight_quote_note = MAX(CASE WHEN n.topic='Freight Quote Required'
                                          AND ISNULL(n.mandatory,'N')='Y' THEN 1 ELSE 0 END),
           signature_note     = MAX(CASE WHEN n.topic='Signature Required' THEN 1 ELSE 0 END)
    FROM   oe_hdr_notepad n
    JOIN   hdr ON hdr.order_no = n.order_no
    WHERE  ISNULL(n.delete_flag,'N') = 'N'
    GROUP  BY n.order_no
),
base AS (
    SELECT h.order_no, h.date_created, h.freight_code_uid,
           fc_desc     = fc.freight_desc,
           auto_adds   = CASE WHEN ISNULL(fc.outgoing_freight,'N')='Y' THEN 1 ELSE 0 END,
           h.packing_basis,
           order_complete = CASE WHEN h.packing_basis='Order Complete' THEN 1 ELSE 0 END,
           carrier_name = ca.name,
           /* Carrier will-call is looked up BY NAME (TOP 1) to mirror the rule's
              [PRESERVED-BUG]. A name that matches nothing yields NULL, and both
              will-call and not-will-call are then false -- the original fail-open. */
           wc = (SELECT TOP 1 COALESCE(ud.will_call,'N')
                 FROM   address a LEFT JOIN address_ud ud ON ud.id = a.id
                 WHERE  a.carrier_flag='Y' AND a.name = ca.name
                 ORDER BY a.id),
           credit_status = c.credit_status,
           cod_cash_prepay = CASE WHEN c.credit_status IN ('COD','CASH','PREPAY') THEN 1 ELSE 0 END,
           a.line_count, a.freight_present, a.freight_open, a.freight_ext,
           a.order_total, a.counted_open,
           freight_zero = CASE WHEN ISNULL(a.freight_present,0)=0 OR ISNULL(a.freight_ext,0)=0
                               THEN 1 ELSE 0 END,
           order_status = CASE CAST(h.requested_date AS date)
                            WHEN '2022-02-22' THEN 'Will Advise'
                            WHEN '2033-03-03' THEN 'Ship with Other Goods'
                            WHEN '2033-03-23' THEN 'Reserve'
                            WHEN '2049-12-31' THEN 'Will Advise'
                            ELSE '' END,
           freight_quote_note = ISNULL(n.freight_quote_note,0),
           signature_note     = ISNULL(n.signature_note,0),
           order_type_desc    = ot.code_desc,
           h.ship_to_id, h.customer_id, h.requested_date
    FROM   hdr h
    LEFT   JOIN agg a  ON a.order_no = h.order_no
    LEFT   JOIN nte n  ON n.order_no = h.order_no
    LEFT   JOIN p21_view_freight_code fc
                        ON fc.freight_code_uid = h.freight_code_uid AND fc.row_status = 704
    LEFT   JOIN address ca ON ca.id = h.carrier_id
    LEFT   JOIN customer c ON c.customer_id = h.customer_id
    /* order_type is an int; the DataWindow hands the rule the DESCRIPTION, so resolve it
       the same way. Code group 1215: 706 OE, 1344 CUO Entry, 3864 Quick Front Counter, etc.
       Join is on code_no -- code_x_code_group_p21 has no code_uid. */
    LEFT   JOIN (SELECT c.code_no, code_desc = c.code_description
                 FROM   code_p21 c
                 JOIN   code_x_code_group_p21 x ON x.code_no = c.code_no
                 WHERE  x.code_group_no = 1215) ot
                        ON ot.code_no = h.order_type
)
SELECT order_no, date_created, freight_code_uid, fc_desc, packing_basis, carrier_name, wc,
       credit_status, line_count, freight_present, freight_ext, order_total, counted_open,
       order_status, freight_quote_note, signature_note, order_type_desc, requested_date,
       expected_branch =
         CASE
           WHEN freight_code_uid IS NULL                     THEN 'v2err#0 freight code blank'
           WHEN ISNULL(line_count,0) = 0                     THEN 'v2err#0 no items'
           WHEN ship_to_id   IS NULL                         THEN 'v2err#0 ship-to blank'
           WHEN credit_status IS NULL                        THEN 'v2err#0 credit blank'
           WHEN customer_id  IS NULL                         THEN 'v2err#0 customer blank'
           WHEN carrier_name IS NULL                         THEN 'v2err#0 carrier blank'
           WHEN packing_basis IS NULL                        THEN 'v2err#0 packing basis blank'
           -- 1
           WHEN cod_cash_prepay=1 AND auto_adds=1 AND wc='N' AND freight_present=1 THEN 'v2err#1a'
           WHEN cod_cash_prepay=1 AND auto_adds=1 AND wc='N'                       THEN 'v2err#1c'
           -- 2
           WHEN auto_adds=1 AND freight_present=1 AND order_complete=1             THEN 'v2err#2a'
           WHEN auto_adds=1 AND freight_open>0    AND order_complete=0             THEN 'v2err#2b'
           -- 3
           WHEN freight_code_uid=6 AND freight_present=0 AND wc='N' AND order_complete=1
                                                                                   THEN 'v2err#3a'
           WHEN freight_code_uid=6 AND freight_open=0 AND counted_open>0 AND wc='N'
                AND order_complete=0                                               THEN 'v2err#3b'
           -- 4
           WHEN freight_code_uid=8 AND wc='N'                                      THEN 'v2err#4a'
           WHEN freight_code_uid NOT IN (8,12,7) AND wc='Y'                        THEN 'v2err#4c'
           -- 6
           WHEN order_status <> 'Will Advise' AND cod_cash_prepay=1 AND freight_zero=1
                AND wc='N' AND freight_code_uid NOT IN (5,7,10,12)                 THEN 'v2err#6a'
           WHEN order_status =  'Will Advise' AND freight_zero=0 AND freight_quote_note=1
                AND wc='N' AND freight_code_uid NOT IN (5,7,10,12)                 THEN 'v2err#6b'
           -- 7
           WHEN order_total >= 15000 AND signature_note=0 AND order_type_desc IS NOT NULL
                AND order_type_desc <> 'CUO Entry'                                 THEN 'v2err#7'
           ELSE 'pass'
         END
INTO   #classified
FROM   base;

/* 1. Distribution -- how much real-world coverage each branch has. */
SELECT expected_branch, orders = COUNT(*)
FROM   #classified GROUP BY expected_branch ORDER BY COUNT(*) DESC;

/* 2. Up to 5 concrete candidate orders per branch, for the test cases. */
SELECT expected_branch, order_no, date_created, freight_code_uid, fc_desc, packing_basis,
       carrier_name, wc, credit_status, order_total, order_status,
       freight_present, signature_note, freight_quote_note, order_type_desc
FROM   (SELECT *, rn = ROW_NUMBER() OVER (PARTITION BY expected_branch ORDER BY order_no DESC)
        FROM   #classified) z
WHERE  rn <= 5
ORDER  BY expected_branch, order_no DESC;

DROP TABLE #classified;
