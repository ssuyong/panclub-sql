select * from dbo.e_othersalerate --8931
where custCode = 'ㅂ022'; 

select * from dbo.vag_1203; --7544



--EXEC sp_rename 'dbo.vag_101.itemCode', 'itemNo', 'COLUMN';


SELECT b.itemNo,b.Brand,b.itemName, b.qty, b.purRate
FROM dbo.vag_1203 b
LEFT JOIN dbo.e_item a ON b.itemNo = a.itemNo
WHERE a.itemNo IS NULL;



--마지막 검증용
SELECT DISTINCT
    v.itemNo,
    ei.itemId
FROM dbo.vag_1203 v
JOIN dbo.e_item ei
    ON LTRIM(RTRIM(v.itemNo)) = LTRIM(RTRIM(ei.itemNo))
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.e_otherSaleRate osr
    WHERE osr.itemId = ei.itemId
      AND osr.comCode = 'ㄱ121'
      AND osr.custCode = 'ㅂ022'
)

--------------------------------------------------------------------------------------------------------
select @@TRANCOUNT

BEGIN TRAN

if object_id('tempdb..#InsertedRows') is not null
  drop table #InsertedRows;

CREATE TABLE #InsertedRows (
    itemId int,
    purRate float
)

DECLARE @UpdatedCnt int;
DECLARE @InsertedCnt  int;

;WITH MaxRate AS (
    SELECT itemNo, MAX(purRate) AS purRate
    FROM dbo.vag_1203
    GROUP BY itemNo
)
UPDATE osr
SET 
    osr.purRate = mr.purRate,
    osr.uptUserId = 'ssuyong',
    osr.modified = GETDATE()
FROM dbo.e_othersalerate osr
JOIN dbo.e_item ei ON osr.itemId = ei.itemId
JOIN MaxRate mr ON ei.itemNo = mr.itemNo
where osr.custCode = 'ㅂ022';
SET @UpdatedCnt = @@ROWCOUNT;

;WITH MaxRate AS (
    SELECT itemNo, MAX(purRate) AS purRate
    FROM dbo.vag_1203
    GROUP BY itemNo
)
INSERT INTO dbo.e_othersalerate (
    comCode,
    custCode,
    itemId,
    purRate,
    regUserId,
    created,
    uptUserId,
    modified
)
OUTPUT inserted.itemId, inserted.purRate
INTO #InsertedRows(itemId, purRate)
SELECT 
    'ㄱ121',               -- 고정값
    'ㅂ022',               -- 고정값
    ei.itemId,
    mr.purRate,
    'ssuyong',
    GETDATE(),
    'ssuyong',
    GETDATE()
FROM MaxRate mr
JOIN dbo.e_item ei ON mr.itemNo = ei.itemNo
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.e_othersalerate osr
    WHERE osr.itemId = ei.itemId
      AND osr.comCode = 'ㄱ121'
      AND osr.custCode = 'ㅂ022'
);

SET @InsertedCnt = @@ROWCOUNT;

SELECT 
    @UpdatedCnt AS UpdatedRowCount,
    @InsertedCnt AS InsertedRowCount;

SELECT 
    ir.itemId,
    ei.itemNo,
    ir.purRate
FROM #InsertedRows ir
JOIN dbo.e_item ei ON ir.itemId = ei.itemId;

--rollback tran

commit tran

select @@TRANCOUNT

select * from #InsertedRows

DROP TABLE #InsertedRows;

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

--250618 이전은 아래

begin tran

INSERT INTO dbo.e_othersalerate  (
comCode
,custCode
,itemId
,purRate
,regUserId
,created
,uptUserId
,modified)
SELECT 'ㄱ121' , 'ㅇ499', b.itemId,a.purRate ,'ssuyong',GETDATE(),'ssuyong',GETDATE()
from dbo.vag_0714 a
join dbo.e_item b on a.itemNo = b.itemNo
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.e_othersalerate x
    WHERE x.itemId = b.itemId
);

rollback tran

commit tran

select @@TRANCOUNT

SELECT b.itemNo
FROM dbo.osr_2 b
LEFT JOIN dbo.e_item a ON b.itemNo = a.itemNo
WHERE a.itemNo IS NULL;

SELECT DISTINCT a.itemNo
FROM dbo.osr_1 a
INNER JOIN dbo.osr_2 b ON a.itemNo = b.itemNo; 


select * from dbo.e_item where itemNo in (
'51417225860'
,'51417225873'
,'0039909497')

159945
159949

select * from dbo.e_stockItem where itemId in (
159945
,159949
)


select * from dbo.e_stockItem where itemId in (
159945
,159949
,406041
)



ㄱ121, ㅇ499, 1277466

select * from dbo.e_othersalerate where itemid = 1277466

select * from dbo.e_item where itemId =  1277466


WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY itemNo 
               ORDER BY purRate DESC
           ) AS rn
    FROM dbo.tt_250616
)
SELECT * FROM CTE
WHERE rn > 1;

begin tran						--테이블에서 중복 데이터 제거 이것부터 돌리고 넣는게 맞지

SELECT *
INTO #KeepRows
FROM (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY itemNo 
               ORDER BY purRate DESC
           ) AS rn
    FROM dbo.vw_250616
) t
WHERE rn = 1;

DELETE FROM dbo.vw_250616;

INSERT INTO dbo.vw_250616 (itemNo, qty, rackCode, purRate)
SELECT itemNo, qty, rackCode, purRate
FROM #KeepRows;

rollback tran

commit tran

WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY itemNo 
               ORDER BY purRate DESC
           ) AS rn
    FROM dbo.osr_4
)
SELECT * FROM CTE
WHERE rn > 1;


select * from dbo.e_item where makerCode = 'HD'

select * from dbo.e_code