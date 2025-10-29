
select * from dbo.total_0728
select * from dbo.e_stockRack where rackCode = '578' and comCode = 'ㄱ121'

begin tran

DELETE FROM dbo.e_stockRack
WHERE rackCode = '578'
  AND comCode = 'ㄱ121'   

-- 신규 INSERT
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
    'ㄱ121' AS comCode,
    ei.itemId,
    '578' AS rackCode,
    SUM(v.qty) AS stockQty,
    'jyspan' AS regUserId,
    GETDATE() AS created,
    'jyspan' AS uptUserId,
    GETDATE() AS modified
FROM dbo.total_0728 v
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
    AND sr.comCode = 'ㄱ121'
    AND sr.rackCode = '578'
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
  AND sr.rackCode = '578'
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
    'jyspan' AS regUserId,

    'jyspan' AS uptUserId
  
FROM #NewStockItem nsi;

rollback tran

commit tran

select @@TRANCOUNT


 SELECT *
FROM dbo.e_stockRack sr
LEFT OUTER JOIN dbo.e_otherSaleRate osr
    ON osr.itemId = sr.itemId AND osr.comCode = 'ㄱ121' AND osr.custCode = 'ㅇ499'
WHERE sr.rackCode = '578'
  AND osr.itemId IS NULL

--'dbo.e_stockRack'에 중복 키를 삽입할 수 없습니다. 중복 키 값은 (ㄱ121, 5850, 578)입니다.

select * from dbo.Sheet1$ where itemNo =  '07131480419'

select * from dbo.e_item where itemId = 5850


