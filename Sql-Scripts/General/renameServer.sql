

sp_dropserver 'LAPTOP-BTI4LO3V\MSSQLSERVER01'
	go
	sp_addserver 'LAPTOP-BT14LO3V\SQL7','local'
go

sp_helpserver
Select @@SERVERNAME


SELECT SERVERPROPERTY ('InstanceName')
