/* Every DataWindow field asi_Order_Validator_t2 actually reads, checked against what is
   registered. ANY 'NOT REGISTERED' row is a latent false block: P21 only populates
   registered elements, so the adapter would see the column as absent.
   Set @uid to the rule being checked. */
DECLARE @uid INT = 166;   -- asi_Order_Validator_t2 (renamed in place 2026-09-03; was the
                          -- _t1 row). Repaired to 76 elements / 5 DataWindows -- all 23 'ok'.
                          -- Re-run this after ANY Rule Manager save on this rule.

;WITH required(dw, field, used_for) AS (
    SELECT * FROM (VALUES
      -- d_oe_header
      ('d_oe_header','order_no',                    'logging + diagnostics'),
      ('d_oe_header','date_created',                'pre-2018 always-allow gate'),
      ('d_oe_header','requested_date',              'required-date status (6a/6b)'),
      ('d_oe_header','freight_code_uid',            '*** precursor + checks 3,4,6 ***'),
      ('d_oe_header','ship_to_id',                  'precursor + freight charge lookup'),
      ('d_oe_header','customer_id',                 'precursor'),
      ('d_oe_header','packing_basis',               'precursor + checks 2,3'),
      ('d_oe_header','order_type',                  'check 7 CUO exemption'),
      ('d_oe_header','rma_flag',                    'skip condition'),
      ('d_oe_header','quote',                       'skip condition'),
      ('d_oe_header','cancel_flag',                 'skip condition'),
      ('d_oe_header','ufc_oe_hdr_ud_oe_surcharge',  'fuel surcharge toggle (WRITTEN)'),
      -- d_dw_oe_line_dataentry
      ('d_dw_oe_line_dataentry','delete_flag',      'line filter'),
      ('d_dw_oe_line_dataentry','oe_order_item_id', 'item id -- freight/fuel/counted'),
      ('d_dw_oe_line_dataentry','qty_ordered',      'qty_open gate'),
      ('d_dw_oe_line_dataentry','oe_line_complete', 'qty_open gate'),
      ('d_dw_oe_line_dataentry','product_type',     'bundle gate'),
      ('d_dw_oe_line_dataentry','extended_price',   'freight_zero + order_total'),
      -- d_dw_oe_hdr_shipinfo
      ('d_dw_oe_hdr_shipinfo','oe_hdr_carrier_id',  'carrier name -> will-call lookup'),
      -- d_oe_hdr_credit
      ('d_oe_hdr_credit','credit_status',           'precursor + checks 1,6a'),
      -- d_dw_oe_hdr_notepad_dataentry
      ('d_dw_oe_hdr_notepad_dataentry','delete_flag','note filter'),
      ('d_dw_oe_hdr_notepad_dataentry','topic',     'freight-quote + signature notes'),
      ('d_dw_oe_hdr_notepad_dataentry','mandatory', 'freight-quote note (6b)')
    ) v(dw, field, used_for)
)
SELECT  status = CASE WHEN e.field_name IS NULL
                      THEN '*** NOT REGISTERED -- WILL FALSE-BLOCK ***' ELSE 'ok' END,
        r.dw, r.field, r.used_for
FROM        required r
LEFT JOIN   business_rule_data_element e
       ON   e.business_rule_uid = @uid
      AND   e.field_name = r.field
      AND   e.class_name = r.dw
ORDER BY CASE WHEN e.field_name IS NULL THEN 0 ELSE 1 END, r.dw, r.field;

-- Registered but unread: harmless (just a bigger DataSet), but they are leftovers from the
-- kb_ list and can be trimmed once the equivalence diff is clean. NOT urgent.
SELECT unread_registered = COUNT(*)
FROM   business_rule_data_element e
WHERE  e.business_rule_uid = @uid
  AND  NOT EXISTS (
        SELECT 1 FROM (VALUES
          ('d_oe_header','order_no'),('d_oe_header','date_created'),
          ('d_oe_header','requested_date'),('d_oe_header','freight_code_uid'),
          ('d_oe_header','ship_to_id'),('d_oe_header','customer_id'),
          ('d_oe_header','packing_basis'),('d_oe_header','order_type'),
          ('d_oe_header','rma_flag'),('d_oe_header','quote'),
          ('d_oe_header','cancel_flag'),('d_oe_header','ufc_oe_hdr_ud_oe_surcharge'),
          ('d_dw_oe_line_dataentry','delete_flag'),('d_dw_oe_line_dataentry','oe_order_item_id'),
          ('d_dw_oe_line_dataentry','qty_ordered'),('d_dw_oe_line_dataentry','oe_line_complete'),
          ('d_dw_oe_line_dataentry','product_type'),('d_dw_oe_line_dataentry','extended_price'),
          ('d_dw_oe_hdr_shipinfo','oe_hdr_carrier_id'),('d_oe_hdr_credit','credit_status'),
          ('d_dw_oe_hdr_notepad_dataentry','delete_flag'),
          ('d_dw_oe_hdr_notepad_dataentry','topic'),
          ('d_dw_oe_hdr_notepad_dataentry','mandatory')
        ) v(dw, field)
        WHERE v.field = e.field_name AND v.dw = e.class_name);
