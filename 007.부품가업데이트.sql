SELECT comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate('')))

select comCode from UF_ErpOperate('')

SELECT comCode FROM dbo.UF_GetGroupComCode('ㄱ121')

select top (1000) itemNo from dbo.e_item where brandCode = 'BZ'

select * from dbo.bz_price_25

select  top (1000) * from dbo.bb_0528

select * from dbo.e_item where itemNo = '76238504227'

select * from dbo.bb_0528 where 부품번호 = '76238504227'

select * from dbo.mb_0601_1

begin tran

UPDATE dbo.mb_0601_1
SET itemNo = REPLACE(RIGHT(itemNo, LEN(itemNo) - 1), '/', '')


rollback tran

commit tran


begin tran

UPDATE dbo.vw_0601
SET itemNo = REPLACE(itemNo, ' ', '')

rollback tran

commit tran


SELECT itemNo, 
       REPLACE(TRANSLATE(itemNo, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '##########################'), '#', '') AS 숫자만
FROM dbo.bb_0601

begin tran

UPDATE dbo.bb_0528
SET F2 = REPLACE(TRANSLATE(F2, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '##########################'), '#', '')


rollback tran

commit tran

SELECT 
    e.itemNo,
    e.centerPrice,
    e.salePrice,
    bb.itemNo,
    bb.centerPrice
FROM dbo.e_item e
INNER JOIN dbo.vag_0828 bb
    ON e.itemNo = bb.itemNo



12108
49107

begin tran

--UPDATE e
--SET e.centerPrice = (SELECT TOP 1 bb.소매가격 FROM dbo.bb_0528 bb WHERE bb.부품번호 = e.itemNo),
--    e.salePrice = (SELECT TOP 1 bb.소매가격 FROM dbo.bb_0528 bb WHERE bb.부품번호 = e.itemNo)
--FROM dbo.e_item e
--WHERE EXISTS (SELECT 1 FROM dbo.bb_0528 bb where bb.부품번호 = e.itemNo);


UPDATE e
SET 
    e.centerPrice = ISNULL(bb.centerPrice,0),
    e.salePrice = ISNULL(bb.centerPrice,0)
FROM dbo.e_item e
JOIN dbo.vag_0828 bb
    ON e.itemNo = bb.itemNo
	where bb.centerPrice > e.centerPrice


rollback tran

commit tran

select @@TRANCOUNT

select *
 from dbo.e_item where itemNo = '51117478844'

 select *
 from dbo.e_pcReq 

 select * from dbo.e_item where itemNo = '9Y0807834ALOK1'

SELECT session_id, start_time, status, command, wait_type, blocking_session_id, text
FROM sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE status = 'running'





 update dbo.e_orderItem set unitPrice = 577000, salePrice = 432750 , sumPrice = 432750 ,centerPrice = 577000,taxPrice = 43275 where orderGroupId = '20250304002'

 rollback tran

 commit tran


 select * from dbo.e_orderItem where orderGroupId = '20250304002'

 select * from dbo.e_saleItem where created > '2025-03-04'
  select * from dbo.e_saleItem where itemId = '6976696' and comCode = 'ㅇ495'

 6976696

 432750

 
 select @@TRANCOUNT

 select * from dbo.e