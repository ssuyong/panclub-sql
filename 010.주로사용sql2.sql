select * from e_cust
where custCode = 'ㅇ002'

select distinct i.makerCode, cd.codeName
from e_item i
join e_code cd on cd.mCode = '1000'
  and i.makerCode = cd.code;

select * from e_code
where mCode = '1000'
  and codeName = '벤츠';


select * from e_stockItemOuterNonDsp;


declare @sql nvarchar(2000) = 'select 122';
exec SP_EXECUTESQL @sql;


select * from dbo.e_storage -- 250515001
WHERE storageName like ( '%아우토%')-- , '%VAG%', '%이지통상%', '%엠케이%', '%인터카스%')

select * from dbo.e_storage -- 250710001
WHERE storageName like ( '%VAG%') --, '%이지통상%', '%엠케이%', '%인터카스%')

select * from dbo.e_storage -- 250211002
WHERE storageName like ( '%이지통상%') --, '%%', '%엠케이%', '%인터카스%')

select * from dbo.e_storage -- 20250925001
WHERE storageName like ( '%엠케이%') --, '%%', '%%', '%인터카스%')


select * from dbo.e_storage -- 20250808001
WHERE storageName like ( '%인터카스%') --, '%%', '%엠케이%', '%%')

select distinct s.storageCode, s.storageName, rackCode 
from dbo.e_Rack r
left join dbo.e_storage s on r.storageCode = s.storageCode
where r.storageCode in ('250515001','250710001','250211002','20250925001','20250808001');

select MAX(try_convert(int, rackCode)) mxRack, MIN(try_convert(int, rackCode)) mnRack
from dbo.e_Rack r
left join dbo.e_storage s on r.storageCode = s.storageCode
where r.storageCode in ('250211002')

select * from e_stockRack
where itemId = (select itemId from e_item where itemNo = '31446866');


select * from e_stockItem
where itemId = (select itemId from e_item where itemNo = '31446866');




panErp.dbo.up_stockItemList	@i__workingType='SALE_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',    @i__eYmd1='',    @i__sYmd2='',    @i__eYmd2='',        @i__storCode='',    @i__itemId=0,    @i__itemNo='',    @i__itemName='',    @i__makerCode='',    @i__classCode='',    @i__storName='',      @i__bulkSrchType='itemNo',    @i__itemBulk='31446866',    @i__checkType='ALL',    @i__outStorCode='',    @i__storageCode='',    @i__noRealYN='N',    @i__qtyZeroYN='N',    @i__consignCustCode='',      @i__logComCode='ㄱ121',    @i__logUserId='ssuyong'

panErp.dbo.up_itemList	@i__workingType='STOCKWRUP_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2025-09-10',      @i__eYmd1='2025-10-10',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',    @i__logUserId='ssuyong',    @i__itemId=0,    @i__itemCode='',    @i__itemNo='16740107007X21',    @i__factoryNo='',    @i__itemName='',      @i__classCode='',    @i__shareYN='',    @i__consignCustCode='',    @i__srchEqualItemNo='',    @i__makerCode='',    @i__immediateRlYN=''

SELECT comCode FROM dbo.UF_GetGroupComCode((select comCode from UF_ErpOperate('')))

select * from e_stockItem;

select sum(stockQty) from e_stockRack
where rackCode = '775774';


select * from e_rack
where rackCode = '775774'

