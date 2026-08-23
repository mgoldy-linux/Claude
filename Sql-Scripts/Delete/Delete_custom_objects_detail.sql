--use P21Dev3;
use Play2;

select *
from dbo.custom_objects_detail
where custom_objects_detail_uid in (38156,38157,38158,38159)

delete 
from dbo.custom_objects_detail
where custom_objects_detail_uid in (38156,38157,38158,38159)

select *
from dbo.custom_objects_detail
where custom_objects_detail_uid in (38156,38157,38158,38159)

