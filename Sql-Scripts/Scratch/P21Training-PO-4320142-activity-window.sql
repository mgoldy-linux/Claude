/*
  P21Training (SQL host P21Dev.allsurfaces.com, database P21Training)
  What else happened around the creation of PO 4320142?

  PO header: created_by = admin, date_created 2026-10-20 05:11:17 (order_date 05:11:16).
  Window: +/- 10 minutes of 2026-10-20 05:11:16.

  Sections: 1 PO tables  2 email  3 audit_trail  4 scheduled jobs.
  Section 3 uses the KBJS_audit_trail_Cover01 index hint (KB/JS-era name - flag for retirement)
  to find the first audit_trail_uid of the window cheaply; drop the hint if the index is retired.
  Everything is read-only.
*/
SET NOCOUNT ON;

DECLARE @po_no     int       = 4320142,
        @center    datetime  = '2026-10-20 05:11:16.000',
        @minutes   int       = 10;
DECLARE @from datetime = DATEADD(MINUTE, -@minutes, @center),
        @to   datetime = DATEADD(MINUTE,  @minutes, @center);

SELECT [window_from] = @from, [window_to] = @to;

/* ---------- 1. PO tables: anything created or modified in the window ---------- */
SELECT 'po_hdr' AS src, h.po_no, NULL AS line_no, h.created_by, h.date_created,
       h.last_maintained_by, h.date_last_modified, CONCAT('source_type=', h.source_type) AS detail
FROM dbo.po_hdr h
WHERE h.date_created BETWEEN @from AND @to OR h.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'po_line', l.po_no, l.line_no, l.created_by, l.date_created,
       l.last_maintained_by, l.date_last_modified, CONCAT('item_id=', i.item_id)
FROM dbo.po_line l
LEFT JOIN dbo.inv_mast i ON i.inv_mast_uid = l.inv_mast_uid
WHERE l.date_created BETWEEN @from AND @to OR l.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'po_hdr_ud', u.po_no, NULL, u.created_by, u.date_created, u.last_maintained_by, u.date_last_modified, NULL
FROM dbo.po_hdr_ud u
WHERE u.date_created BETWEEN @from AND @to OR u.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'po_line_ud', u.po_no, u.line_no, u.created_by, u.date_created, u.last_maintained_by, u.date_last_modified, NULL
FROM dbo.po_line_ud u
WHERE u.date_created BETWEEN @from AND @to OR u.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'po_hdr_notepad', n.po_no, NULL, n.created_by, n.date_created, n.last_maintained_by, n.date_last_modified, NULL
FROM dbo.po_hdr_notepad n
WHERE n.date_created BETWEEN @from AND @to OR n.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'po_line_notepad', n.po_no, n.line_no, n.created_by, n.date_created, n.last_maintained_by, n.date_last_modified, NULL
FROM dbo.po_line_notepad n
WHERE n.date_created BETWEEN @from AND @to OR n.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'oe_line_po', o.po_no, NULL, NULL, o.date_created, o.last_maintained_by, o.date_last_modified, NULL
FROM dbo.oe_line_po o
WHERE o.date_created BETWEEN @from AND @to OR o.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'location_x_po_hdr', x.po_no, NULL, NULL, x.date_created, x.last_maintained_by, x.date_last_modified, NULL
FROM dbo.location_x_po_hdr x
WHERE x.date_created BETWEEN @from AND @to OR x.date_last_modified BETWEEN @from AND @to
UNION ALL
SELECT 'po_shipment_tracking', t.po_no, NULL, t.created_by, t.date_created, t.last_maintained_by, t.date_last_modified, NULL
FROM dbo.po_shipment_tracking t
WHERE t.date_created BETWEEN @from AND @to OR t.date_last_modified BETWEEN @from AND @to
ORDER BY 5, 1, 2, 3;

/* ---------- 2a. email_log (sent document email: PO print/email etc.) ---------- */
SELECT e.email_log_uid, e.date_created, e.transaction_type, e.transaction_number,
       e.email_status_cd, e.created_by, e.sender_email_address, e.email_to, e.email_cc, e.subject,
       [is_this_po] = CASE WHEN e.transaction_number = CAST(@po_no AS varchar(40)) THEN 1 ELSE 0 END
FROM dbo.email_log e
WHERE e.date_created BETWEEN @from AND @to
   OR e.date_last_modified BETWEEN @from AND @to
ORDER BY e.date_created;

/* ---------- 2b. alert_queued_mail (alert mail queue - transient, may already be purged) ---------- */
SELECT q.alert_queued_mail_uid, q.date_created, q.date_last_modified, q.row_status_flag,
       q.sender_email_address, q.email_to, q.subject, q.last_maintained_by,
       [mentions_this_po] = CASE WHEN q.subject LIKE '%' + CAST(@po_no AS varchar(20)) + '%'
                                   OR q.email_body LIKE '%' + CAST(@po_no AS varchar(20)) + '%' THEN 1 ELSE 0 END
FROM dbo.alert_queued_mail q
WHERE q.date_created BETWEEN @from AND @to
   OR q.date_last_modified BETWEEN @from AND @to
ORDER BY q.date_created;

/* ---------- 3. audit_trail in the window ---------- */
DECLARE @min_uid int;
SELECT @min_uid = MIN(a.audit_trail_uid)
FROM dbo.audit_trail a WITH (INDEX(KBJS_audit_trail_Cover01))
WHERE a.date_created >= @from;

SELECT a.audit_trail_uid, a.date_created, a.created_by, a.source_area_cd, a.table_changed,
       a.column_changed, a.key1_cd, a.key1_value, a.key2_cd, a.key2_value, a.key3_cd, a.key3_value,
       a.line_no, a.old_value, a.new_value,
       [is_this_po] = CASE WHEN a.key1_value = CAST(@po_no AS varchar(255))
                             OR a.key2_value = CAST(@po_no AS varchar(255))
                             OR a.key3_value = CAST(@po_no AS varchar(255)) THEN 1 ELSE 0 END
FROM dbo.audit_trail a
WHERE a.audit_trail_uid >= @min_uid
  AND a.date_created BETWEEN @from AND @to
ORDER BY a.audit_trail_uid;

/* ---------- 4. scheduled jobs: last run in the window, or any job row touched ---------- */
-- scheduled_job keeps only the LAST run per job, so a recurring job that ran again after
-- 05:21 will not show here; scheduled_job_history on Prod only holds Deactivated rows,
-- but it is included in case Training logs runs.
SELECT j.scheduled_job_uid, j.name, j.type, j.active_flag, j.running_flag, j.last_run_date, j.last_run_status,
       j.last_ping_date, j.scheduler_identifier, j.scheduled_interval_inminutes, j.recurrence_type,
       j.history_level, j.consecutive_failure_counter, j.date_last_modified, j.last_maintained_by
FROM dbo.scheduled_job j
WHERE j.last_run_date BETWEEN @from AND @to
   OR j.last_ping_date BETWEEN @from AND @to
   OR j.date_last_modified BETWEEN @from AND @to
ORDER BY j.last_run_date;

SELECT h.scheduled_job_history_uid, h.scheduled_job_uid, j.name, h.job_run_at_date, h.job_run_status,
       h.date_created, h.created_by
FROM dbo.scheduled_job_history h
LEFT JOIN dbo.scheduled_job j ON j.scheduled_job_uid = h.scheduled_job_uid
WHERE h.job_run_at_date BETWEEN @from AND @to
   OR h.date_created BETWEEN @from AND @to
ORDER BY h.job_run_at_date;