/* osr rebuild

-- 1) 락 확인
EXEC sp_who2 active;

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



;WITH StockAgg AS (
  SELECT 
      sr.comCode, sr.itemId,
      SUM(sr.stockQty) AS qty1,
      SUM(CASE WHEN s.workableYN='Y' THEN sr.stockQty END) AS workableQty
  FROM dbo.e_stockRack sr
  JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
  JOIN dbo.e_storage s ON r.comCode = s.comCode AND r.storageCode = s.storageCode
  GROUP BY sr.comCode, sr.itemId
)
SELECT i.*, st.qty1, st.workableQty
FROM dbo.e_stockItem i
LEFT JOIN StockAgg st ON st.comCode=i.comCode AND st.itemId=i.itemId;


select * from e_itemCost
where itemId = (select itemId from e_item where itemNo = '16740107007X21');

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

sp_help e_stockItem;

select itemNo, makerCode , cd.codeName
from e_item i
join e_code cd on cd.comCode= 'ㄱ121' and cd.mCode = '1000' and cd.code = i.makerCode
where itemNo in ('AD2343548DA')



SELECT _s.consignCustCode, *
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

select *
from dbo.e_othersalerate
where itemId = (select itemId from e_item where itemNo = '13628650714');


select * from dbo.e_othersalerate
where itemId = '35706'

select len(itemNo) from e_item

--10/14엠케이 재고업로드 두건뺴고 다 안들어감.
select *
from e_otherSaleRate osr
join e_item i on i.itemId = osr.itemId
join mk_1014 mk on mk.itemNo = i.itemNo
where osr.comCode = 'ㄱ121';

----------------------------------------------------
--엠케이 애프터 등록, 전환 : 내일 계속 보자.
--10/16
select * from e_item
where classCode = 'AM';

34116750148 34116774258

select * from e_item
where itemNo in ('34116774258');--7241393

--이렇게 삽입해도 재고다중품번조회에서 보이지 않는다. itemAdd를 확인해 봐야 한다.==>재고수량이 없어서 안나온 거임.
--insert into e_item([comCode], [itemCode], [itemNo], [factoryNo], [carType], [itemName], [itemNameEn],  [makerCode], [brandCode], [saleBrandCode], [genuineYN], [itemExchangeId], [centerPrice], [inPrice], [salePrice], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [productYear], [home], [equipPlace], [color], [shine], [weight], [cbm], [width], [depth], [height], [classCode], [shareYN], [consignCustCode], [class], [cosignCustCode], [dcExceptYN], [immediateRlYN], [noRealYN])
select [comCode], [itemCode], [itemNo], [factoryNo], [carType], [itemName], [itemNameEn], 'AT' [makerCode], '' [brandCode], '' [saleBrandCode], 'N' [genuineYN], [itemExchangeId], 0.00 [centerPrice], 0.00 [inPrice],  0.00 [salePrice], 'ssuyong' [regUserId], [regYmd], [regHms], 'ssuyong' [uptUserId], [uptYmd], [uptHms], [productYear], [home], [equipPlace], [color], [shine], [weight], [cbm], [width], [depth], [height], 'AM' [classCode], [shareYN], [consignCustCode], [class], [cosignCustCode], [dcExceptYN], [immediateRlYN], [noRealYN] 
from e_item
where itemNo in (
'34116774258')
;
/*
begin tran
insert into e_item([comCode], [itemCode], [itemNo], [factoryNo], [carType], [itemName], [itemNameEn],  [makerCode], [brandCode], [saleBrandCode], [genuineYN], [itemExchangeId], [centerPrice], [inPrice], [salePrice], [regUserId], [regYmd], [regHms], [uptUserId], [uptYmd], [uptHms], [productYear], [home], [equipPlace], [color], [shine], [weight], [cbm], [width], [depth], [height], [classCode], [shareYN], [consignCustCode], [class], [cosignCustCode], [dcExceptYN], [immediateRlYN], [noRealYN])
select [comCode], [itemCode], [itemNo], [factoryNo], [carType], [itemName], [itemNameEn], 'AT' [makerCode], '' [brandCode], '' [saleBrandCode], 'N' [genuineYN], [itemExchangeId], 0.00 [centerPrice], 0.00 [inPrice],  0.00 [salePrice], 'ssuyong' [regUserId], [regYmd], [regHms], 'ssuyong' [uptUserId], [uptYmd], [uptHms], [productYear], [home], [equipPlace], [color], [shine], [weight], [cbm], [width], [depth], [height], 'AM' [classCode], [shareYN], [consignCustCode], [class], [cosignCustCode], [dcExceptYN], [immediateRlYN], [noRealYN] 
from e_item
where itemNo in (
'34116750148','34116774258','0004209004','0004209920','0004230230','0014209920','0024202120',
'0024204420','0024205220','0034201920','0034202820','0034202920','0034205320','0034205820',
'0034205920','0034206220','0034206520','0044205120','0044209420','0054200720','0054201020',
'0054201720','0054204920','0446506030','0446522312','0446530400','0446648020','05093183AB',
'05191271AA','06450S9AA01','1126718','1522062','1607083280','1611838880','1634200320',
'1634200720','1644202220','1644202720','1684200420','1694200420','1694200820','22825195',
'34112282995','34112283365','34113404362','34116761246','34116761249','34116767147','34116771868',
'34116774258','34212284685','34213403241','34216753850','34216761239','34216761248','34216761281',
'34216763043','34216775678','34216776937','34216778168','34216788284','34216790761','34216790966',
'3D0698451A','425256','425269','425419','425476','4A0698151','4D0698451B','4E0698151','68020256AA',
'8E0698151N','95835193900','98635293910','C2C42014','SFP500010','SFP500045','XR858178')
rollback tran
commit tran
*/
select * from e_item
where itemNo in ('98635293910')--( '34116750148','34116774258')
 --and makerCode = 'AT'
