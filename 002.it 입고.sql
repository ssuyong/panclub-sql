
select * from dbo.it_0829

select @@TRANCOUNT

begin tran

DELETE FROM dbo.e_stockRack
WHERE rackCode = '794'
  AND comCode = '¤¡121'   

-- ½Å±Ô INSERT
INSERT INTO dbo.e_stockRack (
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
    '¤¡121' AS comCode,
    ei.itemId,
    '794' AS rackCode,
    SUM(v.qty) AS stockQty,
    'jyspan' AS regUserId,
    GETDATE() AS created,
    'jyspan' AS uptUserId,
    GETDATE() AS modified
FROM dbo.it_0829 v
JOIN dbo.e_item ei
    ON v.itemNo = ei.itemNo
GROUP BY
    ei.itemId;

----------------------------------------------------------------------------------
UPDATE si
SET 
    si.stockQty = vw.stockQty,
    si.locaMemo = vw.locaText,
    si.uptUserId = 'jyspan'
FROM dbo.e_stockItem si
JOIN dbo.e_stockRack sr
    ON si.itemId = sr.itemId
    AND sr.comCode = '¤¡121'
    AND sr.rackCode = '794'
JOIN dbo.vw_storItem_loca vw
    ON si.itemId = vw.itemId and vw.comCode = si.comCode
WHERE si.comCode = '¤¡121';

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
WHERE sr.comCode = '¤¡121'
  AND sr.rackCode = '794'
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.e_stockItem si
      WHERE si.comCode = '¤¡121'
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
    '¤¡121' AS comCode,
    nsi.itemId,
    nsi.stockQty,
	nsi.locaText,
    'jyspan' AS regUserId,

    'jyspan' AS uptUserId
  
FROM #NewStockItem nsi;

rollback tran

commit tran

select @@TRANCOUNT

SELECT *
FROM dbo.e_stockRack sr
LEFT OUTER JOIN dbo.e_otherSaleRate osr
    ON osr.itemId = sr.itemId AND osr.comCode = '¤¡121' AND osr.custCode = '¤·479'
WHERE sr.rackCode = '794'
  AND osr.itemId IS NULL


 SELECT *
FROM dbo.e_stockRack sr
LEFT OUTER JOIN dbo.e_otherSaleRate osr
    ON osr.itemId = sr.itemId AND osr.comCode = '¤¡121' AND osr.custCode = '¤·499'
WHERE sr.rackCode = '578'
  AND osr.itemId IS NULL

  select * from #NewStockItem




