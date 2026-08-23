select *
from price_library
where price_library_id like 'IPTCI%'
--where price_library_id = 'IPTCI-1000'

  SELECT DISTINCT price_book_x_library.price_library_uid,   
         price_page_x_book.price_book_uid,   
         price_page_x_book.row_status_flag,   
         price_book.description,   
         price_library.description,   
         price_book.price_book_id,   
         price_library.price_library_id,
         price_book.row_status_flag,
         price_library.strategic_price_library_flag,
         price_page.price_page_uid
    FROM   price_book   
INNER JOIN price_page_x_book ON ( price_page_x_book.price_book_uid = price_book.price_book_uid )
INNER JOIN price_page ON ( price_page_x_book.price_page_uid = price_page.price_page_uid )
INNER JOIN price_book_x_library ON ( price_book_x_library.price_book_uid = price_book.price_book_uid )
INNER JOIN price_library ON ( price_book_x_library.price_library_uid = price_library.price_library_uid )
WHERE price_book.description like 'PTI-DIST%'   

select  *
from price_page
where description like '%IPTCI%'
--where product_group_id = 'B4S' and description like '%IPTCI%'

select *
from price_library
where price_library_uid = 42

select *
from price_page 
where description like 'PTI-DIST-A1%'
order by effective_date desc
