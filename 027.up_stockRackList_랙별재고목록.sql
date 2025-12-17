USE [panErp]
GO
/****** Object:  StoredProcedure [dbo].[up_stockRackList]    Script Date: 2025-12-17 오전 11:34:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROC [dbo].[up_stockRackList]
/***************************************************************
설명 : 랙별 재고 목록
       
작성 : 2023.05.10 hsg  - LIST_QRY
	   2023.06.07 hsg - e_item join 시 a.comCode = i.comCode AND  제거. 공유품목이 노출안됨
	   2023.07.27 hsg - 수량이 0 이 아닌것만 조회. 마이너스도 나와야 함. 
	                  - 최종수정자 나오는 오류 수정. 최초등록자로 나오고 있음. modified 업데이트처리(소스수정은 없음):수정 시 modified가 아닌 created로 업데이트하는 문제있었음    
       2023.09.20 hsg  - costPrice 구하는 방식 변경 
	   2024.01.12 supi - 다중조회 기능 추가
	   2024.04.17 supi - 랙별재고목록 조회시 바코드 정보에 담길 재고의 위탁소유주정보 반환 추가
	   2024.07.26 supi - 제조사명 , 구분, 공장품번 반환 추가
ex)

select * from panErp.dbo._SPLOG where sp like '%up_stockRackList%' order by created desc

panErp.dbo.up_stockRackList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2023-06-27',      @i__eYmd1='2023-07-27',      @i__sYmd2='',    @i__eYmd2='',        @i__rackCode='',    @i__rackName='',    @i__storCode='',    @i__storName='',      @i__itemId=0,    @i__itemNo='',    @i__itemName='',      @i__logComCode='ㅇ413',    @i__logUserId='임파츠'

select * from e_stockRack where comCode <> 'ㄱ000' AND created>modified

select * into e_stockRack_hsgTEMP from e_stockRack
begin tran
	update  e_stockRack set  modified = created where comCode <> 'ㄱ000' AND created>modified

rollback tran
commit tran 
select @@trancount

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

	,@i__rackCode varchar(20) = ''
	,@i__rackName varchar(100) = ''
	,@i__storCode varchar(20) = ''
	,@i__storName varchar(100) = ''

	,@i__itemId bigint = 0   --
    ,@i__itemNo varchar(50) = ''   
	,@i__itemName varchar(100) = ''
	,@i__bulkSrchType varchar(20) =''
	,@i__itemBulk varchar(MAX) = ''

AS

SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--로그--------------------------
INSERT INTO panErp.dbo._SPLOG( sp,params)
	VALUES('panErp.dbo.up_stockRackList', 
	'@i__workingType='''+ISNULL(@i__workingType,'')+''',
	 @i__page='+cast(ISNULL(@i__page,0) as varchar(100))+',
	 @i__qty='+cast(ISNULL(@i__qty,0) as varchar(100))+',	 
	 @i__orderBy='''+ISNULL(@i__orderBy,'')+''',
	 @i__sYmd1='''+ISNULL(@i__sYmd1,'')+''',	 
	 @i__eYmd1='''+ISNULL(@i__eYmd1,'')+''',	 
	 @i__sYmd2='''+ISNULL(@i__sYmd2,'')+''',
	 @i__eYmd2='''+ISNULL(@i__eYmd2,'')+''',
	 
	 @i__rackCode='''+cast(ISNULL(@i__rackCode,'') as varchar(100))+''',
	 @i__rackName='''+cast(ISNULL(@i__rackName,'') as varchar(100))+''',
	 @i__storCode='''+cast(ISNULL(@i__storCode,'') as varchar(100))+''',
	 @i__storName='''+cast(ISNULL(@i__storName,'') as varchar(100))+''',

	 @i__itemId='+cast(ISNULL(@i__itemId,'0') as varchar(100))+',
	 @i__itemNo='''+cast(ISNULL(@i__itemNo,'') as varchar(100))+''',
	 @i__itemName='''+cast(ISNULL(@i__itemName,'') as varchar(100))+''',
	 @i__bulkSrchType='''+cast(ISNULL(@i__bulkSrchType,'') as varchar(100))+''',
	 @i__itemBulk='''+cast(ISNULL(@i__itemBulk,'') as varchar(100))+''',

	 @i__logComCode='''+cast(ISNULL(@i__logComCode,'') as varchar(100))+''',
	 @i__logUserId='''+cast(ISNULL(@i__logUserId,'') as varchar(100))+''''
)
---------------------------------

--DECLARE @subPage INT
--IF @i__page = 0 
--	SET @subPage = 1
--ELSE
--	SET @subPage = (@i__page - 1) * @i__qty

DECLARE @n__sYmd1 varchar(30),  @n__eYmd1 varchar(30)
SET @n__sYmd1 = @i__sYmd1 + ' 00:00:00.000'
SET @n__eYmd1 = @i__eYmd1 + ' 23:59:59.997'


SET	@i__itemId = ISNULL(@i__itemId, 0) 

DECLARE @sql nvarchar(max), @sqlS nvarchar(max) = N'' , @sqlF nvarchar(max) = N'' , @sqlW nvarchar(max) = N'' 
SET @sql = N''

DECLARE @n__item_bulk_origin varchar(4000) = ''
SET @n__item_bulk_origin = @i__itemBulk

IF @i__bulkSrchType <> '' AND @i__itemBulk <> ''  --20210305 에 위의 것에서 변경. 벌크조회가 품명이 빠지고 품번과 브랜드품번이 추가되서 모든 조건일때 이걸타는 걸로 변경
BEGIN

    SET @i__itemBulk= Replace (@i__itemBulk, char(13)+char(10), '')   --엔터
	SET @i__itemBulk= Replace (@i__itemBulk, char(13), '')   --엔터
	SET @i__itemBulk= Replace (@i__itemBulk, char(10), '')   --엔터
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
	INSERT INTO #tbl_itemH (srchKeyword, srchKeyword_origin) 		--SELECT val FROM dbo.[UDF_SPLIT](@i__item_bulk,'힣') WHERE val<>'' -- 공백으로 들어온것은 대상에서 제외
		SELECT a.val, b.val
		FROM 
		 (SELECT idx, val FROM  dbo.UF_SPLIT(@i__itemBulk,'힣') where val <> 'undefined' AND val<>'') a 
		 JOIN (SELECT idx, val FROM  dbo.UF_SPLIT(@n__item_bulk_origin,'힣') where val <> 'undefined' AND val<>'') b ON a.idx = b.idx

END

DECLARE @iGH int =1, @maxiGH int =0, @n__srchKeywordGH varchar(100)= ''


IF @i__workingType = 'LIST' 
	GOTO LIST_QRY   -- 

RETURN
/*************************************************************************************************/
LIST_QRY: 


