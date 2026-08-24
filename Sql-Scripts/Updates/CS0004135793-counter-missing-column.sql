Select *
from vendor_edi_transaction_detail


exec p21_set_counter @counter_id='vendor_edi_transaction_detail'

select * from p21_view_counter 
select max(vendor_edi_trans_detail_uid) from vendor_edi_transaction_detail 

/*
The counter table has no column specified for the table (id) and the uid is an abbreviated version of the table name, which is why they get the error. 

The script below will add the column name and remove the error they are receiving 
update counter set column_name = 'vendor_edi_trans_detail_uid' where id = 'vendor_edi_transaction_detail' 

At that point they can run 
use @set_to_table_value = 1 
this will set the value of the counter to match the table. 

You can still set the value manually, but the "set to table" is safer as it will not allow you to go backwards.
*/

select *
from counter
 where id = 'vendor_edi_transaction_detail'