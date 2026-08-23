Use P21Local;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

Create Table PostalCodes(
Pcid int not null identity(1,1),
PostalCode varchar (2) not null,
StaProvName varchar (30) not null,
date_added datetime not null,
date_last_modifiied datetime not null,
last_maintained_by VARCHAR(30) not null,
CONSTRAINT PK__PostalCodes  PRIMARY KEY(Pcid)
)