order by itemId

--delete from e_item 
where itemId = '7241474'
----------------------------------------------------

select * from e_storage
where storageName like '%이지통상%'

select * from e_rack
where storageCode = '250211002'
order by RIGHT(REPLICATE('0', 5)+rackCode, 5)

--itemList분석:--------------------------------------------------
SELECT DISTINCT sr.comCode, sr.itemId,sr.rackCode, sr.stockQty --, sr.rackCode 
FROM e_stockRack sr
JOIN dbo.e_rack r ON sr.comCode = r.comCode 
  AND sr.rackCode = r.rackCode
WHERE sr.comCode = 'ㄱ121' 
	AND r.storageCode = '250211002' --이지통상
	AND sr.stockQty <> 0
order by sr.itemId

select * from e_item
where itemId = '6332'

select * from e_stockRack
where rackCode = '950';

select * from e_othersalerate
where comCode = 'ㄱ121'
  and custCode = 'ㅇ002';

  select * 
  from e_stockRack sr
  join e_item ei on ei.itemId = sr.itemId
  where ei.itemNO = '34216761239'

  select * from e_storage
  where storageName like '%아파츠%';

  select * from vw_storItem_loca;

------------------------------------------------------------------
 -- 애프터 품번-다중조회 => 센터가 등록 S
 select *
 from e_item ei1
join e_item ei2 on ei2.itemNo = ei1.itemNo and ei2.makerCode != ei1.makerCode
where ei1.itemNo = '0004209004'
  and ei1.makerCode = 'AT';
 
 --AT의 센터가는 정품의 센터가와 같다. 다만 할인율을 60%로 한다.
 /*
begin tran
update ei1
set ei1.centerPrice = ei2.centerPrice
   ,ei1.salePrice = ei2.centerPrice
from e_item ei1
join e_item ei2 on ei2.itemNo = ei1.itemNo and ei2.classCode = 'GN'
where ei1.itemNo in ('0004209004','0004209920','0004230230','0014209920','0024202120','0024204420',
'0024205220','0034201920','0034202820','0034202920','0034205320','0034205820',
'0034205920','0034206220','0034206520','0044205120','0044209420','0054200720',
'0054201020','0054201720','0054204920','0446506030','0446522312','0446530400',
'0446648020','05093183AB','05191271AA','06450S9AA01','1126718','1522062',
'1607083280','1611838880','1634200320','1634200720','1644202220','1644202720',
'1684200420','1694200420','1694200820','22825195','34112282995','34112283365',
'34113404362','34116750148','34116761246','34116761249','34116767147','34116771868',
'34116774258','34212284685','34213403241','34216753850','34216761239','34216761248',
'34216761281','34216763043','34216775678','34216776937','34216778168','34216788284',
'34216790761','34216790966','3D0698451A','425256','425269','425419','425476','4A0698151',
'4D0698451B','4E0698151','68020256AA','8E0698151N','95835193900','98635293910','C2C42014',
'SFP500010','SFP500045','XR858178')
  and ei1.makerCode = 'AT';

  rollback tran
  commit tran;
*/
  select @@TRANCOUNT
------------------------------------------------------------------
 -- 애프터 품번-다중조회 => 센터가 등록 E
------------------------------------------------------------------

--stockItemList분석
SELECT DISTINCT sr.comCode, sr.itemId 
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		WHERE sr.comCode = 'ㄱ121' 
		  --AND r.storageCode = '' 
		  AND sr.stockQty <> 0

select * 
from vw_storType_stock vw
join e_item ei on ei.itemId = vw.itemId 
where ei.itemNo = '7586733050';

