-- for it audit - send to Jim
select id, name, location_name, role, email_address
from dbo.users u
join dbo.roles r
on u.role_uid = r.role_uid
left join location l
on u.default_location_id = l.location_id
where u.delete_flag = 'N'


select id[ID],u.users_uid[UID],u.name[Name],r.role[Role],
case 
	when u.default_branch = 100 then 'PTI'
	when u.default_branch = 200 then 'LMS'
	when u.default_branch = 300 then 'IPTCI'
	when u.default_branch = 400 then 'BL'
end[Branch],
case
	when default_location_id = 100 then 'NC'
	when default_location_id = 150 then 'CA DJ Reps'
	when default_location_id = 200 then 'CO'
	when default_location_id = 300 then 'MN'
	when default_location_id = 350 then 'OR Allied Components'
	when default_location_id = 400 then 'Long Island'
	when default_location_id = 410 then 'NY'
	when default_location_id = 420 then 'CA'
	when default_location_id = 430 then 'IL'
	when default_location_id = 440 then 'GA'
	when default_location_id = 450 then 'TX'
	when default_location_id = 460 then 'ABT-IL'
	when default_location_id = 470 then 'OH'
End[Location],u.designer_rights[Designer],email_address
from roles r
join users u
on r.role_uid = u.role_uid
where r.delete_flag = 'N' and u.delete_flag = 'N' and default_branch = 400
order by Role

--Inside sales like Lauren Stallone
select id[ID],u.name[Name],r.role[Role],
case 
	when u.default_branch = 100 then 'PTI'
	when u.default_branch = 200 then 'LMS'
	when u.default_branch = 300 then 'IPTCI'
	when u.default_branch = 400 then 'BL'
end[Branch],
case
	when default_location_id = 410 then 'NY'
	when default_location_id = 420 then 'CA'
	when default_location_id = 430 then 'IL'
	when default_location_id = 440 then 'GA'
	when default_location_id = 450 then 'TX'
	when default_location_id = 460 then 'ABT-IL'
	when default_location_id = 470 then 'OH'
End[Location]
from roles r
join users u
on r.role_uid = u.role_uid
where users_uid in (154,143,117,141)

--Warehouse like George Lyktey
select id[ID],u.name[Name],r.role[Role],
case 
	when u.default_branch = 100 then 'PTI'
	when u.default_branch = 200 then 'LMS'
	when u.default_branch = 300 then 'IPTCI'
	when u.default_branch = 400 then 'BL'
end[Branch],
case
	when default_location_id = 410 then 'NY'
	when default_location_id = 420 then 'CA'
	when default_location_id = 430 then 'IL'
	when default_location_id = 440 then 'GA'
	when default_location_id = 450 then 'TX'
	when default_location_id = 460 then 'ABT-IL'
	when default_location_id = 470 then 'OH'
End[Location]
from roles r
join users u
on r.role_uid = u.role_uid
where users_uid in (125,144,121,169,194,157,126,184,177)


-- Inside Sales CLT
select id[ID],u.name[Name],r.role[Role],
case 
	when u.default_branch = 100 then 'PTI'
	when u.default_branch = 200 then 'LMS'
	when u.default_branch = 300 then 'IPTCI'
	when u.default_branch = 400 then 'BL'
end[Branch],
case
	when default_location_id = 100 then 'NC'
	when default_location_id = 410 then 'NY'
	when default_location_id = 420 then 'CA'
	when default_location_id = 430 then 'IL'
	when default_location_id = 440 then 'GA'
	when default_location_id = 450 then 'TX'
	when default_location_id = 460 then 'ABT-IL'
	when default_location_id = 470 then 'OH'
End[Location]
from roles r
join users u
on r.role_uid = u.role_uid
where id in ('BWOLF','CARTER','DANITA.MYRICKS','DEBRAS','ISALES','MBRENNING','MILLIDGE','RKIPP','RTAYLOR','SBRASWELL')


select *
from users
where default_branch = 100

select distinct default_branch
from dbo.users