 -- test update with join
 
 use P21Play;
 
 select id, first_name,last_name, email_address,class_5id
 from contacts
 where address_id = 14593

 Update contacts 
 Set class_5id = 'WEB'
 from contacts co
 join customer c
 on co.address_id = c.customer_id and c.default_branch_id = 300 and c.web_enabled_flag = 'Y'
 where email_address = 'tom.roberson@motion-ind.com' and first_name NOT IN ('A/P','AP','Primary','Orders','.','Order','Customer','M. R.','Accounts','A','B','J','L','R') and credit_status != 'INACTIVE'and last_name NOT IN ('.','LOUDENSL...','F','T','*',',')

 select id, first_name,last_name, email_address,class_5id
 from contacts
 where address_id = 14593