select * from e_code
where mCode = '1000'
  and code = 'TT';

 select * from e_item;

 --너무 느려서 인덱스 생성해 봄:쓸데없는 작업이었음. 다시 삭제함.
 /*
CREATE INDEX ssy_IX_item_itemNo
  ON dbo.e_item(comCode, itemNo)
  INCLUDE (itemName, makerCode, classCode, salePrice);

CREATE INDEX ssy_IX_item_maker_class
  ON dbo.e_item(comCode, makerCode, classCode)
  INCLUDE (itemId, itemNo, itemName);

  drop index ssy_IX_item_itemNo ON dbo.e_item
  drop index ssy_IX_item_maker_class ON dbo.e_item
  */

SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' +cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		left join dbo.e_stockItem st on st.itemId = _sr.itemId
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode 
		AND ('' = '' or _s.consignCustCode = 'ㄱ000' or (_s.consignCustCode is null AND _s.comCode = 'ㄱ000'))
		and _sr.stockQty > 0
		AND _s.consignCustCode = 'ㅇ002'


select *
from e_stockItem st
left join e_stockRack sr on sr.comCode = st.comCode and sr.itemId = st.itemId
left join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
left join e_storage s on s.comCode = r.comCode and s.storageCode = r.storageCode
where s.consignCustCode = 'ㅇ002'
  and sr.stockQty > 0;


select * 
from e_stockRack sr
join e_rack r on r.comCode = sr.comCode and sr.rackCode = r.rackCode
join e_storage s on s.comCode = r.comCode and s.storageCode = r.storageCode
join e_stockItem st on st.comCode = s.comCode and st.itemId = sr.itemId
where s.consignCustCode = 'ㄷ199'
;

select * from e_rack
where rackCode = '932'

select * from e_storage
where storageCode = '250923001'

select * from e_otherSaleRate
where custCode = 'ㄷ199'



select * from e_stockItem
where itemId = '7000'

select * from e_stockRack
where itemId = '7000'

select * from vw_storItem_loca
where itemId = '7000'

select it.itemNo, it.qty qty, it.purRate purRate --2392
from it_1014 it
join e_item ei on ei.itemNo = it.itemNo
where ei.classCode = 'GN'


select itemNo, sum(qty) qty, max(purRate) purRate --2360
from (
select it.itemNo, it.qty, osr.purRate 
from it_1014 it
join e_item i on i.itemNo = it.itemNo and i.classCode = 'GN'
join e_otherSaleRate osr 
	on osr.comCode = 'ㄱ121' 
	and osr.custCode = 'ㅇ479'
	and osr.itemId = i.itemId
) a
group by itemNo
order by itemNo;


--이슈!!!!!!!!!!!!!!!!
--엠케이건 주문시 우리쪽에 아이템이 비어서 들어옴.

select * from _SPLOG
where created >= '2025-10-20' 
  --and params like '%20251020007%'
  and params like '%엠케이%'
order by created desc;

--정상: 스카이파츠
panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20251020007',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='ssuyong'

--비정상:신구파츠
panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20251020008',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='ssuyong'


select * from e_user
--where userId like '%디에스%파츠%'
where comCode = 'ㄷ203' --2118200664 ㄷ203	디에스


select * from e_item
where itemNo = '2118200664'

select * from e_stockRack
where itemId = '757404'

select * from e_rack
where rackCode = '950'

select * from e_storage 
where storageCode = '20250925001'



select * from vw_storType_stock vw
join e_item ei on ei.itemId = vw.itemId
where ei.itemNo = '2118200664'



--결론: 엠케이 삽입후 up_reqItemList에서도 엠케이 추가해야 함.

---------------------------------------
2148851700
이 품목 25% 할인으로 아우토 재고로 하나만 올려주세요 !
:수동입고 1개, e_otherSaleRate 26->25 update

select * 
from e_otherSaleRate osr
where itemId = (select itemId from e_item where itemNo = '2148851700')

select *
from e_otherSaleRate osr
where itemId = '6937963'

--update e_otherSaleRate
set purRate = 25
where itemId = '6937963'

select * from e_stockRack sr
where itemId = '6937963'

select * from e_stockItem
where itemId = '6937963'

--

panErp.dbo.up_transactionList	@i__workingType='OUT_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2025-10-20',      @i__eYmd1='2025-10-20',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㅇ002',    @i__logUserId='엠케이',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='',    @i__custOrderNo='',     @i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='',       @i__custCode=''

select * from e_storage
where storageName like '%엠케이%'

select * from e_rack
where storageCode = '20250925001'

select * from e_stockActions
where rackCode = '950'


