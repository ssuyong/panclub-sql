select * from dbo.e_cust
where comCode = 'ㄱ121'
  and custCode in( 'ㅇ499', 'ㅂ022');


select * from dbo.e_stockRack
WHERE rackCode = '644'
  AND comCode = 'ㄱ121';


  select * from dbo.e_item;
  

  select * from dbo.e_cCustPurRate;


  select * from dbo.e_rl
  where rlno = '20250922005';


   select * from dbo.e_rlitem
  where rlno = '20250922005';


  select * from dbo.e_user
  where userId = 'showe200';


  select * from dbo.it_0923;


  select * from dbo.e_cust
  WHERE CUSTNAME LIKE '%멜%츠%';


  select * from dbo.e_cust
  where custName like '%VAG%';

  select * from dbo.e_cust
  where comCode = 'ㄱ121'
    and custCode = 'ㄷ199';

  select * from dbo.e_rack
  where rackName = 'A1-04-02-02-04';

  select * from dbo.e_storage
  where storageCode = '250923001';


  select rackName, rackCode, storageCode 
  from dbo.e_rack
  where comCode = 'ㄱ121'
    and storageCode = '250923001'
  order by rackName asc;


select * from dbo.e_pcReq
order by regYmd desc, regHmsg desc;

select * from dbo.e_rlItem
order by rlNo desc;


select * from dbo.e_othersalerate
where comCode = 'ㄱ121'
  and custCode = 'ㅂ022';

select * from dbo.e_stockrack;

select * from dbo.e_item
where itemNo = 'WHT004935'
;

select * from dbo.e_stockitem
where itemId = '3127271';

--itemNo로 재고아이템 조회하기
select * from dbo.e_stockitem
where itemId in (select itemId from dbo.e_item
where itemNo = 'WHT004935');

select * from dbo.e_stockitem
where itemId in (select itemId from dbo.e_item
where itemNo = '5NJ61TZZAC');

select * from dbo.e_rack
where rackCode = 24;


------------------------불필요한 테이블 지우기(나중에 하자)

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'dbo'
  AND t.name LIKE 'at[_]%'   -- '_'를 글자 그대로 매칭
ORDER BY t.name;

삭제해도 되는 테이블의 시작이름

at_
au_
bb_
bmw_
bz_
it_
jh_
lr_
mb_
mt_
osr_
ps_
Sheet1$
total_
tt_
vag_
vv_
vw_

-----------------------------------------------------
select *
into dbo.ssy_test_0924
from dbo.total_0728;

select *
into dbo.ssy_test_09241
from dbo.total_0728;


SET NOCOUNT ON;

DECLARE @dry_run bit = 1;  -- 1: 미리보기(sql문만 출력), 0: 실제 실행
DECLARE @sql nvarchar(max) = N'';

IF OBJECT_ID('tempdb..#targets') IS NOT NULL DROP TABLE #targets;
SELECT t.object_id, s.name AS schema_name, t.name AS table_name
INTO #targets
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'dbo'
  AND t.name LIKE 'ssy_test[_]%';

