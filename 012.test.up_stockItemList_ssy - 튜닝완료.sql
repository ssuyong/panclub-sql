USE [panErp]
GO
/****** Object:  StoredProcedure [dbo].[up_stockItemList_ssy]    Script Date: 2025-09-25 오후 3:39:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[up_stockItemList_ssy]
/***************************************************************
설명 : 재고 목록 : up_stockList 대체

ㅇ499	아우토서울(rackCode: 578)
ㅂ022	VAG AUTOPARTS CO.LTD(644)
ㅇ496	이지통상(74-738	)
ㅇ002	(주)엠케이파츠(950)
ㅇ479	(주) 인터카스코리아(794)
ㅂ184   보스카통상(1326)
       
--ssy운영:
SET STATISTICS TIME, IO ON;--48초
exec 
panErp.dbo.up_stockItemList	@i__workingType='SALE_LIST',    
@i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',    
@i__eYmd1='',    @i__sYmd2='',    @i__eYmd2='',        @i__storCode='',    
@i__itemId=0,    @i__itemNo='',    @i__itemName='',    @i__makerCode='',    
@i__classCode='',    @i__storName='',      @i__bulkSrchType='itemNo',    
@i__itemBulk='07119904448힣4M0816421D힣01292317853힣07147201307힣11127582245힣07147443710',   
@i__checkType='ALL',    @i__outStorCode='',    @i__storageCode='',    
@i__noRealYN='N',    @i__qtyZeroYN='N',    @i__consignCustCode='',      
@i__logComCode='ㄱ121',    @i__logUserId='ssuyong'
SET STATISTICS TIME, IO OFF;

--ssy개발:
UPDATE STATISTICS dbo.e_item IX_e_item_itemNo WITH FULLSCAN;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

SET STATISTICS TIME, IO ON;--2초
exec 
panErp.dbo.up_stockItemList_test	@i__workingType='SALE_LIST',    
@i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',    
@i__eYmd1='',    @i__sYmd2='',    @i__eYmd2='',        @i__storCode='',    
@i__itemId=0,    @i__itemNo='',    @i__itemName='',    @i__makerCode='',    
@i__classCode='',    @i__storName='',      @i__bulkSrchType='itemNo',    
@i__itemBulk='07119904448힣4M0816421D힣01292317853힣07147201307힣11127582245힣07147443710',   
@i__checkType='ALL',    @i__outStorCode='',    @i__storageCode='',    
@i__noRealYN='N',    @i__qtyZeroYN='N',    @i__consignCustCode='',      
@i__logComCode='ㄱ121',    @i__logUserId='ssuyong'
SET STATISTICS TIME, IO OFF

***************************************************************/
	@i__workingType varchar(20) = '',
	@i__page int = 1,       --페이지 : 몇번째 다음 부터
	@i__qty int = 10,       --레코드 수 : 몇개 출력
	@i__orderBy varchar(20) = '',
	@i__ymdIgnoreYN varchar(1) = 'N',
	
	@i__sYmd1 varchar(10) = '',
	@i__eYmd1 varchar(10) = '',
	@i__sYmd2 varchar(10) = '',
	@i__eYmd2 varchar(10) = ''

	,@i__logComCode varchar(20) = ''    --로그인한 회사코드
	,@i__logUserId varchar(20) = ''    --로그인한 사용자아이디

	,@i__storCode varchar(20) = ''
	,@i__itemId bigint = 0   --
    ,@i__itemNo varchar(50) = ''   
	,@i__itemName varchar(100) = ''
	,@i__makerCode varchar(100) = ''
	,@i__classCode varchar(10) = '' --클래스코드
	,@i__storName varchar(100) = '' 

	,@i__bulkSrchType varchar(20)=''
	,@i__itemBulk varchar(MAX) = ''
	,@i__checkType varchar(100) = ''
	,@i__outStorCode varchar(50) = ''
	,@i__storageCode varchar(max) = ''
	,@i__noRealYN varchar(1) = 'N'
	,@i__qtyZeroYN varchar(1) = 'N'
	,@i__consignCustCode varchar(20) = ''
--WITH RECOMPILE --ssy 1
AS

