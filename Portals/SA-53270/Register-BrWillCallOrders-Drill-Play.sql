/*
    SA 53270 - Make Order Id drillable on the BR WILL CALL ORDERS portal (Play)
    Server: P21Dev.allsurfaces.com   DB: P21Play

    Drill-through is configured in dc_nav_drill, not the .srd -- it maps a portal column
    (by its generated DataWindow column name, source_field) to a destination window/field.
    Template: dc_nav_drill_uid 31, the equivalent row for the sibling CSR WILL ADVISE portal
    (source_datawindow='udp_csr_will_advise', same source_field naming convention since both
    portals reference p21_view_oe_hdr.order_no directly with no alias).

    NOTE: source_datawindow uses a 'udp_' prefix over the raw datawindow_name registered in
    portal_user_defined -- confirmed from the existing udp_csr_will_advise / udp_csr_reserve_orders
    rows. dc_nav_drill_uid is an identity column.

    Idempotent: does nothing if a row for this source_datawindow/source_field already exists.
*/
SET NOCOUNT ON;

IF EXISTS (
    SELECT 1 FROM dc_nav_drill
    WHERE source_datawindow = 'udp_br_will_call_orders'
      AND source_field = 'p21_view_oe_hdr_order_no'
)
BEGIN
    SELECT 'ALREADY EXISTS - no action' AS result, *
    FROM dc_nav_drill
    WHERE source_datawindow = 'udp_br_will_call_orders'
      AND source_field = 'p21_view_oe_hdr_order_no';
    RETURN;
END

INSERT INTO dc_nav_drill
    (source_window, source_datawindow, source_field,
     dest_window, dest_datawindow, dest_field,
     row_status_flag, date_created, created_by, date_last_modified, last_maintained_by,
     type_cd, apply_drill_to_all_users, dest_window_name, source_data_field, navigation_type)
VALUES
    ('w_portal', 'udp_br_will_call_orders', 'p21_view_oe_hdr_order_no',
     'w_order_entry_sheet', 'd_oe_header', 'order_no',
     704, GETDATE(), 'mgoldyn', GETDATE(), 'mgoldyn',
     1418, 'Y', 'Order Entry', NULL, 3590);

SELECT 'CREATED' AS result, * FROM dc_nav_drill
WHERE source_datawindow = 'udp_br_will_call_orders'
  AND source_field = 'p21_view_oe_hdr_order_no';

/* ---------------------------------------------------------------
   ROLLBACK (Play only) -- replace <uid> with the dc_nav_drill_uid reported above:
     DELETE FROM dc_nav_drill WHERE dc_nav_drill_uid = <uid>;
   --------------------------------------------------------------- */
