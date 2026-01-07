/* osr rebuild

-- 1) 락 확인
EXEC sp_who2 active;

만약에 62번이 락걸렸다면:

--DBCC INPUTBUFFER(62);

-- kill 62;

-- 2) tempdb 여유 확인
USE tempdb; EXEC sp_spaceused;

-- 3) REBUILD를 온라인/병렬로 실행
ALTER INDEX ALL ON dbo.e_otherSaleRate REBUILD;
--ALTER INDEX ALL ON dbo.e_otherSaleRate REBUILD WITH (ONLINE = ON, MAXDOP = 0);

USE master;
GO
SELECT 
    db_name(database_id) AS DatabaseName,
    name AS LogicalName,
    physical_name AS FilePath,
    type_desc AS FileType
FROM sys.master_files
WHERE database_id = DB_ID('tempdb');

DBCC INPUTBUFFER(54);

kill 54;


SELECT  
    s.name  AS SchemaName,
    t.name  AS TableName,
    c.name  AS ColumnName
FROM sys.columns c
JOIN sys.tables  t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.name = 'centerPrice'
ORDER BY s.name, t.name;

*/


------------------------------------
------------------------------------
------------------------------------
--속도개선 인덱스 생성(100배이상 빨라짐)
/*
DROP INDEX ssy_IX_stockRack_item ON dbo.e_stockRack;

CREATE INDEX ssy_IX_stockRack_item
  ON dbo.e_stockRack(comCode, itemId)
  INCLUDE (rackCode, stockQty);

CREATE NONCLUSTERED INDEX IX_e_stockRack__rackCode
ON dbo.e_stockRack (comCode, rackCode)
INCLUDE (itemId, stockQty);
--
drop index ssy_IX_storage_consign on dbo.e_storage;
CREATE INDEX ssy_IX_storage_consign
  ON dbo.e_storage(comCode, storageCode)
  INCLUDE (consignCustCode, storType, validYN, workableYN, rlStandByYN,
         ctStorageYN, consignViewYN);

CREATE INDEX ssy_IX_otherSaleRate
  ON dbo.e_otherSaleRate(comCode, custCode, itemId)
  INCLUDE (purRate);

CREATE INDEX ssy_IX_itemCost_recent
  ON dbo.e_itemCost(comCode, itemId, stdYM DESC)
  INCLUDE (cost);

---추가
CREATE NONCLUSTERED INDEX ssy_IX_e_stockItem_comCode_itemId
ON dbo.e_stockItem (comCode, itemId)
INCLUDE (stockQty);

drop INDEX ssy_IX_e_pcReqItem_itemId_procStep on dbo.e_pcReqItem

CREATE NONCLUSTERED INDEX ssy_IX_e_pcReqItem_itemId_procStep
ON dbo.e_pcReqItem (comCode, itemId, procStep)
INCLUDE (gvComCode, gvPlaceNo, gvPlaceSeq, gvQty);

--불필요한 인덱스 삭제
--원본: CREATE INDEX [IX_e_placeItem_placeNo] ON [dbo].[e_placeItem]([placeNo])
	  drop index IX_e_placeItem_placeNo ON dbo.e_placeItem;

CREATE NONCLUSTERED INDEX IX_e_item_itemNo
ON dbo.e_item (itemNo)
INCLUDE (itemId, comCode, itemName, makerCode);

CREATE NONCLUSTERED INDEX IX_e_item_itemId
ON dbo.e_item (itemId)
INCLUDE (itemNo, comCode, itemName, makerCode);
*/

--별 차이 없음.
/*
ALTER INDEX ALL ON dbo.e_stockRack REBUILD;
ALTER INDEX ALL ON dbo.e_storage REBUILD;
ALTER INDEX ALL ON dbo.e_otherSaleRate REBUILD;
ALTER INDEX ALL ON dbo.e_itemCost REBUILD;
ALTER INDEX ALL ON dbo.e_rack REBUILD;
ALTER INDEX ALL ON dbo.e_item REBUILD;
*/

select * from e_user
where userId = '테스트'

--stockItemList분석

--이슈!!!!!!!!!!!!!!!!
--엠케이건 주문시 우리쪽에 아이템이 비어서 들어옴.

select * from _SPLOG
where created >= '2025-10-20' 
  --and params like '%20251020007%'
  and params like '%엠케이%'
order by created desc;

--결론: 엠케이 삽입후 up_pcReqItemList에서도 엠케이 추가해야 함.
--신규 위탁시: up_stockItemList,up_pcReqItemList,창고,기본랙,랙,수탁업체매입율 등록!!!

---------------------------------------


SELECT 
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    o.name AS ProcedureName,
    m.definition
FROM 
    sys.objects o
JOIN 
    sys.sql_modules m ON o.object_id = m.object_id
WHERE 
    1=1 
	AND o.type = 'P'  -- 저장 프로시저만    
	AND m.definition LIKE '%e_item%'  -- 여기에 찾고자 하는 단어 
ORDER BY 
    o.name;


--거래상세내역,위탁재고 판매내역(up_transactionList)은 
--주문요청판매내역(up_pcReqItemList)시점에 만들어진다.
--주문요청판매내역(up_pcReqItemList)시점에서 위탁마진율(UF_cCustPerItemRate)을 'e_saleItem'에 삽입 계산한다.
--이 위탁마진율이 존재하지 않으면 값을 못가져오고 0이 된다.

select * from e_pcReqItem


select * from _SPLOG
where sp = 'panErp.dbo.up_pcReqAdd'
order by created desc;

select * from e_saleItem
order by saleNo desc;

select * from e_saleItem
where 1=1
 and puComCode = 'ㅂ022'
order by created desc, saleNo desc;

/* 테스트: 가격 강제 update하여 매입처거래상세내역에 보이게 함
begin tran
--update e_saleItem
set saleRate = 0.40
   ,costPrice = centerPrice * 0.40
   ,saleUnitPrice = centerPrice * 0.40
where 1=1
  and puComCode = 'ㄷ199'
 and saleNo = '20251001002'

 rollback tran

 commit tran
 */

 
--다중조회와 업체 재고조회가 다르다?

66206923000
51247463163
07146976114
51471911992

--misson:
--51247463163 인터카스1,아우토1개인데 주문이 들어와서 보니 아우토는 안보이고 인터카스만 보여서,
--인터카스 걸로 주문처리 완료=> 이제서야, 아우토1개가 보인다.

==>나중에 다시 나타나면 찾아 보자.

A-parts 판매가상법인
아파츠 - A-parts에 위탁맡기는 업체



SELECT SUSER_SNAME();
--위험!!!!!!!!!!!!!! 백업한DB로 다이어그램 만들기위해.test db만듦
/*
SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE name = 'test_panErp_restore';

SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE name = 'test_panErp_restore';

--ALTER AUTHORIZATION ON DATABASE::test_panErp_restore TO sa;

ALTER LOGIN sa WITH PASSWORD = 'pan@mall0320!A';

ALTER AUTHORIZATION ON DATABASE::test_panErp_restore TO pan_mall;
*/


--탐나네가 들어가있는 테이블 검사(절대!!! testdb에서 실행할것)

DECLARE @find NVARCHAR(100) = N'탐나네';
DECLARE @tbl NVARCHAR(256), @col NVARCHAR(128), @sql NVARCHAR(MAX);

-- 임시 저장 테이블
CREATE TABLE #FoundTables (
    TableName NVARCHAR(256)
);

