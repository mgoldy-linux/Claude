select * from message_log
where message_date > '2022-07-19' and user_id = 'mgoldyn' --and message_no = 3001
order by message_date desc

select *
from note_area
order by date_created desc

select *
from messages
where message_no = 3001

select distinct l.message_no, message_title,m.user_text,m.technical_text, icon, button, l.msg_severity_level, window_flag,use_long_message
from message_log l
join messages m
on l.message_no = m.message_no