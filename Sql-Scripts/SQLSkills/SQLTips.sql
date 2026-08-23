-- dbid = 1 and look at program_name

select * from sys.sysprocesses
where dbid = 1

select * from sys.procedures where name like '%Process%'

exec p21_fn_getconnectioncountbylicensetype P21Local,0

Create Table #temp(
rec_id int IDENTIITY (1,1),
table_name varchar(128),
nbr_of_rows int,
data_space decimal(15,2)
index_space decimal(15,2)
total_size decimal(15,2)