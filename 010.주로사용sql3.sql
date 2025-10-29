
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
	AND m.definition LIKE '%up_autoPcProc%'  -- 여기에 찾고자 하는 단어 
ORDER BY 
    o.name;


거래상세내역,위탁재고 판매내역(up_transactionList)은 주문요청판매내역(up_pcReqItemList)시점에 만들어진다.
주문요청판매내역(up_pcReqItemList)시점에서 위탁마진율(UF_cCustPerItemRate)을 'e_saleItem'에 삽입 계산한다.
이 위탁마진율이 존재하지 않으면 값을 못가져오고 0이 된다.

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

51247463163 인터카스1,아우토1개인데 주문이 들어와서 보니 아우토는 안보이고 인터카스만 보여서,
인터카스 걸로 주문처리 완료=> 이제서야, 아우토1개가 보인다.

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




	--loca memo
select string_agg('['+s.storageName+']'+r.rackName+ ' ' + 
		cast(isnull(sr.stockQty, '') as varchar(100)), ' * ') localMemo
from e_stockRack sr
join e_stockItem st on st.comCode = sr.comCode and st.itemId = sr.itemId
left join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
left join e_storage s on s.comCode = r.comCode and s.storageCode = r.storageCode
where 1=1
  and sr.stockQty > 0
  and s.consignCustCode <> 'ㅇ499'
  and s.consignCustCode <> 'ㅂ022'
  and s.consignCustCode <> 'ㅇ479'
  and s.consignCustCode <> 'ㅇ002'
  and s.consignCustCode <> 'ㅇ496'
  and st.itemId = (select itemId from e_item where itemNo = '테스트테스트')

  select * from vw_storItem_loca
  where itemId = (select itemId from e_item where itemNo = '테스트테스트')


  select * from e_item
  where itemNo = '1568851622'--498031


  select * from e_stockRack
  where itemId = '498031'

select * from e_stockItem
  where itemId = '498031'

  select * from e_rack
  where rackCode = '775741'

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



select * from _SPLOG
where created >= '2025-10-28'   
  and params like '%ssuyong%'
order by created desc;
