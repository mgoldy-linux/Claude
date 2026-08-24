select *
from soa_async_request
where start_date > '2023-08-31'

select COUNT (*)[NumberOfRecs]
from audit_trail
where date_created < '2023-09-01'