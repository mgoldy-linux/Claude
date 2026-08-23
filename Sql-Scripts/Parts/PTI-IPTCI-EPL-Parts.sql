--use P21Sand;

select item_id[SIMG],item_desc,class_id1[Brand],class_id2,class_id3[Syndication],class_id5[Pack Type],extended_desc
from inv_mast m
where class_id1 in ('PTI','IPTCI') and class_id2 = 'EPL'