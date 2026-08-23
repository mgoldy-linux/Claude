/*
	per email from george
	Company Name	address.name
	Contact Name	contacts.first_name, contacts.last_name
	Title			contacts.title
	Phone Number	address.central_phone_number
	E-mail address	contacts.email_address
	*** coludn't get formating of phone number to work				
*/


	select distinct c.address_name,(c.first_name + ' ' + c.last_name)[Contact Name],c.title,replace(replace(replace(replace(replace(replace(a.central_phone_number,'/',''),'-',''),'(',''),')',''),' ',''),'+','')[Phone Number],c.email_address
	from contacts c
	join address a
	on c.address_id = a.id
	where (c.first_name not in ('Primary','A/P','AP','Accounts','Acounts','Order','PTI','*','..','.','940 Industrial','941 Industrial','942 Industrial') and c.last_name not in ('A','*','.','...','Industrial','..','B'))
	and (a.central_phone_number is not NUll or c.email_address is not NULL) and address_name not Like '(%'


