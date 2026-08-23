-- test to see I need to worry about the counter
use P21Play;

select *
from bin_ud
where bin_id = 'LM2300102S' and location_id = 430

select *
from bin 
where bin_id = 'LM2300102S' and location_id = 430

INSERT INTO "bin_ud" ( "company_id", "location_id", "bin_id", "old_bin" ) VALUES ( '1', 430, 'LM2300102S', 'CK2' )

select *
from bin_ud
where bin_id = 'LM2300102S' and location_id = 430

select *
from bin 
where bin_id = 'LM2300102S' and location_id = 430