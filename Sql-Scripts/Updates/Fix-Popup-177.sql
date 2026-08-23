use P21train;

Select *
from popup_detail
where created_by = 'RSNEYD' and popup_desc like 'Updated pop-up%'

use P21;

Select *
from popup_detail
where created_by = 'RSNEYD' and popup_desc like 'Updated pop-up%'


use P21train;
Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid in (4857,177)

use P21;
Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid in (4857,177)

update dbo.popup_statement
set order_by = 'INV_MAST.ITEM_ID'
where popup_detail_uid = 177

Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid in (4857,177)