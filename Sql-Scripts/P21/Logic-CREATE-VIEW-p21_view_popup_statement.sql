SELECT  ISNULL(a.popup_statement_uid, b.popup_statement_uid) as [popup_statement_uid], ISNULL(a.popup_detail_uid, b.popup_detail_uid) as [popup_detail_uid], 
CASE
WHEN isnull(a.popup_statement_uid_parent, 0) = 0 THEN a.[columns]   
 ELSE 
  case Upper(isnull(a.override_columns, ''))
	when 'R' Then a.[columns]
	when 'A' Then Isnull(b.[columns],'')+' '+Isnull(a.[columns],'')
	when '' Then b.[columns]
	end      
END AS [columns],
CASE 
WHEN isnull(a.popup_statement_uid_parent, 0) = 0 THEN a.from_join
ELSE
	case Upper(isnull(a.override_from_join, '') )
	when 'R' Then a.from_join
	when 'A' Then Isnull(b.from_join,'')+' '+Isnull(a.from_join,'')
	when '' Then b.from_join
	end
END AS [from_join],
CASE 
WHEN isnull(a.popup_statement_uid_parent, 0) = 0 THEN a.[where]
ELSE
	case Upper(isnull(a.override_where, '') )
	when 'R' Then a.[where]
	when 'A' Then Isnull(b.[where],'')+' '+Isnull(a.[where],'') 
	when '' Then b.[where]
	end
END AS [where],
CASE 
WHEN isnull(a.popup_statement_uid_parent, 0) = 0 THEN a.order_by              
ELSE                  
	case Upper(isnull(a.override_order_by, '') )
	when 'R' Then a.order_by
	when 'A' Then Isnull(b.order_by, '') + ' ' + Isnull(a.order_by, '')
	when '' Then b.order_by
	end
END AS order_by,
CASE WHEN isnull(a.popup_statement_uid_parent, 0) = 0 THEN a.group_by              ELSE                  case Upper(isnull(a.override_group_by, '') )                      when 'R' Then a.group_by                      when 'A' Then Isnull(b.group_by,'')+' '+Isnull(a.group_by,'')                      when '' Then b.group_by                  end      END AS group_by,      CASE WHEN ISNULL(a.popup_statement_uid_parent, 0) = 0           THEN a.[option]           ELSE CASE WHEN (ISNULL(a.override_option, 0) = 1)              THEN a.[option]              ELSE b.[option]           END      END AS [option],      ISNULL(a.date_created, b.date_created) as [date_created],      ISNULL(a.created_by, b.created_by) as created_by,      ISNULL(a.date_last_modified, b.date_last_modified) as date_last_modified,      ISNULL(a.last_maintained_by, b.last_maintained_by) as last_maintained_by,      isnull(a.[override_columns], b.[override_columns] ) AS [override_columns],      isnull(a.[override_from_join], b.[override_from_join] ) AS [override_from_join]      ,isnull(a.[override_where], b.[override_where] ) AS [override_where]      ,isnull(a.[override_group_by], b.[override_group_by] ) AS [override_group_by]      ,isnull(a.[popup_statement_uid_parent], b.[popup_statement_uid_parent]) AS [popup_statement_uid_parent]      ,isnull(a.[override_order_by], b.[override_order_by] ) AS [override_order_by]  
	FROM dbo.popup_statement AS a WITH (NOLOCK)  
	LEFT OUTER JOIN dbo.p21_view_popup_statement_second AS b WITH (NOLOCK)  
	ON isnull(a.popup_statement_uid_parent, 0) <> 0 and a.popup_statement_uid_parent = b.popup_statement_uid    
	where a.popup_detail_uid = 4865