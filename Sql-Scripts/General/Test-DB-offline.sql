use P21Sand;

Declare @Online as sql_variant;

set @Online = DATABASEPROPERTYEX('master', 'Status') 

if @Online = 'Online'
begin
Select * from Company
end
else Print N'Play2 is offline.';