select * from _SPLOG
where created >= '2025-10-21'  
  and params like '%다온%'
order by created desc;


panErp.dbo.up_transactionList	@i__workingType='OUT_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2025-10-20',      @i__eYmd1='2025-10-21',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄷ199',    @i__logUserId='다온',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='',    @i__custOrderNo='',     @i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='',       @i__custCode=''

select * from e_orderItem
where custCode = 'ㄷ199';

select * from e_storage
--where storageName like '%다온%'
where storageCode = '250609001'

select * from e_rack
where rackCode = '612'


select comCode, rackCode,itemId,unitPriceConsignAdjust 
from e_stockActions
order by created desc


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
    --AND m.definition LIKE '%unitPriceConsignAdjust%'  -- 여기에 찾고자 하는 단어 
	--AND m.definition LIKE '%UF_cCustPerItemRate%'  -- 여기에 찾고자 하는 단어 
	AND m.definition LIKE '%up_autoPcProc%'  -- 여기에 찾고자 하는 단어 
ORDER BY 
    o.name;


거래상세내역,위탁재고 판매내역(up_transactionList)은 주문요청판매내역(up_pcReqItemList)시점에 만들어진다.
주문요청판매내역(up_pcReqItemList)시점에서 위탁마진율(UF_cCustPerItemRate)을 'e_saleItem'에 삽입 계산한다.
이떄 위탁마진율이 존재하지 않으면 값을 못가져오고 0이 된다.

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

select * from e_storage
where storageCode = (
select top 1 storageCode
from e_rack er
where er.rackCode = '578')

select * from e_stockItem
where itemId = (select itemId from e_item where itemNo = '1678854703')

select * from e_storage
where storageCode = '250923001'

select * from e_rack
where rackName = 'A1-02-03-03-06'

select * from e_logisRack
where rackName = 'A1-02-03-03-06'



select rackName, rackCode, storageCode 
  from dbo.e_rack
  where comCode = 'ㄱ121'
    and storageCode = '250923001'--다온위탁
  order by rackName asc;


  select * from vw_storItem_loca
  where itemId = (select itemId from e_item where itemNo='테스트테스트')

    select * from e_stockRack
  where itemId = (select itemId from e_item where itemNo='테스트테스트')

   select * from e_stockItem
  where itemId = (select itemId from e_item where itemNo='테스트테스트')


select * from _splog
where created > '2025-10-24'
  and (params like '%ssuyong%' )--or params like '%테스트%'
  and sp = 'panErp.dbo.up_stockItemList'
order by created desc;

SELECT STRING_AGG('['+_s.storageName+']' + _r.rackName + ' ' +cast(ISNULL( _sr.stockQty,'') as varchar(100)), ' * ')
		from dbo.e_stockRack _sr
		left join dbo.e_stockItem st on st.comCode = _sr.comCode and st.itemId = _sr.itemId
		LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
		LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
		where _sr.itemid = st.itemId and _sr.comCode = st.comCode AND ('ㅇ002' = '' or _s.consignCustCode = 'ㅇ002' or (_s.consignCustCode is null AND _s.comCode = 'ㅇ002'))
		and _sr.stockQty > 0
		AND _s.consignCustCode <> 'ㅇ499'
		AND _s.consignCustCode <> 'ㅂ022'
		AND _s.consignCustCode <> 'ㅇ496'
		AND _s.consignCustCode <> 'ㅇ002'
		AND _s.consignCustCode <> 'ㅇ479'

		select * from e_storage
		where storageName like '%엠케이%'


