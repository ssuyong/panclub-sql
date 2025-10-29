select * from dbo.e_user where userName ='유영규'
select * from dbo.e_user where userName ='홍동우'

begin tran

INSERT INTO [dbo].[e_user]
           ([comCode]
           ,[userId]
           ,[pwdEnc]
           ,[userName]
           ,[divisionCode]
           ,[userTypeCode]
           ,[autoLoginSession]
           ,[autoLoginSessionLimit]
           ,[validYN]
           ,[created]
           ,[modified]
           ,[permissionTemplateIdx]
           ,[permissionModified])
 
         select
		 [comCode]
           ,'ssuyong'
           ,[pwdEnc]
           ,'송수용'
           ,[divisionCode]
           ,[userTypeCode]
           ,[autoLoginSession]
           ,[autoLoginSessionLimit]
           ,[validYN]
           ,GETDATE()
           ,GETDATE()
           ,[permissionTemplateIdx]
           ,[permissionModified]
		   from dbo.e_user where userName ='유영규'

rollback tran

commit tran

/*
select * from dbo.e_user
*/