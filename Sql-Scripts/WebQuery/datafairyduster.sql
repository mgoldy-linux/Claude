/*	the error message occurs on the web page too
		Msg 7202, Level 11, State 2, Procedure vwStrategic_pricing_invoice_analysis, Line 5 [Batch Start Line 0]
Could not find server 'datafairyduster' in sys.servers. Verify that the correct server name was specified. If necessary, execute the stored procedure sp_addlinkedserver to add the server to sys.servers.
Msg 4413, Level 16, State 1, Line 2
Could not use view or function 'vwStrategic_pricing_invoice_analysis' because of binding errors.
fixed 03/04/22
*/


select *
from vwStrategic_pricing_invoice_analysis