,dbo.UF_GREATEST(0 ,(ISNULL(str.qtyNewWorkable, 0) 
- ISNULL(temp.qtyNew,0)  - ISNULL(ca3.qty3,0) - ISNULL(ca4.qty4,0) 
- ISNULL(ca5.qty5,0)  - ISNULL(ca6.qty6,0) - ISNULL(ca7.qty7,0)
- ISNULL((select sum(CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
			WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
			ELSE 0  END) qty 
			from dbo.e_pcReqItem s
			LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
			WHERE s.itemId = st.itemId AND 
			s.comCode = st.comCode  AND	
			((ISNULL(s.procStep,'''') <> ''거부'') AND 
			(((ISNULL(s.procStep,'''') <> ''접수'') AND (ISNULL(s.procStep,'''') <> ''처리'')) ) )
		) 
		,
		0))) AS qtyNew


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



SELECT sum(_sr.stockQty) as qty1
from e_stockRack _sr
join e_stockItem si on si.comCode = _sr.comCode and si.itemId = _sr.itemId
left join e_rack _r on _sr.comCode =_r.comCode and _sr.rackCode = _r.rackCode
left join e_storage _s on _s.comCode = _r.comCode and _s.storageCode = _r.storageCode
where 1=1 --('ㅇ496' = '' or _s.consignCustCode = 'ㅇ496' or (_s.consignCustCode is null AND _s.comCode = 'ㅇ496'))
  AND _s.consignCustCode = 'ㅇ499'


  select sum(stockQty) qty1 --아우토전체재고: 9693
  from e_stockRack sr
  join e_rack er on er.comCode = sr.comCode and er.rackCode = sr.rackCode
  join e_storage sg on sg.comCode = er.comCode and sg.storageCode = er.storageCode
  where sg.consignCustCode = 'ㅇ499' 


select sum(_sr.stockQty) as qty2--아우토 사용가능한 수량:9693
from dbo.e_stockRack _sr
join dbo.e_stockItem st on st.comCOde = _sr.comCode and st.itemId = _sr.itemId
left join dbo.e_rack _r on _r.comCode = _sr.comCode and _r.rackCode = _sr.rackCode
left join dbo.e_storage _s on _s.comCode = _r.comCode and _s.storageCode = _r.storageCode
where _r.validYN = 'Y' and (_s.rlStandByYN is null or _s.rlStandByYN <> 'Y')
  and _s.validYN = 'Y'
  and _s.storType in ('신품', '중고', '리퍼') and _s.workableYN = 'Y'
  and _s.consignCustCode = 'ㅇ499'

select sum(_sr.stockQty) AS qty3--아우토제외(이지통상도)한 전체 사용가능한 수량:80734
	from dbo.e_stockRack _sr
	join dbo.e_stockItem st on st.comCOde = _sr.comCode and st.itemId = _sr.itemId
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' and _s.validYN = 'Y' 
	AND _s.storType in ('신품','중고','리퍼') 
	AND _s.workableYN = 'Y'
	AND _s.consignCustCode <> 'ㅇ499'
	AND _s.consignCustCode <> 'ㅇ496'


select sum(_sr.stockQty) AS qty5 --이지통상 전체 사용가능한 수량:11620
	from dbo.e_stockRack _sr
	join dbo.e_stockItem st on st.comCOde = _sr.comCode and st.itemId = _sr.itemId
	LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
	LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
	where _sr.itemid = st.itemId and _sr.comCode = st.comCode 	
	and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
	and _s.validYN = 'Y' AND _s.storType in ('신품','중고','리퍼') 
	AND _s.workableYN = 'Y'
	AND _s.consignCustCode = 'ㅇ496'


	--loca memo
select string_agg('['+s.storageName+']'+r.rackName+ ' ' + 
		cast(isnull(sr.stockQty, '') as varchar(100)), ' * ') localMemo
from e_stockRack sr
join e_stockItem st on st.comCode = sr.comCode and st.itemId = sr.itemId
left join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
left join e_storage s on s.comCode = r.comCode and s.storageCode = r.storageCode
where 1=1
  and sr.stockQty > 0
  AND ('' = '' or s.consignCustCode = '' 
			or (s.consignCustCode is null AND s.comCode = '')
	  )
  and s.consignCustCode <> 'ㅇ499'
  and s.consignCustCode <> 'ㅂ022'
  and s.consignCustCode <> 'ㅇ479'
  and s.consignCustCode <> 'ㅇ002'
  and s.consignCustCode <> 'ㅇ496'
  and st.itemId = (select itemId from e_item where itemNo = '테스트테스트')


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

신규 티파츠(구:탐나네) 삭제

select * from e_user where comCode = 'ㅌ090'
select * from c_cust where custCode = 'ㅌ090'
select * from e_cust where custCode = 'ㅌ090'
select * from e_custAtt where custCode = 'ㅌ090'

select * from it_1024




select * from e_item
where itemNo = '1568851622'--498031

select * from e_stockRack
where itemId = '498031'

select * from e_stockItem
where itemId = '498031'

select * from e_rack
where rackCode = '775741'

select * from e_storage
where storageCode = '2000'


select * from vw_storItem_loca
where itemId = '498031'