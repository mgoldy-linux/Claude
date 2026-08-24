use P21Sand;

select *
from alert_message
where alert_message_uid = 7

update dbo.alert_message
set line_item = REPLACE(CONVERT(VARCHAR(MAX),line_item),'<item_description>','<item_description> - <inventory_class1_id>')
where alert_message_uid = 7

select line_item
from alert_message
where alert_message_uid = 7