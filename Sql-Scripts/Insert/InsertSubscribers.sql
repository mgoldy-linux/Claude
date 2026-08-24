Use Subscribers
CREATE TABLE [dbo].[OrderInfo] (
[SubscriptionID] [int] NOT NULL PRIMARY KEY ,
[Order] [nvarchar] (20) NOT NULL,
[FileType] [bit],
[Format] [nvarchar] (20) NOT NULL ,
) ON [PRIMARY]
GO
INSERT INTO [dbo].[OrderInfo] (SubscriptionID, [Order], FileType, Format)
VALUES ('1', 'so43659', '1', 'IMAGE')
INSERT INTO [dbo].[OrderInfo] (SubscriptionID, [Order], FileType, Format)
VALUES ('2', 'so43664', '1', 'MHTML')
INSERT INTO [dbo].[OrderInfo] (SubscriptionID, [Order], FileType, Format)
VALUES ('3', 'so43668', '1', 'PDF')
INSERT INTO [dbo].[OrderInfo] (SubscriptionID, [Order], FileType, Format)
VALUES ('4', 'so71949', '1', 'Excel')
GO