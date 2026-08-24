select trg.name as trigger_name,
    schema_name(tab.schema_id) + '.' + tab.name as [table],
    case when is_instead_of_trigger = 1 then 'Instead of'
        else 'After' end as [activation],
    (case when objectproperty(trg.object_id, 'ExecIsUpdateTrigger') = 1
                then 'Update ' else '' end 
    + case when objectproperty(trg.object_id, 'ExecIsDeleteTrigger') = 1
                then 'Delete ' else '' end
    + case when objectproperty(trg.object_id, 'ExecIsInsertTrigger') = 1
                then 'Insert' else '' end
    ) as [event],
    case when trg.parent_class = 1 then 'Table trigger'
        when trg.parent_class = 0 then 'Database trigger' 
    end [class], 
    case when trg.[type] = 'TA' then 'Assembly (CLR) trigger'
        when trg.[type] = 'TR' then 'SQL trigger' 
        else '' end as [type],
    case when is_disabled = 1 then 'Disabled'
        else 'Active' end as [status],
    object_definition(trg.object_id) as [definition]
from sys.triggers trg
    left join sys.objects tab
        on trg.parent_id = tab.object_id
order by trg.name;