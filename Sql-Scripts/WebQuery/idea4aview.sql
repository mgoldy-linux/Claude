use WQMetaData;

select top 10  rt.item_id,m.item_id[simg],rt.*
from vwSalesAnalysis rt
join P21.dbo.inv_mast m
on rt.inv_mast_uid = m.inv_mast_uid