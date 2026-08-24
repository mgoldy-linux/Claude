--use P21;
use P21Play;

Select *
from dbo.inv_xref
where their_item_id = '35GD84'

update dbo.inv_xref
set their_item_id = '36GD84'
where inv_xref_uid = 943311 and customer_id = 54533

Select *
from dbo.inv_xref
where their_item_id in ('35GD84', '36GD84')