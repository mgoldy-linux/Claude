Use P21Play;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AlternativeSourceLocation](
	[id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[SourceLocationCompoosite] [varchar](320) NULL,
	[LocationSelectionPriority1] [int] NOT NULL,
	[LocationSelectionPriority2] [int] NULL,
	[LocationSelectionPriority3] [int] NULL,
	[LocationSelectionPriority4] [int] NULL,
	[LocationSelectionPriority5] [int] NULL,
	[LocationSelectionPriorityElse] [int] NOT NULL,
 CONSTRAINT [AK_SourcLocComposite] UNIQUE NONCLUSTERED 
(
	[SourceLocationCompoosite] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO