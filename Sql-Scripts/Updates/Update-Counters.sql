--Orders
--exec p21_set_counter @counter_id='WO', @counter_num='1068600'
--Pick tickets
--exec p21_set_counter @counter_id='PICK', @counter_num='2056700'
--Invoices
--exec p21_set_counter @counter_id='INV', @counter_num='3053400'
--Purchases Orders
--exec p21_set_counter @counter_id='PO', @counter_num='4002800'
--inventory Receipts
--exec p21_set_counter @counter_id='RECPT', @counter_num='5003300'
--Vouchers
--exec p21_set_counter @counter_id='VOU', @counter_num='6005000'
--Inventory Adjustments
--exec p21_set_counter @counter_id='ADJ', @counter_num='7002000'
--Transfers
--exec p21_set_counter @counter_id='TRNNO', @counter_num='8001100'
--Production Orders
--exec p21_set_counter @counter_id='PPO', @counter_num='9005200'
/* -- after edi update
Use P21Play;
-- Live 20220921 DXP 33331
-- Live 20220922 Purvis 33344, play 33443
select max(customer_edi_trans_detail_uid)[MaxRecord]
from customer_edi_trans_detail

exec p21_set_counter @counter_id='customer_edi_trans_detail' ,@counter_num = 33443

-- Live 20220921 DXP 9358
-- Live 20220922 Purvis 9371, play 9443
select  max(customer_edi_transaction_uid)[MaxRecord]
from customer_edi_transaction

exec p21_set_counter @counter_id='customer_edi_transaction' ,@counter_num = 9443


Use P21;

select Max(note_id)[MaxRecord]
from oe_hdr_notepad


exec p21_set_counter @counter_id='oe_hdr_notepad' ,@counter_num = 184240

select top 5 *
from  oe_hdr_notepad
order by note_id desc 

-- 10/06/22 P21Play2021.1.4420Local - 274112
-- 10/06/22 P21Play - 278135
-- 10/06/22 P21 - 278404
-- 10/12/22 P21 - 293037
 select max(inv_bin_uid)[MaxRecord]
 from inv_bin

  EXEC p21_set_counter @counter_id='inv_bin' ,@counter_num = 293037

  -- 10/06/22 P21Play2021.1.4420Local - 57787
  -- 10/06/22 P21Play -- 57849
  -- 10/06/22 P21 -- 57856
  select max(bin_uid)[MaxRecord]
  from bin

  EXEC p21_set_counter @counter_id='bin' ,@counter_num = 57856

  */

 -- Use Play2;
 -- P21Play -20220915 81143 after ADMP 81143
 -- P21Play -20220915 81143 after B35 81143
 -- P21 -20220915 81249 after Both, 20220923 Ross error 81281
 /*
   select max(job_price_line_uid)[MaxRecord]
 from job_price_line

  exec p21_set_counter @counter_id='job_price_line',@counter_num = 81281

  -- P21Play -20220915 after ADMP 106664
  -- P21Play -20220915 81143 after B35 107484
  -- P21 -20220915 107484
  select Max(job_price_cust_shipto_uid)[MaxRecord]
  from job_price_customer_shipto

exec p21_set_counter @counter_id='job_price_customer_shipto',@counter_num = 107484


 select *
 from job_price_line
 order by job_price_line_uid desc

  select *
  from job_price_customer_shipto
  order by job_price_cust_shipto_uid desc

  exec p21_set_counter @counter_id='job_price_cust_shipto_csn'

  select Max(bin_ud_uid)[MaxUID]
  from Bin_ud
  /* doesn't work on user define tables
  exec p21_set_counter @counter_id='bin_ud',@counter_num = 144989
  */

  select MAX(inventory_supplier_uid)[MaxUID]
  from dbo.inventory_supplier

  exec p21_set_counter @counter_id='inventory_supplier',@counter_num = 132960
*/
/* not a valid table
select MAX(inventory_supplier_trade_uid)[MaxUID]
from dbo.inventory_supplier_trade

exec p21_set_counter @counter_id='inventory_supplier_trade',@counter_num = 109356
*/
/*
select max(oe_line_schedule_uid)[max]
from dbo.oe_line_schedule

exec p21_set_counter @counter_id='oe_line_schedule',@counter_num = 6881008
*//*
select max(territory_x_customer_uid)[max]
from territory_x_customer
exec p21_set_counter @counter_id='territory_x_customer', @counter_num = 4703
*/
/*
select max(inventory_supplier_x_loc_uid)[max]
from inventory_supplier_x_loc

exec p21_set_counter @counter_id='inventory_supplier_x_loc',@counter_num = 774218424
*/
/*
select max(inv_loc_msp_uid)[max]
from inv_loc_msp

exec p21_set_counter @counter_id='inv_loc_msp',@counter_num = 7776472796
*/
/*
select MAX(inventory_supplier_uid)[max]
from inventory_supplier

exec p21_set_counter @counter_id='inventory_supplier',@counter_num = 194520
*/

/*
-- doesn't exist
exec p21_set_counter @counter_id='inv_loc',@counter_num = 
*/

select max(territory_x_customer_uid)[counter]
from territory_x_customer

exec p21_set_counter @counter_id=territory_x_customer, @counter_num = 8191