DECLARE cur CURSOR FOR
SELECT t.name, c.name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar','varchar','nchar','char','text','ntext')
  AND t.is_ms_shipped = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @tbl, @col;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@tbl) +
               N' WHERE ' + QUOTENAME(@col) + N' LIKE N''%' + @find + N'%'')' +
               N' INSERT INTO #FoundTables VALUES (N''' + @tbl + N''');';

    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        -- 무시 (권한 또는 타입 문제 있는 경우)
    END CATCH;

    FETCH NEXT FROM cur INTO @tbl, @col;
END;

CLOSE cur;
DEALLOCATE cur;

-- 결과 보기
SELECT DISTINCT TableName
FROM #FoundTables
ORDER BY TableName;

DROP TABLE #FoundTables;


select * from c_cust where masterId = '탐나네'
select * from e_cust where custName = '티파츠'
select * from e_custAtt where attaFileOri = '탐나네.png'
select * from e_notiMsg
select * from e_order where custMgrName like '%탐나네%' order by created desc;
select * from e_orderGroup where custMgrName like '%탐나네%'
select * from e_pcReq where gvMgr = '탐나네'
select * from e_pcReqItem where gvComCode = 'ㅌ087'
select * from e_stockSrchLog where userId = '탐나네' order by created desc;

select * from e_user where userId = '탐나네->티파츠' --일단 이 아이디를 막아야 하는데...

--탐나네를 티파츠로 변경하기 시작
select * from c_cust where masterId = '티파츠'
--1
update c_cust 
set masterId = '티파츠'
where masterId = '탐나네'
  and custCode = 'ㅌ087'

  --2.이미 변경되서 수정 필요없음
select * from e_cust where  custCode = 'ㅌ087'

update e_cust
set custName = '티파츠', formalName = '주식회사 티파츠', bizNo = '262-88-03100',
custAddress1 = '경기도 김포시 고촌읍 인향로24번길 66-22, 지1층 비07호(디아이빌4단지501 지하층)',
phone = '01041550411'
where comCode = 'ㄱ121' and custCode = 'ㅌ087'

--3. 로그인 업데이트
select * from e_user where comCode = 'ㅌ087'

update e_user
set userId = '티파츠' , userName = '주식회사 티파츠'
where comCode = 'ㅌ087'

select * from e_user
where comCode = 'ㅌ087'

--티파츠(구:탐나네) update하고 신규는 삭제함

select * from e_user where comCode = 'ㅌ090'
select * from c_cust where custCode = 'ㅌ090'
select * from e_cust where custCode = 'ㅌ090'
select * from e_custAtt where custCode = 'ㅌ090'


-------------------------------------

--아파츠재고조회 수량: 1178 vs 다중품번 수량: 1188 10건의 차이는 무엇인가?
--stockItemList에 있는 다음 쿼리에서 해답을 찾았다.
--10건은 결국 주문상태에 머물러 있는 건수였다. 주문을 취소시키니 모두 1188건이 되었다.
--다음은 주문에 걸려 있는 수량을 찾는 쿼리이다.
select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
from dbo.e_pcReqItem s
join e_stockItem st on st.itemId = s.itemId
LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode 
  AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
WHERE s.itemId = st.itemId 
AND s.comCode = st.comCode  
AND	ISNULL(s.procStep,'') not in ('거부', '접수', '처리') 
  and s.itemId = (select itemId from e_item where itemNo = '0039909497')

--출고대기랙에 있는 물건
select * -- sum(_sr.stockQty) AS qty2 --8
from dbo.e_stockRack _sr
join e_item ei on ei.itemId = _sr.itemId
join e_stockItem st on  1=1
LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
  AND _sr.rackCode = _r.rackCode
LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
  AND _s.storageCode = _r.storageCode 
where _sr.itemid = st.itemId and _sr.comCode = st.comCode 	
  and _r.validYN = 'Y' 
  and _s.validYN = 'Y' 
  AND _s.storType in ('신품','중고','리퍼') 
  --AND _s.workableYN = 'Y'
  and ISNULL(_s.rlStandByYN,'') = 'Y'
  and _sr.comCode = 'ㄱ121'
  and ei.itemNo = '0039909497'


DBCC USEROPTIONS;

SELECT transaction_isolation_level
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID;

다음을 할인율 40->50%로 인터카스(ㅇ479) 794

4K5945093C 
5G4833055AD
561821021A 

/*
select * from e_otherSaleRate osr
join e_item ei on ei.itemId = osr.itemId
where ei.itemNo in ('4K5945093C',
'5G4833055AD',
'561821021A')
and osr.custCode = 'ㅇ479';

update osr
set purRate = '40'
from e_otherSaleRate osr
join e_item ei on ei.itemId = osr.itemId
where ei.itemNo in ('4K5945093C',
'5G4833055AD',
'561821021A')
and osr.custCode = 'ㅇ479';
*/


--11/4======================================================================================
--mission: 0009050030 인터카스 물건 판매되었다가 반품되었는데 쓸만하여 우리 물건으로 돌림,
           --반품으로 인해 인터카스 판매가 취소되지 않게 유지시켜야 함
		   --:e_saleItem 에서 반품내역을 삭제->d_saleItem으로 옮김


select * from e_stockRack sr--373461
join e_item ei on ei.itemId = sr.itemId
where itemNo = '66209261582'
  and sr.rackCode = '1349'
  order by created desc;


  select * from e_Rack
  where rackCode = '1349'

  select * from e_storage
  where storageCode = '20251121001'


  select * from e_saleItem
  where 1=1
    and regYmd = '2025-12-17'
    and itemId = '265998'
	and comCode = 'ㅈ011'


 select distinct saleType from e_saleItem

 --1.내역 d_saleItem로 옮겨놓고
	insert into  d_saleItem([deleted], [delUserId], [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [plRoNo], [plRoSeq], [storageUseReqNo], [storageUseReqSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created])
    select                   getDate(), 'ssuyong',  [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [storageUseReqNo], [storageUseReqSeq], [plRoNo], [plRoSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created]       
	from e_saleItem
	where 1=1
    and regYmd = '2025-12-17'
    and itemId = '265998'
	and comCode = 'ㅈ011'

	--2.내역 삭제
	begin tran 
	delete from e_saleItem
	where 1=1
    and regYmd = '2025-12-17'
    and itemId = '265998'
	and comCode = 'ㅈ011'

	rollback tran
	commit tran

--=====================================================================================
select *
FROM dbo.e_stockItem si
JOIN dbo.e_stockRack sr ON sr.itemId = si.itemId
  and sr.comCode = si.comCode    
JOIN dbo.vw_storItem_loca vw ON vw.itemId = sr.itemId 
  and vw.comCode = sr.comCode
WHERE sr.comCode = 'ㄱ121'
  and sr.rackCode = '950';




SELECT 
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    o.name AS ProcedureName,
    m.definition
FROM 
    sys.objects o
JOIN 
    sys.sql_modules m ON o.object_id = m.object_id
WHERE 
    o.type = 'P'  -- 저장 프로시저만
    AND m.definition LIKE '%회수%'  -- 여기에 찾고자 하는 단어
ORDER BY 
    o.name;


------------------------------------------------------
--회수요청이 오면 벨이 울리게 해달라: 유영규
------------------------------------------------------

select * from e_ctReq
order by ctReqNo desc

drop trigger trgCtReqNewAlert;
drop table e_alertQueue;

CREATE TABLE e_alertQueue (
    alertId INT IDENTITY PRIMARY KEY,
    alertType VARCHAR(50),
    message NVARCHAR(500),
    created DATETIME DEFAULT GETDATE(),
    ProcessedYN CHAR(1) DEFAULT 'N'
);

CREATE TRIGGER trgCtReqNewAlert
ON dbo.e_ctReq
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.e_alertQueue (alertType, message, created)
    SELECT 
        'NewCtReq', 
        CONCAT('신규 회수요청 발생: ', i.ctReqNo, ' (', i.reqMgr, ')'),
        GETDATE()
    FROM inserted i;
END;



insert into e_ctReq
select [comCode], '20251103003테스트' [ctReqNo], [reqCustCode], [reqMgr], [reqMemo1], [procStep], [procUserId], [procDate], [inMemo1], [regUserId], [regYmd], [regHmsg], [uptUserId], [uptYmd], [uptHmsg], [custCode], [custName], [deliWay], [deliPayType], [senderCustName], [senderName], [senderTel], [senderAddr1], [receiverCustName], [receiverName], [receiverTel], [receiverAddr1], [rcvLogisCode], [acceptType] 
from e_ctReq
where ctReqNo = '20251103002'


select * from e_ctReq
order by ctReqNo desc
--------------------------------------------------------------
--------------------------------------------------------------

--11/4 이지통상경매 아파츠 귀속예상 판매개시
select ei.itemNo, sr.stockQty, sr.* 
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  --and sr.rackCode >= 74
  --and sr.rackCode < =738
  and sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0

select sum(sr.stockQty) --11,643개
  from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  --and sr.rackCode >= 74
  --and sr.rackCode < =738
  and sg.consignCustCode = 'ㅇ496'

select *
from e_storage 
--where storageCode in ('250327001', '250211002')
where consignCustCode = 'ㅇ496'

랙코드  기본랙   랙이름
1260	3189	A1-147

select * from e_rack
where rackCode = '1260'
  and comCode = 'ㄱ121'

select * from e_logisrack
where logisRackId = '3189'

--아파츠에 기본랙,랙 A1-147만들고 거기에
--기존 이지통상 물건을 수동이동시킨다.
--1.수기입력자료-엑셀만들기
--2.기본랙,랙 만들기
--3.수동입출고 엑셀업로드 등록,처리
--1,2,3  모두 재고없는걸로 나와 수동입고처리함.
select ei.itemNo, sr.rackCode, stockQty
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode and sg.storageCode = r.storageCode
  and sg.consignCustCode = 'ㅇ496'
where sr.comCode = 'ㄱ121' 
  and sr.stockQty > 0 
  and ei.itemNo in
(
'61667220827',
'61617427901',
'41008497156',
'61129320490',
'51767433334',
'51337299997',
'51477378054',
'51118056491',
'52107477767',
'36117852491',
'36118074185',
'51137205780',
'31318008628',
'51137114734'
)
order by ei.itemNo

select * from e_item
where itemNo like '74195T2GA11'

select * from e_rack
where memo = '통'
order by rackName ;

select sum(ei.centerPrice) tot--59,779,025.00
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode 
  and r.rackCode = sr.rackCode
	and r.memo = '통'
	
select *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0

select *
from e_stockItem sr
join e_item ei on ei.itemId = sr.itemId
where sr.comCode = 'ㄱ121'
  and ei.itemNo in ('2115401717')

select * from e_rack er
join e_storage sg on sg.storageCode = er.storageCode
where er.rackCode = '1348'

select sum(sr.stockQty * ei.centerPrice) total --32,663,165
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0
  and r.rackName > 'A2-11'
  and r.rackName < 'A2-14'

select *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0
  and r.rackName > 'A2-11'
  and r.rackName < 'A2-14'

--재고위치 재고현황
select ei.centerPrice,*
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and ei.itemNo = '0009058706'

select pcReqNo, gvQty, gvComCode, pr.regUserId, procStep from e_pcReqItem pr
join e_item ei on ei.itemId = pr.itemId
where ei.itemNo = '0009058706'


/*
select *
from e_rack
where rackCode = 535
  and comCode = 'ㄱ121'--' A2-110 '

select * 
from e_logisRack
where logisRackId = '3253'--' A2-110 '

update e_rack
set rackName = 'A2-110'
where rackCode = 1348
  and comCode = 'ㄱ121'--'A2-110'


update e_logisRack
set rackName = 'A2-110'
where logisRackId = '3253'--'A2-110'
*/


 

--==========================================

--213905240364 할인율 0... 주문요청상세내역에 213905240364가 판매가 0로 나온다.
--고대표는 메이커를 등록해야 한다고 하는데 ㅇ495 아파츠 매입율 등록문제가 아닌가 생각된다. 다음에 다시 보자.

select *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode 
  and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode 
  and sg.storageCode = r.storageCode
where ei.itemNo = '213905240364'
  and sr.comCode = 'ㄱ121'
  and sg.consignCustCode = 'ㅇ499'


  select *  from e_otherSaleRate osr
  where custCode = 'ㅇ495'
  where osr.itemId = '7241635'


  select * from e_item ei
  where  ei.itemNo = '213905240364'

  select * from e_item ei
  where ei.itemName like '%스위치 모듈 라인 센서 B%'
    and ei.itemNo = '213905240364'

  update ei
  set ei.makerCode = 'BZ'
    , ei.brandCode = 'BZ'
	, ei.saleBrandCode = 'BZ'
	, ei.genuineYN = 'Y'
  from e_item ei
  where ei.itemName like '%스위치 모듈 라인 센서 B%'
    and ei.itemNo = '213905240364'


	select * from e_saleItem
	where itemId = '7241635'

	select * from e_saleItem
	where idx >= 65537

	select * from e_cust
	where custCode = 'ㅌ089'--테스트250207


--==========================================


--==========================================


SELECT 
        sr.comCode,
        sr.itemId,
        sg.storType,
        SUM(sr.stockQty) AS stockQty,
        ISNULL(sg.validYN,'N') AS storValidYN,
        ISNULL(sg.workableYN,'N') AS storWorkableYN,
        ISNULL(sg.rlStandByYN,'N') AS storStandbyYN,
        ISNULL(sg.ctStorageYN,'N') AS storCtYN,
        ISNULL(r.validYN,'N') AS rackValidYN
    FROM dbo.e_stockRack sr WITH(NOLOCK)
	join e_item ei on ei.itemId = sr.itemId
    JOIN dbo.e_rack r WITH(NOLOCK)
        ON sr.comCode = r.comCode 
       AND sr.rackCode = r.rackCode
    JOIN dbo.e_storage sg WITH(NOLOCK)
        ON sr.comCode = sg.comCode 
       AND r.storageCode = sg.storageCode
    WHERE sr.stockQty <> 0
      AND ISNULL(sg.validYN,'N') = 'Y'
	  and ei.itemNo = '테스트테스트'
    GROUP BY 
        sr.comCode, sr.itemId, sg.storType,
        sg.validYN, sg.workableYN, sg.rlStandByYN, 
        sg.ctStorageYN, r.validYN


select comCode, storageName, consignViewYN
from e_storage 
where 1=1--(consignViewYN = 'Y' or consignViewYN = 'N')
  and comCode = 'ㄱ121';


-----------------
--이지통상 물건 랙위치, 수량 확인
select * from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where ei.itemNo = 'FR3Z8475C'
  and sg.consignCustCode = 'ㅇ496';

select * from e_storage sg
where sg.consignCustCode in ('ㅇ496', 'ㅇ495');

--이지통상 A2-01 ~ A2-09까지 아파츠로 이동하라?
--:현164개를 storageCode 250211002->250214001
select * from e_rack--164개
where storageCode = '250211002'--이지통상
  and rackName > 'A2-01'
  and rackName < 'A2-10'
union all
select * from e_rack --12개
where storageCode = '250214001'--아파츠
  and rackName > 'A2-01'
  and rackName < 'A2-10'
order by rackName

--stockRack 459 에 무슨 아이템이 있을까?
select * from e_stockRack --14,11
where rackCode = '459'
  --itemId = '1391990'
  and stockQty > 0

  select * from e_rack -- 176
  where storageCode in ('', '250214001')
    and rackName > 'A2-01'
    and rackName < 'A2-10'
  order by rackName

  select * from e_storage
  where storageCode = '250214001'

------------------------------------------------------------
-- 2025-11-18 이지통상(250211002) A2-01 ~ A2-09 랙을 아파츠(250214001)로 변경
------------------------------------------------------------
--실행: A2-01~A2-09.. 이지통상->아파츠로 변경
begin tran
update e_rack
set storageCode = '250214001' --250214001:아파츠
  , modified = getDate()
where storageCode = '250211002'--250211002:이지통상
  and rackName > 'A2-01'
  and rackName < 'A2-10'

rollback tran

commit tran


--변경내역!!!!
select sg.storageName, er.rackName, sum(sr.stockQty) 
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ495'
  --and sr.stockQty > 0
  and rackName > 'A2-01'
  and rackName < 'A2-10'
  and cast(er.modified as date) = '2025-11-18'
group by  sg.storageName, er.rackName

--A2-01~ A2_09 재고자산: 5억8천7백
select sg.storageName, sum(sr.stockQty * ei.centerPrice) --587,090,864.00
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ495'
  and sr.stockQty > 0
  and rackName > 'A2-01'
  and rackName < 'A2-10'
  and cast(er.modified as date) = '2025-11-18'
group by  sg.storageName


---------------------------------------------
 --=-------------------------------------
--랙이동후(A2-01 ~ A2-09) 이지통상 물건
select sg.storageName, sum(sr.stockQty * ei.centerPrice) --898,655,602.00
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ496'
group by sg.storageName


---------------------------------------
--품번별 재고위치 파악
select sr.itemId, ei.itemNo, sg.storageName, er.rackName, sr.stockQty
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = er.storageCode
where 1=1 --sr.stockQty <> 0
  and ei.itemNo = '51779478315'

  select sr.itemId, ei.itemNo, sg.storageName, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = er.storageCode
where sr.stockQty <> 0
  and ei.itemNo = '51779478315'

  select sr.itemId, ei.itemNo, sg.storageName, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = er.storageCode
where 1=1 --sr.stockQty <> 0
  and er.rackCode = '740'

select * from e_orderItem oi
join e_item ei on ei.itemId = oi.itemId
where ei.itemNo = '51779478315'

--------------------------------------------------
--제이에이치파츠:51779478315 불량 회수요청시 안보이게
--------------------------------------------------

  select * from e_cust
  where custName like '%제이에이치파츠%'

  select * from e_user
  where userName like '%제이에이치파츠%'

  --신품으로 뜬다.

  select * from e_rack er 
  join e_storage sg on sg.comCode = er.comCode
    and sg.storageCode = er.storageCode
	and er.rackCode = '740'
	and er.comCode = 'ㄱ121';

	select * from e_rack er
	where er.rackCode = '740'
	  and comCode = 'ㄱ121';

	--update e_rack
	set validYN = 'N'
	where rackCode = '740'
	  and comCode = 'ㄱ121';

--제이에이치위탁 740랙(불량) 신품창고에 연결되어 있는거 불량창고로 수정
250609001	신품
250630001	불량

begin tran
update e_rack
set storageCode = '250630001'--불량창고
where storageCode = '250609001'--신품창고
  and comCode = 'ㄱ121'
  and rackCode = '740';

rollback tran
commit tran;

select * from e_rack er
where comCode = 'ㄱ121'
  and rackCode = '740';

  select *
  from e_storage sg
  where comCode = 'ㄱ121'
    and consignCustCode = 'ㅈ008'

select * from e_rack er
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where er.comCode = 'ㄱ121'
  and er.rackCode = '740'

--------------------------------------------------
--2025-11-18 선대표:매입처상세내역 40%지급, 일부 50%지급으로 변경할 수 있나?
5C7941005H   헤드램프 좌
63117365600  전조등, 할로겐, 우측
17B941036E    헤드램프 우

select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where si.puComCode = 'ㅇ479'
  and si.regYmd >= '2025-11-01'
  and si.regYmd <= '2025-11-18'
  and ei.itemNo in ('5C7941005H', '63117365600', '17B941036E');

--실행
begin tran
update si
set saleRate = '0.50', --0.40
  costPrice = '682550',-- 546040
  saleUnitPrice = '682550'--546040
from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where si.puComCode = 'ㅇ479'
  and si.regYmd >= '2025-11-01'
  and si.regYmd <= '2025-11-18'
  and ei.itemNo in ('5C7941005H', '63117365600', '17B941036E')
  and ei.itemNo = '17B941036E'

update si
set saleRate = '0.50',--0.40
  costPrice = '196950',-- 157560
  saleUnitPrice = '196950'--157560
from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where si.puComCode = 'ㅇ479'
  and si.regYmd >= '2025-11-01'
  and si.regYmd <= '2025-11-18'
  and ei.itemNo in ('5C7941005H', '63117365600', '17B941036E')
  and ei.itemNo = '5C7941005H'

update si
set saleRate = '0.50',--0.40
  costPrice = '383800',-- 307040
  saleUnitPrice = '383800'--307040
from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where si.puComCode = 'ㅇ479'
  and si.regYmd >= '2025-11-01'
  and si.regYmd <= '2025-11-18'
  and ei.itemNo in ('5C7941005H', '63117365600', '17B941036E')
  and ei.itemNo = '63117365600'

  rollback tran

  commit tran

--------------------------------------------------
1. 아파츠 보유재고
2. 위탁재고(인터카스, 엠케이, JH, 인비전스, 에이스부품, 다온, 비알오토)
3. 이지통상(2층 1~9번랙 제외)

--1. 아파츠 보유재고
select sg.storageName, sr.itemId, ei.itemNo, ei.itemName, sr.stockQty, ei.centerPrice, er.rackName
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = er.storageCode
where sr.stockQty <> 0
  and sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ495')

--2. 위탁재고(인터카스, 엠케이, JH, 인비전스, 에이스부품, 다온, 비알오토)
select sg.storageName, sr.itemId, ei.itemNo, ei.itemName, sr.stockQty, ei.centerPrice, er.rackName
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = er.storageCode
where sr.stockQty <> 0
  and sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ479', 'ㅇ002', 'ㅈ008', 'ㅇ004', 'ㅇ455', 'ㄷ199', 'ㅂ018')
order by sg.consignCustCode

--3. 이지통상(2층 1~9번랙 제외)
select sg.storageName, sr.itemId, ei.itemNo, ei.itemName, sr.stockQty, ei.centerPrice, er.rackName
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = er.storageCode
where sr.stockQty <> 0
  and sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ496')

  -----------------------
  --제파 위탁 등록
  select * from e_cust
  where custName like '%제파%'--1349 ㅈ011

  select *
  from e_rack er
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
  where sg.consignCustCode = 'ㅈ011'


  -----------------------

  --=-------------------------------------
--2025-11-26 박스이동후 남은 이지통상 물건
select sg.storageName, sum(sr.stockQty * ei.centerPrice) --666,855,934.00
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0
group by sg.storageName

select *
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0

--이지통상에서 이동한 물건
select sum(sr.stockQty * ei.centerPrice) tot--312,329,823.00
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode 
  and r.rackCode = sr.rackCode
  and r.memo = '통'
where sr.stockQty > 0

-- 이지통상 건수
select sum(sr.stockQty) --11,643개 -> 4,967
  from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode = 'ㅇ496'

--9억에서 3억 정도 이동됐네... 아직 6억어치가 남았어.

  --=-------------------------------------

/*
SET STATISTICS TIME, IO ON;--0초
exec 
panErp.dbo.up_stockItemList	@i__workingType='SALE_LIST',    
@i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',    
@i__eYmd1='',    @i__sYmd2='',    @i__eYmd2='',        @i__storCode='',    
@i__itemId=0,    @i__itemNo='',    @i__itemName='',    @i__makerCode='',    
@i__classCode='',    @i__storName='',      @i__bulkSrchType='itemNo',    
@i__itemBulk='07119904448힣4M0816421D힣01292317853힣07147201307힣11127582245힣07119905032',   
@i__checkType='ALL',    @i__outStorCode='',    @i__storageCode='',    
@i__noRealYN='N',    @i__qtyZeroYN='N',    @i__consignCustCode='',      
@i__logComCode='ㅌ089',    @i__logUserId='테스트'
SET STATISTICS TIME, IO OFF;

*/



3Q0919275A9B9

select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId 
where ei.itemNo = '3Q0919275A9B9'
  and si.regYmd = '2025-11-28'

3Q0919275A9B9

select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId 
where ei.itemNo = '3Q0919275A9B9'
  and si.regYmd = '2025-12-01'
  and si.comCode = 'ㅈ011'





  panErp.dbo.up_transactionList	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2025-11-01',      @i__eYmd1='2025-12-01',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',    @i__logUserId='ssuyong',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',     @i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode='ㅈ011'


  select * from e_stockActions
  where itemId = '2544626'
  order by idx desc


  select * from e_cust
  where custName like '%부품인%'--ㅂ186

--------------------------------------
--3Q0919275A9B9 매입처 입고날자 변경 12-01=>11-28 S
--------------------------------------
  select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId 
where ei.itemNo = '3Q0919275A9B9'
  and si.regYmd = '2025-12-01'
  and si.comCode = 'ㅈ011'


  begin tran

    update si
	set si.regYmd = '2025-11-28'
	from e_saleItem si
join e_item ei on ei.itemId = si.itemId 
where ei.itemNo = '3Q0919275A9B9'
  and si.regYmd = '2025-12-01'
  and si.comCode = 'ㅈ011'

  rollback tran
  commit tran

--------------------------------------
--3Q0919275A9B9 매입처 입고날자 변경 12-01=>11-28 E
--------------------------------------

--창고사용완료할때 404에러
--서버에 localhost.2025-12-01.log 에 pk중복에러 발생:중복키를 임의 변경처리함.
select *
from e_rack er 
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode 
where sg.consignCustCode = 'ㅈ011'


  select * from _spLog
  where params like '%ssuyong%'
    and created >= '2025-12-01'
  order by created desc;

  panErp.dbo.up_storageUseReqItemAdd	@i__workingType='CHK',      @i__storageUseReqNo='',    
  @i__reqSeq='',    @i__orderNo='',    @i__orderSeq='',    @i__cnt='0',    @i__ordArr='',    
  @i__seqArr='',    @i__scdArr='',    @i__cntArr='',    
  @i__reqArr='20251201015^20251201015^20251201015^20251201015^20251201015^20251201015^',    
  @i__rseArr='1^2^3^4^5^6^',    @i__mm1Arr='',    @i__mm2Arr='',    @i__rackArr='',    
  @i__afterRackCode='1',    @i__consignItemArr='',    @i__logisCodeArr='',      
  @i__logUserId='ssuyong',    @i__logComCode='ㄱ121' 	2025-12-01 14:29:58.350


  panErp.dbo.up_storageUseReqItemAdd	@i__workingType='CHK',      @i__storageUseReqNo='',    
  @i__reqSeq='',    @i__orderNo='',    @i__orderSeq='',    @i__cnt='0',    @i__ordArr='',    
  @i__seqArr='',    @i__scdArr='',    @i__cntArr='',    
  @i__reqArr='20251201030^20251201030^20251201030^20251201030^20251201030^20251201030^',    
  @i__rseArr='1^2^3^4^5^6^',    @i__mm1Arr='',    @i__mm2Arr='',    @i__rackArr='',    
  @i__afterRackCode='1',    @i__consignItemArr='',    @i__logisCodeArr='',      
  @i__logUserId='ssuyong',    @i__logComCode='ㄱ121'


  중복 키 값은 (ㅈ011, 20251201002, 1)입니다

  select * from e_storageUseReqItem
  where comCode = 'ㅈ011'
    and storageUseReqNo = '20251201002'
	and reqSeq = '1'

	select * from e_storageUseReqItem
	order by chkDate desc;


select * from e_saleItem
where comCode = 'ㅈ011'
  and saleNo = '20251201002'
  --and saleSeq = 1
order by idx desc;

--update e_saleItem
set saleNo = '20251201002zzz'
where comCode = 'ㅈ011'
  and saleNo = '20251201002'

select * from e_saleItem
where comCode = 'ㅈ011'
  and saleNo like '20251201002%'
  --and saleSeq = 1
order by idx desc;

-----------------------------------------------
-----------------------------------------------




select 
	sum(case when _s.consignCustCode = v.consignCustCode then _sr.stockQty else 0 end) AS qty1, --위탁업체 재고
	sum(case when _s.consignCustCode = v.consignCustCode 
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _r.validYN = 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.workableYN = 'Y'
	  AND _s.storType in ('신품','중고','리퍼') 
	  then _sr.stockQty else 0 end) AS qty2, --위탁업체 가용재고
	sum(case when ISNULL(_s.consignCustCode,'') NOT IN (v.excludeSelf, v.excludeOther)
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _r.validYN = 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.workableYN = 'Y'
	  AND _s.storType in ('신품','중고','리퍼') 	  
	  then _sr.stockQty else 0 end) AS qty3, --위탁업체,이지통상 제외 가용재고
    sum(case when _s.consignCustCode = 'ㅇ496'
	  and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	  and _r.validYN = 'Y' 
	  and _s.validYN = 'Y' 
	  AND _s.workableYN = 'Y'
	  AND _s.storType in ('신품','중고','리퍼') 	  
	  then _sr.stockQty else 0 end) AS qty5, --이지통상 가용재고
	STRING_AGG(
        '[' + _s.storageName + ']' + _r.rackName + ' ' 
		+ CAST(_sr.stockQty AS VARCHAR(20)),
        ' * '
    ) AS locaMemo
	  
	from dbo.e_stockRack _sr
	join e_stockItem st on st.comCode = _sr.comCode and st.itemId = _sr.itemId	
	join e_item ei on ei.itemId = _sr.itemId
JOIN (
    VALUES
        ('ㅇ499','ㅇ499','ㅇ496'),
        ('ㅂ022','ㅂ022','ㅇ496'),
        ('ㅇ479','ㅇ479','ㅇ496'),
        ('ㅇ002','ㅇ002','ㅇ496'),
        ('ㅂ184','ㅂ184','ㅇ496'),
		('ㅈ011','ㅈ011','ㅇ496'),
		('ㅂ186','ㅂ186','ㅇ496')
) v(consignCustCode, excludeSelf, excludeOther)
    ON 1 = 1
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
	  AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
	  AND _s.storageCode = _r.storageCode	  
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
	  and ei.itemNo = '4K0807283'


select *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCOde = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
  and sg.consignCustCode = 'ㅂ186'
where ei.itemNo = '4K0807283'


-----------------------------------------------------
--센터가 업데이트

select * from center_jp
where itemNo = '958362146229A1'

select ei.itemNo, v.centerPrice vPrice, ei.centerPrice itemPrice, ei.centerPrice - v.centerPrice gap
from e_item ei
join center_jp v on v.itemNo = ei.itemNo
where v.centerPrice != ei.centerPrice

begin tran
update ei
set ei.centerPrice = v.centerPrice
  , ei.salePrice = v.centerPrice
from e_item ei
join center_jp v on v.itemNo = ei.itemNo
  where v.centerPrice != ei.centerPrice


rollback tran
commit tran

------------------------------------------------------------
-- 2025-12-02 이지통상(250211002) A2-11 ~ A2-13 랙을 아파츠(250214001)로 변경
------------------------------------------------------------

select *
from e_rack
where storageCode = '250211002'--250211002:이지통상
  and rackName > 'A2-11'
  and rackName < 'A2-14'
order by rackName ;

select * from e_storage --아파츠 창고
where storageCode = '250214001'

--실행: A2-01~A2-09.. 이지통상->아파츠로 변경
begin tran
update e_rack
set storageCode = '250214001' --250214001:아파츠
  , modified = getDate()
where storageCode = '250211002'--250211002:이지통상
  and rackName > 'A2-11'
  and rackName < 'A2-14'

rollback tran

commit tran

--변경내역!!!!
select sr.itemId, sg.storageName, er.rackName, sum(sr.stockQty) 
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ495'
  --and sr.stockQty > 0
  and rackName > 'A2-11'
  and rackName < 'A2-14'
  and cast(er.modified as date) = '2025-12-02'
group by  sr.itemId, sg.storageName, er.rackName

--A2-11 ~ A2-13 재고자산: 
select sg.storageName, sum(sr.stockQty * ei.centerPrice) --32,663,165.00
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ495'
  and sr.stockQty > 0
  and rackName > 'A2-11'
  and rackName < 'A2-14'
  and cast(er.modified as date) = '2025-12-02'
group by  sg.storageName

------------------------------------------------------------
--매입처 거래 상세내역에 택배비 녹여달라? 택배비 7100원
select 7100/1.1
select * from e_saleItem
where comCode = 'ㅇ479'
  and saleNo = '20251202001'
order by idx desc;

select * from e_saleItem
where saleNo = '20251202001'

begin tran
update e_saleItem
set memo1 = '운송비(7100)포함(54,400+6,455)'
where comCode = 'ㅇ479'
  and saleNo = '20251202001'

rollback tran
commit tran


6455
select 54400+6455

begin tran
update e_saleItem
set costPrice = 54400+6455,
  saleUnitPrice = 54400+6455
where comCode = 'ㅇ479'
  and saleNo = '20251202001'

  rollback tran

  commit tran

54400+택배비



6455
 645

 select * from e_saleItem
 where memo1 like '운송비%'

------------------------------------------------------------

select sum(sr.stockQty * ei.centerPrice) --637,185,169
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0


select sg.storageName, ei.itemNo, ei.itemName, ei.centerPrice, sr.stockQty, (ei.centerPrice*sr.stockQty) totPrice, er.rackName
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ496'
  and sr.stockQty > 0
  and ei.itemNo != '테스트테스트'

  --------------------------------------
-- 매입처 입고날자 변경 11-27,28 =>12-01 S
51117332684
1615068280
--------------------------------------
  select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId 
where ei.itemNo in( '51117332684', '1615068280')
  --and si.regYmd = '2025-12-01'
  and si.comCode = 'ㅂ184'


  begin tran

    update si
	set si.regYmd = '2025-12-01'
	from e_saleItem si
join e_item ei on ei.itemId = si.itemId 
where ei.itemNo in( '51117332684', '1615068280')
  --and si.regYmd = '2025-12-01'
  and si.comCode = 'ㅂ184'

  rollback tran
  commit tran

--------------------------------------
--3Q0919275A9B9 매입처 입고날자 변경 12-01=>11-28 E
--------------------------------------

-----------------------------------------------
--매입처 상세내역 삭제: 제파꺼 대신 우리꺼 납품했는데 제파내역에 남아있다. 삭제해달라.
select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where saleNo = '20260106001'
  and ei.itemNo = '3Q09191339B9'


  begin tran 
 --1.내역 d_saleItem로 옮겨놓고
	insert into  d_saleItem([deleted], [delUserId], [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [plRoNo], [plRoSeq], [storageUseReqNo], [storageUseReqSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created])
    select                   getDate(), 'ssuyong',  [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [storageUseReqNo], [storageUseReqSeq], [plRoNo], [plRoSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created]       
	from e_saleItem
	where 1=1
    and regYmd = '2026-01-06'
    and itemId = '2544625'
	and comCode = 'ㅈ011'

	--2.내역 삭제
	
	delete from e_saleItem
	where 1=1
    and regYmd = '2026-01-06'
    and itemId = '2544625'
	and comCode = 'ㅈ011'

	rollback tran
	commit tran


----------------------------------------------------
------------------------------------------------------------
--매입처 거래 상세내역에 택배비 녹여달라? 택배비 9600원
select 9600, round(9600/1.1, 0) + round(9600/1.1/10, 0); --8727

select round(8727*1.1, 0)


select * from e_saleItem
where comCode = 'ㅂ186'
  and saleNo = '20251204001'
order by idx desc;

select * from e_saleItem
where saleNo = '20251204001'

begin tran
update e_saleItem
set memo1 = '운송비(9600)포함(80,560+8,728)'
where comCode = 'ㅂ186'
  and saleNo = '20251204001'

rollback tran
commit tran


------


select 80560+8728

begin tran
update e_saleItem
set costPrice = 80560+8728,
  saleUnitPrice = 80560+8728
where comCode = 'ㅂ186'
  and saleNo = '20251204001'

  rollback tran

  commit tran

select 88616+9600 = 98,216

 select * from e_saleItem
 where memo1 like '운송비%'

------------------------------------------------------------

select * from e_saleItem
where comCode = 'ㅂ186'


-----------------------------------------------------
--센터가 업데이트

select * from center_au_1210


select ei.itemNo, vw.centerPrice vwPrice, ei.centerPrice itemPrice --6431건이 다름
from e_item ei
join center_au_1210 vw on vw.itemNo = ei.itemNo
where vw.centerPrice != ei.centerPrice
--where vw.centerPrice != ei.salePrice

begin tran
update ei
set ei.centerPrice = vw.centerPrice
  , ei.salePrice = vw.centerPrice
from e_item ei
join center_au_1210 vw on vw.itemNo = ei.itemNo
  where vw.centerPrice != ei.centerPrice

rollback tran
commit tran



--------------------------------------------------
--영규: 오케이상사가 오케이르만으로 나온다.
오케이르만

select * from e_cust
where custName like '오케이상사%'


select * from e_cust
where custName like '%오케이상사%'
  and comCode = 'ㄱ121'


select * from e_user
where userId like '%오케이%'

ㅇ065	(주)오케이상사 (주)오케이르만 647-81-00720
ㅇ498	오케이상사 오케이상사 472-15-02338


select * from e_userLoginHis
where userId like '오케이%'
order by created desc;


select *
from e_user
where comCode in ('ㅇ065', 'ㅇ498')

select * from e_cust
where custCode in ('ㅇ065', 'ㅇ498')
and comCode = 'ㄱ121'


update eu
set eu.userId = '오케이상사dd'
from e_user eu
where comCode in ('ㅇ065')

select * from e_user
where userid = '오케이상사'
--------------------------------------------------
--12/8======================================================================================
--mission: 5387930040 제파 물건 대신 우리 물건으로 판매함.
--e_saleItem 에서 반품내역을 삭제->d_saleItem으로 옮김


select * from e_stockRack sr--373461
join e_item ei on ei.itemId = sr.itemId
where itemNo = '5387930040'
  --and sr.rackCode = '794'
  order by created desc;


  select * from e_Rack
  where rackCode = '1082'

  select * from e_storage
  where storageCode = '250214001'


  select * from e_saleItem
  where 1=1
    and regYmd = '2025-12-08'
    and itemId = '2139435'
	and comCode = 'ㅈ011'

select * from e_Item
where itemNo = '0009050030'

 select distinct saleType from e_saleItem

 --1.내역 d_saleItem로 옮겨놓고
	insert into  d_saleItem([deleted], [delUserId], [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [plRoNo], [plRoSeq], [storageUseReqNo], [storageUseReqSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created])
    select                   getDate(), 'ssuyong',  [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [storageUseReqNo], [storageUseReqSeq], [plRoNo], [plRoSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created]       
	from e_saleItem
	where 1=1
    and regYmd = '2025-12-08'
    and itemId = '2139435'
	and comCode = 'ㅈ011'

	--2.내역 삭제
	begin tran 
	delete from e_saleItem
	where 1=1
    and regYmd = '2025-12-08'
    and itemId = '2139435'
	and comCode = 'ㅈ011'

	rollback tran
	commit tran

--=====================================================================================
------------------------------------------------------------
--12/10 매입상세내역에 운송비 추가 예정=>기존 발주등록 이용함.

20251211002
20251211001

select * from e_place
order by placeNO desc;

select * from e_placeItem
order by placeNO desc;


-------------------------------------------------
--빈박스 메모, 박스 10 있나 확인

select r.memo, sg.storageName,r.rackName,*
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  --and r.rackName like '%A2-11%'
  and sg.consignCustCode = 'ㅇ495'
  and ei.itemNo in (
  '670104593',
'4638807406',
'1646401231',
'1646401131',
'1646201931',
'2043304411',
'2043304311',
'2218800328',
'J9C2047',
'PAD963417',
'5C6827301C',
'561809414',
'5Q0411105HE',
'44300SNA952'
)


begin tran
update r
set r.memo = 'A2-10' --A2-박스번호
from e_rack r
join e_stockRack sr on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_item ei on ei.itemId = sr.itemId
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  --and r.rackName like '%A2-11%'
  and sg.consignCustCode = 'ㅇ495'
  and ei.itemNo in (
  '670104593',
'4638807406',
'1646401231',
'1646401131',
'1646201931',
'2043304411',
'2043304311',
'2218800328',
'J9C2047',
'PAD963417',
'5C6827301C',
'561809414',
'5Q0411105HE',
'44300SNA952'


)
  and r.memo = ''

rollback tran
commit tran

-------------------------------------------------
--12/10 영규: 퀵/용차, 택배, 화물 는 빨간 바탕으로 해달라
select distinct deliWay from e_pcReq
--화면단에서 처리함.

--=====================================================================================
--12/15 부품인 센터가 조정:
select ei.itemNo, ei.centerPrice, v.centerPrice '업체센터가격', ei.centerPrice - v.centerPrice gap
from bp_1215 v
join e_item ei on ei.itemNo = v.itemNo
where v.centerPrice != ei.centerPrice

begin tran
update ei
set ei.centerPrice = v.centerPrice
from e_item ei
join bp_1215 v on v.itemNo = ei.itemNo
where ei.centerPrice != v.centerPrice

rollback tran
commit tran
--=====================================================================================
--12/15 유영규: A2-07-02-04-01에 아무것도 없다. 비어달라.
select * from e_rack
where rackName = 'A2-07-02-04-01'

파일: C:\Users\admin\Desktop\A2-07-02-04-01.xlsx

select *
from e_storage 
where storageCode = '250214001'

select sr.itemId, ei.itemNo, sr.stockQty, sr.rackCode
from e_stockRack sr 
join e_item ei on ei.itemId = sr.itemId
where sr.rackCode = '470'
  and ei.itemNo in ('T2H11606', 'T2H1223')

1879763
1879764

select * from e_stockItem si
join e_item ei on ei.itemId = si.itemId
where 1=1
and ei.itemNo in ('T2H11606', 'T2H1223')
and si.comCode = 'ㄱ121'


select * from vw_storItem_loca
where itemId in ('1879763','1879764')

begin tran

update sr
set sr.stockQty = 0
from e_stockRack sr
where sr.itemId in ('1879763','1879764')
  and sr.rackCode = '470';

UPDATE si
SET 
    si.stockQty = 0,
    si.locaMemo = '',	
    si.uptUserId = 'ssuyong'
FROM dbo.e_stockItem si
where si.itemId in ('1879763','1879764')
  and si.comCode = 'ㄱ121';

rollback tran

commit tran

select * from e_stockRack sr
where sr.itemId in ('1879763','1879764')
	and sr.comCode = 'ㄱ121'

select * from e_stockItem si
where si.itemId in ('1879763','1879764')
	and si.comCode = 'ㄱ121'
--=====================================================================================
--아우토->아파츠->글로벌웍스코리아 판매 에서 
--판매문제 되어 우리가 대신 팔아주기로 함 할인율 20%
select *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and ei.itemNo = '63119450230'

  63119450230 글로벌웍스코리아

select * from e_otherSaleRate
where itemId = '245381'


select * from e_cust
where custName like '글로벌%'
--ㄱ008, 1447

select * from e_otherSaleRate
where itemId = '245381'

insert into e_otherSaleRate
select 'ㄱ121' comCode,
'ㄱ008' custCode,
'245381' itemId, 
'20' purRate,
'ssuyong',
getdate(),
'ssuyong',
getdate()

--

select sg.storageName, er.rackName, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ495', 'ㅇ496')
  and sr.stockQty > 0
  and ei.centerPrice > 1000000
  --and ei.itemId = '985791'
  --and er.rackName = 'A3-01-01-05-01'  
order by sr.modified desc;
--=====================================================================================
--유영규, 2025-12-12 이동을 했어야 하는데 수동입고를 하고 12-16 이동을 하는 바람에, 
--아파츠,이지통상에 중복 재고가 생겼다. : 12-16건에 대해 수동출고를 통해 이지통상 재고 삭제
--=====================================================================================
--stockItemList 재고조회시 조회순서 유지
drop table #tbl_itemH;
CREATE TABLE  #tbl_itemH (
		idx int identity primary key,
		srchKeyword varchar(100),
		srchKeyword_origin varchar(100)
		--,primary key(srchKeyword)
	)
create nonclustered index TIX_itemH_srchKeyWord ON #tbl_itemH(srchKeyword)


declare @i__itemBulk varchar(max) = '4M0816421D힣4M0816421D힣07119904448힣01292317853힣07147201307힣11127582245힣07147443710'
declare @n__item_bulk_origin varchar(max) = @i__itemBulk;

INSERT INTO #tbl_itemH (srchKeyword, srchKeyword_origin)
SELECT s1, s2
FROM (
	SELECT a.val s1, b.val s2, MIN(a.idx) idx
	FROM (
		SELECT idx, val
		FROM dbo.UF_SPLIT(@i__itemBulk, '힣')
		WHERE val <> 'undefined' AND val <> ''
	) a
	CROSS APPLY (
		SELECT idx, val
		FROM dbo.UF_SPLIT(@n__item_bulk_origin, '힣')
		WHERE val <> 'undefined' AND val <> ''
	) b
	WHERE a.idx = b.idx
	GROUP BY a.val, b.val
) z
ORDER BY idx

select * from #tbl_itemH;

--=====================================================================================
--12/19 gjl: VAG 매입율 0.4가 아니고 0.6. 이전 자료 반영 못시키나?
panErp.dbo.up_conStockRpt	@i__workingType='List',    @i__sYmd1='2025-12-01',      @i__eYmd1='2025-12-19',      @i__logComCode='ㄱ121',    @i__logUserId='ssuyong',    @i__consignCustCode='ㅂ022',    @i__orderCustCode='',    @i__rcvCustCode='',    @i__itemId='',    @i__itemNo='',    @i__itemName='',    @i__pIgnoreYN='Y'

select * from e_saleItem
where comCode = 'ㅂ022'
and regYmd >= '2025-12-01'
and saleRate = 0.4
and saleNo = '20251218008'
order by idx desc;

begin tran
update e_saleItem
set saleRate = 0.6,
    costPrice = centerPrice * 0.6,
	saleUnitPrice = centerPrice * 0.6
where comCode = 'ㅂ022'
and regYmd >= '2025-12-01'
and regYmd <= '2025-12-18'
and saleRate = 0.4
and saleNo = '20251218008'

rollback tran
commit tran

0.40	1560.00	3900.00	1560.00
0.60	2340.00	3900.00	2340.00

--==================================================================
--재고현황,재고 현황
select sg.storageName, er.rackName,ei.itemNo, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  --and sg.consignCustCode in ('ㅇ496')
  and sr.stockQty > 0  
  and ei.itemNo in ('4G8853764H2ZZ')
order by ei.itemNo, sr.modified desc;

--=====================================================================
--최근테이블사용내역
SELECT 
    OBJECT_NAME(ius.object_id) AS table_name,
    last_user_seek,
    last_user_scan,
    last_user_lookup,
    last_user_update
FROM sys.dm_db_index_usage_stats ius
JOIN sys.objects o ON ius.object_id = o.object_id
WHERE o.type = 'U'
ORDER BY 
    COALESCE(last_user_update, last_user_seek, last_user_scan, last_user_lookup) DESC;


select * from _SPLOG
where created >= '2025-12-19' 
  and params like '%ssuyong%'
order by created desc;

panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    
@i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      
@i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    
@i__pcReqNo='20251218004',   @i__reqSeq ='',   
@i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='ssuyong'

--==================================================================

--2025-12-22 선종성:
--엠케이파츠 20251020001(saleNo) 금액빠진거:681000 40%적용 
--다섯개 50%적용 으로 변경해달라.
--'63117401132', '2048203539', '63117401132', '33550T2AY21', '2129060803'
-----
  select * from e_saleItem
where saleNo = '20251020001'
  and puComCode = 'ㅇ002'

  select 681000*(0.4)

  begin tran
  update  e_saleItem
  set saleRate = 0.4,
      costPrice = centerPrice * 0.4,
	  saleUnitPrice = centerPrice * 0.4      
where saleNo = '20251020001'
  and puComCode = 'ㅇ002'

  rollback tran

  commit tran


  select *
  from e_saleItem si
  join e_item ei on ei.itemId = si.itemId    
  where si.regYmd >= '2025-11-04'
    and si.regYmd <= '2025-11-26'
	and si.puComCode = 'ㅇ002'
	and ei.itemNo in ('63117401132', '2048203539', '63117401132', '33550T2AY21', '2129060803')
	order by saleNo asc


begin tran
  update  si
  set si.saleRate = 0.5,
      si.costPrice = si.centerPrice * 0.5,
	  si.saleUnitPrice = si.centerPrice * 0.5
  from e_saleItem si
  join e_item ei on ei.itemId = si.itemId    
  where si.regYmd >= '2025-11-04'
    and si.regYmd <= '2025-11-26'
	and si.puComCode = 'ㅇ002'
	and ei.itemNo in ('63117401132', '2048203539', '63117401132', '33550T2AY21', '2129060803')
	

	rollback tran

  commit tran

-----------------------------------------------
--매입처 상세내역 삭제: 8934876010  
select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where saleNo = '20251224001'
  and ei.itemNo = '8934876010'


  begin tran 
 --1.내역 d_saleItem로 옮겨놓고
	insert into  d_saleItem([deleted], [delUserId], [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [plRoNo], [plRoSeq], [storageUseReqNo], [storageUseReqSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created])
    select                   getDate(), 'ssuyong',  [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [storageUseReqNo], [storageUseReqSeq], [plRoNo], [plRoSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created]       
	from e_saleItem
	where 1=1
    and regYmd = '2025-12-24'
    and itemId = '2229100'
	and comCode = 'ㅈ011'

	--2.내역 삭제
	
	delete from e_saleItem
	where 1=1
    and regYmd = '2025-12-24'
    and itemId = '2229100'
	and comCode = 'ㅈ011'

	rollback tran
	commit tran

--==================================================================
select * from _SPLOG
where created >= '2025-12-22' 
  and params like '%ssuyong%'
order by created desc;


select * from e_pcReqItem
where comCode = 'ㄱ121'
  and itemId = '547460'--1676930000
  and gvComCode = 'ㅈ011'

select * from e_stockRack sr
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
join e_item ei on sr.itemId = ei.itemId
where ei.itemNo = '63119450230'
  and sr.comCode = 'ㄱ121'

select sg.storageName, * 
  from e_rack er
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sg.consignCustCode in (
'ㅇ499', 'ㅂ022','ㅇ479', 'ㅇ002', 'ㅂ184', 'ㅈ011', 'ㅂ186', 'ㄱ008')


select * from e_cust
where custCode in ('ㅇ499', 'ㅂ022', 'ㅇ479', 'ㅇ002', 'ㅂ184', 'ㅈ011', 
			'ㅂ186', 'ㄱ008', 'ㅇ496')
  and comCode = 'ㄱ121'


  select sg.storageName, * from e_stockRack sr
  join e_item ei on ei.itemId = sr.itemId
  join e_rack er on er.comCode = sr.comCode
    and er.rackCode = sr.rackCode
  join e_storage sg on sg.comCode = er.comCode
    and sg.storageCode = er.storageCode
where ei.itemNo in ('2188170116')
  --and sr.stockQty > 0
  order by sr.modified desc

  select * 
  from e_cust
  where custName like '대경무역%'

  ------------------------------------------------------------
  /*22일
3G5945207E  
센터가 410,100 원

19일
6766333060   ₩8,100 
7598533040   ₩35,700 
07146875114   ₩8,500 

8일
30622862
센터가 개당 4,700원

4일
21176007709999
센터가 316,000 원

이렇게 제파 매입처 거래상세내역 금액이 변경 되어야 합니다!*/

  --제파 매입처 상세내역 변경: 센터가가 틀려서 발생한 문제임.
  --먼저 e_item 센터카를 수정한후 e_saleItem centerPrice,costPrice,saleUnitPrice 를 수정함.
  select * from e_saleItem si
  join e_item ei on ei.itemId = si.itemId
  where si.puComCode = 'ㅈ011'
    and si.regYmd = '2025-12-09'
	and ei.itemNo = '30622862'

select centerPrice, *
from e_item
where itemNo = '21176007709999'

	begin tran
--update si
set centerPrice = ei.centerPrice,
    costPrice = ei.centerPrice * si.saleRate,
	saleUnitPrice = ei.centerPrice * si.saleRate
from e_saleItem si
  join e_item ei on ei.itemId = si.itemId
  where si.puComCode = 'ㅈ011'
    and si.regYmd = '2025-12-04'
	and ei.itemNo = '21176007709999'

	rollback tran
    commit tran

--=============================================================
create table e_consignCust(
	consignCustCode varchar(10) primary key,
	excludeSelf varchar(10) not null,
	excludeOther varchar(10) not null
)



--insert into e_consignCust
values ('ㅇ499', 'ㅇ499', 'ㅇ496'),
	   ('ㅂ022', 'ㅂ022', 'ㅇ496'),
	   ('ㅇ479', 'ㅇ479', 'ㅇ496'),
	   ('ㅇ002', 'ㅇ002', 'ㅇ496'),
	   ('ㅂ184', 'ㅂ184', 'ㅇ496'),
	   ('ㅈ011', 'ㅈ011', 'ㅇ496'),
	   ('ㅂ186', 'ㅂ186', 'ㅇ496'),
	   ('ㄱ008', 'ㄱ008', 'ㅇ496')


select * from e_consignCust cc
join e_cust ec on ec.custCode = cc.consignCustCode
  and ec.comCode = 'ㄱ121'

--====================================================
업체: 공장개인위탁, 창고: ,수탁업체등록

select * from e_cust
where custCode like 'ㄱ%'
  and len(custCode) = 5
order by custCode desc

--====================================================
orderItemAdd

select * from e_orderItem
where orderNo = '20251224001'
order by orderNo desc;
--====================================================

select * from _spLog
where params like '%ssuyong%'
  and created >= '2025-12-31'
order by created desc;

@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      
@i__orderBy='',    @i__ymdIgnoreYN='N',    
@i__sYmd1='2025-12-26',      @i__eYmd1='2025-12-26',      @i__sYmd2='',    
@i__eYmd2='',    @i__logComCode='ㅂ184',        @i__pcReqNo='',    
@i__gvComCode='',    @i__gvMgr='',    @i__procUserId='',    @i__procStep='',    
@i__gvPlacNo ='',    @i__logUserId='보스카',    @i__itemId='',    @i__itemNo='',    @i__procState=''

--재고수량 전체,위탁업체 제외, 위탁업체
--itemNo별 전체 29,444 항목, 123,189개
select --ei.itemNo, count(*)
  sum(sr.stockQty)
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sr.stockQty > 0
--group by ei.itemNo

--itemNo별 위탁업체 제외(남양주창고만) 13,939 항목, 30,860개
select --ei.itemNo, count(*)
  sum(sr.stockQty)
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sr.stockQty > 0
  and not exists (
	select 1
	from e_consignCust cc
	where cc.consignCustCode = sg.consignCustCode
  )
--group by ei.itemNo

--itemNo별 위탁업체 17,552 항목, 92,329개
select --ei.itemNo, count(*)
  sum(sr.stockQty)
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  and sr.stockQty > 0
  and exists (
	select 1
	from e_consignCust cc
	where cc.consignCustCode = sg.consignCustCode
  )
--group by ei.itemNo

--======================================================
SELECT TOP (1) osr.purRate
         FROM dbo.e_otherSaleRate AS osr WITH (NOLOCK)
         WHERE osr.comCode = @i__forcarComCode
           AND osr.custCode = 'ㅇ495'
           AND osr.itemId  = @i__itemId


select * from out_except_1230

SELECT
    'ㄱ121' AS comCode,
    ei.itemId,
    '578' AS rackCode,
    SUM(v.qty) AS stockQty,
    'ssuyong' AS regUserId,
    GETDATE() AS created,
    'ssuyong' AS uptUserId,
    GETDATE() AS modified
FROM dbo.out_1209 v
JOIN dbo.e_item ei
    ON v.itemNo = ei.itemNo
	and ei.classCode = 'GN'--......검토할 것.
where not exists (
	select 1
	from out_except_1230 ec
	where ec.itemNo = v.itemNo
)
GROUP BY
    ei.itemId;

--=========================================
------------------------------------------------------------
-- 2025-11-18 이지통상(250211002) A2-01 ~ A2-09 랙을 아파츠(250214001)로 변경
------------------------------------------------------------
--실행: A2-01~A2-09.. 이지통상->아파츠로 변경
begin tran
update e_rack
set storageCode = '250214001' --250214001:아파츠
  , modified = getDate()
where storageCode = '250211002'--250211002:이지통상
  and rackName > 'A2-01'
  and rackName < 'A2-10'

rollback tran

commit tran


--변경내역!!!!
select sg.storageName, er.rackName, sum(sr.stockQty) 
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ495'
  --and sr.stockQty > 0
  and rackName > 'A2-01'
  and rackName < 'A2-10'
  and cast(er.modified as date) = '2025-11-18'
group by  sg.storageName, er.rackName

--A2-01~ A2_09 재고자산: 5억8천7백
select sg.storageName, sum(sr.stockQty * ei.centerPrice) --587,090,864.00
from e_stockrack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode 
  and er.rackCode = sr.rackCode
join e_storage  sg on sg.comCode = er.comCode 
  and sg.storageCode = er.storageCode
where sg.consignCustCode = 'ㅇ495'
  and sr.stockQty > 0
  and rackName > 'A2-01'
  and rackName < 'A2-10'
  and cast(er.modified as date) = '2025-11-18'
group by  sg.storageName


---------------------------------------------
--이지통상 재고현황 파악 2025-12-31
select sg.storageName, er.rackName,ei.itemNo, sr.stockQty, ei.centerPrice, 
sr.stockQty * ei.centerPrice sumPrice,
*  
--sum(sr.stockQty * ei.centerPrice) sumPrice --591,340,659
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ496')
  and sr.stockQty > 0
order by er.rackName, ei.itemNo;
---------------------------------------------



select sg.storageName,ei.itemNo, sr.stockQty, sr.rackCode, er.rackName
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ496')
  and sr.stockQty > 0
  and er.rackName >= 'A1-10-01-01-01'
  and er.rackName < 'A4'
order by er.rackName, ei.itemNo;

-------------------------------------------------------------
-----------------------------------------------
--매입처 상세내역 금액및 할인율 변경: 1618048180  
select * from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where 1=1--si.saleNo = '20251205002'
  and si.regYmd >= '2025-12-23'
  and ei.itemNo = '1618048180'


  select centerPrice
  from e_item 
  where itemNo = '1618048180'
 /*
 begin tran
  update si
  set centerPrice = 49700,
      costPrice = 49700 * saleRate,
      saleUnitPrice = 49700 * saleRate
  from e_saleItem si
  join e_item ei on ei.itemId = si.itemId  
  where 1=1--si.saleNo = '20251205002'
  and si.regYmd >= '2025-12-23'
  and ei.itemNo = '1618048180'


begin tran
update si
set saleRate = 0.5,
    costPrice = si.centerPrice * 0.5,
    saleUnitPrice = si.centerPrice * 0.5
from e_saleItem si
join e_item ei on ei.itemId = si.itemId  
where si.saleNo = '20251217001'
  and ei.itemNo = '5C6821105'

  rollback tran
  commit tran
    */


--==================================================================
/*

ㅇ479, 20251231001, 1

select * from e_saleItem
where comCode = 'ㅇ479'
  and saleNo = '20251231001'
  and saleSeq = '1'

  begin tran
update e_saleItem
set saleNo = '20251231001zzz'
where comCode = 'ㅇ479'
  and saleNo = '20251231001'
  and saleSeq = '1'

  rollback tran
  commit tran


*/

--아우토 3,133개 - 벤츠 1647 = 1486
select sr.itemId, ei.itemNo, sr.stockQty, cd.codeName, osr.purRate
from e_stockRack sr
join e_otherSaleRate osr on osr.comCode = sr.comCode  
  and osr.itemId = sr.itemId
join e_item ei on ei.itemId = sr.itemId
join e_code cd on cd.comCode = 'ㄱ121'
  and cd.mCode = '1000'
  and cd.code = ei.makerCode
where sr.comCode = 'ㄱ121'
 and osr.custCode = 'ㅇ499'
  and sr.rackCode = '578'
  and ei.makerCode = 'BZ'
  --and sr.stockQty > 0


--stockRack 에서 아우토 벤츠 삭제
--stockItem 에서도 아우토 벤츠를 삭제해야 하는데...

select * from e_code
where comCode = 'ㄱ121'
  and mCode = '1000'
  and code = 'AU'

select * from e_item
where makerCode = 'AU'

--===========================================================
--아우디 센터가 등록및 수정(center_audi테이블에 data있다.)
--부품등록 센터가 업로드
select * from center_audi
--itemNo, itemName, class?Code, centerPRice, makerCode

select * from e_item
where itemNo = 'N91068002'

select CONVERT(char(10), GETDATE(), 102)

begin tran
MERGE e_item AS T
USING (
    SELECT 
        itemNo,
		itemName,
		class,
        centerPrice,
		makerCode
	FROM center_audi
) AS S
ON T.itemNo = S.itemNo

WHEN MATCHED THEN
    UPDATE SET        
        T.centerPrice    = S.centerPrice,
		T.salePrice = S.centerPrice,
        T.uptYmd   = CONVERT(char(10), GETDATE(), 102)

WHEN NOT MATCHED THEN
    INSERT ([comCode], [itemCode], [itemNo], [factoryNo], [carType], [itemName], [itemNameEn], [makerCode], [brandCode], [saleBrandCode], [genuineYN], [itemExchangeId], [centerPrice], [inPrice], [salePrice], [regUserId], [regYmd],                   [regHms], [uptUserId], [uptYmd],                       [uptHms], [classCode])
    VALUES ('ㄱ000',    '',      S.itemNo,        '',      '',       S.itemName, '',           S.makerCode, S.makerCode,  S.makerCode,         'Y',          '',             S.centerPrice, '', S.centerPrice, 'ssuyong',  CONVERT(char(10), GETDATE(), 102), '',      'ssuyong', CONVERT(char(10), GETDATE(), 102), '',     'GN'       );

rollback tran
commit tran

--===========================================================
--제파 매입처 상세 거래 내역 금액변경(센터가변경에 따른.)
select ei.centerPrice, * 
from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where si.regYmd = '2026-01-02'
  and si.puComCode = 'ㅈ011'
  and ei.itemNo = '63147388765'

begin tran
update si
set si.centerPrice = 118000,
    si.costPrice = 118000 * saleRate,
	si.saleUnitPrice = 118000 * saleRate
from e_saleItem si
join e_item ei on ei.itemId = si.itemId
where si.regYmd = '2026-01-02'
  and si.puComCode = 'ㅈ011'
  and ei.itemNo = '2926200100'

rollback tran
commit tran

--=============================================
--매입처거래내역의 날짜(e_saleItem.regYmd)를 변경하고 나면,
--창고사용요청시 404에러가 뜬다.
--pk dup error가 발생=>...001zzz변경하고나면
--창고사용요청시 404에러가 뜬다.
CALL panErp.dbo.up_storageUseReqItemAdd
### Cause: com.microsoft.sqlserver.jdbc.SQLServerException: varchar 값 '001zzz'을(를) 
데이터 형식 int(으)로 변환하지 못했습니다.
; uncategorized SQLException; SQL state [S0001]; error code [245]; varchar 값 '001zzz'을(를) 
데이터 형식 int(으)로 변환하지 못했습니다.; nested exception is com.microsoft.sqlserver.jdbc.
SQLServerException: varchar 값 '001zzz'을(를) 데이터 형식 int(으)로 
변환하지 못했습니다.] with root cause


20260102048


select * from e_saleItem
where saleNo like '%zz'

select * from e_saleItem
where saleNo like '20251231%'
  and comCode = 'ㅇ479'

--  update e_saleItem
  set saleNo = '20251231003'
  where saleNo = '20251231001zzz'
    and comCode = 'ㅇ479'

select * from e_saleItem
where saleNo like '20251201%'
  and comCode = 'ㅈ011'

  --update e_saleItem
  set saleNo = '20251201009'
  where saleNo = '20251201002zzz'
    and comCode = 'ㅈ011'

select * from e_saleItem
where saleNo = '20251201009'
  and comCode = 'ㅈ011'

  --===============================================================
-- 1/5:  12/31 이지통상 이동건 이제서야 처리하려고 한다.(408,123,744원)
select --sum(sr.stockQty * ei.centerPrice) sumPrice\
sg.storageName, er.rackName,ei.itemNo, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  --and sg.consignCustCode in ('ㅇ496')
 -- and sr.stockQty > 0
  and ei.itemNo = '51117385350'
order by ei.itemNo, sr.modified desc;

select * 
from e_stockItem si
join e_item ei on ei.itemId = si.itemId
  and si.comCode = 'ㄱ121'
where ei.itemNo = '51117211486'


begin tran
update e_rack
set storageCode = '250214001' --250214001:아파츠
  , modified = getDate()
  , uptUserId = 'ssuyong'
where storageCode = '250211002'--250211002:이지통상


rollback tran
commit tran

select si.locaMemo, vw.locaText, * --> 4396개
FROM dbo.e_stockItem si
JOIN dbo.vw_storItem_loca vw ON si.itemId = vw.itemId 
 and vw.comCode = si.comCode
where si.comCode = 'ㄱ121'
  and si.locaMemo like '%이지통상%'
  and exists (
	select 1
	from dbo.e_stockRack sr
	join e_rack er on er.comCode = sr.comCode
	  and er.rackCode = sr.rackCode
	join e_storage sg on sg.comCode = er.comCode
	  and sg.storageCode = er.storageCode
	where sr.comCode = si.comCode
	  and sr.itemId = si.itemId
	  and sg.consignCustCode = 'ㅇ495'	  
  )
order by si.itemId


begin tran
UPDATE si
SET 
    --si.stockQty = vw.stockQty,
    si.locaMemo = vw.locaText,
    si.uptUserId = 'ssuyong',
	si.uptYmd = CONVERT(char(10), GETDATE(), 102),
	si.uptHms = CONVERT(char(8), GETDATE(), 108)
FROM dbo.e_stockItem si
JOIN dbo.vw_storItem_loca vw ON si.itemId = vw.itemId 
 and vw.comCode = si.comCode
where si.comCode = 'ㄱ121'
  and si.locaMemo like '%이지통상%'
  and exists (
	select 1
	from dbo.e_stockRack sr
	join e_rack er on er.comCode = sr.comCode
	  and er.rackCode = sr.rackCode
	join e_storage sg on sg.comCode = er.comCode
	  and sg.storageCode = er.storageCode
	where sr.comCode = si.comCode
	  and sr.itemId = si.itemId
	  and sg.consignCustCode = 'ㅇ495'	  
  )

  
rollback tran
commit tran

--아파츠 21억 13천건, 위탁 108억 25천건
--현재 아파츠 자산 2,171,664,127원 13,182개 항목
select --sum(sr.stockQty * ei.centerPrice) sumPrice --
sg.storageName, er.rackName,ei.itemNo, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode in ('ㅇ495')
  and sr.stockQty > 0

--외부 위탁업체 제외 자산 2,561,510,917 15,970개 항목
select --sum(sr.stockQty * ei.centerPrice) sumPrice --
sg.storageName, er.rackName,ei.itemNo, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode not in (select consignCustCode from e_consignCust)
  and sr.stockQty > 0

--외부 위탁업체 자산 10,869,046,182 25,507개 항목
select sum(sr.stockQty * ei.centerPrice) sumPrice --
--sg.storageName, er.rackName,ei.itemNo, *
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where sr.comCode = 'ㄱ121'
  and sg.consignCustCode in (select consignCustCode from e_consignCust)
  and sr.stockQty > 0

--===============================================================
select * from e_pcReqItem
where itemId in (select itemId from e_item 
                 where itemNo in ('N90286604'))

2087193
3120457

select * from e_stockRack
where itemId in (select itemId from e_item 
                 where itemNo in ('N90286604'))

