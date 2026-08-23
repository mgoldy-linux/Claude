Select top 100 *
from RESTSettings
--where Type = 'Audit'
order by ModifyDate desc

Select distinct Type
from ApplicationLog

SELECT miscellane0_.[MiscellaneousCodeId] as column1_88_0_, miscellane0_.[CompanyId] as column2_88_0_, miscellane0_.[Name] as column3_88_0_, miscellane0_.[Value] as column4_88_0_, miscellane0_.[AdditionalInfo] as column5_88_0_, miscellane0_.[DeactivateDate] as column6_88_0_, miscellane0_.[CreateDate] as column7_88_0_, miscellane0_.[CreatedBy] as column8_88_0_, miscellane0_.[ModifyDate] as column9_88_0_, miscellane0_.[ModifiedBy] as column10_88_0_, miscellane0_.[ParentId] as column11_88_0_ FROM [dbo].[MiscellaneousCode] miscellane0_ WHERE miscellane0_.[MiscellaneousCodeId]= ',N'@p0 uniqueidentifier',@p0='6C01CBA0-5430-4782-8DAA-DCA72632964B'