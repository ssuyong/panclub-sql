DECLARE @ErpOperateComCode varchar(50) =  ''
SELECT @ErpOperateComCode= comCode from dbo.UF_ErpOperate('')
declare @i__logComCode varchar(100) = (SELECT top 1 comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate(''))))
        , @i__consignCustCode varchar(100) = 'ㄱ000'
DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')
DECLARE @n__4carComCode varchar(10) = 'ㄱ121'

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
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	
	and _s.consignCustCode <> 'ㅇ496' -- select * from e_cust where custCode = 'ㅇ496'
) stockQty ,
(
	select sum(_sr.stockQty) 
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' and _s.validYN = 'Y' AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	
	and _s.consignCustCode <> 'ㅇ496'
	
)  workableQty,

	(
		SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' +cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode and _s.consignCustCode <> 'ㅇ496'
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		and _sr.stockQty > 0

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
,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) - ISNULL(temp.qtyNew,0)  - ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId AND 
			s.comCode = st.comCode  AND	
			((ISNULL(s.procStep,'') <> '거부') AND 
			(((ISNULL(s.procStep,'') <> '접수') AND (ISNULL(s.procStep,'') <> '처리')) ) )
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
            WHEN @n__salePriceType = '매입가' THEN 
                ROUND(i.centerPrice * dbo.UF_cCustPerItemRate(@n__4carComCode, @i__logComCode, st.itemId, 1), 0) *
                (1 + dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1))
            ELSE 
                i.centerPrice * (1 - dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1))
        END
    WHEN stockCheck.has499 = 1 THEN
        ROUND(i.centerPrice * (1 - ISNULL(osr.purRate / 100.0, 0)), 0)
    ELSE
        CASE 
            WHEN @n__salePriceType = '매입가' THEN 
                ROUND(i.centerPrice * dbo.UF_cCustPerItemRate(@n__4carComCode, @i__logComCode, st.itemId, 1), 0) *
                (1 + dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1))
            ELSE 
                i.centerPrice * (1 - dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1))
        END
END AS outSalePrice

,cd1.code classCode ,cd1.codeName className	,i.factoryNo

,IIF(stockCheck.has499 = 1 AND stockCheck.hasNot499 = 0, 'ㅇ499', '') AS otherSaleType

,CASE
    WHEN stockCheck.hasNot499 = 1 THEN
        CASE 
            WHEN @n__salePriceType = '매입가' THEN 
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1)*100
            ELSE 
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1)*100
        END
    WHEN stockCheck.has499 = 1 THEN
       ISNULL(osr.purRate , 0)
    ELSE
        CASE 
            WHEN @n__salePriceType = '매입가' THEN            
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1)*100
            ELSE 
                dbo.UF_sCustPerItemRate(@n__4carComCode, @i__logComCode, @n__salePriceType, st.itemId, 1)*100
        END
END AS saleRate

,stockCheck.hasNot499

,stockCheck.has499

FROM dbo.e_stockItem st 
LEFT JOIN dbo.e_item i ON st.itemId = i.itemId

LEFT OUTER JOIN dbo.e_itemCost ic ON st.comCode = ic.comCode AND st.itemId = ic.itemId AND ic.stdYM = REPLACE(st.uptYmd, '-','')
LEFT OUTER JOIN (SELECT comCode, itemId, MAX(stdYM) stdYM FROM dbo.e_itemCost WHERE comCode = @i__logComCode GROUP BY comCode, itemId) ic2 ON st.comCode = ic2.comCode AND st.itemId = ic2.itemId 
LEFT OUTER JOIN dbo.e_itemCost ic3 ON ic2.comCode = ic3.comCode AND ic2.itemId = ic3.itemId AND ic2.stdYM = ic3.stdYM
LEFT OUTER JOIN dbo.e_code b ON st.comCode = b.comCode AND b.mCode='1000' AND b.code = i.makerCode
LEFT OUTER JOIN dbo.e_user u1 ON st.comCode = u1.comCode AND st.regUserId = u1.userId
LEFT OUTER JOIN dbo.e_user u2 ON st.comCode = u2.comCode AND st.uptUserId = u2.userId
LEFT OUTER JOIN dbo.vw_storType_stock str ON i.itemId = str.itemId AND st.comCode = str.comCode
LEFT JOIN (select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  AND _s.storType = '불량' , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((_s.consignCustCode <> @i__logComCode  AND _s.storType = '신품'  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan = 'N') OR
	        (_s.consignCustCode = @i__logComCode  AND _s.storType = '신품' AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) , ISNULL(stockQty,0),0)) qtyNew,
	sum(IIF((_s.consignCustCode <> @i__logComCode  AND _s.storType = '중고'  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan = 'N') OR
	        (_s.consignCustCode = @i__logComCode  AND _s.storType = '중고' AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) , ISNULL(stockQty,0),0)) qtyUsed,
	sum(IIF((_s.consignCustCode <> @i__logComCode  AND _s.storType = '리퍼'  AND ISNULL(_s.consignViewYN,'N') <> 'N'  AND @n__isPan = 'N') OR
	        (_s.consignCustCode = @i__logComCode  AND _s.storType = '리퍼' AND ISNULL(_s.rlStandByYN,'N') = 'N' AND  ISNULL(_s.workableYN,'N') = 'Y' AND ISNULL(_s.ctStorageYN,'N') = 'N' AND ISNULL(_r.validYN ,'N') = 'Y'  ) , ISNULL(stockQty,0),0)) qtyRefur
	from dbo.e_stockRack _sr  
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  AND _s.storageCode = _r.storageCode 
	where    @n__4carComCode = _sr.comCode  AND @n__4carComCode <> @i__logComCode  
	
	
	and _s.consignCustCode <> 'ㅇ496'
	

	GROUP BY _sr.itemId ) temp ON temp.itemId = st.itemId 
LEFT JOIN dbo.e_code cd1 ON cd1.comCode = i.comCode AND cd1.mCode = '1100' AND cd1.code = i.classCode AND cd1.validYN = 'Y'

CROSS APPLY (
	select sum(_sr.stockQty) AS qty5
	from dbo.e_stockRack _sr
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' and _s.validYN = 'Y' AND _s.storType in ('신품','중고','리퍼') AND _s.workableYN = 'Y'
	AND _s.consignCustCode = 'ㅇ496'
    
) ca5

OUTER APPLY (
    SELECT
        MAX(CASE 
            WHEN s_s.consignCustCode = 'ㅇ499' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS has499,

        MAX(CASE 
            WHEN s_s.consignCustCode != 'ㅇ499' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS hasNot499
    FROM dbo.e_storage s_s
    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode
    JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
    WHERE s_s.comCode = @n__4carComCode 
      AND s_sr.itemId = i.itemId
) stockCheck

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = @n__4carComCode AND osr.custCode = 'ㅇ499' AND osr.itemId = i.itemId 
WHERE 1= 1 and

dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) - ISNULL(temp.qtyNew,0)  - ISNULL(ca5.qty5,0)
	- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId AND 
			s.comCode = st.comCode  AND	
			((ISNULL(s.procStep,'') <> '거부') AND 
			(((ISNULL(s.procStep,'') <> '접수') AND (ISNULL(s.procStep,'') <> '처리')) ) )
		),0))) > 0

ORDER BY st.uptYmd DESC, st.UptHms DESC

