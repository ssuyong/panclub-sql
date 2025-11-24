
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
*/


------------------------------------
------------------------------------
------------------------------------
--속도개선 인덱스 생성(100배이상 빨라짐)
/*
CREATE INDEX ssy_IX_stockRack_item
  ON dbo.e_stockRack(comCode, itemId)
  INCLUDE (stockQty, rackCode);

CREATE INDEX ssy_IX_storage_consign
  ON dbo.e_storage(comCode, storageCode)
  INCLUDE (workableYN, validYN, consignCustCode);

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

CREATE NONCLUSTERED INDEX ssy_IX_e_pcReqItem_itemId_procStep
ON dbo.e_pcReqItem (itemId, procStep)
INCLUDE (gvQty, comCode);

--불필요한 인덱스 삭제
--원본: CREATE INDEX [IX_e_placeItem_placeNo] ON [dbo].[e_placeItem]([placeNo])
	  drop index IX_e_placeItem_placeNo ON dbo.e_placeItem;
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

SELECT max(_s.consignCustCode) consignCustCode, _sr.rackCode, sum(_sr.stockQty) stockQty
from dbo.e_stockRack _sr
left join dbo.e_stockItem st on st.comCode = _sr.comCode and _sr.itemId = st.itemId
LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
--AND (@i__consignCustCode = '''' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
and _sr.stockQty > 0
AND _s.consignCustCode <> 'ㅇ499'
AND _s.consignCustCode <> 'ㅂ022'
AND _s.consignCustCode <> 'ㅇ479'
AND _s.consignCustCode <> 'ㅇ002'
--AND _s.consignCustCode <> 'ㅂ184'
AND _s.consignCustCode <> 'ㅇ496'
group by _sr.rackCode

--stockItemList분석


--이슈!!!!!!!!!!!!!!!!
--엠케이건 주문시 우리쪽에 아이템이 비어서 들어옴.

select * from _SPLOG
where created >= '2025-10-20' 
  --and params like '%20251020007%'
  and params like '%엠케이%'
order by created desc;

--결론: 엠케이 삽입후 up_reqItemList에서도 엠케이 추가해야 함.
--신규 위탁시: up_stockItemList,up_reqItemList,수탁업체매입율 등록!!!

---------------------------------------

select * from e_storage
where storageName like '%엠케이%'

select * from e_rack
where storageCode = '20250925001'

select * from e_stockActions
where rackCode = '950'


select * from _SPLOG
where created >= '2025-10-28'  
  and params like '%ssuyong%'
order by created desc;

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
	AND m.definition LIKE '%e_saleItem%'  -- 여기에 찾고자 하는 단어 
ORDER BY 
    o.name;


--거래상세내역,위탁재고 판매내역(up_transactionList)은 주문요청판매내역(up_pcReqItemList)시점에 만들어진다.
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

select * from _SPLOG
where created >= '2025-10-23'   
  --and params like '%ssuyong%'
  --and params like '%다온%'
order by created desc;
----------------------------------
181392	675.00

select * from e_rlItem
where itemId = '181392'

select * from e_item ei
where ei.itemNo = '51471911992'

A-parts 판매가상법인
아파츠 - A-parts에 위탁맡기는 업체

declare @i__consignCustCode varchar(100) = 'ㄷ199'
SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' 
				+cast(ISNULL( _sr.stockQty,'''') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		join e_stockItem st on st.comCode = _sr.comCode and st.itemId = _sr.itemId
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode 
		  AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode 
		  AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode 
			or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
		and _sr.stockQty > 0
		AND _s.consignCustCode <> 'ㅇ499' --아우토서울
		AND _s.consignCustCode <> 'ㅂ022' --VAG 군포
		AND _s.consignCustCode <> 'ㅇ479' --인터카스 부산
		AND _s.consignCustCode <> 'ㅇ002' --엠케이 대구
		AND _s.consignCustCode <> 'ㅇ496' --이지통상 남양주





SELECT SUSER_SNAME();
--위험!!!!!!!!!!!!!! 백업한DB로 다이어그램 만들기위해.test db만듦
/*
SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE name = 'panErp_restore_test';

SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE name = 'panErp_restore_test';

--ALTER AUTHORIZATION ON DATABASE::panErp_restore_test TO sa;

ALTER LOGIN sa WITH PASSWORD = 'pan@mall0320!A';

ALTER AUTHORIZATION ON DATABASE::panErp_restore_test TO pan_mall;
*/




  select * from vw_storItem_loca
  where itemId = (select itemId from e_item where itemNo = '테스트테스트')



  select * from e_rack
  where rackName = '위탁회수랙'


  select * from _splog
  where created > '2025-10-27'
    and params like '%ssuyong%'
  order by created desc;

panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20251027003',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='ssuyong'
panErp.dbo.up_pcReqList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__ymdIgnoreYN='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',        @i__pcReqNo='20251027003',    @i__gvComCode='',    @i__gvMgr='',    @i__procUserId='',    @i__procStep='',    @i__gvPlacNo ='',    @i__logUserId='ssuyong',    @i__itemId='',    @i__itemNo='',    @i__procState=''


select * from e_stockRack
where itemId = (select itemId from e_item where itemNo = '51117422251')

select * from e_rack
where rackCode = '578'

select * from e_storage
where storageCode = '250515001'

1568851622

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',  
@i__pcReqNo='20251027003',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'


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



select *
from e_storage
where storageName like '%대기%'--250304001	신품	남양-출고대기창고

select * from  e_stockRack sr
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_item ei on ei.itemId = sr.itemId
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where ei.itemNo = '0039909497'


select distinct er.rackCode, sg.storageName
from e_rack er 
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where er.rackCode in ('1', '100', '577')
  and er.comCode = 'ㄱ121'

1	남양-출고대기창고
100	이지통상 위탁
577	테스트250207_판매


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



select * from _SPLOG
where cast(created as date) = '2025-10-31' 
  and params like '%ssuyong%'
order by created desc;



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




SELECT  a.itemId , sum(a.stockQty) stockQty , 
STRING_AGG(  storageName , '^') storageName  
	FROM dbo.e_stockRack a 
	LEFT OUTER JOIN dbo.e_rack b ON a.comCode = b.comCode 
	  AND a.rackCode = b.rackCode
	LEFT OUTER JOIN dbo.e_storage stor ON stor.comCode = a.comCode 
	  AND stor.storageCode = b.storageCode
	WHERE a.comCode = 'ㄱ121' 
	      AND b.storageCode in (SELECT val 
		                        FROM dbo.UF_SPLIT('20250808001','^')) 
		  AND a.stockQty >0 
		  AND a.itemId <> 0
		  and stor.consignCustCode <> 'ㅇ496'
	GROUP BY a.itemId  
	

--11/4======================================================================================
--mission: 0009050030 인터카스 물건 판매되었다가 반품되었는데 쓸만하여 우리 물건으로 돌림,
           --반품으로 인해 인터카스 판매가 취소되지 않게 유지시켜야 함
		   --:e_saleItem 에서 반품내역을 삭제->d_saleItem으로 옮김


select * from e_stockRack sr--373461
join e_item ei on ei.itemId = sr.itemId
where itemNo = '0009050030'
  --and sr.rackCode = '794'
  order by created desc;


  select * from e_Rack
  where rackCode = '1073'

  select * from e_storage
  where storageCode = '250214001'


  select * from e_saleItem
  where 1=1
    and regYmd = '2025-11-04'
    and itemId = '373461'
	and comCode = 'ㅇ479'

