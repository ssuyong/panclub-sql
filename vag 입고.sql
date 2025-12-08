select * from dbo.vag_1203--7544

select * --8104
FROM dbo.e_stockRack
WHERE rackCode = '644'
  AND comCode = 'ㄱ121' ;

select @@TRANCOUNT

BEGIN TRAN

DELETE FROM dbo.e_stockRack
WHERE rackCode = '644'
  AND comCode = 'ㄱ121'   

-- 신규 INSERT
INSERT INTO dbo.e_stockRack (--6835
    comCode,
    itemId,
    rackCode,
    stockQty,
    regUserId,
    created,
    uptUserId,
    modified
)
SELECT
    'ㄱ121' AS comCode,
    ei.itemId,
    '644' AS rackCode,
    SUM(v.qty) AS stockQty,
    'ssuyong' AS regUserId,
    GETDATE() AS created,
    'ssuyong' AS uptUserId,
    GETDATE() AS modified
FROM dbo.vag_1203 v
JOIN dbo.e_item ei
    ON v.itemNo = ei.itemNo
	and ei.classCode = 'GN'--......검토할 것.
GROUP BY
    ei.itemId;

----------------------------------------------------------------------------------
UPDATE si
SET 
    si.stockQty = vw.stockQty,
    si.locaMemo = vw.locaText,
    si.uptUserId = 'ssuyong'
FROM dbo.e_stockItem si
JOIN dbo.e_stockRack sr
    ON sr.comCode = si.comCode
    AND sr.itemId = si.itemId
    AND sr.rackCode = '644'
JOIN dbo.vw_storItem_loca vw
    ON si.itemId = vw.itemId and vw.comCode = si.comCode
WHERE si.comCode = 'ㄱ121';

IF OBJECT_ID('tempdb..#NewStockItem') IS NOT NULL
    DROP TABLE #NewStockItem;

SELECT DISTINCT
    sr.itemId,
    vw.stockQty,
	vw.locaText
INTO #NewStockItem
FROM dbo.e_stockRack sr
JOIN dbo.vw_storItem_loca vw
    ON sr.itemId = vw.itemId and sr.comCode = vw.comCode
WHERE sr.comCode = 'ㄱ121'
  AND sr.rackCode = '644'
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.e_stockItem si
      WHERE si.comCode = 'ㄱ121'
        AND si.itemId = sr.itemId
  );

INSERT INTO dbo.e_stockItem (
    comCode,
    itemId,
    stockQty,
	locaMemo,
    regUserId,

    uptUserId
 
)
SELECT
    'ㄱ121' AS comCode,
    nsi.itemId,
    nsi.stockQty,
	nsi.locaText,
    'ssuyong' AS regUserId,

    'ssuyong' AS uptUserId
  
FROM #NewStockItem nsi;

--rollback tran

commit tran

select @@TRANCOUNT

SELECT *
FROM dbo.e_stockRack sr
LEFT OUTER JOIN dbo.e_otherSaleRate osr
    ON osr.itemId = sr.itemId 
	 AND osr.comCode = 'ㄱ121' 
	 AND osr.custCode = 'ㅂ022'
WHERE sr.rackCode = '644'
  AND osr.itemId IS NULL


 SELECT *
FROM dbo.e_stockRack sr
LEFT OUTER JOIN dbo.e_otherSaleRate osr
    ON osr.itemId = sr.itemId AND osr.comCode = 'ㄱ121' AND osr.custCode = 'ㅇ499'
WHERE sr.rackCode = '578'
  AND osr.itemId IS NULL

  select * from #NewStockItem