SET ARITHABORT ON;
SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--로그--------------------------
INSERT INTO panErp.dbo._SPLOG( sp,params)
	VALUES('panErp.dbo.up_stockItemList_ssy', 
	'@i__workingType='''+ISNULL(@i__workingType,'')+''',
	 @i__page='+cast(ISNULL(@i__page,0) as varchar(100))+',
	 @i__qty='+cast(ISNULL(@i__qty,0) as varchar(100))+',	 
	 @i__orderBy='''+ISNULL(@i__orderBy,'')+''',
	 @i__sYmd1='''+ISNULL(@i__sYmd1,'')+''',
	 @i__eYmd1='''+ISNULL(@i__eYmd1,'')+''',
	 @i__sYmd2='''+ISNULL(@i__sYmd2,'')+''',
	 @i__eYmd2='''+ISNULL(@i__eYmd2,'')+''',
	 
	 @i__storCode='''+cast(ISNULL(@i__storCode,'') as varchar(100))+''',
	 @i__itemId='+cast(ISNULL(@i__itemId,'0') as varchar(100))+',
	 @i__itemNo='''+cast(ISNULL(@i__itemNo,'') as varchar(100))+''',
	 @i__itemName='''+cast(ISNULL(@i__itemName,'') as varchar(100))+''',
	 @i__makerCode='''+cast(ISNULL(@i__makerCode,'') as varchar(100))+''',
	 @i__classCode='''+cast(ISNULL(@i__classCode,'') as varchar(100))+''',
	 @i__storName='''+cast(ISNULL(@i__storName,'') as varchar(100))+''',

	 @i__bulkSrchType='''+cast(ISNULL(@i__bulkSrchType,'') as varchar(100))+''',
	 @i__itemBulk='''+cast(ISNULL(@i__itemBulk,'') as varchar(100))+''',
	 @i__checkType='''+cast(ISNULL(@i__checkType,'') as varchar(100))+''',
	 @i__outStorCode='''+cast(ISNULL(@i__outStorCode,'') as varchar(50))+''',
	 @i__storageCode='''+cast(ISNULL(@i__storageCode,'') as varchar(max))+''',
	 @i__noRealYN='''+cast(ISNULL(@i__noRealYN,'') as varchar(50))+''',
	 @i__qtyZeroYN='''+cast(ISNULL(@i__qtyZeroYN,'') as varchar(50))+''',
	 @i__consignCustCode='''+cast(ISNULL(@i__consignCustCode,'') as varchar(50))+''',

	 @i__logComCode='''+cast(ISNULL(@i__logComCode,'') as varchar(100))+''',
	 @i__logUserId='''+cast(ISNULL(@i__logUserId,'') as varchar(100))+''''
)
---------------------------------

--DECLARE @subPage INT
--IF @i__page = 0 
--	SET @subPage = 1
--ELSE
--	SET @subPage = (@i__page - 1) * @i__qty
DECLARE @n__4carComCode varchar(10) = 'ㄱ121' -- ㄱ000이던 부분을 변수로 대체
--DECLARE @n__4carComCode varchar(10) = 'ㄱ000' -- ㄱ000이던 부분을 변수로 대체

/*
-- 개발서버거나 / 로그인한 계정이 팬오토거나 제로무역의 시스템관리자인 경우만 해당 컴코드의 환경설정에 있는 위탁판매업체 코드로 셋팅, 
만약 조건은 맞는데 코드가 NULL이면 ㄱ121
IF (@@SERVERNAME = 'WIN-0KVI4NMDLFI' OR EXISTS (select 1 from dbo.e_user
										 where @i__logComCode = comCode AND @i__logUserId = userId AND 
										 ('ㄱ000' = comCode OR 'ㅈ004' = comCode) AND '시스템관리자' = userTypeCode ))
BEGIN
	SET @n__4carComCode = 'ㄱ121' -- 셀렉트 결과가 없을경우를 위해서 ㄱ121로 변경
	SELECT @n__4carComCode = ISNULL(IIF(stockConsignCustCode='','ㄱ121',stockConsignCustCode) , 'ㄱ121')
	FROM dbo.e_config 
	WHERE @i__logComCode = comCode
END
*/
SET @i__eYmd1  = ISNULL(@i__eYmd1,'')
SET @i__sYmd1  = ISNULL(@i__sYmd1,'')
SET @i__sYmd2  = ISNULL(@i__sYmd2,'')
SET @i__eYmd2  = ISNULL(@i__eYmd2,'')
SET @i__logComCode  = ISNULL(@i__logComCode,'')
SET @i__logUserId  = ISNULL(@i__logUserId,'')
SET @i__storCode  = ISNULL(@i__storCode,'')
SET @i__itemId  = ISNULL(@i__itemId,0)
SET @i__itemNo  = ISNULL(@i__itemNo,'')
SET @i__itemName  = ISNULL(@i__itemName,'')
SET @i__makerCode  = ISNULL(@i__makerCode,'')
SET @i__classCode  = ISNULL(@i__classCode,'')
SET @i__storName  = ISNULL(@i__storName,'')
SET @i__bulkSrchType = ISNULL(@i__bulkSrchType,'')
SET @i__itemBulk  = ISNULL(@i__itemBulk,'')
SET @i__checkType  = ISNULL(@i__checkType,'')
SET @i__outStorCode  = ISNULL(@i__outStorCode,'')
SET @i__storageCode  = ISNULL(@i__storageCode,'')
SET @i__noRealYN  = ISNULL(@i__noRealYN,'')
SET @i__qtyZeroYN  = ISNULL(@i__qtyZeroYN,'')
SET @i__consignCustCode  = ISNULL(@i__consignCustCode,'')


DECLARE @n__sYmd1 varchar(10),  @n__eYmd1 varchar(10)
SET @n__sYmd1 = @i__sYmd1
SET @n__eYmd1 = @i__eYmd1

IF @i__sYmd1 <> ''
	SET @n__sYmd1 = REPLACE(@i__sYmd1,'-','')
IF @i__eYmd1 <> ''
	SET @n__eYmd1 = REPLACE(@i__eYmd1,'-','')

SET	@i__itemId = ISNULL(@i__itemId, 0) 

DECLARE @sql nvarchar(max), @sqlS nvarchar(max) = N'' , @sqlF nvarchar(max) = N'' 
      , @sqlW nvarchar(max) = N''  , @sql1 nvarchar(max) = N''  , @sql2 nvarchar(max) = N''
SET @sql = N''

--ERP 운영업체. 2024.10.16 hsg
DECLARE @ErpOperateComCode varchar(50) =  ''
SELECT @ErpOperateComCode = comCode from dbo.UF_ErpOperate('') -- 'ㄱ000'

--ssy SELECT comCode from dbo.UF_ErpOperate('')

DECLARE @n__item_bulk_origin varchar(4000) = ''
SET @n__item_bulk_origin = @i__itemBulk

 --20210305 에 위의 것에서 변경. 
 --벌크조회가 품명이 빠지고 품번과 브랜드품번이 추가되서 모든 조건일때 이걸타는 걸로 변경
IF @i__bulkSrchType <> '' AND @i__itemBulk <> '' 
BEGIN

    SET @i__itemBulk= Replace (@i__itemBulk, char(13)+char(10), '')   --엔터(new line+carrage return)
	SET @i__itemBulk= Replace (@i__itemBulk, char(13), '')   --new line
	SET @i__itemBulk= Replace (@i__itemBulk, char(10), '')   --carrage return
    SET @i__itemBulk= Replace (@i__itemBulk, char(9), '')              --탭
	SET @i__itemBulk= Replace (@i__itemBulk, '-', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '.', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '/', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '\', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '|', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '!', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '?', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '@', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '#', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '$', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '%', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '^', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '&', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '*', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '(', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, ')', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '+', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '_', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '=', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '~', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '`', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, ';', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, ':', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '[', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, ']', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '{', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, '}', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, ' ', '') 
	SET @i__itemBulk= Replace (@i__itemBulk, ',', '') 

	--SET @i__item_bulk = Replace(@i__item_bulk, ',', ''',''')
	--SET @i__item_bulk = Replace(@i__item_bulk, '힣', ''',''')
	--SET @i__item_bulk = ''''+@i__item_bulk+ ''''
END
----------------------------------------

IF @i__itemBulk <> ''
BEGIN
	-- 검색어 처리
	CREATE TABLE  #tbl_itemH (
		idx int identity primary key,
		srchKeyword varchar(100),
		srchKeyword_origin varchar(100)
		--,primary key(srchKeyword)
	)

	create nonclustered index TIX_itemH_srchKeyWord ON #tbl_itemH(srchKeyword)

    -- 검색어 AND 조건 처리
    -- 공백으로 들어온것은 대상에서 제외
	--SELECT val FROM dbo.[UDF_SPLIT](@i__item_bulk,'힣') WHERE val<>''
	INSERT INTO #tbl_itemH (srchKeyword, srchKeyword_origin)
		SELECT a.val, b.val
		FROM 
		 (SELECT idx, val 
		  FROM  dbo.UF_SPLIT(@i__itemBulk,'힣') 
		  where val <> 'undefined' AND val<>'') a 
		  JOIN (SELECT idx, val 
		        FROM  dbo.UF_SPLIT(@n__item_bulk_origin,'힣') 
				where val <> 'undefined' AND val<>'') b ON a.idx = b.idx

	--멀티검색로그 입력 . 2024.03.28 hsg
	--IF @i__bulkSrchType = 'itemId' 
	INSERT INTO dbo.e_stockSrchLog(	comCode ,	userId, multiYN, itemId ,	itemNo, origin)
		SELECT @i__logComCode, @i__logUserId, 'Y'
			,CASE WHEN @i__bulkSrchType = 'itemId'  THEN srchKeyword ELSE '' END  
			,CASE WHEN @i__bulkSrchType = 'itemId'  THEN '' ELSE srchKeyword END  
			,srchKeyword_origin
		FROM #tbl_itemH
END

ELSE
BEGIN
	--단일검색로그 입력 . 2024.03.28 hsg
	IF @i__itemId > 0 OR @i__itemNo <> ''
	BEGIN
		INSERT INTO dbo.e_stockSrchLog(	comCode ,	userid, multiYN , itemId ,	itemNo, origin)
			VALUES ( @i__logComCode	, @i__logUserId, 'N', 
			  CASE WHEN @i__itemId = 0 THEN '' ELSE CAST(@i__itemId as varchar(100)) END , 
			  @i__itemNo			,@i__itemNo)		
	END
END

DECLARE @iGH int =1, @maxiGH int =0, @n__srchKeywordGH varchar(100)= ''

IF @i__workingType = 'LIST'    
	GOTO LIST_QRY   --  위탁관리>4car재고조회도 이걸 사용

IF @i__workingType = 'OUT_LIST' 
	GOTO OUT_LIST_QRY   -- ssy 판매

IF @i__workingType = 'STOR_LIST'
	GOTO STOR_LIST_QRY  -- ssy 창고

IF @i__workingType = 'SALE_LIST'  --ssy:업체가 보는 화면 (Aparts 재고조회화면)
	GOTO SALE_LIST_QRY  


RETURN
/*************************************************************************************************/
LIST_QRY: 


CREATE TABLE #stockItem  (
		idx int identity,
		comCode varchar(20),
		itemId bigint
		--rackCode varchar(20)  --2024.01.08 주석처리
		,primary key(idx)
)

create nonclustered index IX_e_stockRack__itemId On #stockItem(comCode, itemId) 


IF @i__storageCode <> ''
BEGIN 
	--INSERT INTO #stockItem( comCode, itemId, rackCode)
	INSERT INTO #stockItem( comCode, itemId)
		SELECT DISTINCT sr.comCode, sr.itemId --, sr.rackCode 
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		join dbo.e_storage _s on _s.comCode = r.comCode AND  _s.storageCode = r.storageCode
		WHERE sr.comCode = @i__logComCode AND   --조건추가 -- 20234.01.08 
		      r.storageCode = @i__storageCode AND sr.stockQty <> 0

			  and ISNULL(_s.consignCustCode, '') <> 'ㅇ496' --이지통상
END

--DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'매입가') FROM dbo.e_cust WHERE comCode = 'ㄱ000' AND custCode = @i__logComCode)
--위에거에서 이걸로 변경. 2024.10.16 hsg
DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'센터가') 
  FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
--DECLARE @n__isErp VARCHAR(10) = IIF((@i__logComCode in (select custCode from dbo.c_cust where erpYN = 'Y') OR  @i__logComCode = 'ㄱ000'),'Y','N')
DECLARE @n__isPan VARCHAR(10) 
  = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')

SET @sql = N'
SELECT
st.idx,
st.wrMemo,
st.inspecMemo,
st.regUserId,
st.regYmd,
st.regHms,
st.uptUserId,
st.uptYmd,
st.uptHms, 
(
	select sum(_sr.stockQty) 
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	 AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))	
	  and ISNULL(_s.consignCustCode, '''') <> ''ㅇ496''

	'
--if @i__logUserId = 'zzz'
--	SET @sql = @sql + N'	and _s.storageCode <> ''zzz'' '

SET @sql = @sql + N'	
) stockQty ,
(
	select sum(_sr.stockQty) 
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode 
	   or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = ''Y'' 
	  and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	  and _s.validYN = ''Y'' 
	  AND _s.storType in (''신품'',''중고'',''리퍼'') 
	  AND _s.workableYN = ''Y''	
	  and ISNULL(_s.consignCustCode, '''') <> ''ㅇ496''
	
	'
--if @i__logUserId = 'zzz'
--	SET @sql = @sql + N'	and _s.storageCode <> ''zzz'' '

SET @sql = @sql + N'	
)  workableQty,  '

IF @i__logComCode in (
  SELECT comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate('')))
  )
BEGIN
SET @sql = @sql + N'
	(
		SELECT STRING_AGG(''[''+_s.storageName+'']'' + _r.rackName + '' '' 
		  +cast(ISNULL( _sr.stockQty,'''') as varchar(100)), '' * '')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		  and ISNULL(_s.consignCustCode, '''') <> ''ㅇ496''
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		  AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode 
		    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		  and _sr.stockQty > 0

	'
	--if @i__logUserId = 'zzz'
	--	SET @sql = @sql + N'	and _s.storageCode <> ''zzz'' '
	SET @sql = @sql + N'	) locaMemo ,  '
END
ELSE
BEGIN
SET @sql = @sql + N''''' locaMemo, '
END

SET @sql = @sql + N' 

st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
	ELSE i.itemNameEn END itemName,
i.makerCode,
i.brandCode,
i.saleBrandCode,
i.genuineYN,
i.centerPrice,
ISNULL(ISNULL(ic.cost, ic3.cost),0) costPrice,
i.salePrice,
b.codeName AS makerName,
u1.userName regUserName,
u2.userName uptUserName

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0)  
	- ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo 
			  AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			  AND s.comCode = st.comCode
			  AND ISNULL(s.procStep,'''') NOT IN (''거부'', ''접수'', ''처리'')
		),0))) qtyNew
,ISNULL(str.qtyUsedWorkable, 0)  - ISNULL(temp.qtyUsed,0) qtyUsed
,ISNULL(str.qtyRefurWorkable, 0) - ISNULL(temp.qtyRefur,0) qtyRefur
,ISNULL(temp.qtyCtNew,0) qtyCtNew
,ISNULL(temp.qtyCtUsed,0) qtyCtUsed
,ISNULL(temp.qtyCtRefur,0) qtyCtRefur
,ISNULL(temp.qtyCtBad,0) qtyCtBad 

,CASE
    WHEN stockCheck.hasNot499 = 1 THEN
        CASE 
            WHEN @n__salePriceType = ''매입가'' THEN 
                ROUND(i.centerPrice * dbo.UF_cCustPerItemRate(@n__4carComCode, 
				  @i__logComCode, st.itemId, 1), 0) *
                 (1 + dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode,
				 @n__salePriceType, st.itemId, 1))
            ELSE 
                i.centerPrice * (1 - dbo.UF_sCustPerItemRate(@n__4carComCode, 
				  @i__logComCode, @n__salePriceType, st.itemId, 1))
        END
    WHEN stockCheck.has499 = 1 THEN
        ROUND(i.centerPrice * (1 - ISNULL(osr.purRate / 100.0, 0)), 0)
    ELSE
        CASE 
            WHEN @n__salePriceType = ''매입가'' THEN 
                ROUND(i.centerPrice * dbo.UF_cCustPerItemRate(@n__4carComCode, 
				 @i__logComCode, st.itemId, 1), 0) *
                (1 + dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, 
				  @n__salePriceType, st.itemId, 1))
            ELSE 
                i.centerPrice * (1 - dbo.UF_sCustPerItemRate(@n__4carComCode, 
				  @i__logComCode, @n__salePriceType, st.itemId, 1))
        END
END AS outSalePrice

,cd1.code classCode ,cd1.codeName className	,i.factoryNo

,IIF(stockCheck.has499 = 1 AND stockCheck.hasNot499 = 0, ''ㅇ499'', '''') AS otherSaleType

,CASE
    WHEN stockCheck.hasNot499 = 1 THEN
        CASE 
            WHEN @n__salePriceType = ''매입가'' THEN 
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, 
				  @n__salePriceType, st.itemId, 1)*100
            ELSE 
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, 
				  @n__salePriceType, st.itemId, 1)*100
        END
    WHEN stockCheck.has499 = 1 THEN
       ISNULL(osr.purRate , 0)
    ELSE
        CASE 
            WHEN @n__salePriceType = ''매입가'' THEN            
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, 
				  @n__salePriceType, st.itemId, 1)*100
            ELSE 
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, 
				  @n__salePriceType, st.itemId, 1)*100
        END
