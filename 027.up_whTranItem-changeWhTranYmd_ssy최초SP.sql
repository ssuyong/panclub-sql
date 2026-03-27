USE [panErp]
GO
/****** Object:  StoredProcedure [dbo].[up_rlAdd]    Script Date: 2026-03-18 오후 5:35:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[up_whTranItem]
/***************************************************************
설명 : 매입거래일 변경

작성 : 2026.03.20  -  신규

***************************************************************/
	 @i__workingType varchar(20) = ''
	,@i__logComCode varchar(20) = ''    --로그인한 회사코드
	,@i__logUserId varchar(30) = ''  -- 로그인한 사용자

	,@i__saleNo varchar(50) = ''	--판매번호	
	,@i__regYmd varchar(50) = ''    --변경일
	,@i__puComCode varchar(50) = '' --매입처

	,@i__saleRate numeric(5,2) = 0.0 --판매율
	,@i__itemNo varchar(30) = '' --품번
	,@i__centerPrice money = 0 --센터가
AS

SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--로그--------------------------
INSERT INTO panErp.dbo._SPLOG( sp,params)
	VALUES('panErp.dbo.up_whTranItem', 
	'@i__workingType='''+ISNULL(@i__workingType,'')+''',
	 @i__logUserId='''+ISNULL(@i__logUserId,'')+''',
	 @i__saleNo='''+cast(ISNULL(@i__saleNo,'') as varchar(100))+''',
	 @i__regYmd='''+cast(ISNULL(@i__regYmd,'') as varchar(100))+''',
	 @i__puComCode='''+cast(ISNULL(@i__puComCode,'') as varchar(100))+''',
	 @i__saleRate='''+cast(ISNULL(@i__saleRate,'') as varchar(100))+''',
	 @i__itemNo='''+cast(ISNULL(@i__itemNo,'') as varchar(100))+''',
	 @i__centerPrice='''+cast(ISNULL(@i__centerPrice,'') as varchar(100))+'''
	 '
   )
---------------------------------
IF ISNULL(@i__saleRate, 0) = 0 	SET @i__saleRate = 1

IF @i__workingType = 'CHANGE_YMD' 
	GOTO CHANGE_YMD_PROC --매입거래일 변경 
IF @i__workingType = 'CHANGE_PRICE' 
	GOTO CHANGE_PRICE_PROC --가격 변경

RETURN
/***************************************************************************************************/
CHANGE_YMD_PROC:

--매입일 변경
BEGIN TRAN

UPDATE dbo.e_saleItem 
SET
	regYmd = @i__regYmd,
	saleNo = (
		select cast(cast(isnull(max(saleNo),REPLACE(@i__regYmd, '-', '') + '000') as bigint)+1 as varchar) 
        from e_saleItem 
		where comCode = @i__puComCode
		and regYmd = @i__regYmd
	)
WHERE comCode = @i__puComCode
  and saleNo = @i__saleNo

IF @@ROWCOUNT =0 OR @@ERROR <> 0
BEGIN
	ROLLBACK TRAN
	SELECT 'Err' db_resultCode , '실패:DB Update 오류' db_resultMsg
	RETURN
END 

COMMIT TRAN

--결과값 조회
SELECT 'OK' db_resultCode , '성공' db_resultMsg, @i__saleNo saleNo

RETURN
/***************************************************************************************************/
CHANGE_PRICE_PROC:

--가격 변경
BEGIN TRAN

UPDATE dbo.e_item
SET centerPrice = @i__centerPrice,
    salePrice = @i__centerPrice
WHERE itemNo = @i__itemNo
  and centerPrice != @i__centerPrice


UPDATE si
SET
	si.saleRate = @i__saleRate,
	si.centerPrice = ei.centerPrice,
	si.costPrice = ei.centerPrice * @i__saleRate,
	si.saleUnitPrice = ei.centerPrice * @i__saleRate
FROM dbo.e_saleItem si
JOIN dbo.e_item ei on ei.itemId = si.itemId
WHERE si.comCode = @i__puComCode
  and si.saleNo = @i__saleNo

IF @@ROWCOUNT =0 OR @@ERROR <> 0
BEGIN
	ROLLBACK TRAN
	SELECT 'Err' db_resultCode , '실패:DB Update 오류' db_resultMsg
	RETURN
END 

COMMIT TRAN

--결과값 조회
SELECT 'OK' db_resultCode , '성공' db_resultMsg, @i__saleNo saleNo

RETURN
/***************************************************************************************************/
