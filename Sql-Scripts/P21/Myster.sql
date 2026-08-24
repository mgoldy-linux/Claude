/*
update company set company_name = left('*** PLAY 20200829 *** ' + company.company_name + ' *** PLAY 20200829 ***', 40)
update location set location_name = left('*** PLAY *** ' + location.location_name + ' *** PLAY ***', 255)
update branch set branch_description = left('*** PLAY *** ' + branch_description + ' *** PLAY ***', 40) 
*/

select *
from company