END AS saleRate

,stockCheck.hasNot499

,stockCheck.has499

FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i  ON st.itemId = i.itemId

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId 
  AND ic.stdYM = REPLACE(st.uptYmd, ''-'','''')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
				 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode 
				   AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId 
  AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode=''1000'' 
  AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId 
  AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''신품'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''중고'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''리퍼'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''불량'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((ISNULL(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''신품''  
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = ''신품'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((ISNULL(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''중고''  
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''중고'' 
		AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((ISNULL(_s.consignCustCode, '''') <> @i__logComCode 
	  AND _s.storType = ''리퍼''  
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''리퍼'' 
		AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  
	  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  
	  AND _s.storageCode = _r.storageCode 
	where @n__4carComCode = _sr.comCode
	  AND @n__4carComCode <> @i__logComCode	
	
	and ISNULL(_s.consignCustCode, '''') <> ''ㅇ496'' --이지통상

	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
 AND cd1.mCode = ''1100'' 
 AND cd1.code = i.classCode 
 AND cd1.validYN = ''Y''

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '''' 
	    or _s.consignCustCode = @i__consignCustCode 
		or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = ''Y'' 
	  and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	  and _s.validYN = ''Y'' 
	  AND _s.storType in (''신품'',''중고'',''리퍼'') 
	  AND _s.workableYN = ''Y''
	  AND _s.consignCustCode = ''ㅇ496'' --이지통상
    
) ca5

OUTER APPLY (
    SELECT
        MAX(CASE 
            WHEN s_s.consignCustCode = ''ㅇ499'' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS has499,

        MAX(CASE 
            WHEN s_s.consignCustCode != ''ㅇ499'' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS hasNot499
    FROM dbo.e_storage s_s
    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode
    JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
    WHERE s_s.comCode = @n__4carComCode 
      AND s_sr.itemId = i.itemId
) stockCheck

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode 
  AND osr.custCode = ''ㅇ499''
  AND osr.itemId = i.itemId 
'


IF @i__itemBulk <> '' 
BEGIN
	IF @i__bulkSrchType = 'itemId' 
		SET @sql = @sql + '	LEFT OUTER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                     FROM #tbl_itemH 
											 GROUP BY srchKeyWord) bk ON i.ItemId = bk.srchKeyword '

	IF @i__bulkSrchType = 'itemNo' 
		SET @sql = @sql + '	LEFT OUTER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                     FROM #tbl_itemH 
											 GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword '
END

IF @i__storageCode <> '' 
BEGIN
	SET @sql = @sql + '	JOIN #stockItem st2 ON st2.comCode = st.comCode AND st2.itemId = st.itemId '
END

--IF @i__logComCode NOT IN ('ㄱ000','ㄱ121', 'ㅇ413','ㅇ434','ㅇ436', 'ㅇ439', 'ㅋ127')
--IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode('ㄱ000'))
--위에서 이걸로 변경. 2024.10.16 hsg
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))   
BEGIN
	SET @sql = @sql + '	LEFT OUTER JOIN dbo.e_stockItemOuterNonDsp nd ON st.comCode = nd.comCode 
	                      AND st.itemId = nd.itemId '
END



SET @sql = @sql + N'
WHERE 1= 1 and

dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0)  
	- ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo 
			  AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			  AND s.comCode = st.comCode			
			  AND ISNULL(s.procStep,'''') NOT IN (''거부'', ''접수'', ''처리'')
		),0))) > 0

'

--IF @i__checkType <> '' AND @i__checkType <> 'ALL'
IF @i__checkType = 'OUT'
BEGIN
	SET @sql = @sql + N' AND 1=1 '
END
ELSE IF @i__checkType = 'ALL' --외부재고다중조회
BEGIN
	SET @sql = @sql + N' AND @n__4carComCode = st.comCode  '
END
ELSE
BEGIN
	SET @sql = @sql + N' AND st.comCode = @i__logComCode '
END


--IF @i__storCode <> ''
--SET @sqlW = @sqlW + N'   AND st.storCode= @i__storCode '

IF @i__itemId <> ''
SET @sql = @sql + N' AND st.itemId= @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo LIKE ''%'+@i__itemNo+'%'' '	

--IF @i__storName <> ''
--SET @sqlW = @sqlW + N'  AND sg.storageName LIKE '''+@i__storName+'%'' '	

IF @i__makerCode <> ''
SET @sql = @sql + N' AND i.makerCode= @i__makerCode '

IF @i__itemName <> ''
SET @sql = @sql + N' AND (i.itemName LIKE ''%'+@i__itemName+'%'' OR i.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '

IF @i__classCode <> ''
SET @sql = @sql + N' AND i.classCode= @i__classCode '

IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
	SET @sql = @sql + N' AND st.uptYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__noRealYN = 'Y'
	SET @sql = @sql + N' AND  ISNULL(noRealYN, ''N'') <> ''Y'''
IF @i__qtyZeroYN = 'Y'
	SET @sql = @sql + N' AND ISNULL(str.qtyWorkable, 0) <> 0 AND ISNULL(st.stockQty, 0) <> 0 '

--IF @i__logComCode NOT IN ('ㄱ000','ㄱ121', 'ㅇ413','ㅇ434','ㅇ436', 'ㅇ439', 'ㅋ127')
--IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode('ㄱ000'))
--위에서 이걸로 변경. 2024.10.16 hsg
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))   
BEGIN
	SET @sql = @sql + N' AND nd.itemId IS NULL'
