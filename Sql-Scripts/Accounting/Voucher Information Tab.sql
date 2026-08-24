--Voucher Information Tab on AP Drill Down By Vendor: [untitled]
  SELECT vendor.vendor_id,   
         vendor.company_id,   
         ' ' voucher_class,   
         address.name,   
         company.company_name,   
         vendor.date_created,   
         vendor.date_last_modified,   
         vendor.last_maintained_by,
         'B' cc_approved,  
         'N' cc_show_all,
         ' ' cc_include_disputed_vouchers
         ,'N' use_archive_data
         , 'N' show_foreign_amts
         ,current_timestamp last_paid_date
         ,CURRENT_TIMESTAMP 'beg_invoice_date'
         ,CURRENT_TIMESTAMP 'end_invoice_date'
         ,vendor.currency_id
    FROM vendor

      INNER JOIN address
         ON address.id = 16167
      INNER JOIN company
         ON vendor.company_id = 1