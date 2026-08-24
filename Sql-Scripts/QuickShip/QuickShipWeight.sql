use QuickShip;

select *
from BOLLine
where weight > 0

select ProductKey, Description,UnitWeight,StockingUnitOfMeasure
from Product
where ProductKey Like '%-BOX'
order by ProductKey 