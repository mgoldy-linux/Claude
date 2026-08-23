select distinct invoice_line_type
from A_Invoice_Line_with_Hdr_Data_Olivia

--invoice line types
select code_no,code_description
from code_p21
where code_no in (928,929,981,982)