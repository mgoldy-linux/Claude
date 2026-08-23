select * from sysobjects where id in ( 
select parent_obj from sysobjects where name not like 't_%' 
and xtype = 'TR')

select * from p21_view_counter where id = 'note' 
select max(note_id) from oe_hdr_notepad 

select max(note_id) from note_area


exec p21_set_counter @counter_id = 'note', @set_to_table_value = 1 