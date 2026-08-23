ALTER AUTHORIZATION ON DATABASE::P21Play TO SA
ALTER DATABASE P21Play  SET TRUSTWORTHY ON;

-- other qry
select * from p21_view_manifest_pick_ticket_data where [shipment.releaseidentification] = 176166