select * from e_Item
where itemNo = '0009050030'

 select distinct saleType from e_saleItem

 --1.내역 d_saleItem로 옮겨놓고
	insert into  d_saleItem([deleted], [delUserId], [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [plRoNo], [plRoSeq], [storageUseReqNo], [storageUseReqSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created])
    select                   getDate(), 'ssuyong',  [comCode], [saleNo], [saleSeq], [saleType], [plComCode], [plPlaceNo], [plPlaceSeq], [puComCode], [itemId], [qty], [salePriceType], [saleRate], [costPrice], [centerPrice], [saleUnitPrice], [pcReqNo], [pcReqSeq], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [storageUseReqNo], [storageUseReqSeq], [plRoNo], [plRoSeq], [puRackCode], [riNo], [riSeq], [memo1], [idx], [created]       
	from e_saleItem
	where 1=1
    and regYmd = '2025-11-04'
    and itemId = '373461'
	and comCode = 'ㅇ479'

	--2.내역 삭제
	begin tran 
	delete from e_saleItem
	where 1=1
    and regYmd = '2025-11-04'
    and itemId = '373461'
	and comCode = 'ㅇ479'

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
select ei.itemNo, sr.stockQty, sr.* from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where sr.comCode = 'ㄱ121'
  --and sr.rackCode >= 74
  --and sr.rackCode < =738
  and sg.consignCustCode = 'ㅇ496'

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

select ei.itemNo, sr.rackCode, stockQty
from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack r on r.comCode = sr.comCode 
  and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = sr.comCode
  and sg.storageCode = r.storageCode
  and sg.consignCustCode = 'ㅇ496'
where sr.comCode = 'ㄱ121'
  --and sr.stockQty > 0
  and ei.itemNo in
(
'447905180480',
'963023U203',
'2228853721',
'1778801100',
'5214633060',
'5K0857508AF9B9',
'4G0890905'
)
order by ei.itemNo

select * from e_item
where itemNo like '971861531A6B0'

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
  and ei.itemNo in ('963023U203',
'2228853721',
'1778801100',
'5214633060',
'5K0857508AF9B9',
'4G0890905')

select * from e_rack er
join e_storage sg on sg.storageCode = er.storageCode
where er.rackCode = '1348'
/*
select *
from e_rack
where rackCode = 1348
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
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
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

--stockItemList에서 사용되는 temp
DECLARE @ErpOperateComCode varchar(50) =  ''
SELECT @ErpOperateComCode= comCode from dbo.UF_ErpOperate('')
declare @i__logComCode varchar(100) = 'ㄱ121'--(SELECT top 1 comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate(''))))
        , @i__consignCustCode varchar(100) = ''
DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')
DECLARE @n__4carComCode varchar(10) = 'ㄱ121'
DECLARE @n__salePriceType3 varchar(10) = (SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode AND custCode = @i__logComCode) 
DECLARE @n__isPan3 VARCHAR(10) = IIF(@i__logComCode in (SELECT * FROM dbo.UF_GetChildComcode('ㄱ000')),'Y','N')
declare @i__itemNo varchar(20) = '테스트테스트'

select  _sr.itemId ,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	  AND _s.storType = '신품' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtNew,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	  AND _s.storType = '중고' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtUsed,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	   AND _s.storType = '리퍼' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtRefur,
	sum(IIF(_s.consignCustCode = @i__logComCode  
	   AND _s.storType = '불량' 
	  , iif(_s.validYN ='Y' , ISNULL(stockQty,0),0) , 0)) qtyCtBad ,
	sum(IIF((isnull(_s.consignCustCode, '') <> @i__logComCode 
	--로그인업체와 보유업체가 다르고 신품이고 불량창고인 경우나,
	  AND _s.storType = '신품'  
	  AND ISNULL(_s.consignViewYN,'N') <> 'N' --Y:불량창고 
	  AND @n__isPan3 = 'N') 
	  OR (_s.consignCustCode = @i__logComCode 
	  --로그인업체와 보유업체가 같을때 신품 가용재고
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
	join e_item ei on ei.itemId = _sr.itemId
	left join dbo.e_rack _r on _r.comCode = _sr.comCode  
	  AND _r.rackCode = _sr.rackCode  
	left join dbo.e_storage _s on _s.comCode = _r.comCode  
	  AND _s.storageCode = _r.storageCode 
	where    1=1--@n__4carComCode = _sr.comCode  
	  --AND @n__4carComCode <> @i__logComCode  
	  and isnull(_s.consignCustCode,'') not in ('ㅇ496')
	  and ei.itemNo = '테스트테스트'
	GROUP BY _sr.itemId;

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
  select * from e_cust
  where custName like '보스카%'

보스카통상 ㅂ184 재고 업로드
가상: 테스트테스트 577->1326
SELECT * from e_rack er
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
  and sg.consignCustCode in( 'ㅂ184', 'ㅌ089')

  랙:대구2 1326
  창고:있음.ㅂ184
  기본랙:대구2


SELECT * from e_stockRack sr
join e_item ei on ei.itemId = sr.itemId
join e_rack er on er.comCode = sr.comCode
  and er.rackCode = sr.rackCode
join e_storage sg on sg.comCode = er.comCode
  and sg.storageCode = er.storageCode
where ei.itemNo = '31407831'

select *
from vw_storType_stock vw
join e_item ei on ei.itemId = vw.itemId
where ei.itemNo = '7575542020'

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
  