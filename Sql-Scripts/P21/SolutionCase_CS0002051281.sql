---case CS0002051281

exec p21_repair_sales_orders /* this gave an error - Msg 245, Level 16, State 1, Line 2
Conversion failed when converting the varchar value 'Cancelled schedule lines have incorrect disposition' to data type int.*/

exec p21_exec_metric_invoice_rebuild
exec p21_exec_metric_sales_rebuild  -- this one made a difference