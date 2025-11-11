DECLARE @ErpOperateComCode varchar(50) =  ''
SELECT @ErpOperateComCode= comCode from dbo.UF_ErpOperate('')
declare @i__logComCode varchar(100) = (SELECT top 1 comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate(''))))
        , @i__consignCustCode varchar(100) = ''
DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')
DECLARE @n__4carComCode varchar(10) = 'ㄱ121'
DECLARE @n__salePriceType3 varchar(10) = (SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan3 VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')
declare @i__itemNo varchar(20) = ''
,@i__itemBulk varchar(MAX) = '테스트테스트힣13628650714'
,@i__bulkSrchType varchar(20)='itemNo'
,@i__logUserId varchar(20) = 'ssuyong'
,@i__storageCode varchar(20) = ''
,@i__qtyZeroYN varchar(20) = 'Y'
DECLARE @n__item_bulk_origin varchar(4000) = ''
SET @n__item_bulk_origin = @i__itemBulk

drop table #tbl_itemH
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

drop table #stockItem3
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
		WHERE sr.comCode = @i__logComCode AND   --조건추가 -- 2024.01.08 
		      r.storageCode = @i__storageCode AND sr.stockQty <> 0
END

select 
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
from (
SELECT --자사 재고
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
(
		SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' +
						cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
		  AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
		  AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
			or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		and _sr.stockQty > 0
		AND isnull(_s.consignCustCode,'') not in ('ㅇ499', 'ㅂ022', 'ㅇ479', 'ㅇ002', 'ㅇ496')
) locaMemo ,
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '') <> '' THEN i.itemName 
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

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0)  
    - ISNULL(ca3.qty3,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0) --주문중인 상태의 개수
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			  AND s.comCode = st.comCode  
			  AND ISNULL(s.procStep,'') not in ('거부', '접수', '처리')
		) 
		,
		0))) AS qtyNew

,ISNULL(str.qtyUsedWorkable, 0)  - ISNULL(temp.qtyUsed,0) qtyUsed
,ISNULL(str.qtyRefurWorkable, 0) - ISNULL(temp.qtyRefur,0) qtyRefur
,ISNULL(temp.qtyCtNew,0) qtyCtNew
,ISNULL(temp.qtyCtUsed,0) qtyCtUsed
,ISNULL(temp.qtyCtRefur,0) qtyCtRefur
,ISNULL(temp.qtyCtBad,0) qtyCtBad 

, CASE 
    WHEN @n__salePriceType3 = '매입가' THEN 
        ROUND(i.centerPrice * dbo.UF_cCustPerItemRate(@n__4carComCode, @i__logComCode, st.itemId, 1), 0) *
        (1 + dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1))
    ELSE 
        i.centerPrice * (1 - dbo.UF_sCustPerItemRate(
		                       @n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1))
END AS outSalePrice

,cd1.code classCode ,cd1.codeName className	,i.factoryNo

,'' AS otherSaleType

, CASE 
    WHEN @n__salePriceType3 = '매입가' THEN 
        dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1)*100
    ELSE 
        dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType3, st.itemId, 1)*100
END AS saleRate
 ,ca3.qty3 AS qty3

,'' AS stockRackCode


FROM dbo.e_stockItem st 

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1  --5개위탁업체 제외 전체 수량(순수 자사 총재고)
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	AND isnull(_s.consignCustCode,'') not in ('ㅇ499', 'ㅂ022', 'ㅇ496', 'ㅇ479', 'ㅇ002')	
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2 --5개위탁업체 제외 사용가능수량(순수 자사 가용재고)
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	AND isnull(_s.consignCustCode,'') not in ('ㅇ499', 'ㅂ022', 'ㅇ496', 'ㅇ479', 'ㅇ002')
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3 --5개위탁업체 사용가능수량(위탁 재고)
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	AND _s.consignCustCode in ('ㅇ499', 'ㅂ022', 'ㅇ496', 'ㅇ479', 'ㅇ002')
    
) ca3

LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId AND ic.stdYM = REPLACE(st.uptYmd, '-','')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
                 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode AND b.mCode='1000' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '불량' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  AND _s.storType = '신품'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  )  
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  AND _s.storType = '중고'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  AND _s.storType = '리퍼' 
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' 
	    AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  AND @n__4carComCode <> @i__logComCode  
	  and isnull(_s.consignCustCode,'') not in ('ㅇ499', 'ㅂ022', 'ㅇ496', 'ㅇ479', 'ㅇ002')
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode
  AND cd1.mCode = '1100' AND cd1.code = i.classCode AND cd1.validYN = 'Y'
INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword
--JOIN #stockItem3 st2 ON st2.comCode = st.comCode AND st2.itemId = st.itemId
LEFT OUTER JOIN dbo.e_stockItemOuterNonDsp nd ON st.comCode = nd.comCode 
                              AND st.itemId = nd.itemId
WHERE 1= 1
AND @n__4carComCode = st.comCode
AND i.itemNo LIKE '%'+@i__itemNo+'%'	


union all

SELECT --아우토 재고
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
(
		SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' 
		         +cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
		    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		  and _sr.stockQty > 0
		  AND _s.consignCustCode = 'ㅇ499' --아우토
) locaMemo ,
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '') <> '' THEN i.itemName 
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

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0) 
    - ISNULL(ca3.qty3,0) 
	- ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			  AND s.comCode = st.comCode  
			  AND ISNULL(s.procStep,'') not in ('거부', '접수', '처리')
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

,'ㅇ499' AS otherSaleType

,ISNULL(osr.purRate , 0) AS saleRate
 ,ca3.qty3 AS qty3

,'ㅇ499' AS stockRackCode


FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1 --아우토 총재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  AND _s.consignCustCode = 'ㅇ499'
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2 --아우토 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
	     or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	  AND _s.consignCustCode = 'ㅇ499'
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3 --아우토,이지통상 제외 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	  AND isnull(_s.consignCustCode,'') <> 'ㅇ499'
	  AND isnull(_s.consignCustCode,'') <> 'ㅇ496'
    
) ca3

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5 --이지통상 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	  AND _s.consignCustCode = 'ㅇ496'
    
) ca5

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId AND ic.stdYM = REPLACE(st.uptYmd, '-','')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
				 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 
				 ON st.comCode = ic2.comCode AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode='1000' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId 
  AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '불량' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  AND _s.storType = '신품'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  )  
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '중고'  AND ISNULL(_s.consignViewYN,'N') <> 'N' AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  AND _s.storType = '리퍼'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  AND @n__4carComCode <> @i__logComCode  
	  and _s.consignCustCode = 'ㅇ499'
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
  AND cd1.mCode = '1100' 
  AND cd1.code = i.classCode 
  AND cd1.validYN = 'Y'

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode 
  AND osr.custCode = 'ㅇ499' 
  AND osr.itemId = i.itemId 