SET @sqlS = N'
SELECT
	st.itemId ,
	st.rackCode ,
	st.stockQty ,
	st.regUserId ,
	st.created ,
	st.uptUserId ,
	st.modified,
	--CONVERT(varchar, st.modified, 121) modified ,

	rack.rackName,
	sg.storageCode storCode,
	sg.storageName storName,

	i.itemNo ,  --품번
	i.carType , --차종
	CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
	  ELSE i.itemNameEn END itemName,
	i.makerCode ,				--제조사코드
	i.brandCode,
	i.saleBrandCode,
	i.genuineYN , --정품여부

	i.centerPrice ,
	--ic.cost costPrice,  
	ISNULL(ISNULL(ic.cost, ic3.cost),0) costPrice,
	i.salePrice 
  
	,b.codeName AS makerName
	,u1.userName regUserName
	,u2.userName uptUserName
	,ISNULL(sg.consignCustCode , '''') storConsignCustCode
	,b2.codeName className 
	,IIF(i.classCode = ''GN'','''', i.factoryNo) factoryNo
'

SET @sqlF = N'
FROM dbo.e_stockRack st 
JOIN dbo.e_rack rack ON st.comCode = rack.comCode AND st.rackCode = rack.rackCode
JOIN dbo.e_storage sg ON st.comCode = sg.comCode 
  AND rack.storageCode = sg.storageCode 
  --and sg.consignCustCode <> ''ㅇ496''
LEFT OUTER JOIN dbo.e_item i ON st.itemId = i.itemId
--LEFT OUTER JOIN dbo.e_itemCost ic ON i.comCode = ic.comCode AND i.itemId = ic.itemId
LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode AND st.itemId = ic.itemId AND ic.stdYM = REPLACE(CONVERT(CHAR(7),st.created ,121), ''-'','''')  --창고사용월의 원가
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM FROM dbo.e_itemCost GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode AND ic2.itemId = ic3.itemId AND ic2.stdYM = ic3.stdYM   --마지막월의 원가

LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode AND b.mCode=''1000'' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.e_code b2 ON st.comCode = b2.comCode AND b2.mCode=''1100'' AND b2.code = i.classCode 

'

IF @i__itemBulk <> '' 
BEGIN
	IF @i__bulkSrchType = 'itemId' 
		SET @sqlF = @sqlF + '	LEFT OUTER JOIN (SELECT srchKeyWord, MIN(idx) idx FROM #tbl_itemH GROUP BY srchKeyWord) bk ON i.ItemId = bk.srchKeyword '

	IF @i__bulkSrchType = 'itemNO' 
		SET @sqlF = @sqlF + '	LEFT OUTER JOIN (SELECT srchKeyWord, MIN(idx) idx FROM #tbl_itemH GROUP BY srchKeyWord) bk ON i.ItemNO = bk.srchKeyword '
END

SET @sqlW = N'
WHERE 1= 1 AND st.comCode = @i__logComCode '
SET @sqlW = @sqlW + N' AND st.stockQty <> 0'  --0이 아닌건만 조회


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

BEGIN
	IF @i__rackCode <> ''
		SET @sqlW = @sqlW + N' AND st.rackCode= @i__rackCode '
	IF @i__rackName <> ''
		SET @sqlW = @sqlW + N' AND rack.rackName LIKE '''+@i__rackName+'%'' '	

	IF @i__storCode <> ''
		SET @sqlW = @sqlW + N' AND sg.storageCode= @i__storCode '
	IF @i__storName <> ''
		SET @sqlW = @sqlW + N' AND sg.storageName LIKE '''+@i__storName+'%'' '	

	IF @i__itemId <> ''
	SET @sqlW = @sqlW + N'   AND st.itemId= @i__itemId '
	IF @i__itemNo <> ''
		SET @sqlW = @sqlW + N'  AND i.itemNo LIKE '''+@i__itemNo+'%'' '	
	IF @i__itemName <> ''
		SET @sqlW = @sqlW + ' AND (i.itemName LIKE ''%'+@i__itemName+'%'' OR i.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '

	IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
		SET @sqlW = @sqlW + ' AND st.modified BETWEEN @n__sYmd1 AND @n__eYmd1 '


	SET @sqlW = @sqlW + N' ORDER BY st.modified DESC'

END

print @sqlS
print @sqlF
print @sqlW

SET @sql = @sqlS + @sqlF + @sqlW

EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, @i__storCode varchar(30), @i__rackCode varchar(30)
						,@n__sYmd1 varchar(30) ,@n__eYmd1 varchar(30) ',
						@i__logComCode, @i__itemId, @i__storCode ,@i__rackCode , @n__sYmd1 ,@n__eYmd1

RETURN
/*************************************************************************************************/

