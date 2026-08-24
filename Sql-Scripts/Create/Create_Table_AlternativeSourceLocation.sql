-- from email RE: Solve  Duplicate Sales Order Line RMB Rule --
/*Eli Schwarz
Software Developer
MindHarbor, Inc.
(phone) 678-740-6223
(text)     678-740-6223*/
use Play2
--use P21Play
go

create table AlternativeSourceLocation
(
id int IDENTITY(1,1) not NULL,
SourceLocationCompoosite nvarchar(max),
LocationSelectionPriority1 int not null,
LocationSelectionPriority2 int null,
LocationSelectionPriority3 int null,
LocationSelectionPriority4 int null,
LocationSelectionPriority5 int null,
LocationSelectionPriorityElse int not null,
)

grant insert,select, update, delete on alternativeSourceLocation to [pxxiuser]
grant insert,select, update, delete on alternativeSourceLocation to [p21_application_role]