INNER JOIN (SELECT srchKeyWord, MIN(idx) idx FROM #tbl_itemH GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword
  AND @n__4carComCode = st.comCode
  AND i.itemNo LIKE '%'+@i__itemNo+'%'
  
  
union all

SELECT --VAG 재고
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
(
		SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' 
		  +cast(ISNULL( _sr.stockQty,'''') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
		  AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
		  AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId 
		  and _sr.comCode = st.comCode 
		  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
		    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		  and _sr.stockQty > 0
		  AND _s.consignCustCode = 'ㅂ022'
) locaMemo ,
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '') <> '' THEN i.itemName 
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

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0) 
	- ISNULL(ca3.qty3,0) 
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
			  AND ISNULL(s.procStep,'') not in ('거부', '접수', '처리')
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

,'ㅂ022' AS otherSaleType

,ISNULL(osr.purRate , 0) AS saleRate
,ca3.qty3 AS qty3

,'ㅂ022' AS stockRackCode
FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1 --VAG 총 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode
	 or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	AND _s.consignCustCode = 'ㅂ022'
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2 --VAG 가용 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' AND _s.storType in ('신품','중고','리퍼') 
	AND _s.workableYN = 'Y'
	AND _s.consignCustCode = 'ㅂ022'
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3 --VAG,이지통상제외 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' 
	and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' 
	AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	AND isnull(_s.consignCustCode, '') <> 'ㅂ022'
	AND isnull(_s.consignCustCode, '') <> 'ㅇ496'
    
) ca3

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5 --이지통상 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' 
	and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' 
	AND _s.storType in ('신품','중고','리퍼') 
	AND _s.workableYN = 'Y'
	AND _s.consignCustCode = 'ㅇ496'
    
) ca5

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId 
  AND ic.stdYM = REPLACE(st.uptYmd, '-','')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
				 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode 
				   AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId 
  AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode='1000' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId 
  AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '불량' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '신품'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '신품' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  )  
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '중고'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '중고' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '리퍼'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '리퍼' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  
	  AND @n__4carComCode <> @i__logComCode  
	  and _s.consignCustCode = 'ㅂ022'
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
  AND cd1.mCode = '1100' 
  AND cd1.code = i.classCode AND 
  cd1.validYN = 'Y'

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode 
  AND osr.custCode = 'ㅂ022' 
  AND osr.itemId = i.itemId
INNER JOIN (SELECT srchKeyWord, MIN(idx) idx FROM #tbl_itemH 
		                                    GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword
WHERE 1= 1 
AND @n__4carComCode = st.comCode
AND i.itemNo LIKE '%'+@i__itemNo+'%'

union all

SELECT --인터카스 재고
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
(
		SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' 
		  +cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		AND (@i__consignCustCode = '' 
		  or _s.consignCustCode = @i__consignCustCode 
		  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		and _sr.stockQty > 0
		AND _s.consignCustCode = 'ㅇ479'
) locaMemo,
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '') <> '' THEN i.itemName 
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

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0) 
	- ISNULL(ca3.qty3,0) 
	- ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			AND s.comCode = st.comCode
			AND ISNULL(s.procStep,'') not in ('거부', '접수', '처리')
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

,'ㅇ479' AS otherSaleType

,ISNULL(osr.purRate , 0) AS saleRate

,ca3.qty3 AS qty3

,'ㅇ479' AS stockRackCode


FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1 --인터카스 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	AND _s.consignCustCode = 'ㅇ479'
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2 --인터카스 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' 
	and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' 
	AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	AND _s.consignCustCode = 'ㅇ479'
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3 --인터카스,이지통상 제외 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	AND (@i__consignCustCode = '' 
	  or _s.consignCustCode = @i__consignCustCode 
	  or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' 
	and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' 
	AND _s.storType in ('신품','중고','리퍼') 
	AND _s.workableYN = 'Y'
	AND isnull(_s.consignCustCode,'') <> 'ㅇ479'
	AND isnull(_s.consignCustCode,'') <> 'ㅇ496'
    
) ca3

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5 --이지통상 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' 
	    or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null 
	    AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' 
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') 
	  AND _s.workableYN = 'Y'
	  AND _s.consignCustCode = 'ㅇ496'
    
) ca5

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId 
  AND ic.stdYM = REPLACE(st.uptYmd, '-','')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
				 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode 
				   AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId 
  AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode='1000' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId 
  AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' 
	, iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	, iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	, iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '불량' 
	, iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '신품'
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '신품' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  )  
	, ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '중고'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '중고' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	, ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '리퍼'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '리퍼' 
	    AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	, ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  
	  AND @n__4carComCode <> @i__logComCode  
	  and _s.consignCustCode = 'ㅇ479'
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
  AND cd1.mCode = '1100' 
  AND cd1.code = i.classCode 
  AND cd1.validYN = 'Y'

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode 
  AND osr.custCode = 'ㅇ479' 
  AND osr.itemId = i.itemId 
INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword
  AND @n__4carComCode = st.comCode
  AND i.itemNo LIKE '%'+@i__itemNo+'%'	
  
union all

SELECT --엠케이 재고
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
(
		SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' 
		  +cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
		    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		  and _sr.stockQty > 0
		  AND _s.consignCustCode = 'ㅇ002'
) locaMemo ,
st.comCode,
st.itemId,
i.itemNo,
i.carType,
CASE WHEN ISNULL(i.itemName, '') <> '' THEN i.itemName 
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

,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
    - ISNULL(temp.qtyNew,0) 
	- ISNULL(ca3.qty3,0) 
	- ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
			  AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId 
			  AND s.comCode = st.comCode  
			  AND ISNULL(s.procStep,'') not in ('거부', '접수', '처리')
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

,'ㅇ002' AS otherSaleType

,ISNULL(osr.purRate , 0) AS saleRate
,ca3.qty3 AS qty3

,'ㅇ002' AS stockRackCode


FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

CROSS APPLY (
	select sum(_sr.stockQty) AS qty1 --엠케이 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' 
	    or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  AND _s.consignCustCode = 'ㅇ002'
    
) ca1

CROSS APPLY (
	select sum(_sr.stockQty) AS qty2 --엠케이 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' 
	    or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' 
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') 
	  AND _s.workableYN = 'Y'
	  AND _s.consignCustCode = 'ㅇ002'
    
) ca2

CROSS APPLY (
	select sum(_sr.stockQty) AS qty3 --엠케이,이지통상 제외 가용재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' 
	    or _s.consignCustCode = @i__consignCustCode 
	    or (_s.consignCustCode is null 
		AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' 
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') 
	  AND _s.workableYN = 'Y'
	  AND isnull(_s.consignCustCode,'') <> 'ㅇ002'
	  AND isnull(_s.consignCustCode,'') <> 'ㅇ496'
    
) ca3

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5 --이지통상 재고
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId 
	  and _sr.comCode = st.comCode 
	  AND (@i__consignCustCode = '' 
	    or _s.consignCustCode = @i__consignCustCode 
		or (_s.consignCustCode is null 
		  AND _s.comCode = @i__consignCustCode))
	  and _r.validYN = 'Y' 
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.storType in ('신품','중고','리퍼') 
	  AND _s.workableYN = 'Y'
	  AND _s.consignCustCode = 'ㅇ496'
    
) ca5

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode 
  AND st.itemId = ic.itemId 
  AND ic.stdYM = REPLACE(st.uptYmd, '-','')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM 
                 FROM dbo.e_itemCost 
				 WHERE comCode = @i__logComCode 
				 GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode 
				   AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode 
  AND ic2.itemId = ic3.itemId 
  AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode 
  AND b.mCode='1000' 
  AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode 
  AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode 
  AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId
  AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode AND _s.storType = '신품' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '불량' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '신품'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '신품' 
		AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND  ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  )  
	  , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '중고'
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N')
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '중고' 
		AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode  
	  AND _s.storType = '리퍼'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N'  
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode  
	    AND _s.storType = '리퍼' 
		AND ISNULL(_s.rlStandByYN,'N') = 'N' 
		AND ISNULL(_s.workableYN,'N') = 'Y' 
		AND ISNULL(_s.ctStorageYN,'N') = 'N' 
		AND ISNULL(_r.validYN ,'N') = 'Y'  ) 
	  , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  
	  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  
	  AND _s.storageCode = _r.storageCode 
	where @n__4carComCode = _sr.comCode  
	  AND @n__4carComCode <> @i__logComCode  
	  and _s.consignCustCode = 'ㅇ002'
	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode 
  AND cd1.mCode = '1100' 
  AND cd1.code = i.classCode 
  AND cd1.validYN = 'Y'

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode 
  AND osr.custCode = 'ㅇ002' 
  AND osr.itemId = i.itemId 
INNER JOIN (SELECT srchKeyWord, MIN(idx) idx 
		                                    FROM #tbl_itemH 
											GROUP BY srchKeyWord) bk ON i.ItemNo = bk.srchKeyword
  AND @n__4carComCode = st.comCode
  AND i.itemNo LIKE '%'+@i__itemNo+'%'	
) T
--WHERE (T.qtyNew > 0 OR T.qtyCtNew > 0)

--ORDER BY  T.stockRackCode , T.saleRate DESC, T.uptYmd DESC, T.uptHms DESC

