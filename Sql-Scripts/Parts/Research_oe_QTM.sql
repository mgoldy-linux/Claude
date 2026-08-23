select assembly
from inv_mast
where inv_mast_uid = 23489

exec p21_get_qty_to_make 'SR2-FB4-100MMTLNE', 17860, 100, 0

--23489          6           1

select top 6*
from assembly_hdr
where inv_mast_uid = 23489


/*
26810
24241
23548
17860
40068
6513
*/

select distinct i.inv_mast_uid
	from inv_mast i
	join assembly_line a
	on i.inv_mast_uid = a.inv_mast_uid
	where i.class_id2 = 'EPL' and i.class_id1 = 'PTI' and a.other_charge_item = 'N'and a.delete_flag = 'N' 
