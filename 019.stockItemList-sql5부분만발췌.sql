DECLARE @ErpOperateComCode varchar(50) =  ''
SELECT @ErpOperateComCode= comCode from dbo.UF_ErpOperate('')
declare @i__logComCode varchar(100) = (SELECT top 1 comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate(''))))
        , @i__consignCustCode varchar(100) = '¤¡000'
DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'¼¾ÅÍ°¡') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('¤¡000')),'Y','N')
DECLARE @n__4carComCode varchar(10) = '¤¡121'
declare @sql5 nvarchar(max) = N''
declare @i__itemBulk varchar(20) = '2218200959'
declare @i__storageCode varchar(20) =''
declare @i__bulkSrchType varchar(20) ='itemNo'
declare @i__checkType varchar(20) = 'ALL'
,@i__storCode varchar(20) = ''
	,@i__itemId bigint = 0   --
    ,@i__itemNo varchar(50) = '2218200959'   
	,@i__itemName varchar(100) = ''
	,@i__makerCode varchar(100) = ''
	,@i__classCode varchar(10) = '' --Å¬·¡½ºÄÚµå
	,@i__storName varchar(100) = '' 	
	,@i__outStorCode varchar(50) = ''
	,@i__noRealYN varchar(1) = 'N'
	,@i__qtyZeroYN varchar(1) = 'N'
	,@sql nvarchar(max) = N''
	,@i__ymdIgnoreYN varchar(1) = 'N'
	,@i__sYmd1 varchar(10) = ''
	,@i__eYmd1 varchar(10) = ''
	,@i__logUserId varchar(20) = 'ssuyong'    --·Î±×ÀÎÇÑ »ç¿ëÀÚ¾ÆÀÌµð

DECLARE @n__salePriceType3 varchar(10) = (SELECT ISNULL(salePriceType,'¼¾ÅÍ°¡') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan3 VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('¤¡000')),'Y','N')
DECLARE @n__item_bulk_origin varchar(4000) = ''
SET @n__item_bulk_origin = @i__itemBulk

IF @i__itemBulk <> ''
BEGIN
	-- °Ë»ö¾î Ã³¸®
	DROP TABLE #tbl_itemH
	CREATE TABLE  #tbl_itemH (
		idx int identity primary key,
		srchKeyword varchar(100),
		srchKeyword_origin varchar(100)
		--,primary key(srchKeyword)
	)

	create nonclustered index TIX_itemH_srchKeyWord ON #tbl_itemH(srchKeyword)

    -- °Ë»ö¾î AND Á¶°Ç Ã³¸®
	INSERT INTO #tbl_itemH (srchKeyword, srchKeyword_origin) 		--SELECT val FROM dbo.[UDF_SPLIT](@i__item_bulk,'ÆR') WHERE val<>'' -- °ø¹éÀ¸·Î µé¾î¿Â°ÍÀº ´ë»ó¿¡¼­ Á¦¿Ü
		SELECT a.val, b.val
		FROM 
		 (SELECT idx, val FROM  dbo.UF_SPLIT(@i__itemBulk,'ÆR') where val <> 'undefined' AND val<>'') a 
		 JOIN (SELECT idx, val FROM  dbo.UF_SPLIT(@n__item_bulk_origin,'ÆR') where val <> 'undefined' AND val<>'') b ON a.idx = b.idx

	--¸ÖÆ¼°Ë»ö·Î±× ÀÔ·Â . 2024.03.28 hsg
	--IF @i__bulkSrchType = 'itemId' 
	/*INSERT INTO dbo.e_stockSrchLog(	comCode ,	userId, multiYN, itemId ,	itemNo, origin)
		SELECT @i__logComCode, @i__logUserId, 'Y'
			,CASE WHEN @i__bulkSrchType = 'itemId'  THEN srchKeyword ELSE '' END  
			,CASE WHEN @i__bulkSrchType = 'itemId'  THEN '' ELSE srchKeyword END  
			,srchKeyword_origin
		FROM #tbl_itemH
	*/
END

SET @sql5 = N'
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