IF NOT EXISTS (SELECT 1 FROM #targets)
BEGIN
    PRINT 'No matching tables in dbo starting with at_.';
    RETURN;
END

-- 0) (옵션) 시스템 버전(Temporal)인 경우 먼저 OFF
SET @sql = N'';
SELECT @sql = @sql + N'ALTER TABLE '
    + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    + N' SET (SYSTEM_VERSIONING = OFF);' + CHAR(10)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.object_id IN (SELECT object_id FROM #targets)
  AND t.temporal_type = 2;  -- system-versioned

IF (@sql <> N'')
BEGIN
    IF @dry_run = 1 PRINT @sql ELSE EXEC sys.sp_executesql @sql;
END

-- 1) 이 테이블들과 얽힌 모든 외래키 드롭 (참조/피참조 모두)
SET @sql = N'';
;WITH fks AS (
    SELECT
        fk.name AS fk_name,
        s1.name AS parent_schema, t1.name AS parent_table
    FROM sys.foreign_keys AS fk
    JOIN sys.tables AS t1 ON t1.object_id = fk.parent_object_id
    JOIN sys.schemas AS s1 ON s1.schema_id = t1.schema_id
    WHERE fk.parent_object_id    IN (SELECT object_id FROM #targets)
       OR fk.referenced_object_id IN (SELECT object_id FROM #targets)
)
SELECT @sql = @sql + N'ALTER TABLE '
    + QUOTENAME(parent_schema) + N'.' + QUOTENAME(parent_table)
    + N' DROP CONSTRAINT ' + QUOTENAME(fk_name) + N';' + CHAR(10)
FROM fks;

IF (@sql <> N'')
BEGIN
    IF @dry_run = 1 PRINT @sql ELSE EXEC sys.sp_executesql @sql;
END

-- 2) 테이블 드롭
SET @sql = N'';
SELECT @sql = @sql + N'DROP TABLE '
    + QUOTENAME(schema_name) + N'.' + QUOTENAME(table_name)
    + N';' + CHAR(10)
FROM #targets;

IF @dry_run = 1 PRINT @sql ELSE EXEC sys.sp_executesql @sql;



select * from dbo.ssy_test_0924;
select * from dbo.ssy_test_09241;


select * from dbo.e_stockrack
where itemId = '2634905';

select * from dbo.e_stockitem
where itemId = '2634905';

-- dbo.up_stockItemList;

--최종판매내역
select orderNo, saleUnitPrice, rlUnitPrice, rlSumPrice, costPrice
from dbo.e_rlItem
where orderNo = '20231004012';
/*
orderNo	saleUnitPrice	rlUnitPrice	rlSumPrice	costPrice
20231004012	20735.00	20735.00	20735.00	5742.00
*/


select * from dbo.e_item
where itemNo = '4F0825429A'
;

select * from dbo.e_stockitem
where itemId = '2608962';

--itemNo로 재고아이템 조회하기
select * from dbo.e_stockitem
where itemId in (select itemId from dbo.e_item
where itemNo = '46386914007C45');

select * from dbo.e_stockrack
where itemId = '2757011';

select * from dbo.c_cust --이용업체
where masterId = '아파츠';

select * from dbo.e_cust --거래처
where custName like '%밥파츠%';


select * from dbo.e_cust --거래처
where custName = '대경무역';

/*
begin tran
update dbo.e_cust
set bzType = '도소매'
, bzItems = '자동차부품'
, custAddress1 = '성동구 광나루로 206, 2층 201호'
, phone = '01049011755'
, fax = '024633852'
--, payDay = '카드'
, taxEmail = 'bobo2250@naver.com'
where custName = '대경무역'
  and comCode = 'ㄱ121';

commit;

*/
select * from dbo.c_cust
where custCode = 'ㅇ495';

select * from dbo.e_cust
where 1=1
  and comCode = 'ㄱ121'
  and custCode in ('ㄱ000', 'ㄱ121', 'ㅇ495');


--어제 업체들 접속데이터 올려주세요
select distinct userId from dbo.e_userLoginHis
where created >= '2025-09-25' 
  and created < '2025-09-26'
  ;

select * from dbo.c_cust --이용업체
where custCode in( 'ㅇ479', 'ㅇ496', 'ㅇ002');


--이지통상이 정상화됐을떄 다음 into 주석을 풀고 실행하라! 언제? 압류 풀리면...
select 'ㅇ496' , '이지통상' [masterId], [validYN], [created], [regUserId], [modified], [uptUserId], [dpColor], [erpYN], [consignYN], [permissionTemplateIdx], [parentComCode], [permissionModified] 
--into dbo.c_cust --이용업체
from dbo.c_cust --이용업체
where custCode in( 'ㅇ479');--인터카스



select * from dbo.e_cust --이용업체
where custCode in( 'ㅇ479', --인터카스
'ㅇ496', --이지통상
'ㅇ002');--엠케이



select * from dbo.e_cust --이용업체
where custCode in('ㅇ002');


select * FROM panErp.dbo.e_storage a
where storageCode = '250925002';


select * from dbo.e_stockRack
WHERE rackCode = '644'
  AND comCode = 'ㄱ121';

  select * from dbo.e_user
  where userId = 'tjswhdtjd12';

select * from dbo.e_rack;

-- ㅋ004 을 사용하는 프로시저
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
    --AND m.definition LIKE '%ㅋ004%'  -- 여기에 찾고자 하는 단어
	AND m.definition LIKE '%week%'  -- 여기에 찾고자 하는 단어
ORDER BY 
    o.name;

	--아파츠 위탁 창고에 새로 만든 랙 A4-로 시작하는
	select * from dbo.e_rack
	where storageCode = '250214001'
	  and rackName like 'A4-%'
	order by rackName ;



--물류센터 기본랙: e_logisRack 
--랙: e_rack

select * from dbo.e_logisRack
where rackName like 'A4-%'
  and memo = '아파츠 2층 전산실'
order by rackName;

select * from dbo.e_logisRack
where rackName = 'A4-03-01-01-01';

update dbo.e_logisRack
set memo = '아파츠 2층 전산실'
where rackName = 'A4-03-01-01-01';

select * from dbo.e_rack
where rackName = 'A4-03-01-01-01';


--일주일동안 안보이기 팝업
select title, isWeekCheckboxYN 
from dbo.e_noticePopup;

select *
from dbo.e_noticePopup
where title = '주문요청과 회수요청 방법';



select * from dbo.vag_0929
where itemNo = '1J0612041FN';


select * from dbo.e_item
where itemNo = '5Q0919275BG2X';


select * from dbo.e_cust -- ㅇ002
where custName like '%엠케이파츠%'
  and comCOde = 'ㄱ121';

  
  select * from dbo.e_storage --20250925001
  where storageName like '%엠케이%';

  select * from dbo.e_rack --950
  WHERE storageCode = '20250925001';



578 - 아우토
644 - vag
794 - it
950 - mk

select * 
FROM dbo.e_stockRack
WHERE rackCode = '644'
  AND comCode = 'ㄱ121';


select * from dbo.e_rack
WHERE rackCode in( '644', '578', '794', '950')
  and comCode = 'ㄱ121';

  select * from dbo.e_otherSaleRate
  where custCode = 'ㅇ002'
  ;

  select * from dbo.e_cCustPurMakerRate


  select * from dbo.e_cust --(주)엠케이파츠
  where custCode = 'ㅇ002';

  select * from dbo.e_stockRack;

  select * from dbo.e_stockItem;
  
  select * from dbo.e_item
  where itemid = '7240263';


  select * from dbo.mk_0929
  where itemNo = 'BB5Z16005A';


  

  select * from dbo.e_othersalerate
  where custCode = 'ㅇ002'
    and itemId = (select itemId from dbo.e_item where itemNo = '21240109029765')



	select * from dbo.e_cust
	where comCode = 'ㄱ121'
	  and custCode = 'ㅇ002';




  --엠케이 재고랙
  SELECT DISTINCT sr.comCode, sr.itemId --, sr.rackCode 
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		join dbo.e_storage _s on _s.comCode = r.comCode AND  _s.storageCode = r.storageCode
		WHERE sr.comCode = 'ㄱ121' AND   --조건추가 -- 20234.01.08 
		      r.storageCode = '20250925001' AND sr.stockQty <> 0
			  ;

select * from dbo.e_storage
where storageCode = '20250925001';

SELECT sr.*
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		join dbo.e_storage _s on _s.comCode = r.comCode AND  _s.storageCode = r.storageCode
		WHERE sr.comCode = 'ㄱ121' AND   --조건추가 -- 20234.01.08 
		      r.storageCode = '20250925001' AND sr.stockQty <> 0
			  --and sr.itemId in( '91871', '2762429')
			  ;


select * from e_stockItem si
WHERE si.comCode = 'ㄱ121' 
AND si.itemId in 
(SELECT sr.itemId
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		join dbo.e_storage _s on _s.comCode = r.comCode AND  _s.storageCode = r.storageCode
		WHERE sr.comCode = 'ㄱ121' AND   --조건추가 -- 20234.01.08 
		      r.storageCode = '20250925001' AND sr.stockQty <> 0 
);


select * from dbo._SPLOG
  where 1=1 
    -- and created >= '2025-09-21'
    and sp = 'panErp.dbo.up_stockItemList_test'
  order by created desc;


  --63115A0AFC0 재고가 있나?
  select * from dbo.e_stockRack
  where itemId = (select itemId from dbo.e_item where itemNo = '63115A0AFC0')

  select * from dbo.e_stockItem
  where itemId = (select itemId from dbo.e_item where itemNo = '63115A0AFC0')


  --rack, stockRack관계
  select * from e_rack;

  --table description 보기
  EXEC sp_help 'e_stockRack';


  -- stockItemList_test분석중:
  --1083 line
  SELECT DISTINCT sr.comCode, sr.itemId , r.storageCode--, sr.rackCode 
		FROM e_stockRack sr
		JOIN dbo.e_rack r ON sr.comCode = r.comCode AND sr.rackCode = r.rackCode
		WHERE sr.comCode = 'ㄱ121' 
		      AND  r.storageCode =  '20250925001' --조건추가 -- 20234.01.08 		      
			  AND sr.stockQty <> 0

SELECT ISNULL(salePriceType,'센터가') 
FROM dbo.e_cust WHERE comCode = 'ㄱ121' 
  AND custCode = 'ㅂ022';

SELECT salePriceType
FROM dbo.e_cust WHERE comCode = 'ㄱ121' 
  AND custCode = 'ㅂ022'
 ;


select * from e_item
where itemNo = '2218200959';



  --팝업 안뜨는 원인 분석: url설정 안한 문제였음.
  SELECT idx , c.custName regComName , u.userName regUserName , np.regYmd , np.regHms,
	   ISNULL(u2.userName,'') uptUserName, uptYmd , uptHms , title , width ,
	   height , sYmd , eYmd , allCustViewYN , allMenuViewYN , 
	   preText , imgOriginFileName , imgFileName , imgMag , postText , 
	   np.memo , np.validYN 
	   , priority , allYmdYN , isOpenPopupYN , isWeekCheckboxYN , isModalYN , popupName, fileUploadComCode
FROM dbo.e_noticePopup np
LEFT OUTER JOIN dbo.e_cust c ON c.comCode = (select top(1) comCode from dbo.UF_ErpOperate('')) AND c.custCode = np.regComCode 
LEFT OUTER JOIN dbo.e_user u ON u.comCode = np.regComCode AND u.userId = np.regUserId
LEFT OUTER JOIN dbo.e_user u2 ON u2.comCode = np.regComCode AND u2.userId = np.uptUserId
where np.popupName in ('브랜드별아이템할인율','주황부품 추가할인','수도권이외할인율공지');


exec sp_help e_noticePopup;

SELECT idx , c.custName regComName , u.userName regUserName , np.regYmd , np.regHms,
	   ISNULL(u2.userName,'') uptUserName, uptYmd , uptHms , title , width ,
	   height , sYmd , eYmd , allCustViewYN , allMenuViewYN , 
	   preText , imgOriginFileName , imgFileName , imgMag , postText , 
	   np.memo 
	   , priority , allYmdYN , isOpenPopupYN , isWeekCheckboxYN , isModalYN , popupName, fileUploadComCode
FROM dbo.e_noticePopup np
LEFT OUTER JOIN dbo.e_cust c ON c.comCode = (select top(1) comCode from dbo.UF_ErpOperate('')) AND c.custCode = np.regComCode 
LEFT OUTER JOIN dbo.e_user u ON u.comCode = np.regComCode AND u.userId = np.regUserId
LEFT OUTER JOIN dbo.e_user u2 ON u2.comCode = np.regComCode AND u2.userId = np.uptUserId 
where 1=1
  --and allMenuViewYN ='Y'
--WHERE (allCustViewYN = 'Y' OR @i__logComCode in (SELECT custCode FROM dbo.e_noticePopupViewCust npc 
--											WHERE npc.popUpidx = np.idx AND npc.validYN = 'Y'))
--AND (allMenuViewYN ='Y' OR @i__menuUrl in (SELECT p.url FROM dbo.e_noticePopupViewMenu npm
--									LEFT JOIN dbo.e_permission p ON p.code = npm.menuCode 
--									WHERE npm.popUpidx = np.idx AND npm.validYN = 'Y'))
AND np.validYN ='Y'

select * FROM dbo.e_noticePopup np
cross apply (
SELECT p.url FROM dbo.e_noticePopupViewMenu npm
									LEFT JOIN dbo.e_permission p ON p.code = npm.menuCode 
									WHERE npm.popUpidx = np.idx AND npm.validYN = 'Y') ca1;


select * from dbo.e_permission--code: JC003
where url = '/logis/out-stock-bulk-list';

select * from dbo.e_noticePopupViewMenu
where menuCode = 'JC003';

----------------------------------------------------------------------------------------------------
--위탁업체 중 다온오토파츠 매입율(40%) 설정이 안되어 있습니다.
--급한거는 아니니 시간날때 설정해주시면 됩니다


select * from e_otherSaleRate
where custCode = 'ㄷ199'

select * from e_cust -- ㄷ199
where custName like '%(주)다온오토파츠%';



panErp.dbo.up_conStockRpt	
	@i__workingType='List',
	 @i__sYmd1='2000-10-02',	 
	 @i__eYmd1='2025-10-02',	 
	 @i__logComCode='ㄱ121',
	 @i__logUserId='ssuyong',
	 @i__consignCustCode='ㄷ199',
	 @i__orderCustCode='',
	 @i__rcvCustCode='',
	 @i__itemId='',
	 @i__itemNo='',
	 @i__itemName='',
	 @i__pIgnoreYN='Y';







panErp.dbo.up_cCustPurRateList	@i__workingType='MAKER-LIST',
	
	 @i__logComCode='ㄱ121',
	 @i__logUserId='ssuyong',
	 @i__selectCustCode='ㄷ199'

	  SELECT
	a.comCode    --회사코드
	,a.custCode
	,a.purRate
	,cust.custName
FROM dbo.e_cCustPurRate a 
JOIN dbo.e_cust cust ON cust.comCode = a.comCode AND cust.custCode = a.custCode
WHERE 1= 1 AND a.comCode = 'ㄱ121'


sp_help e_cust;

--수탁업체 매입율
select c.custName, cpr.* 
from e_cCustPurRate cpr
join e_cust c on cpr.custCode = c.custCode
  and c.comCode = 'ㄱ121'
  and c.comCode = cpr.comCode
;






  --수주업체 매입율 다온오토파츠 40.00

 -- panErp.dbo.up_cCustPurRateAdd	@i__workingType='ADD',
	 @i__custCode='ㄷ199',
     @i__purRate='40.00',
	 @i__logUserId='ssuyong',
	 @i__logComCode='ㄱ121'


panErp.dbo.up_conStockRpt	@i__workingType='List',
	 @i__sYmd1='2024-10-02',	 
	 @i__eYmd1='2025-10-02',	 
	 @i__logComCode='ㄱ121',
	 @i__logUserId='ssuyong',
	 @i__consignCustCode='ㄷ199',
	 @i__orderCustCode='',
	 @i__rcvCustCode='',
	 @i__itemId='',
	 @i__itemNo='',
	 @i__itemName='',
	 @i__pIgnoreYN='Y'


	 select * from dbo.e_saleItem
	 where comCode = 'ㄷ199';

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
    AND m.definition LIKE '%e_saleItem%'  -- 여기에 찾고자 하는 단어
ORDER BY 
    o.name;


	 select * from dbo._SPLOG
  where 1=1 
    and created >= '2025-10-02'
    and sp = 'panErp.dbo.up_conStockRpt'
  order by created desc;

  
panErp.dbo.up_conStockRpt	@i__workingType='List',
	 @i__sYmd1='2020-10-01',	 
	 @i__eYmd1='2025-10-02',	 
	 @i__logComCode='ㄱ121',
	 @i__logUserId='ssuyong',
	 @i__consignCustCode='ㄷ199',
	 @i__orderCustCode='',
	 @i__rcvCustCode='',
	 @i__itemId='',
	 @i__itemNo='',
	 @i__itemName='',
	 @i__pIgnoreYN='Y';

--다온 위탁매입율
SELECT		[comCode]
           ,[custCode]
           ,[purRate]
           ,[regUserId]
           ,[created]
           ,[uptUserId]
           ,[modified]
		   ,GETDATE()
FROM dbo.e_cCustPurRate 
WHERE comCode = 'ㄱ121' AND custCode = 'ㄷ199';

SELECT * 
FROM dbo.e_cCustPurRate a 
WHERE a.comCode = 'ㄱ121'
  AND a.custCode = 'ㄷ199';

--할인율저장
select *
 FROM dbo.e_othersalerate osr
JOIN dbo.e_item ei ON osr.itemId = ei.itemId
JOIN (SELECT itemNo, MAX(purRate) AS purRate
    FROM dbo.vag_1001
    GROUP BY itemNo
) mr ON ei.itemNo = mr.itemNo
where osr.custCode = 'ㅂ022';


;WITH MaxRate AS (
    SELECT itemNo, MAX(purRate) AS purRate
    FROM dbo.vag_1001
    GROUP BY itemNo
)

select *
from MaxRate mr


select * from _SPLOG
where created >= '2025-10-10' 
  and params like '%16740107007X21%'
  --and params like '%ssuyong%'
order by created desc;

SELECT comCode FROM dbo.UF_GetChildComcode('ㄱ000')

--stockItemList ca5:
declare @i__consignCustCode varchar(100) = '';
select sum(_sr.stockQty) AS qty5
from dbo.e_stockRack _sr
left join dbo.e_stockItem st on _sr.itemId = st.itemId
LEFT JOIN dbo.e_rack _r ON _sr.comCode = _r.comCode AND _sr.rackCode = _r.rackCode
LEFT JOIN dbo.e_storage _s ON _s.comCode = _r.comCode AND _s.storageCode = _r.storageCode 
where _sr.itemid = st.itemId 
  and _sr.comCode = st.comCode 
  AND (@i__consignCustCode = '' or _s.consignCustCode = @i__consignCustCode or (_s.consignCustCode is null AND _s.comCode = @i__consignCustCode))
  and _r.validYN = 'Y' and ISNULL(_s.rlStandByYN,'N') <> 'Y' 
  and _s.validYN = 'Y' AND _s.storType in ('신품', '중고','리퍼') AND _s.workableYN = 'Y'
  AND _s.consignCustCode = 'ㅇ496';

  sp_help e_stockItem;

select sum(sr.stockQty) qty5
from e_stockRack sr 
left join e_stockItem si on si.comCode = sr.comCode and si.itemId = sr.itemId
left join e_rack r on r.comCode = si.comCode and r.rackCode = sr.rackCode
left join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where 1=1
  and r.validYN = 'Y' and isnull(sg.rlStandByYN, 'N') <> 'Y'
  and sg.validYN = 'Y' and sg.storType in ('신품','중고','리퍼') and sg.workableYN = 'Y'
  and sg.consignCustCode = 'ㅇ496';

/*
20250808001	인터카스 위탁	794
20250925001	엠케이 위탁	950
250515001	아우토서울 위탁	578
250710001	VAG_위탁	644
250211002   이지통상 74~738
*/
select * 
from e_rack
where validYN != 'N'
  and storageCode in ('250515001','250710001','250211002','20250925001','20250808001');

select *
from e_stockRack sr
join e_rack r on r.comCode = sr.comCode and r.rackCode = sr.rackCode
join e_storage sg on sg.comCode = r.comCode and sg.storageCode = r.storageCode
where consignCustCode = 'ㅇ496'
  and r.validYN <> 'Y'
  and sg.validYN = 'Y'

select * from vw_storType_stock
where itemId = (select itemId from e_item
                where itemNo = '테스트테스트');


SELECT RIGHT(REPLICATE('0', 5)+'123', 5)


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
    AND m.definition LIKE '%ㅇ496%'  -- 여기에 찾고자 하는 단어
ORDER BY 
    o.name;


select * from e_storage
where storageName like '%아파츠%불량%';

select * from e_rack
where storageCode = '250312001';


select * from e_stockRack
where itemId = (select itemId 
                from e_item 
				where itemNo = 'LR010632')
order by modified desc;


select * from e_stockItem
where itemId = (select itemId 
                from e_item 
				where itemNo = 'LR010632')
  and comCode = 'ㄱ121';


select * from dbo.e_stockSrchLog
order by created desc;


select * from #tbl_itemH;


select * from e_stockItem
where itemId = '6899223'
  and comCode = 'ㄱ121';


select * from e_otherSaleRate
where itemId = (select itemId from e_item where itemNo = '13628650714');

select * from ato_1013

select * from e_otherSaleRate
where itemId = (select itemId from e_item where itemNo = '13046071822');


select * from mk_1014 mk
left join e_item i on i.itemNo = mk.itemNO
where mk.itemNo = '13046071822'

select * from _splog
where created > '2025-10-17'
  and sp = 'panErp.dbo.up_transactionList'
order by created desc;