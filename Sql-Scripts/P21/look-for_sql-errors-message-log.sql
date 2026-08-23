select top 5 *
from message_log
where user_text like '%SQL%'
order by message_date desc