IF @i__logComCode in (SELECT comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate(''))))
BEGIN
SET @sql5 = @sql5 + N'
	(
		SELECT STRING_AGG(''[''+_s.storageName+'']'' + _r.rackName + '' '' +cast(ISNULL( _sr.stockQty,'''') as varchar(100)), '' * '')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		and _sr.stockQty > 0
		AND _s.consignCustCode = ''¤·002''
	'
	--if @i__logUserId = 'zzz'
	--	SET @sql = @sql + N'	and _s.storageCode <> ''zzz'' '
	SET @sql5 = @sql5 + N'	) locaMemo ,  '
END
ELSE
BEGIN
SET @sql5 = @sql5 + N''''' locaMemo ,'
END

SET @sql5 = @sql5 + N' 
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
b.codeName AS makerName
,u1.userName regUserName ,u1.userName uptUserName

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) - ISNULL(temp.qtyNew,0) - ISNULL(ca3.qty3,0) - ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId AND 
			s.comCode = st.comCode  AND	
			((ISNULL(s.procStep,'''') <> ''°ÅºÎ'') AND 
			(((ISNULL(s.procStep,'''') <> ''Á¢¼ö'') AND (ISNULL(s.procStep,'''') <> ''Ã³¸®'')) ) )
		) 
		, 
		
		0))) AS qtyNew

,ISNULL(str.qtyUsedWorkable, 0)  - ISNULL(temp.qtyUsed,0) qtyUsed
,ISNULL(str.qtyRefurWorkable, 0) - ISNULL(temp.qtyRefur,0) qtyRefur
,ISNULL(temp.qtyCtNew,0) qtyCtNew
,ISNULL(temp.qtyCtUsed,0) qtyCtUsed
,ISNULL(temp.qtyCtRefur,0) qtyCtRefur
,ISNULL(temp.qtyCtBad,0) qtyCtBad 

,ROUND(i.centerPrice * (1 - ISNULL(osr.purRate / 100.0, 0)), 0) AS outSalePrice

,cd1.code classCode ,cd1.codeName className	,i.factoryNo

,''¤·002'' AS otherSaleType

,ISNULL(osr.purRate , 0) AS saleRate
'
IF @i__itemBulk <> ''
BEGIN
    SET @sql5 = @sql5 + N' , ISNULL(bk.idx, NULL) AS bk_idx '
END
SET @sql5 = @sql5 + N' 

,ca3.qty3 AS qty3

,''¤·002'' AS stockRackCode


FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	AND _s.consignCustCode = ''¤·002''
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = ''Y'' and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' and _s.validYN = ''Y'' AND _s.storType in (''½ÅÇ°'',''Áß°í'',''¸®ÆÛ'') AND _s.workableYN = ''Y''
	AND _s.consignCustCode = ''¤·002''
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = ''Y'' and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' and _s.validYN = ''Y'' AND _s.storType in (''½ÅÇ°'',''Áß°í'',''¸®ÆÛ'') AND _s.workableYN = ''Y''
	AND _s.consignCustCode <> ''¤·002''
	AND _s.consignCustCode <> ''¤·496''
    
) ca3

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = ''Y'' and ISNULL(_s.rlStandByYN,''N'') <> ''Y'' and _s.validYN = ''Y'' AND _s.storType in (''½ÅÇ°'',''Áß°í'',''¸®ÆÛ'') AND _s.workableYN = ''Y''
	AND _s.consignCustCode = ''¤·496''
    
) ca5

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode AND st.itemId = ic.itemId AND ic.stdYM = REPLACE(st.uptYmd, ''-'','''')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM FROM dbo.e_itemCost WHERE comCode = @i__logComCode GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode AND ic2.itemId = ic3.itemId AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode AND b.mCode=''1000'' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''½ÅÇ°'' , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''Áß°í'' , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''¸®ÆÛ'' , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = ''ºÒ·®'' , iif(_s.validYN =''Y'' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((_s.consignCustCode <> @i__logComCode  AND _s.storType = ''½ÅÇ°''  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  AND @n__isPan3 = ''N'') OR
	        (_s.consignCustCode = @i__logComCode  AND _s.storType = ''½ÅÇ°'' AND ISNULL(_s.rlStandByYN,''N'') = ''N'' AND  ISNULL(_s.workableYN,''N'') = ''Y'' AND ISNULL(_s.ctStorageYN,''N'') = ''N'' AND ISNULL(_r.validYN ,''N'') = ''Y''  )  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((_s.consignCustCode <> @i__logComCode  AND _s.storType = ''Áß°í''  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  AND @n__isPan3 = ''N'') OR
	        (_s.consignCustCode = @i__logComCode  AND _s.storType = ''Áß°í'' AND ISNULL(_s.rlStandByYN,''N'') = ''N'' AND  ISNULL(_s.workableYN,''N'') = ''Y'' AND ISNULL(_s.ctStorageYN,''N'') = ''N'' AND ISNULL(_r.validYN ,''N'') = ''Y''  ) , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((_s.consignCustCode <> @i__logComCode  AND _s.storType = ''¸®ÆÛ''  AND ISNULL(_s.consignViewYN,''N'') <> ''N''  AND @n__isPan3 = ''N'') OR
	        (_s.consignCustCode = @i__logComCode  AND _s.storType = ''¸®ÆÛ'' AND ISNULL(_s.rlStandByYN,''N'') = ''N'' AND  ISNULL(_s.workableYN,''N'') = ''Y'' AND ISNULL(_s.ctStorageYN,''N'') = ''N'' AND ISNULL(_r.validYN ,''N'') = ''Y''  ) , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  AND @n__4carComCode <> @i__logComCode  and _s.consignCustCode = ''¤²022''
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode AND cd1.mCode = ''1100'' AND cd1.code = i.classCode AND cd1.validYN = ''Y''

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode AND osr.custCode = ''¤·002'' AND osr.itemId = i.itemId 
'


IF @i__itemBulk <> '' 
BEGIN
	IF @i__bulkSrchType = 'itemId' 
		SET @sql5 = @sql5 + '	INNER JOIN (SELECT srchKeyWord, MIN(idx) idx FROM #tbl_itemH GROUP BY srchKeyWord) bk ON i.ItemId = bk.srchKeyword '

	IF @i__bulkSrchType = 'itemNo' 
		SET @sql5 = @sql5 + '	INNER JOIN (SELECT srchKeyWord, MIN(idx) idx FROM #tbl_itemH GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword '
END

IF @i__storageCode <> '' 
BEGIN
	SET @sql5 = @sql5 + '	JOIN #stockItem3 st2 ON st2.comCode = st.comCode AND st2.itemId = st.itemId '
END

--IF @i__logComCode NOT IN ('¤¡000','¤¡121', '¤·413','¤·434','¤·436', '¤·439', '¤»127')
--IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode('¤¡000'))
IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))   --À§¿¡¼­ ÀÌ°É·Î º¯°æ. 2024.10.16 hsg
BEGIN
	SET @sql5 = @sql5 + '	LEFT OUTER JOIN dbo.e_stockItemOuterNonDsp nd ON st.comCode = nd.comCode AND st.itemId = nd.itemId '
END


SET @sql5 = @sql5 + N'
WHERE 1= 1 '

--IF @i__checkType <> '' AND @i__checkType <> 'ALL'
IF @i__checkType = 'OUT'
BEGIN
	SET @sql5 = @sql5 + N' AND 1=1 '
END
ELSE IF @i__checkType = 'ALL' --¿ÜºÎÀç°í´ÙÁßÁ¶È¸
BEGIN
	SET @sql5 = @sql5 + N' AND @n__4carComCode = st.comCode  '
END
ELSE
BEGIN
	SET @sql5 = @sql5 + N' AND st.comCode = @i__logComCode '
END


--IF @i__storCode <> ''
--SET @sqlW = @sqlW + N'   AND st.storCode= @i__storCode '

IF @i__itemId <> ''
SET @sql5 = @sql5 + N' AND st.itemId= @i__itemId '

IF @i__itemNo <> ''
SET @sql5 = @sql5 + N' AND i.itemNo LIKE ''%'+@i__itemNo+'%'' '	

--IF @i__storName <> ''
--SET @sqlW = @sqlW + N'  AND sg.storageName LIKE '''+@i__storName+'%'' '	

IF @i__makerCode <> ''
SET @sql5 = @sql5 + N' AND i.makerCode= @i__makerCode '

IF @i__itemName <> ''
SET @sql5 = @sql5 + N' AND (i.itemName LIKE ''%'+@i__itemName+'%'' OR i.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '

IF @i__classCode <> ''
SET @sql5 = @sql5 + N' AND i.classCode= @i__classCode '

IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
	SET @sql5 = @sql5 + N' AND st.uptYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__noRealYN = 'Y'
	SET @sql5 = @sql5 + N' AND  ISNULL(noRealYN, ''N'') <> ''Y'''
IF @i__qtyZeroYN = 'Y'
	SET @sql5 = @sql5 + N' AND ISNULL(str.qtyWorkable, 0) <> 0 AND ISNULL(st.stockQty, 0) <> 0 '

IF @i__logComCode NOT IN (SELECT comCode FROM dbo.UF_GetChildComcode(@ErpOperateComCode))   --À§¿¡¼­ ÀÌ°É·Î º¯°æ. 2024.10.16 hsg
BEGIN
	SET @sql5 = @sql5 + N' AND	nd.itemId IS NULL'
END

DECLARE @orderBy NVARCHAR(MAX) 

IF @i__itemBulk <> ''
    SET @orderBy = N'ORDER BY ISNULL(T.bk_idx, 999999), T.stockRackCode , T.saleRate DESC , T.uptYmd DESC, T.uptHms DESC'
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
    ' + @sql5 + N'
) T

WHERE (T.qtyNew > 0 OR T.qtyCtNew > 0)

' + @orderBy

EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, @i__storCode varchar(20), @i__storName varchar(100)
						,@i__makerCode varchar(20) ,@i__classCode varchar(10) ,@i__sYmd1 varchar(10) ,@i__eYmd1 varchar(10) ,@i__checkType varchar(100), @i__outStorCode varchar(50), @i__noRealYN varchar(1) 
						,@i__qtyZeroYN varchar(1) , @n__4carComCode  varchar(10) , @n__salePriceType3 varchar(10) , @n__isPan3 varchar(10), @i__consignCustCode varchar(20)
						,@i__logUserId varchar(50), @i__itemNo varchar(50)',
						@i__logComCode, @i__itemId, @i__storCode ,@i__storName ,@i__makerCode ,@i__classCode, @i__sYmd1 ,@i__eYmd1 ,@i__checkType ,@i__outStorCode , @i__noRealYN,@i__qtyZeroYN,@n__4carComCode  , @n__salePriceType3 
						, @n__isPan3 , @i__consignCustCode, @i__logUserId ,@i__itemNo