END
	--SET @sqlW = @sqlW + N'  AND i.itemNo NOT IN (''000989180811'',''NQ0810078'',''NQ0810075'',''NQ0810070'',''83512355290'',''ZZSA1702201BRL'',''ZZSV1702201BRL'',''ZZSV2002102BLA'',''ZZSA2002102BLA'',''NB81201136'',''NB81201137'',''97000000801'',''90200006337'',''97000000701'',''90200006979	'') ' 

--멀티조회: 상품조회 메뉴의 대량조회 시. 2023.08.31
IF @i__itemBulk <> ''
BEGIN

	--DECLARE @iGH int =1, @maxiGH int =0, @n__srchKeywordGH varchar(100)= ''

	SELECT @maxiGH = MAX(idx) FROM #tbl_itemH
	SET @sql = @sql + N' AND ('

	WHILE(@iGH<=@maxiGH)
	BEGIN
		
		SELECT @n__srchKeywordGH = srchKeyword FROM #tbl_itemH WHERE idx = @iGH

		IF @n__srchKeywordGH <> ''
		BEGIN
			IF @i__bulkSrchType = 'itemId'
				SET @sql = @sql + N' i.itemId = '''+@n__srchKeywordGH+'''   '

			IF @i__bulkSrchType = 'itemNo'
				SET @sql = @sql + N' i.itemNo  = '''+@n__srchKeywordGH+'''   '   --LIKE ''%'+@n__srchKeywordGH+'%'' '
		END
		
		IF (@iGH<> @maxiGH)
			SET @sql = @sql + ' OR '
		ELSE 
			SET @sql = @sql + ' )'

		SET @iGH = @iGH+1
	END
	
	SET @sql = @sql + N' ORDER BY ISNULL(bk.idx, 999999)'    --대량조회및 대량조회한 품목순
	
END

ELSE 
	SET @sql = @sql + N' ORDER BY st.uptYmd DESC, st.UptHms DESC'



EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, @i__storCode varchar(20)
                        , @i__storName varchar(100), @i__makerCode varchar(20) ,@i__classCode varchar(10) 
						,@i__sYmd1 varchar(10) ,@i__eYmd1 varchar(10) ,@i__checkType varchar(100)
						, @i__outStorCode varchar(50), @i__noRealYN varchar(1) 
						,@i__qtyZeroYN varchar(1) , @n__4carComCode  varchar(10) 
						, @n__salePriceType varchar(10) , @n__isPan varchar(10), @i__consignCustCode varchar(20)
						,@i__logUserId varchar(50)',
						@i__logComCode, @i__itemId, @i__storCode ,@i__storName ,@i__makerCode 
						,@i__classCode, @i__sYmd1 ,@i__eYmd1 ,@i__checkType ,@i__outStorCode 
						, @i__noRealYN,@i__qtyZeroYN,@n__4carComCode  , @n__salePriceType 
						, @n__isPan , @i__consignCustCode, @i__logUserId

IF @i__itemBulk <> ''
BEGIN

DROP TABLE #tbl_itemH

END

RETURN

/*************************************************************************************************/
OUT_LIST_QRY: 

SET @sqlS = N'
SELECT
	st.stockQty, 
	st.comCode,
	st.itemId , -- 품목ID 

	i.itemNo ,  --품번
	i.carType , --차종
	CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
 	     ELSE i.itemNameEn END itemName,
	i.makerCode ,				--제조사코드
	i.brandCode,
	i.saleBrandCode,
	i.genuineYN , --정품여부
	i.centerPrice ,
	i.salePrice 
	,b.codeName AS makerName
	,ISNULL(cust.custCode, '''') custCode
	,ISNULL(cust.custName, '''') custName
	,locaMemo 
	,i.classCode 
	,cd1.codeName className	 
	,IIF(i.classCode = ''GN'','''', i.factoryNo) factoryNo
'
SET @sqlF = N'
FROM (
	SELECT  s_st.comCode, s_st.itemId, SUM(s_st.stockQty) stockQty, MAX(s_st.locaMemo) locaMemo
	FROM (
		SELECT sr.comCode, sr.itemId , sr.stockQty
			,STUFF((
				SELECT '','' + storageName  +'':''+ CAST(sr.stockQty as varchar(10)) 
				FROM    dbo.e_storage b 
				WHERE   b.comCode = sg.comCode AND b.storageCode = sg.storageCode
				FOR XML PATH('''')
				),1,1,'''') 	 AS locaMemo 
				FROM dbo.e_stockRack sr
				JOIN dbo.e_rack rk ON sr.comCode = rk.comCode  AND sr.rackCode = rk.rackCode
				JOIN dbo.e_storage sg ON rk.comCode = sg.comCode AND rk.storageCode = sg.storageCode
				WHERE sg.consignYN = ''Y''
				'

				
IF @i__logComCode = 'ㅍ008' --파츠몰
	SET @sqlF =  @sqlF + N'   AND @n__4carComCode = sg.comCode  AND sg.consignCoworkCustCode = ''ㅍ008''  '
ELSE
	SET @sqlF =  @sqlF + N'   AND sg.consignCustCode = @i__logComCode '
SET @sqlF =  @sqlF + N'
		) s_st
	GROUP BY s_st.comCode , s_st.itemId	
	--HAVING SUM(s_st.stockQty) > 0 
	) st
LEFT OUTER JOIN dbo.e_item i  ON st.itemId = i.itemId
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode=''1000'' 
  AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_cust cust ON cust.comCode = @ErpOperateComCode 
  AND st.comCode = cust.custCode
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
  AND cd1.mCode = ''1100'' 
  AND cd1.code = i.classCode 
  AND cd1.validYN = ''Y''
'
--250211 yoonsang HAVING SUM(s_st.stockQty) > 0 추가

--FROM (SELECT sr.comCode, sr.itemId, SUM(sr.stockQty) stockQty
--	,STUFF((
--		SELECT '','' + storageName
--		FROM    e_storage b 
--		WHERE   b.comCode = st.comCode AND b.storageCode = sg.storageCode
--		FOR XML PATH('''')
--		),1,1,'''') 	 AS locaMemo 
--		FROM dbo.e_stockRack sr
--		JOIN dbo.e_rack rk ON sr.comCode = rk.comCode  AND sr.rackCode = rk.rackCode
--		JOIN dbo.e_storage sg ON rk.comCode = sg.comCode AND rk.storageCode = sg.storageCode
--		WHERE sg.consignYN = ''Y''
--		  AND sg.consignCustCode = @i__logComCode
--		GROUP BY sr.comCode , sr.itemId
--		) st 
--LEFT OUTER JOIN dbo.e_cust cust ON cust.comCode = ''ㄱ000'' AND st.comCode = cust.custCode
--LEFT JOIN dbo.e_code cd1 ON cd1.comCode = ''ㄱ000'' AND cd1.mCode = ''1100'' AND cd1.code = i.classCode AND cd1.validYN = ''Y''
SET @sqlW = N'
WHERE 1= 1 
and st.comCode = ''ㄱ121''
'

IF @i__itemBulk <> '' 
BEGIN
	IF @i__bulkSrchType = 'itemId' 
		SET @sqlF = @sqlF + '	LEFT OUTER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                         FROM #tbl_itemH 
												 GROUP BY srchKeyWord) bk ON i.ItemId = bk.srchKeyword '

	IF @i__bulkSrchType = 'itemNo' 
		SET @sqlF = @sqlF + '	LEFT OUTER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                         FROM #tbl_itemH 
												 GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword '
END

IF @i__itemId <> ''
SET @sqlW = @sqlW + N'   AND st.itemId= @i__itemId '

IF @i__itemNo <> ''
SET @sqlW = @sqlW + N'  AND i.itemNo LIKE ''%'+@i__itemNo+'%'' '	

--IF @i__storName <> ''
--SET @sqlW = @sqlW + N'  AND st.locaMemo LIKE ''%'+@i__storName+'%'' '	
IF @i__outStorCode <> ''
SET @sqlW = @sqlW + N'  AND st.locaMemo LIKE ''%'+@i__outStorCode+'%'' '	

IF @i__makerCode <> ''
SET @sqlW = @sqlW + N'  AND i.makerCode= @i__makerCode '

IF @i__itemName <> ''
SET @sqlW = @sqlW + ' AND (i.itemName LIKE ''%'+@i__itemName+'%'' OR i.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '

IF @i__classCode <> ''
SET @sqlW = @sqlW + N'   AND i.classCode= @i__classCode '

IF @i__noRealYN = 'Y'
	SET @sqlW = @sqlW + ' AND  ISNULL(noRealYN, ''N'') <> ''Y'''
IF @i__qtyZeroYN = 'Y'
	SET @sqlW = @sqlW + ' AND ISNULL(str.qtyWorkable, 0) <> 0 AND ISNULL(st.stockQty, 0) <> 0 '


IF @i__itemBulk <> ''
BEGIN

	--DECLARE @iGH int =1, @maxiGH int =0, @n__srchKeywordGH varchar(100)= ''

	SELECT @maxiGH = MAX(idx) FROM #tbl_itemH
	SET @sqlW = @sqlW + ' AND ('

	WHILE(@iGH<=@maxiGH)
	BEGIN
		
		SELECT @n__srchKeywordGH = srchKeyword FROM #tbl_itemH WHERE idx = @iGH

		IF @n__srchKeywordGH <> ''
		BEGIN
			IF @i__bulkSrchType = 'itemId'
				SET @sqlW = @sqlW + '  i.itemId = '''+@n__srchKeywordGH+'''   '

			IF @i__bulkSrchType = 'itemNo'
				SET @sqlW = @sqlW + '  i.itemNo  = '''+@n__srchKeywordGH+'''   '   --LIKE ''%'+@n__srchKeywordGH+'%'' '
		END
		
		IF (@iGH<> @maxiGH)
			SET @sqlW = @sqlW + ' OR '
		ELSE 
			SET @sqlW = @sqlW + ' )'

		SET @iGH = @iGH+1
	END
	
	SET @sqlW = @sqlW + N' ORDER BY ISNULL(bk.idx, 999999)'    --대량조회및 대량조회한 품목순
	
END
ELSE
SET @sqlW = @sqlW + N' ORDER BY i.itemNo '

print @sqlS
print @sqlF
print @sqlW

SET @sql = @sqlS + @sqlF + @sqlW

EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, @i__storCode varchar(20)
                        , @i__storName varchar(100), @i__makerCode varchar(20) ,@i__classCode varchar(10) 
						,@i__sYmd1 varchar(10) ,@i__eYmd1 varchar(10) ,@i__checkType varchar(100)
						, @i__outStorCode varchar(50) , @i__noRealYN varchar(1) ,@i__qtyZeroYN varchar(1)
						, @n__4carComCode  varchar(10), @ErpOperateComCode varchar(50)',
						@i__logComCode, @i__itemId, @i__storCode ,@i__storName ,@i__makerCode ,@i__classCode
						, @i__sYmd1 ,@i__eYmd1 ,@i__checkType ,@i__outStorCode, @i__noRealYN,@i__qtyZeroYN 
						, @n__4carComCode , @ErpOperateComCode

IF @i__itemBulk <> ''
BEGIN

DROP TABLE #tbl_itemH

END

RETURN
/*************************************************************************************************/

STOR_LIST_QRY:

CREATE TABLE #storTable  (
		idx int identity,
		itemId bigint,
		stockQty int,
		storageNameArr varchar(MAX),
		primary key(idx)
)

IF (@i__checkType = 'itemId')
BEGIN 
	INSERT INTO #storTable(itemId,stockQty,storageNameArr)
	SELECT  a.itemId , sum(a.stockQty) stockQty , STRING_AGG(  storageName , '^') storageName  
	FROM dbo.e_stockRack a 
	LEFT OUTER JOIN dbo.e_rack b ON a.comCode = b.comCode AND a.rackCode = b.rackCode
	LEFT OUTER JOIN dbo.e_storage stor ON stor.comCode = a.comCode AND stor.storageCode = b.storageCode
	WHERE a.comCode = @i__logComCode AND 
	      b.storageCode in (SELECT val FROM dbo.UF_SPLIT(@i__storageCode,'^')) AND 
	      a.stockQty >0 AND 
		  a.itemId <> 0
		  and stor.consignCustCode <> 'ㅇ496'
	GROUP BY a.itemId   
END
ELSE
IF (@i__checkType = 'stor')
BEGIN 
	INSERT INTO #storTable(itemId,stockQty,storageNameArr)
	SELECT  a.itemId , sum(a.stockQty) stockQty , STRING_AGG(  storageName , '^') storageName  
	FROM dbo.e_stockRack a 
	LEFT OUTER JOIN dbo.e_rack b ON a.comCode = b.comCode AND a.rackCode = b.rackCode
	LEFT OUTER JOIN dbo.e_storage stor ON stor.comCode = a.comCode AND stor.storageCode = b.storageCode
	WHERE a.comCode = @i__logComCode AND 
	      b.storageCode in (SELECT val FROM dbo.UF_SPLIT(@i__storageCode,'^')) AND 
	      a.stockQty >0 AND 
		  a.itemId <> 0
		  and stor.consignCustCode <> 'ㅇ496'
	GROUP BY a.itemId , stor.storageName
END
 

SELECT a.itemId,
	   c.itemNo,
	   CASE WHEN ISNULL(c.itemName, '') <> '' THEN c.itemName 
	   ELSE c.itemNameEn END itemName,
	   c.makerCode,
	   d.codeName makerName,
	   a.stockQty,
	   c.centerPrice,
	   c.salePrice,
	 --  ISNULL(ic.cost,0) costPrice,
	   (SELECT string_agg( val,',')
		FROM (SELECT DISTINCT val from UF_SPLIT(storageNameArr, '^')) a) locaMemo
		,d2.codeName className
		,IIF(c.classCode = 'GN','', c.factoryNo) factoryNo
FROM #storTable a
LEFT OUTER JOIN dbo.e_item c  ON  a.itemId = c.itemId
LEFT OUTER JOIN dbo.e_code d ON d.comCode = @i__logComCode 
  AND d.mCode='1000' 
  AND d.code = c.makerCode
LEFT OUTER JOIN dbo.e_code d2 ON d2.comCode = @i__logComCode 
  AND d2.mCode='1100' 
  AND d2.code = c.classCode
--LEFT OUTER JOIN dbo.e_itemCost ic ON ic.comCode = @i__logComCode AND a.itemId = ic.itemId   
ORDER BY itemId

DROP TABLE #storTable

RETURN
/*************************************************************************************************/


/*************************************************************************************************/
SALE_LIST_QRY: 


CREATE TABLE #stockItem3  (
		idx int identity,
		comCode varchar(20),
		itemId bigint
		--rackCode varchar(20)  --2024.01.08 주석처리
		,primary key(idx)
)

create nonclustered index IX_e_stockRack__itemId3 On #stockItem3(comCode, itemId) 


IF @i__storageCode <> ''
BEGIN 
	INSERT INTO #stockItem3( comCode, itemId)
		SELECT DISTINCT sr.comCode, sr.itemId --, sr.rackCode 
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		WHERE sr.comCode = @i__logComCode 
		--조건추가 -- 2024.01.08 
		  AND r.storageCode = @i__storageCode 
		  AND sr.stockQty <> 0
END

create table #e_itemForStock(
	comCode varchar(50) NOT NULL,
	itemId bigint NOT NULL,
	itemNo varchar(50) NOT NULL,
	factoryNo varchar(50) NOT NULL,
	carType varchar(100) NOT NULL,
	itemName varchar(100) NOT NULL,
	itemNameEn varchar(100) NOT NULL,
	makerCode varchar(20) NOT NULL,
	brandCode varchar(20) NOT NULL,
	saleBrandCode varchar(20) NOT NULL,
	genuineYN varchar(1) NOT NULL,	
	centerPrice money NOT NULL,
	salePrice money NOT NULL,	
	classCode varchar(10) NULL	
)
CREATE INDEX IX_e_itemForStock_1 ON #e_itemForStock(comCode, itemId);
CREATE INDEX IX_e_itemForStock_2 ON #e_itemForStock(itemNo);

IF @i__itemBulk <> ''
BEGIN

	IF @i__bulkSrchType = 'itemNo'
	BEGIN
	    INSERT INTO #e_itemForStock(comCode, itemId, itemNo, 
			itemName, itemNameEn, carType, makerCode, brandCode,
			saleBrandCode, genuineYN, centerPrice, salePrice,
			classCode, factoryNo)
		SELECT
			  i.comCode
			, i.itemId
			, i.itemNo
			, i.itemName
			, i.itemNameEn
			, i.carType
			, i.makerCode
			, i.brandCode
			, i.saleBrandCode
			, i.genuineYN
			, i.centerPrice
			, i.salePrice
			, i.classCode
			, i.factoryNo
		FROM dbo.e_item i
		JOIN #tbl_itemH ih
		  ON ih.srchKeyword = i.itemNo;
	END	
	ELSE IF @i__bulkSrchType = 'itemId'
	BEGIN
		INSERT INTO #e_itemForStock(comCode, itemId, itemNo, 
			itemName, itemNameEn, carType, makerCode, brandCode,
			saleBrandCode, genuineYN, centerPrice, salePrice,
			classCode, factoryNo)
		SELECT
			  i.comCode
			, i.itemId
			, i.itemNo
			, i.itemName
			, i.itemNameEn
			, i.carType
			, i.makerCode
			, i.brandCode
			, i.saleBrandCode
			, i.genuineYN
			, i.centerPrice
			, i.salePrice
			, i.classCode
			, i.factoryNo
		FROM dbo.e_item i
		JOIN #tbl_itemH ih
		  ON ih.srchKeyword = CONVERT(varchar(100), i.itemId);
	END

END



DECLARE @n__salePriceType3 varchar(10) = 
	(SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust 
	WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan3 VARCHAR(10) = 
	IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')
-----------------------------------------------------------------------------------------------------------------
--sql1: 자사 재고
SET @sql1 = N'
SELECT
st.idx,
st.wrMemo,
st.inspecMemo,
st.regUserId,
st.regYmd,
st.regHms,
st.uptUserId,
st.uptYmd,
st.uptHms, 
ISNULL(ca1.qty1,0) AS stockQty ,
ISNULL(ca2.qty2,0) AS workableQty,  
'

IF @i__logComCode in (SELECT comCode FROM dbo.UF_GetGroupComCode(
                        (select comCode from UF_ErpOperate(''))))
BEGIN

SET @sql1 = @sql1 + N'
	(
		SELECT STRING_AGG(''[''+_s.storageName+'']'' + _r.rackName + '' '' +
						cast(ISNULL( _sr.stockQty,'''') as varchar(100)), '' * '')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
		  AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
		  AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId 
		  and _sr.comCode = st.comCode 
		  AND (@i__consignCustCode = '''' 
		    or _s.consignCustCode = @i__consignCustCode 
			or (_s.consignCustCode is null 
			  AND _s.comCode = @i__consignCustCode))
		  and _sr.stockQty > 0
		  AND ISNULL(_s.consignCustCode,'''') 
		    NOT IN (''ㅇ499'', ''ㅂ022'', ''ㅇ479'', ''ㅇ002'', ''ㅂ184'', ''ㅈ011'', ''ㅂ186'', ''ㅇ496'')
	'
	--if @i__logUserId = 'zzz'
	--	SET @sql = @sql + N'	and _s.storageCode <> ''zzz'' '
	SET @sql1 = @sql1 + N'	) locaMemo ,  '
END
ELSE
BEGIN
SET @sql1 = @sql1 + N''''' locaMemo ,'
END

SET @sql1 = @sql1 + N' 
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
	 ELSE i.itemNameEn END itemName,
i.makerCode,
i.brandCode,
i.saleBrandCode,
i.genuineYN,
i.centerPrice,
ISNULL(ISNULL(ic.cost, ic3.cost),0) costPrice,
i.salePrice,
b.codeName AS makerName,
u1.userName regUserName,
u2.userName uptUserName

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) --신품 가용재고
    - ISNULL(temp.qtyNew,0) --타사공개위탁재고or자사신품가용재고
    - ISNULL(ca3.qty3,0) --위탁 재고
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0) --주문중인 상태
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s --재고주문
			LEFT OUTER JOIN dbo.e_placeItem pli --발주(25.6이후 사용안됨)
			  ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo 
			  AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			  AND s.comCode = st.comCode  
			  AND ISNULL(s.procStep,'''') NOT IN (''거부'', ''접수'', ''처리'')
		) 
		,
		0))) AS qtyNew -- 신품 재고

,ISNULL(str.qtyUsedWorkable, 0)  - ISNULL(temp.qtyUsed,0) qtyUsed --중고 재고
,ISNULL(str.qtyRefurWorkable, 0) - ISNULL(temp.qtyRefur,0) qtyRefur --리퍼 재고
,ISNULL(temp.qtyCtNew,0) qtyCtNew --신품 회수 재고
,ISNULL(temp.qtyCtUsed,0) qtyCtUsed --중고 회수 재고
,ISNULL(temp.qtyCtRefur,0) qtyCtRefur --리퍼 회수 재고
,ISNULL(temp.qtyCtBad,0) qtyCtBad --불량 회수 재고

, CASE 
    WHEN @n__salePriceType3 = ''매입가'' THEN 
        ROUND(i.centerPrice * dbo.UF_cCustPerItemRate(@n__4carComCode, @i__logComCode, st.itemId, 1), 0) *
        (1 + dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1))
    ELSE 
        i.centerPrice * (1 - dbo.UF_sCustPerItemRate(
		                       @n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1))
END AS outSalePrice

,cd1.code classCode ,cd1.codeName className	,i.factoryNo

,'''' AS otherSaleType

, CASE 
    WHEN @n__salePriceType3 = ''매입가'' THEN 
        dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1)*100
    ELSE 
        dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1)*100
END AS saleRate
'
IF @i__itemBulk <> ''
BEGIN
    SET @sql1 = @sql1 + N' , ISNULL(bk.idx, NULL) AS bk_idx '
END


SET @sql1 = @sql1 + N' 

,ca3.qty3 AS qty3

,'''' AS stockRackCode


FROM dbo.e_stockItem st 

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1  --순수 자사 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '''' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null 
	    AND _s.comCode = @i__consignCustCode))
	AND ISNULL(_s.consignCustCode,'''') 
	 NOT IN (''ㅇ499'', ''ㅂ022'', ''ㅇ479'', ''ㅇ002'', ''ㅂ184'', ''ㅈ011'', ''ㅂ186'', ''ㅇ496'')
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2 --순수 자사 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '''' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null 
	    AND _s.comCode = @i__consignCustCode))
	and _r.validYN = ''Y'' 
	and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	and _s.validYN = ''Y'' 
	AND _s.storType in (''신품'',''중고'',''리퍼'') 
	AND _s.workableYN = ''Y''
	AND ISNULL(_s.consignCustCode,'''') 
	  NOT IN (''ㅇ499'', ''ㅂ022'', ''ㅇ479'', ''ㅇ002'', ''ㅂ184'', ''ㅈ011'', ''ㅂ186'', ''ㅇ496'')
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3 --위탁업체 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '''' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null 
	    AND _s.comCode = @i__consignCustCode))
	and _r.validYN = ''Y'' 
	and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	and _s.validYN = ''Y'' 
	AND _s.storType in (''신품'',''중고'',''리퍼'') 
	AND _s.workableYN = ''Y''
	AND _s.consignCustCode 
	  in (''ㅇ499'', ''ㅂ022'', ''ㅇ479'', ''ㅇ002'', ''ㅂ184'', ''ㅈ011'', ''ㅂ186'', ''ㅇ496'')
    
) ca3
'

IF @i__itemBulk <> ''
BEGIN
  SET @sql1 = @sql1 + N' LEFT JOIN dbo.#e_itemForStock i ON st.itemId = i.itemId '
END
ELSE
  SET @sql1 = @sql1 + N' LEFT JOIN dbo.e_item i ON st.itemId = i.itemId '

SET @sql1 = @sql1 + N'
LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId 
  AND ic.stdYM = REPLACE(st.uptYmd, ''-'','''')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
                 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode 
				   AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId 
  AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode=''1000'' 
  AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON st.comCode = str.comCode
  AND i.itemId = str.itemId
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	  AND _s.storType = ''신품''
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	  AND _s.storType = ''중고'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	  AND _s.storType = ''리퍼'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	  AND _s.storType = ''불량'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((ISNULL(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''신품''  
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan3 = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode
	    AND _s.storType = ''신품'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  )  
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((ISNULL(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''중고''
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''
	  AND @n__isPan3 = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''중고'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((ISNULL(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''리퍼''
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan3 = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''리퍼'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
	    AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  
	  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  
	  AND _s.storageCode = _r.storageCode 
	where @n__4carComCode = _sr.comCode  
	  AND @n__4carComCode <> @i__logComCode  
	  and ISNULL(_s.consignCustCode,'''') 
	    NOT IN (''ㅇ499'', ''ㅂ022'', ''ㅇ479'', ''ㅇ002'', ''ㅂ184'', ''ㅈ011'', ''ㅂ186'', ''ㅇ496'')
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode
  AND cd1.mCode = ''1100'' 
  AND cd1.code = i.classCode 
  AND cd1.validYN = ''Y''

'

IF @i__itemBulk <> '' 
BEGIN
	IF @i__bulkSrchType = 'itemId' 
		SET @sql1 = @sql1 + '	INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemId = bk.srchKeyword '

	IF @i__bulkSrchType = 'itemNo' 
		SET @sql1 = @sql1 + '	INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword '
END

IF @i__storageCode <> '' 
BEGIN
	SET @sql1 = @sql1 + '	JOIN #stockItem3 st2 ON st2.comCode = st.comCode AND st2.itemId = st.itemId '
END

--IF @i__logComCode NOT IN ('ㄱ000','ㄱ121', 'ㅇ413','ㅇ434','ㅇ436', 'ㅇ439', 'ㅋ127')
--IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode('ㄱ000'))
--위에서 이걸로 변경. 2024.10.16 hsg
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))
BEGIN
	SET @sql1 = @sql1 + '	LEFT OUTER JOIN dbo.e_stockItemOuterNonDsp nd ON st.comCode = nd.comCode 
                              AND st.itemId = nd.itemId '
END


SET @sql1 = @sql1 + N'
WHERE 1= 1 '

--IF @i__checkType <> '' AND @i__checkType <> 'ALL'
IF @i__checkType = 'OUT'
BEGIN
	SET @sql1 = @sql1 + N' AND 1=1 '
END
ELSE IF @i__checkType = 'ALL' --외부재고다중조회
BEGIN
	SET @sql1 = @sql1 + N' AND @n__4carComCode = st.comCode  '
END
ELSE
BEGIN
	SET @sql1 = @sql1 + N' AND st.comCode = @i__logComCode '
END


--IF @i__storCode <> ''
--SET @sqlW = @sqlW + N'   AND st.storCode= @i__storCode '

IF @i__itemId <> ''
SET @sql1 = @sql1 + N' AND st.itemId= @i__itemId '

IF @i__itemNo <> ''
SET @sql1 = @sql1 + N' AND i.itemNo LIKE ''%'+@i__itemNo+'%'' '	

--IF @i__storName <> ''
--SET @sqlW = @sqlW + N'  AND sg.storageName LIKE '''+@i__storName+'%'' '	

IF @i__makerCode <> ''
SET @sql1 = @sql1 + N' AND i.makerCode= @i__makerCode '

IF @i__itemName <> ''
SET @sql1 = @sql1 + N' AND (i.itemName LIKE ''%'+@i__itemName+'%'' OR i.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '

IF @i__classCode <> ''
SET @sql1 = @sql1 + N' AND i.classCode= @i__classCode '

IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
	SET @sql1 = @sql1 + N' AND st.uptYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__noRealYN = 'Y'
	SET @sql1 = @sql1 + N' AND  ISNULL(noRealYN, ''N'') <> ''Y'''
IF @i__qtyZeroYN = 'Y'
	SET @sql1 = @sql1 + N' AND ISNULL(str.qtyWorkable, 0) <> 0 AND ISNULL(st.stockQty, 0) <> 0 '

--위에서 이걸로 변경. 2024.10.16 hsg
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))
BEGIN
	SET @sql1 = @sql1 + N' AND	nd.itemId IS NULL'
END


-----------------------------------------------------------------------------------------------------------------
--sql2: 위탁업체 재고
SET @sql2 = N'
SELECT
st.idx,
st.wrMemo,
st.inspecMemo,
st.regUserId,
st.regYmd,
st.regHms,
st.uptUserId,
st.uptYmd,
st.uptHms, 
ISNULL(ca.qty1,0) AS stockQty ,
ISNULL(ca.qty2,0) AS workableQty,

'

IF @i__logComCode in (SELECT comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate(''))))
BEGIN
SET @sql2 = @sql2 + N'
	ca.locaMemo,  '
END
ELSE
BEGIN
SET @sql2 = @sql2 + N' '''' locaMemo ,'
END

SET @sql2 = @sql2 + N' 
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
	ELSE i.itemNameEn END itemName,
i.makerCode,
i.brandCode,
i.saleBrandCode,
i.genuineYN,
i.centerPrice,
ISNULL(ISNULL(ic.cost, ic3.cost),0) costPrice,
i.salePrice,
b.codeName AS makerName,
u1.userName regUserName,
u2.userName uptUserName

,dbo.UF_GREATEST(
    0,
	ISNULL(str.qtyNewWorkable, 0)
    - ISNULL(temp.qtyNew, 0) 
    - ISNULL(ca.qty3, 0) 
	- ISNULL(ca.qty5, 0)
	- ISNULL(ord.orderQty, 0)
 ) AS qtyNew

,ISNULL(str.qtyUsedWorkable, 0)  - ISNULL(temp.qtyUsed,0) qtyUsed
,ISNULL(str.qtyRefurWorkable, 0) - ISNULL(temp.qtyRefur,0) qtyRefur
,ISNULL(temp.qtyCtNew,0) qtyCtNew
,ISNULL(temp.qtyCtUsed,0) qtyCtUsed
,ISNULL(temp.qtyCtRefur,0) qtyCtRefur
,ISNULL(temp.qtyCtBad,0) qtyCtBad 

,ROUND(i.centerPrice * (1 - ISNULL(osr.purRate / 100.0, 0)), 0) AS outSalePrice

,cd1.code classCode 
,cd1.codeName className	
,i.factoryNo

,v.consignCustCode AS otherSaleType

,ISNULL(osr.purRate , 0) AS saleRate
'
IF @i__itemBulk <> ''
BEGIN
    SET @sql2 = @sql2 + N' , ISNULL(bk.idx, NULL) AS bk_idx '
END
SET @sql2 = @sql2 + N' 

,ca.qty3 AS qty3

,v.consignCustCode AS stockRackCode

FROM dbo.e_stockItem st 
JOIN (
    VALUES
        (''ㅇ499'',''ㅇ499'',''ㅇ496''),--아우토서울
        (''ㅂ022'',''ㅂ022'',''ㅇ496''),--VAG
        (''ㅇ479'',''ㅇ479'',''ㅇ496''),--인터카스
        (''ㅇ002'',''ㅇ002'',''ㅇ496''),--엠케이
        (''ㅂ184'',''ㅂ184'',''ㅇ496''),--보스카통상
		(''ㅈ011'',''ㅈ011'',''ㅇ496''),--제파
		(''ㅂ186'',''ㅂ186'',''ㅇ496'') --부품인
) v(consignCustCode, excludeSelf, excludeOther)
    ON 1 = 1
'
IF @i__itemBulk <> ''
BEGIN
  SET @sql2 = @sql2 + N' LEFT JOIN dbo.#e_itemForStock i ON st.itemId = i.itemId'
END
ELSE
  SET @sql2 = @sql2 + N' LEFT JOIN dbo.e_item i ON st.itemId = i.itemId'

SET @sql2 = @sql2 + N'
CROSS APPLY (
	select 
	sum(case when _s.consignCustCode = param.consignCustCode then _sr.stockQty else 0 end) AS qty1, --위탁업체 재고
	sum(case when _s.consignCustCode = param.consignCustCode 
	  and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	  and _r.validYN = ''Y'' 
	  and _s.validYN = ''Y'' 
	  AND _s.workableYN = ''Y''
	  AND _s.storType in (''신품'',''중고'',''리퍼'') 
	  then _sr.stockQty else 0 end) AS qty2, --위탁업체 가용재고
	sum(case when ISNULL(_s.consignCustCode,'''') NOT IN (param.excludeSelf, param.excludeOther)
	  and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	  and _r.validYN = ''Y'' 
	  and _s.validYN = ''Y'' 
	  AND _s.workableYN = ''Y''
	  AND _s.storType in (''신품'',''중고'',''리퍼'') 	  
	  then _sr.stockQty else 0 end) AS qty3, --위탁업체,이지통상 제외 가용재고
    sum(case when _s.consignCustCode = ''ㅇ496''
	  and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' 
	  and _r.validYN = ''Y'' 
	  and _s.validYN = ''Y'' 
	  AND _s.workableYN = ''Y''
	  AND _s.storType in (''신품'',''중고'',''리퍼'') 	  
	  then _sr.stockQty else 0 end) AS qty5, --이지통상 가용재고
	STRING_AGG(case when _s.consignCustCode = param.consignCustCode then
        ''['' + _s.storageName + '']'' + _r.rackName + '' '' 
		+ CAST(_sr.stockQty AS VARCHAR(20)) end,
        '' * ''
    ) AS locaMemo
	  
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode
	CROSS JOIN (
        SELECT v.consignCustCode, v.excludeSelf, v.excludeOther
    ) AS param
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode
	  and _sr.stockQty <> 0
	  AND (@i__consignCustCode = '''' 
	    or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))	  
) ca

CROSS APPLY (
    SELECT SUM(
        CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
             WHEN pli.placeNo IS NULL THEN ISNULL(pi.gvQty,0)
        END
    ) AS orderQty
    FROM dbo.e_pcReqItem pi
    LEFT JOIN dbo.e_placeItem pli
      ON pi.gvComCode=pli.comCode 
	  AND pi.gvPlaceNo=pli.placeNo 
	  AND pi.gvPlaceSeq=pli.placeSeq
    WHERE pi.itemId = st.itemId
      AND pi.comCode = st.comCode
      AND ISNULL(pi.procStep,'''') NOT IN (''거부'',''접수'',''처리'')
) ord

OUTER APPLY (
select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''신품''
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''중고'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''리퍼'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''불량'' 
	  , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''신품''  
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan3 = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''신품'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  )  
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((isnull(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''중고'' 
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan3 = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''중고'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
		AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((isnull(_s.consignCustCode, '''') <> @i__logComCode  
	  AND _s.storType = ''리퍼'' 
	  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  
	  AND @n__isPan3 = ''N'') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = ''리퍼'' 
	    AND ISNULL(_s.rlStandByYN,''N'') = ''N'' 
		AND  ISNULL(_s.workableYN,''N'') = ''Y'' 
	    AND ISNULL(_s.ctStorageYN,''N'') = ''N'' 
		AND ISNULL(_r.validYN ,''N'') = ''Y''  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  
	  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  
	  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  
	  AND @n__4carComCode <> @i__logComCode  
	  and _s.consignCustCode = v.consignCustCode
	  and _sr.itemId = st.itemId
	GROUP BY _sr.itemId
) temp

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId AND ic.stdYM = REPLACE(st.uptYmd, ''-'','''')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
				 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 
				 ON st.comCode = ic2.comCode 
				   AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode=''1000'' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId 
  AND st.comCode = str.comCode
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
  AND cd1.mCode = ''1100'' 
  AND cd1.code = i.classCode 
  AND cd1.validYN = ''Y''

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode 
  AND osr.custCode = v.consignCustCode 
  AND osr.itemId = i.itemId 

'

IF @i__itemBulk <> '' 
BEGIN
	IF @i__bulkSrchType = 'itemId' 
		SET @sql2 = @sql2 + '	INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemId = bk.srchKeyword '

	IF @i__bulkSrchType = 'itemNo' 
		SET @sql2 = @sql2 + '	INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword '
END

IF @i__storageCode <> '' 
BEGIN
	SET @sql2 = @sql2 + '	JOIN #stockItem3 st2 ON st2.comCode = st.comCode AND st2.itemId = st.itemId '
END

--IF @i__logComCode NOT IN ('ㄱ000','ㄱ121', 'ㅇ413','ㅇ434','ㅇ436', 'ㅇ439', 'ㅋ127')
--IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode('ㄱ000'))
--위에서 이걸로 변경. 2024.10.16 hsg
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))  
BEGIN
	SET @sql2 = @sql2 + '	LEFT OUTER JOIN dbo.e_stockItemOuterNonDsp nd ON st.comCode = nd.comCode 
	                          AND st.itemId = nd.itemId '
END


SET @sql2 = @sql2 + N'
WHERE 1= 1 '

--IF @i__checkType <> '' AND @i__checkType <> 'ALL'
IF @i__checkType = 'OUT'
BEGIN
	SET @sql2 = @sql2 + N' AND 1=1 '
END
ELSE IF @i__checkType = 'ALL' --외부재고다중조회
BEGIN
	SET @sql2 = @sql2 + N' AND @n__4carComCode = st.comCode  '
END
ELSE
BEGIN
	SET @sql2 = @sql2 + N' AND st.comCode = @i__logComCode '
END


--IF @i__storCode <> ''
--SET @sqlW = @sqlW + N'   AND st.storCode= @i__storCode '

IF @i__itemId <> ''
SET @sql2 = @sql2 + N' AND st.itemId= @i__itemId '

IF @i__itemNo <> ''
SET @sql2 = @sql2 + N' AND i.itemNo LIKE ''%'+@i__itemNo+'%'' '	

--IF @i__storName <> ''
--SET @sqlW = @sqlW + N'  AND sg.storageName LIKE '''+@i__storName+'%'' '	

IF @i__makerCode <> ''
SET @sql2 = @sql2 + N' AND i.makerCode= @i__makerCode '

IF @i__itemName <> ''
SET @sql2 = @sql2 + N' AND (i.itemName LIKE ''%'+@i__itemName+'%'' OR i.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '

IF @i__classCode <> ''
SET @sql2 = @sql2 + N' AND i.classCode= @i__classCode '

IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
	SET @sql2 = @sql2 + N' AND st.uptYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__noRealYN = 'Y'
	SET @sql2 = @sql2 + N' AND  ISNULL(noRealYN, ''N'') <> ''Y'''
IF @i__qtyZeroYN = 'Y'
	SET @sql2 = @sql2 + N' AND ISNULL(str.qtyWorkable, 0) <> 0 AND ISNULL(st.stockQty, 0) <> 0 '

--위에서 이걸로 변경. 2024.10.16 hsg
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))   
BEGIN
	SET @sql2 = @sql2 + N' AND	nd.itemId IS NULL'
END

-------------------------------------------------------------------------------------------------------------------------------------------------------------ssy
-------------------------------------------------------------------------------------------------------------------------------------------------------------ssy

DECLARE @orderBy NVARCHAR(MAX) 

IF @i__itemBulk <> ''
    SET @orderBy = N'ORDER BY ISNULL(T.bk_idx, 999999), T.stockRackCode , T.saleRate DESC 
	                   , T.uptYmd DESC, T.uptHms DESC'
ELSE
    SET @orderBy = N'ORDER BY  T.stockRackCode , T.saleRate DESC, T.uptYmd DESC, T.uptHms DESC'

DECLARE @finalColumns NVARCHAR(MAX) = '
    T.idx,
    T.wrMemo,
    T.inspecMemo,
    T.regUserId,
    T.regYmd,
    T.regHms,
    T.uptUserId,
    T.uptYmd,
    T.uptHms,
    T.stockQty,
    T.workableQty,
    T.locaMemo,
    T.comCode,
    T.itemId,
    T.itemNo,
    T.carType,
    T.itemName,
    T.makerCode,
    T.brandCode,
    T.saleBrandCode,
    T.genuineYN,
    T.centerPrice,
    T.costPrice,
    T.salePrice,
    T.makerName,
    T.regUserName,
    T.uptUserName,
    T.qtyNew,
    T.qtyUsed,
    T.qtyRefur,
    T.qtyCtNew,
    T.qtyCtUsed,
    T.qtyCtRefur,
    T.qtyCtBad,
    T.outSalePrice,
    T.classCode,
    T.className,
    T.factoryNo,
    T.otherSaleType,
    T.saleRate, 
	T.stockRackCode
'

IF @i__itemBulk <> ''
BEGIN
    SET @finalColumns = @finalColumns + N', T.bk_idx '
END

SET @sql = N'
SELECT
' + @finalColumns + '
FROM (
    ' + @sql1 + N'
    UNION ALL
    ' + @sql2 + N'
) T

WHERE (T.qtyNew > 0 OR T.qtyCtNew > 0)

' + @orderBy

EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, 
                         @i__storCode varchar(20), @i__storName varchar(100)
						,@i__makerCode varchar(20) ,@i__classCode varchar(10) ,
						@i__sYmd1 varchar(10) ,@i__eYmd1 varchar(10) ,
						@i__checkType varchar(100), @i__outStorCode varchar(50), 
						@i__noRealYN varchar(1) 
						,@i__qtyZeroYN varchar(1) , @n__4carComCode  varchar(10) , 
						@n__salePriceType3 varchar(10) , @n__isPan3 varchar(10), 
						@i__consignCustCode varchar(20)
						,@i__logUserId varchar(50), @i__itemNo varchar(50)',
						@i__logComCode, @i__itemId, 
						@i__storCode ,@i__storName ,
						@i__makerCode ,@i__classCode, 
						@i__sYmd1 ,@i__eYmd1 ,
						@i__checkType ,@i__outStorCode ,
						@i__noRealYN,
						@i__qtyZeroYN,@n__4carComCode  , 
						@n__salePriceType3, @n__isPan3 , 
						@i__consignCustCode, 
						@i__logUserId ,@i__itemNo

IF @i__itemBulk <> ''
BEGIN

DROP TABLE #tbl_itemH

DROP TABLE #e_itemForStock

END

RETURN
