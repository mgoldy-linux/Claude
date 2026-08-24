-- Show bad quotes 
EXEC p21_repair_quote_allocation 'DISPLAY'

-- repair incorrect allocation
EXEC p21_repair_quote_allocation

-- CleanUp quotes 
EXEC p21_repair_quote_allocation 'DISPLAY'
