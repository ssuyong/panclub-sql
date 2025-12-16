USE [panErp]
GO
/****** Object:  StoredProcedure [dbo].[up_transactionList]    Script Date: 2025-12-05 오후 1:47:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER  PROC [dbo].[up_transactionList]
/***************************************************************
설명 : 거래상세내역
		-- 현재 LIST WORKING TYPE은 사용 X 
			매입처 거래상세내역 - WHLIST
			매출처 거래상세내역 - RLLIST 사용

작성 : 2023-06-12
		2023-06-26 bk - 일반건 보험전환 추가 	
		2023.06.30 bk - #{placeYmdYN} 추가 발주처 출고기준 조회조건 
		2023.07.04 bk- item comcode 조인조건 삭제
		2023.07.04 bk - 입고 조인조건 변경 (주문없는 입고-단수조정)
		2023.07.10 bk - LIST QRY 수정 
		2023.07.10 bk- RLLIST_QRY 추가
		2023.07.10 yoonsang 발주처입출고기준 반출 적용
		2023.07.12 itemId/itemNo 검색기준 추가 
		2023.07.13 bk - centerPrice 추가 
        2023.07.24 yoonsang - 반출단가 잘못나오고있는부분 수정 unitPrice -> roiUnitPrice
		2023.07.27 hsg - 입고단가(원가) costPrice 추가. 박준범 파트장 요청
		2023.08.02 bk - 조회조건 수정 
		2023.08.10 BK -WHLIST 쿼리 수정 ( 주문없는 발주 ) 
		2023.08.29  BK -WHLIST 쿼리 수정 ( oi.placeCustCode-> p.custCode  ) 
		2023.09.05 bk - WHLIST 쿼리 수정 (orderNo, orderSeq, withdrawStatus추가 ) 
		2023.09.08 bk -WHLIST 쿼리 수정 (placedmdymd -> placeYmd )
		2023.09.13 yoonsang - 반출패널티 금액 잘못나오고있던것 수정(penaltyPrice -> penaltyPrice/1.1)
		2023.09.19 bk -  RLLIST/LIST 쿼리 수정 (출고-운송비 추가 ) 
		2023.09.20 bk - RLLIST/LIST 쿼리 group by 오류 수정 
		2023.10.04 hsg - WHLIST에 JOIN -> OUTER JOIN으로 변경. 주문없이 발생한 위탁창고의 반출이 조회가 안되는 문제 해결
		2023.10.05 bk - RLLIST 쿼리 운송비 관련 오류 수정 (GROUP BY ) 
		2023.10.16 bk - srCode 추가 （RLLIST 쿼리）　
		2023.10.17 bk - srCode 수정 
		2023.10.19 bk - makerCode 추가 (박재범 팀장 요청) 
		2023.10.23 hsg - OUT_LIST 추가. 위탁재고업체에서 보는 매입처내역. 매입처라bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb서 원래 입고,반출로 표시되는 것을 출고와 반입으로 표시함. 그리고 지점법인의 경우 수정입출고(수동입출고)한 내역까지  UNION으로 노출
		2023.10.26 hsg - OUT_LIST에 위탁업체가 로그인했을 경우 해당 업체것만 조회되게 했으나  팬오토가 로그인한 경우 위탁하는 모든 업체의 내역을 볼수 있게처리,조회조거넹 거래처코드 @i__custCode 값도 넘어옴  
		2023.11.02 hsg - OUT_LIST에 AND ISNULL(wi.storageUseReqNo, '''') <> '''' 추가. 창고사용한것만 노출되게. 위탁업체라고 해도 발주입고등록하는 경우가 있음.
		               - OUT_LIST 반출에서 JOIN dbo.e_storage stor ON ro.comCode = stor.comCode AND ro.storageCode = stor.storageCode AND  consignYn=''Y''  추가. 위탁창고에서 반출된것만 노출되게
		2023.11.06 hsg - 매입처거래내역(WHLIST_QRY)에 위탁창고의 판매출고,반품입고 추가
		2023.11.07 hsg - OUT_LISt에 출금상태가 필요 없어서 해당 부분 주석처리
		               - WH_LIST의 반출에서 custCode를 oi의 placeCustCode 가 아닌 ro의 custCode로 가져오는것으로 변경
		2023-12-04 - yoonsang 모든금액 round 처리
		2024-01-12 - supi 위탁재고판매데이터에서 판매가격(salePrice) 노출
		2024-01-16 - yoonsang summary2추가 구분값이같이나오는 적요 ex)20240102002(입고) 
		2024-01-31 - yoonsang RLLIST 판매출고(e_saleItem) 추가 WHERE절 추가해야함
		2024-02-01 - yoonsang RLLIST e_saleItem 부분 WHERE절 수정(실섭적용안함)
		2024-02-07 - yoonsang RLLIST 판매출고부분 수정, WHLIST에 입고(판매내역) 추가(saleitem)
		2024-02-14 - yoonsang 판매출고 조인부분 수정 WHLIST_QRY/ RLLIST_QRY
		2024-02-15 - yoonsang WHLIST_QRY 부분 주문없는 판매출고만 나오도록 수정
		2024-02-19 hsg - OUT_LIST 에 판매내역 e_saleItem 적용
		               - LIST_QRY 주석처리. 현재 시점 안쓰임  
		2024-03-05 yoonsang WHLIST,RLLIST 에 @i__mainYN 조회조건 추가 (대표거래처)
		2024.04.02 hsg - SET ARITHABORT ON; .추가. 매출처 거래상세내역에서 조회가 느리다고 해서 추가하여 처리
		2024.05.02 yoonsang - 4car 재고 구매내역 볼수있는 워킹타입추가 OUT_PL_LIST
		2024.05.22 yoonsang 주문이 없는 경우(주문요청건) 반품패널티나오도록 수정
		2024.06.10 yoonsang OUT_PL_LIST 에서 운송비부분 센터가(표준가)를 가져오던것을 0으로 나오도록 수정
		2024.06.21 yoonsang 반품패널티와 수동판매출고 입력에서 부품아이디와 부품번호로 검색하는 조건 누락되어 추가
		2024.06.24 yoonsang 매출처거래상세내역에 영업대표별 조회 주석처리되어있었는데 주석풀어서 조회가능하도록함
		2024.07.08 yoonsang WHLIST의 withdrawStatus 부분 수정 jobType 조건 추가
		2024.07.15 yoonsang WHLIST의 withdrawStatus 부분 수정 placeNo 로 조인할수있도록 원장2에 placeNo,placeSeq 추가
		2024.07.19 yoonsang 대표거래처 조회 조건 틀려서 수정함
		2024.07.26 supi - 제조사명 , 구분, 공장품번 반환 추가
		2024.08.05 yoonsang - 매입처거래상세내역에 mainCustCode,mainCustName 추가해서 출금등록시 활용
		2024.08.06 yoonsang - 08.05 코드 수정
ex) 

select * from panErp.dbo._SPLOG  where sp like '%up_transactionList%' --and params like '%ㅈ115%'
order by created desc


panErp.dbo.up_transactionList_yoonsang	@i__workingType='OUT_PL_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-05-02',      @i__eYmd1='2024-05-02',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='',    @i__custOrderNo='',       @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='',       @i__custCode=''

panErp.dbo.up_transactionList	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-04-01',      @i__eYmd1='2024-06-20',   
@i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',   
@i__itemId=0,    @i__itemNo ='2128803000649999',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode=''

panErp.dbo.up_transactionList	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-06-01',      @i__eYmd1='2024-06-30',      
@i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='', 
@i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode='ㄱ001'


panErp.dbo.up_transactionList	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-07-01',      @i__eYmd1='2024-07-15',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',     @i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode='ㅋ093'

panErp.dbo.up_transactionList_yoonsang	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-07-01',      @i__eYmd1='2024-07-15',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',     @i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode='ㅋ093'


panErp.dbo.up_transactionList_yoonsang	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-07-15',      @i__eYmd1='2024-07-15',      @i__sYmd2='',   
@i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='jyspan',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',     @i__itemId=0,    @i__itemNo ='', 
@i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='Y',       @i__custCode='ㅎ177'

panErp.dbo.up_transactionList	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2023-05-01',      @i__eYmd1='2024-08-05',     
@i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',   
@i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode=''

panErp.dbo.up_transactionList	@i__workingType='WHLIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-07-29',      @i__eYmd1='2024-08-02',   
@i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='N',    @i__custOrderNo='',  
@i__itemId=0,    @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='N',       @i__custCode='ㅇ407'


--***************************************************************/
	@i__workingType varchar(20) = '',
	@i__page int = 1,       --페이지 : 몇번째 다음 부터
	@i__qty int = 10,       --레코드 수 : 몇개 출력
	@i__orderBy varchar(20) = '',
	@i__ymdIgnoreYN varchar(1) = 'N',
	
	@i__sYmd1 varchar(10) = '',
	@i__eYmd1 varchar(10) = '',
	@i__sYmd2 varchar(10) = '',
	@i__eYmd2 varchar(10) = ''

    ,@i__logComCode varchar(30) = ''    --로그인한 회사코드
	,@i__logUserId varchar(50) = ''       --로그인한 멤버아이디
    
	,@i__custCode varchar(20) = '' 
	,@i__clType varchar(20) = '' 
	,@i__ledgType varchar(30) = '' 
	,@i__placeYmdYN varchar(5) = '' 

	,@i__custOrderNo varchar(100) = '' 
	
	,@i__itemId bigint = 0
	,@i__itemNo varchar(50) = '' 
	,@i__orderGroupId varchar(50) = '' 
	,@i__carNo varchar(50) = '' 
	,@i__srCode varchar(50) = ''  --sr코드
	
	,@i__taxBillRegYN varchar(2) = ''  --세금계산서 등록 여부
	,@i__mainYN varchar(2) = ''  --대표거래처 여부
	
AS

SET ARITHABORT ON;
SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @subPage INT
SET @subPage = (@i__page - 1) * @i__qty

SET @i__orderBy = ISNULL(@i__orderBy, '')


--로그--------------------------
INSERT INTO panErp.dbo._SPLOG( sp,params)
	VALUES('panErp.dbo.up_transactionList', 
	'@i__workingType='''+ISNULL(@i__workingType,'')+''',
	 @i__page='+cast(ISNULL(@i__page,0) as varchar(100))+',
	 @i__qty='+cast(ISNULL(@i__qty,0) as varchar(100))+',	 
	 @i__orderBy='''+ISNULL(@i__orderBy,'')+''',
	 @i__sYmd1='''+ISNULL(@i__sYmd1,'')+''',	 
	 @i__eYmd1='''+ISNULL(@i__eYmd1,'')+''',	 
	 @i__sYmd2='''+ISNULL(@i__sYmd2,'')+''',
	 @i__eYmd2='''+ISNULL(@i__eYmd2,'')+''',
	 @i__logComCode='''+cast(ISNULL(@i__logComCode,'') as varchar(100))+''',
	 @i__logUserId='''+ISNULL(@i__logUserId,'')+''',
	 @i__clType='''+ISNULL(@i__clType,'')+''',
	 @i__ledgType='''+ISNULL(@i__ledgType,'')+''',
	 @i__placeYmdYN='''+ISNULL(@i__placeYmdYN,'')+''',
	 @i__custOrderNo='''+ISNULL(@i__custOrderNo,'')+''',
	  @i__itemId='+cast(ISNULL(@i__itemId,'0') as varchar(100))+',
	 @i__itemNo ='''+ISNULL(@i__itemNo,'')+''',
	 @i__orderGroupId ='''+ISNULL(@i__orderGroupId ,'')+''',
	 @i__carNo ='''+ISNULL(@i__carNo,'')+''',
	@i__srCode ='''+ISNULL(@i__srCode,'')+''',
	@i__taxBillRegYN ='''+ISNULL(@i__taxBillRegYN,'')+''',
	@i__mainYN ='''+ISNULL(@i__mainYN,'')+''',
     @i__custCode='''+ISNULL(@i__custCode,'')+''''
   )
---------------------------------

SET @i__workingType=ISNULL(@i__workingType,'')
SET @i__page=ISNULL(@i__page,0)
SET @i__qty=ISNULL(@i__qty,0)
SET @i__orderBy=ISNULL(@i__orderBy,'')
SET @i__sYmd1=ISNULL(@i__sYmd1,'') 
SET @i__eYmd1=ISNULL(@i__eYmd1,'') 
SET @i__sYmd2=ISNULL(@i__sYmd2,'')
SET @i__eYmd2=ISNULL(@i__eYmd2,'')
SET @i__logComCode=ISNULL(@i__logComCode,'')
SET @i__logUserId=ISNULL(@i__logUserId,'')

SET @i__custCode=ISNULL(@i__custCode,'')
SET @i__clType=ISNULL(@i__clType,'')
SET @i__ledgType=ISNULL(@i__ledgType,'')
SET @i__placeYmdYN=ISNULL(@i__placeYmdYN,'')

SET @i__orderGroupId =ISNULL(@i__orderGroupId,'')
SET @i__carNo =ISNULL(@i__carNo,'')
SET @i__srCode =ISNULL(@i__srCode,'')

SET @i__mainYN =ISNULL(@i__mainYN,'N')

DECLARE @sql nvarchar(max), @param nvarchar(2000)
SET @sql = N''
SET @param = N''

DECLARE @mainCustCode varchar(20)
IF @i__mainYN='Y'
	SELECT @mainCustCode = mainCustCode 
	FROM dbo.e_cust
	WHERE custCode =  @i__custCode AND comCode = @i__logComCode


/*
IF @i__workingType = 'LIST' OR @i__workingType = ''
	GOTO LIST_QRY  --리스팅  --이거 사용안함. 이거 사용하려면 수정할게 많음. 2023.11.07  ->2024.02.19 hsg 주석처리
*/

IF @i__workingType = 'WHLIST' --매입처 거래상세내역
	GOTO WHLIST_QRY  --리스팅
IF @i__workingType = 'RLLIST' --매출처 거래상세내역
	GOTO RLLIST_QRY  --리스팅

IF @i__workingType = 'OUT_LIST'
	GOTO OUT_LIST  --위탁업체용 출고/반입내역(실제는 입고/반출)

IF @i__workingType = 'OUT_PL_LIST'
	GOTO OUT_PL_LIST  --위탁업체용 출고/반입내역(실제는 입고/반출)


RETURN
/*********************************************************************************************************/
WHLIST_QRY:

CREATE TABLE #원장2 (
	idx int identity primary key , 
	custCode varchar(10) , 
	stdYmd varchar(10),--날짜
	ledgType varchar(50), --구분
	summary varchar(20),--적요
	regYmd varchar(10)
	,regHms varchar(8)
	,seq varchar(20) --순번
	,cnt varchar(20)
	,unitPrice money 
	, sumPrice money  --공급가액
	, taxPrice money --세액  
	, sumPriceTax money  --합계금액
	,itemId bigint 
	,itemNo varchar (50)
	,itemName varchar (200)  
	,memo varchar (2000) 
	,carNo varchar(100)
	, carType varchar(50) 
	,orderGroupId varchar( 30)
	, clType varchar(20)
	,regUserId varchar(50)
	,makerCode varchar(50)
	,custOrderNo varchar(100)
	,ledgCateg varchar(50)
	,rcvCustCode varchar(100) --납품처 
	,centerPrice money --센터가 
	,orderNo varchar(20)
	,orderSeq varchar(20) 
	,summary2 varchar(100)--적요2 구분값을포함한 적요
	,placeNo varchar(20)
	,placeSeq varchar(20)

)

--입고
SET @sql = N'
SELECT 
	w.custCode,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(wi.placeRlYmd,w.whYmd) ELSE w.whYmd END AS whYmd,
	''입고'',
	w.whNo,
	w.regYmd,
	w.regHms,
	wi.whSeq,
	wi.cnt,
	ROUND(wi.whUnitPrice,0),
	ROUND(wi.whSumPrice,0),
	ROUND(wi.whSumPrice*0.1,0)  ,
	ROUND(wi.whSumPrice *1.1,0),
	wi.itemId
	,i.itemNo
	--,ISNULL(i.itemName,i.itemNameEn)
		,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,wi.memo1
	,ISNULL(og.carNo ,'''')
	,ISNULL(og.carType,'''') 
	, og.orderGroupId
	, ''''
	,wi.regUserId
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerCode
	,ISNULL (p.custOrderNo,'''') custOrderNo
	,''입고''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice 
	,oi.orderNo
	,oi.orderSeq
	,w.whNo+ ''(입고)''
	,pli.placeNo
	,pli.placeSeq
	
FROM dbo.e_whItem wi 
JOIN dbo.e_wh w on w.comCode = wi.comCode AND w.whNo = wi.whNo
--JOIN dbo.e_item i ON w.comCode = i.comCode AND wi.itemId = i.itemId
JOIN dbo.e_item i ON wi.itemId = i.itemId
--JOIN dbo.e_orderItem oi on wi.comCode = oi.comCode and wi.orderNo = oi.orderNo and wi.orderSeq = oi.orderSeq
LEFT OUTER JOIN dbo.e_orderItem oi on wi.comCode = oi.comCode and wi.orderNo = oi.orderNo and wi.orderSeq = oi.orderSeq
--LEFT OUTER JOIN dbo.e_place p on p.comCode = wi.comCode and p.placeNo = wi.placeNo
JOIN dbo.e_placeItem pli ON pli.comCode = wi.comCode AND pli.placeNo = wi.placeNo AND pli.placeSeq = wi.placeSeq
JOIN dbo.e_place p ON p.comCode = pli.comCode AND p.placeNo = pli.placeNo
--JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = wi.comCode
LEFT OUTER JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = wi.comCode 
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = wi.comCode AND cd.code = i.makerCode and  mCode = ''1000''

WHERE wi.comCode = @i__logComCode '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND w.custCode = @i__custCode '

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND w.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '

IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND w.custCode =  @i__custCode'
--SET @sql = @sql + N' AND w.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE  @i__custCode END'
--SET @sql = @sql + N' AND w.custCode = CASE WHEN @i__mainYN = ''Y'' THEN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @i__custCode) ELSE  @i__custCode END'

IF @i__placeYmdYN = 'Y'
SET @sql = @sql + N' AND wi.placeRlYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
SET @sql = @sql + N' AND w.whYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
SET @sql = @sql + N' AND wi.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId = @i__orderGroupId '

IF @i__carNo <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

IF @i__custOrderNo  <> ''
SET @sql = @sql + N' AND p.custOrderNo = @i__custOrderNo '

INSERT INTO #원장2 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,custOrderNo,ledgCateg,rcvCustCode,centerPrice ,orderNo, orderSeq,summary2,placeNo,placeSeq)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50), @i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)   ,@i__orderGroupId varchar(50), @i__carNo varchar(30)
														,@i__custOrderNo varchar(100) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__placeYmdYN ,@i__itemId	,@i__itemNo  ,@i__orderGroupId, @i__carNo ,@i__custOrderNo , @i__mainYN ,@mainCustCode

--운송비 
SET @sql = N'
SELECT 
	p.custCode, 
	--placeDmdYmd,
	ISNULL(p.placeYmd, p.regYmd ) placeDmdYmd,
	''입고(운송비)'',
	placeNo
	,regYmd
	, regHms
	,''운송비''
	,1
	,ROUND(directCost/1.1,0)
	,ROUND(directCost /1.1,0)
	,ROUND(directCost /1.1 * 0.1,0)
	,ROUND(directCost,0)
	,0
	,''운송비''
	,''운송비''
	,''''
	,''''
	,''''
	,''''
	,''''
	,regUserId
	,ISNULL (p.custOrderNo,'''') custOrderNo
	,''운송비''
	,ISNULL(cust.custName,'''')　rcvCustCode
	,0
	,placeNo+''(발주)''
	,placeNo
	,''운송비''
FROM dbo.e_place p
JOIN dbo.e_cust cust ON cust.comCode = p.comCode AND cust.custCode = p.custCode 
WHERE p.comCode = @i__logComCode AND directYN = ''Y''  AND ISNULL(p.placeYmd, p.regYmd)  BETWEEN @i__sYmd1 AND @i__eYmd1 '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND p.custCode = @i__custCode '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND p.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND p.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '

IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND p.custCode  = @i__custCode '


IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND '''' = @i__orderGroupId '

IF @i__carNo <> ''
SET @sql = @sql + N' AND '''' = @i__carNo '

IF @i__custOrderNo  <> ''
SET @sql = @sql + N' AND p.custOrderNo = @i__custOrderNo '

IF @i__itemId <> ''
SET @sql = @sql + N' AND 0 = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND ''운송비''  = @i__itemNo '

INSERT INTO #원장2 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,custOrderNo, ledgCateg,rcvCustCode,centerPrice,summary2,placeNo,placeSeq)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50)  ,@i__orderGroupId varchar(50), @i__carNo varchar(30) ,@i__custOrderNo varchar(100)
											,@i__itemId bigint ,@i__itemNo varchar(50) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode  ,@i__orderGroupId , @i__carNo ,@i__custOrderNo  ,@i__itemId	,@i__itemNo,@i__mainYN ,@mainCustCode

--반출내역 
SET @sql = N'
SELECT 
	--oi.placeCustCode as custCode ,
	ISNULL(ro.custCode,'''') custCode, --	ISNULL(p.custCode,'''') custCode,
	--ro.roYmd,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(roi.placeWhYmd,ro.roYmd) ELSE ro.roYmd END AS roYmd,
	''입고(반출)'',
	ro.roNo,
	ro.regYmd,
	ro.regHms,
	roi.roSeq,
	-roi.cnt,
	--0,
	ROUND(roi.roUnitPrice,0),
	ROUND(-roi.roUnitPrice * roi.cnt,0),
	ROUND(-roi.roUnitPrice * roi.cnt*0.1,0),
	ROUND(-roi.roUnitPrice * roi.cnt * 1.1,0),
	roi.itemId,
	i.itemNo
	--ISNULL(i.itemName,i.itemNameEn)
		,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,roi.memo1
	,og.carNo 
	,og.carType 
	, og.orderGroupId
	, ''''
	,roi.regUserId
	,ISNULL(ro.custRoNo,'''') custRoNo
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerCode
	,''반출''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice
	,oi.orderNo
	,oi.orderSeq
	,ro.roNo+''(반출)''
FROM e_roItem roi
JOIN dbo.e_ro ro ON roi.roNo = ro.roNo AND roi.comCode = ro.comCode 
--join dbo.e_orderItem oi on oi.orderNo = roi.orderNo and oi.orderSeq = roi.orderSeq  and oi.comCode = roi.comCode
LEFT OUTER JOIN dbo.e_orderItem oi on oi.orderNo = roi.orderNo and oi.orderSeq = roi.orderSeq  and oi.comCode = roi.comCode  --2023.10.04 위에거에서 변경 left outer 로 변경
--JOIN dbo.e_item i ON roi.comCode = i.comCode AND roi.itemId = i.itemId
JOIN dbo.e_item i ON  roi.itemId = i.itemId
--JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = roi.comCode 
--JOIN dbo.e_place p on roi.comCode = p.comCode AND roi.placeNo = p.placeNo
--JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
LEFT OUTER JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = roi.comCode   --2023.10.04 위에거에서 변경 left outer 로 변경
LEFT OUTER JOIN dbo.e_place p on roi.comCode = p.comCode AND roi.placeNo = p.placeNo   --2023.10.04 위에거에서 변경 left outer 로 변경
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode   --2023.10.04 위에거에서 변경 left outer 로 변경
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = roi.comCode AND cd.code = i.makerCode and  mCode = ''1000''
WHERE roi.comCode = @i__logComCode '


--IF @i__custCode <> ''
--SET @sql = @sql + N' AND ro.custCode = @i__custCode '  --아래거에서 변경. 2023.11.07 hsg
----SET @sql = @sql + N' AND oi.placeCustCode = @i__custCode '
--IF @i__custCode <> ''
--SET @sql = @sql + N' AND ro.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND ro.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '

IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND ro.custCode =  @i__custCode '

IF @i__placeYmdYN = 'Y'
SET @sql = @sql + N' AND roi.placeWhYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
SET @sql = @sql + N' AND ro.roYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
SET @sql = @sql + N' AND roi.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId = @i__orderGroupId '

IF @i__carNo <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

IF @i__custOrderNo  <> ''
SET @sql = @sql + N' AND ro.custRoNo = @i__custOrderNo '
print @sql
INSERT INTO #원장2 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,summary2 )

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)  ,@i__orderGroupId varchar(50), @i__carNo varchar(30) 
														,@i__custOrderNo varchar(100) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN, @i__itemId	,@i__itemNo ,@i__orderGroupId , @i__carNo ,@i__custOrderNo ,@i__mainYN ,@mainCustCode


--반출페널티
SET @sql = N'
SELECT 
	--oi.placeCustCode as custCode ,
	ISNULL(ro.custCode,'''') custCode,  --ISNULL(p.custCode,'''') custCode,
	--ro.roYmd,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(roi.placeWhYmd,ro.roYmd) ELSE ro.roYmd END AS roYmd,
	''입고(반출페널티)'',
	ro.roNo,
	ro.regYmd,
	ro.regHms,
	roi.roSeq,
	1,
	--0,
	ROUND(penaltyPrice/1.1,0),
	ROUND(penaltyPrice/1.1,0),
	ROUND(penaltyPrice/1.1*0.1,0),
	ROUND(penaltyPrice,0),
	0,
	''반품페널티'',
	''반품페널티''
	,''''
	,og.carNo 
	,og.carType 
	, og.orderGroupId
	, ''''
	,roi.uptUserId
	,ISNULL(ro.custRoNo,'''') custRoNo
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerName
	,''반품페널티''                       
	,ISNULL (cust.custName, '''') rcvCustCode
	,0
	,ro.roNo+''(반출)''
FROM e_roItem roi
JOIN dbo.e_ro ro ON roi.roNo = ro.roNo AND roi.comCode = ro.comCode 
LEFT OUTER join dbo.e_orderItem oi on oi.orderNo = roi.orderNo and oi.orderSeq = roi.orderSeq  and oi.comCode = roi.comCode
--JOIN dbo.e_item i ON roi.comCode = i.comCode AND roi.itemId = i.itemId
JOIN dbo.e_item i ON  roi.itemId = i.itemId
LEFT OUTER JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = roi.comCode 
JOIN dbo.e_place p on roi.comCode = p.comCode AND roi.placeNo = p.placeNo
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = roi.comCode AND cd.code = i.makerCode and  mCode = ''1000''
WHERE roi.comCode = @i__logComCode AND penaltyPrice >0'

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND ro.custCode = @i__custCode '  --아래거에서 변경. 2023.11.07 hsg
----SET @sql = @sql + N' AND oi.placeCustCode = @i__custCode '
--IF @i__custCode <> ''
--SET @sql = @sql + N' AND ro.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND ro.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '

IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND ro.custCode  = @i__custCode '

IF @i__placeYmdYN = 'Y'
SET @sql = @sql + N' AND roi.placeWhYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
SET @sql = @sql + N' AND ro.roYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId = @i__orderGroupId '

IF @i__carNo <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

IF @i__itemId <> ''
SET @sql = @sql + N' AND roi.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__custOrderNo  <> ''
SET @sql = @sql + N' AND ro.custRoNo = @i__custOrderNo '

INSERT INTO #원장2 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)
,@i__orderGroupId varchar(50), @i__carNo varchar(30) ,@i__custOrderNo varchar(100) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20) 
,@i__itemId bigint ,@i__itemNo varchar(50)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN  ,@i__orderGroupId , @i__carNo,@i__custOrderNo ,@i__mainYN ,@mainCustCode 
						,@i__itemId  ,@i__itemNo




-- 2023.11.06 hsg :  수동처리: 판매출고, 반품입고
SET @sql = N'
SELECT 
	stor.consignCustCode custCode, 
	convert(char(10), act.created, 121) stdYmd ,	  
	CASE act.actionType WHEN ''rlod'' THEN ''입고'' WHEN ''whri'' THEN ''입고(반출)'' ELSE act.actionType END ledgType, 
	CAST(act.idx as varchar(100)) summary, 
	convert(char(10), act.created, 121) regYmd ,          --등록 연월일
    convert(char(8), act.created, 108) regHms,           --등록 시분초
	'''' seq ,
	CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END cnt,

	ROUND(act.unitPriceConsignAdjust,0) unitPrice,
	ROUND(act.unitPriceConsignAdjust * (CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END),0) sumPrice, 
	ROUND((act.unitPriceConsignAdjust * (CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END)) * 0.1,0) taxPrice ,  
	ROUND((act.unitPriceConsignAdjust * (CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END)) * 1.1,0) sumPriceTax, 

	i.itemId ,
	i.itemNo ,
	CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName  ELSE i.itemNameEn END itemName,
	CASE act.actionType WHEN ''rlod'' THEN ''
	'' WHEN ''whri'' THEN ''반품입고'' ELSE '''' END  memo,
	'''' carNo,
	'''' carType, 
	'''' orderGroupId, 
	'''' clType,
	'''' regUserId,
	'''' custOrderNo,
	ISNULL(cd.codeName, '''') makerCode,
	CASE act.actionType WHEN ''rlod'' THEN ''판매출고'' WHEN ''whri'' THEN ''반품입고'' ELSE '''' END  ledgCateg,
	'''' rcvCustCode,
	act.centerPrice 
	,CAST(act.idx as varchar(100))+''(판매출고)'' summary2
FROM dbo.e_stockActions act
JOIN dbo.e_rack rk ON act.comCode = rk.comCode AND act.rackCode = rk.rackCode
JOIN dbo.e_storage stor ON rk.comCOde = stor.comCode AND rk.storageCode = stor.storageCode
JOIN dbo.e_item i ON act.itemId = i.itemId
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = act.comCode AND cd.code = i.makerCode and  mCode = ''1000''
WHERE 1 = 1 AND stor.consignYN = ''Y'' AND act.actionType IN (''rlod'', ''whri'')
  AND convert(char(10), act.created, 121)  BETWEEN  @i__sYmd1 AND @i__eYmd1 '

 IF @i__itemId <> ''
SET @sql = @sql + N' AND i.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__logComCode = 'ㄱ000' -- 팬오토인 경우 
BEGIN
	SET @sql = @sql + N' AND stor.consignCustCode IN (SELECT consignCustCode FROM dbo.e_storage WHERE comCode=@i__logComCode AND consignYn=''Y'') '  -- 위탁창고로 등록된 거래처만
	--IF @i__custCode <> ''  --거래처로 조회한 경우 
	--	SET @sql = @sql + N' AND stor.consignCustCode = @i__custCode '
	--IF @i__custCode <> ''
	--	SET @sql = @sql + N' AND stor.consignCustCode =  CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'
	IF @i__custCode <> '' AND @i__mainYN = 'Y'
	SET @sql = @sql + N' AND stor.consignCustCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '
	IF @i__custCode <> '' AND @i__mainYN <> 'Y'
	SET @sql = @sql + N' AND stor.consignCustCode  = @i__custCode '
END
ELSE  --위탁한 업체인 경우  
BEGIN
	SET @sql = @sql + N' AND 1 = 2  '  --팬오토 이외의 업체에는 이 항목이 노출이 안되게 하기 위함.
END

INSERT INTO #원장2 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
						,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
						,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) 
,@i__placeYmdYN varchar(5) ,@i__orderGroupId varchar(50), @i__carNo varchar(30) ,@i__custOrderNo varchar(100) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)
,@i__itemId bigint ,@i__itemNo varchar(50)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN  ,@i__orderGroupId , @i__carNo,@i__custOrderNo ,@i__mainYN ,@mainCustCode
						,@i__itemId  ,@i__itemNo 


--판매출고
SET @sql = N'
SELECT 
	si.comCode, 
	si.regYmd,	
	CASE WHEN si.saleType = ''판매출고'' THEN ''입고(판매내역)''
		WHEN si.saleType = ''반품입고'' THEN ''입고(반출판매내역)''
		ELSE '''' END,
	si.saleNo,
	si.regYmd,
	si.regHms,

	si.saleSeq,
	CASE WHEN si.saleType = ''판매출고'' THEN si.qty
		WHEN si.saleType = ''반품입고'' THEN -si.qty
		ELSE si.qty END,	
	ROUND(si.saleUnitPrice,0),	
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*0.1,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*1.1,0) END,
 
	si.itemId,
	i.itemNo,
	ISNULL(i.itemName,i.itemNameEn),
	'''',
	'''',
	'''',
	'''',
	'''',
	--si.regUserId,
	''AUTO'',
	'''',
	'''',
	si.saleType,
	ISNULL(cust.custName,'''') rcvCustCode,
	si.centerPrice,
	si.saleNo + ''(saleNo)''

	
	
FROM	dbo.e_saleItem   si
--left outer JOIN dbo.e_item i ON si.itemId = i.itemId AND i.comCode = si.plComCode --20240214 yoonsang 재고옮기고 수정
--left outer JOIN dbo.e_cust cust ON cust.comCode = si.comCode AND cust.custCode = si.puComCode --20240214 yoonsang 재고옮기고 수정
JOIN dbo.e_item i ON si.itemId = i.itemId 
LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = @i__logComCode AND pli.placeNo = si.plPlaceNo
left outer JOIN dbo.e_cust cust ON cust.comCode = pli.comCode AND cust.custCode = pli.rcvCustCode

WHERE si.plComCode = @i__logComCode AND si.regYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND ISNULL(pli.orderGroupId,'''') = '''' 
'

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND si.comCode = @i__custCode '

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND si.comCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '

IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND si.comCode = @i__custCode '

IF @i__itemId <> ''
SET @sql = @sql + N' AND si.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '


ELSE
BEGIN
	SET @sql = @sql
END


INSERT INTO #원장2 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
						,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
						,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50),@i__itemId bigint 
								,@i__itemNo varchar(50) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode,@i__itemId ,@i__itemNo ,@i__mainYN ,@mainCustCode


SELECT distinct 
    a.custCode,
    cust.custName as custName,
    stdYmd,
    ledgType,
    summary,
    a.regYmd,
    a.regHms,
    seq,
    a.cnt,
    ROUND(a.unitPrice,0) unitPrice,
    ROUND(a.sumPrice,0) sumPrice,
    ROUND(a.taxPrice,0) taxPrice,
    ROUND(sumPriceTax,0) sumPriceTax,
    a.itemId,
    a.itemNo,
    a.itemName,
    a.memo,
    ISNULL(carNo,'') AS carNo ,
    ISNULL(a.carType,'') AS carType,
    a.orderGroupId,
    ISNULL(clType,'') as clType,
    a.regUserId,
   -- u.userName as userName
    CASE WHEN a.regUserId = 'AUTO' 
		THEN 'AUTO'
		ELSE u.userName 
		END userName 
	,ISNULL(a.makerCode,'') as makerCode 
	,ISNULL(a.custOrderNo,'') as custOrderNo      
	,a.ledgCateg
	,a.rcvCustCode
	,a.centerPrice
	,a.orderNo 
	,a.orderSeq 
		--,CASE WHEN wd1.wdNo IS NOT NULL THEN '완료(발주)'
	 --   WHEN wd2.wdNo IS NOT NULL THEN '완료(입고)' 
		--WHEN z.wdReqNo IS NOT NULL THEN '요청(발주)'
	 --   WHEN y.wdReqNo IS NOT NULL THEN '요청(입고)'
		--ELSE ''	END as withdrawStatus --출금상태
	,CASE 
		WHEN y.wdReqNo IS NOT NULL THEN y.withdrawStatus
		WHEN z.wdReqNo IS NOT NULL THEN z.withdrawStatus
		ELSE '' 
	END AS withdrawStatus	
	,summary2
	, d.codeName makerName
	,d2.codeName className
	,IIF(c.classCode = 'GN','', c.factoryNo) factoryNo
	--,ISNULL(cust.mainCustCode,cust.custCode) AS mainCustCode
	--,cust2.custName AS mainCustName
	,CASE WHEN ISNULL(cust.mainCustCode,'') = '' THEN cust.custCode ELSE cust.mainCustCode END  AS mainCustCode
	,(SELECT custName FROM dbo.e_cust WHERE comCode=@i__logComCode AND custCode = CASE WHEN ISNULL(cust.mainCustCode,'') = '' THEN cust.custCode ELSE cust.mainCustCode END) AS mainCustName


FROM #원장2 a
JOIN dbo.e_cust cust ON a.custCode = cust.custCode and cust.comCode = @i__logComCode
--JOIN dbo.e_cust cust2 ON cust2.comCode =  cust.comCode  AND  cust2.custCode = ISNULL(cust.mainCustCode,cust.custCode)
LEFT OUTER JOIN dbo.e_user u on u.userId = a.regUserId and u.comCode = @i__logComCode
--LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = @i__logComCode AND pli.orderNo = a.orderNo AND pli.orderSeq = a.orderSeq
--LEFT OUTER JOIN (SELECT DISTINCT wrd1.comCode, wrd1.wdReqNo, wrd1.jobNo FROM dbo.e_wdReqDtl wrd1 --발주출금요청
--					      JOIN dbo.e_wdReq wr1 ON wrd1.comCode = wr1.comCode AND wrd1.wdReqNo = wr1.wdReqNo AND wr1.wdReqType ='발주출금'
--				) z ON pli.comCode = z.comCode AND pli.placeNo = z.jobNo	
--LEFT OUTER JOIN (SELECT DISTINCT wrd2.comCode, wrd2.wdReqNo, wrd2.jobNo,wrd2.jobSeq FROM dbo.e_wdReqDtl wrd2 --입고출금요청
--					      JOIN dbo.e_wdReq wr2 ON wrd2.comCode = wr2.comCode AND wrd2.wdReqNo = wr2.wdReqNo AND wr2.wdReqType ='입고출금'
--				) y ON pli.comCode = y.comCode AND a.summary = y.jobNo and a.seq = y.jobSeq
--LEFT OUTER JOIN dbo.e_withdraw wd1 ON z.comCode = wd1.comCode AND z.wdReqNo = wd1.wdReqNo --발주출금
--LEFT OUTER JOIN dbo.e_withdraw wd2 ON y.comCode = wd2.comCode AND y.wdReqNo = wd2.wdReqNo --입고출금

LEFT OUTER JOIN (SELECT wrd1.comCode, wrd1.wdReqNo, wrd1.jobNo,wrd1.jobSeq, wrd1.jobType, CASE WHEN wd1.wdReqNo IS NULL THEN '요청(발주)' ELSE '완료(발주)' END withdrawStatus
					FROM dbo.e_wdReqDtl wrd1 --발주출금요청
					JOIN dbo.e_wdReq wr1 ON wrd1.comCode = wr1.comCode AND wrd1.wdReqNo = wr1.wdReqNo AND wr1.wdReqType ='발주출금'
					--JOIN dbo.e_placeItem pli ON pli.comCode = wrd1.comCode AND pli.placeNo = wrd1.jobNo AND pli.placeSeq = wrd1.jobSeq
					LEFT OUTER JOIN dbo.e_withdraw wd1 ON wr1.comCode = wd1.comCode AND wr1.wdReqNo = wd1.wdReqNo --발주출금
					WHERE wrd1.comCode = @i__logComCode
				) z ON z.comCode = @i__logComCode AND a.placeNo = z.jobNo  --AND a.ledgType = z.jobType

LEFT OUTER JOIN (SELECT  wrd2.comCode, wrd2.wdReqNo, wrd2.jobNo,wrd2.jobSeq, wrd2.jobType, CASE WHEN wd2.wdReqNo IS NULL THEN '요청(입고)' ELSE '완료(입고)' END withdrawStatus
					FROM dbo.e_wdReqDtl wrd2 --입고출금요청
					JOIN dbo.e_wdReq wr2 ON wrd2.comCode = wr2.comCode AND wrd2.wdReqNo = wr2.wdReqNo AND wr2.wdReqType ='입고출금'
					LEFT OUTER JOIN dbo.e_withdraw wd2 ON wr2.comCode = wd2.comCode AND wr2.wdReqNo = wd2.wdReqNo --입고출금
					WHERE wrd2.comCode = @i__logComCode
				) y ON y.comCode = @i__logComCode AND a.summary = y.jobNo and a.seq = y.jobSeq AND a.ledgType = y.jobType
LEFT OUTER JOIN dbo.e_item c ON  a.itemId = c.itemId
LEFT OUTER JOIN dbo.e_code d ON d.comCode = @i__logComCode AND d.mCode='1000' AND d.code = c.makerCode
LEFT OUTER JOIN dbo.e_code d2 ON d2.comCode = @i__logComCode AND d2.mCode='1100' AND d2.code = c.classCode

WHERE a.ledgType LIKE CASE WHEN @i__ledgType = '' THEN '%' ELSE '%' + @i__ledgType + '%' END
ORDER BY stdYmd, custName, a.regYmd, a.regHms
             
DROP TABLE #원장2

RETURN
/*********************************************************************************************************/
RLLIST_QRY:　--매출처 거래상세내역 



CREATE TABLE #원장3 (
	idx int identity primary key , 
	custCode varchar(10) , 
	stdYmd varchar(10),--날짜
	ledgType varchar(50), --구분
	summary varchar(20),--적요
	regYmd varchar(10)
	,regHms varchar(8)
	,seq varchar(20) --순번
	,cnt varchar(20)
	,unitPrice money 
	, sumPrice money  --공급가액
	, taxPrice money --세액  
	, sumPriceTax money  --합계금액
	,itemId bigint 
	,itemNo varchar (50)
	,itemName varchar (200)  
	,memo varchar (2000) 
	,carNo varchar(100)
	, carType varchar(50) 
	,orderGroupId varchar( 30)
	, clType varchar(20)
	,regUserId varchar(50)
	,makerCode varchar(50)
	,ledgCateg varchar(50)
	,centerPrice money 
	,costPrice money --원가 (입고단가)
	,srCode varchar(50) --sr코드
	,summary2 varchar(100)--적요2

)
--반입 
SET @sql = N'
SELECT 
	ri.custCode,
	ri.riYmd,
	''출고(반입)'',
	ri.riNo,
	ri.regYmd,
	ri.regHms,
	rii.riSeq,
	-rii.cnt,
	ROUND(rii.riUnitPrice,0),
	ROUND(-rii.riUnitPrice * rii.cnt,0),
	ROUND(-rii.riUnitPrice * rii.cnt*0.1,0),
	ROUND(-rii.riUnitPrice* rii.cnt*1.1,0)
	,rii.itemId
	,i.itemNo
	--,ISNULL(i.itemName,i.itemNameEn)
	,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,rii.memo1
	,og.carNo
	,og.carType
	,og.orderGroupId 
	,oi.clType 
	,rii.regUserId
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerCode
	,''반입''
	,oi.centerPrice
	,rli.costPrice
	,	 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b
                      WHERE  b.custcode = ri.custcode AND rii.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') AS srCode
	,ri.riNo + ''(반입)''
FROM dbo.e_riItem rii
JOIN dbo.e_ri ri ON rii.riNo = ri.riNo AND rii.comCode = ri.comCode 
left outer join dbo.e_orderItem oi on oi.orderNo = rii.orderNo and oi.orderSeq = rii.orderSeq  and oi.comCode = rii.comCode
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rii.comCode
--JOIN dbo.e_item i ON rii.comCode = i.comCode AND rii.itemId = i.itemId
JOIN dbo.e_item i ON rii.itemId = i.itemId

LEFT OUTER JOIN (SELECT comCode, orderNo, orderSeq, AVG(costPrice) costPrice FROM dbo.e_rlitem WHERE comCode = @i__logComCode GROUP BY comCode, orderNo, orderSeq
				) rli ON rii.comCode = rli.comCode AND rii.orderNo = rli.orderNo AND rii.orderSeq = rli.orderSeq
LEFT OUTER JOIN dbo.e_srCust sc ON rii.comCode = sc.comCode AND ri.custCode = sc.custCode
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = rii.comCode AND cd.code = i.makerCode and  mCode = ''1000''

WHERE rii.comCode = @i__logComCode AND ri.riYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND ri.custCode = @i__custCode '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND ri.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND ri.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '
IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND ri.custCode = @i__custCode '

IF @i__clType <> ''
SET @sql = @sql + N' AND oi.clType = @i__clType '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId = @i__orderGroupId '

IF @i__carNo  <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

IF @i__itemId <> ''
SET @sql = @sql + N' AND rii.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__srCode <> ''
SET @sql = @sql + N' AND sc.srCode= @i__srCode '

IF @i__srCode <> ''
SET @sql = @sql + N' AND 
 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b             
                      WHERE  b.custcode = ri.custcode AND rii.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') LIKE ''%'' + @i__srCode + ''%'' '

print @sql

INSERT INTO #원장3 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice, costPrice,srCode,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30) ,@i__orderGroupId varchar(50)
											,@i__carNo varchar(50) ,@i__itemId bigint ,@i__itemNo varchar(50) ,@i__srCode varchar(50)  ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType,@i__orderGroupId ,@i__carNo ,@i__itemId  ,@i__itemNo ,@i__srCode ,@i__mainYN ,@mainCustCode
					
--출고 
SET @sql = N'
SELECT 
	rl.custCode,
	rl.rlYmd,
	''출고'',
	rl.rlNo,
	rl.regYmd,
	rl.regHms,
	rli.rlSeq
	,rli.cnt
	,ROUND(rli.rlUnitPrice,0)
	,ROUND(rli.rlSumPrice,0)
	,ROUND(rli.rlSumPrice*0.1,0)
	,ROUND(rli.rlSumPrice*1.1,0)
	,rli.itemId
	,i.itemNo
	--,ISNULL(i.itemName,i.itemNameEn)
	,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,rli.memo1
	,og.carNo
	,og.carType
	,og.orderGroupId 
	,oi.clType 
	,rli.regUserId
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerName
	,''출고''
	,oi.centerPrice
	,rli.costPrice
	,	 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b
                      WHERE  b.custcode = rl.custcode AND rli.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') AS srCode
	,rl.rlNo + ''(출고)''
FROM	dbo.e_rlItem rli 
JOIN dbo.e_rl rl ON rl.rlNo = rli.rlNo AND rl.comCode = rli.comCode
LEFT OUTER JOIN dbo.e_orderItem oi ON oi.comCode = rli.comCode AND oi.orderNo = rli.orderNo AND oi.orderSeq = rli.orderSeq
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rli.comCode
--JOIN dbo.e_item i ON rli.comCode = i.comCode AND rli.itemId = i.itemId 
JOIN dbo.e_item i ON rli.itemId = i.itemId 
LEFT OUTER JOIN dbo.e_srCust sc ON rli.comCode = sc.comCode AND rl.custCode = sc.custCode
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = rli.comCode AND cd.code = i.makerCode and  mCode = ''1000''
WHERE rli.comCode = @i__logComCode AND rl.rlYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND rl.custCode = @i__custCode'

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND rl.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND rl.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '
IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND rl.custCode = @i__custCode '


IF @i__clType <> ''
SET @sql = @sql + N' AND oi.clType = @i__clType '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId = @i__orderGroupId '

IF @i__carNo  <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

IF @i__itemId <> ''
SET @sql = @sql + N' AND rli.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__srCode <> ''
SET @sql = @sql + N' AND sc.srCode= @i__srCode '

IF @i__srCode <> ''
SET @sql = @sql + N' AND 
 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b
                      WHERE   b.custcode = rl.custcode AND rli.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') LIKE ''%'' + @i__srCode + ''%'' '

INSERT INTO #원장3 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice	,costPrice,srCode,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30) ,@i__orderGroupId varchar(50)
											,@i__carNo varchar(50) ,@i__itemId bigint ,@i__itemNo varchar(50) ,@i__srCode varchar(50) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType ,@i__orderGroupId ,@i__carNo ,@i__itemId ,@i__itemNo ,@i__srCode ,@i__mainYN ,@mainCustCode

--운송비
SET @sql = N'
SELECT 
	rl.custCode,
	rl.rlYmd,
	''출고(운송비)'',
	rl.rlNo,
	rl.regYmd,
	rl.regHms,
	''운송비'' --seq
	,1 --cnt
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1 ,0) 	
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1 ,0) 	
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1*0.1,0) 	
	,ROUND(ISNULL(max(rl.deliveryFee),''''),0)
	,0
	,''운송비''
	,''운송비''
	,MAX(rl.memo1)memo1
	,MAX(og.carNo)
	,MAX(og.carType)
	,MAX(og.orderGroupId )
	,MAX(oi.clType )
	,MAX(rl.uptUserId)
	,ISNULL(MAX(og.makerCode),'''') makerCode
	,''출고(운송비)''
	,''''
	,''''
	--, ISNULL(Replace(Stuff((SELECT '','' + MAX(sc.srCode)
 --                     FOR xml path('''')), 1, 1, ''''), '','', '',''),'''')  AS srCode
 	,	 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b                
                      WHERE  b.custcode = rl.custcode AND rl.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') AS srCode
	,rl.rlNo + ''(출고)''
FROM	dbo.e_rl rl 
JOIN dbo.e_rlItem rli ON rl.comCode = rli.comCode AND  rl.rlNo = rli.rlNo
LEFT OUTER JOIN dbo.e_orderItem oi ON oi.comCode = rli.comCode AND oi.orderNo = rli.orderNo AND oi.orderSeq = rli.orderSeq
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rli.comCode
LEFT OUTER JOIN dbo.e_srCust sc ON rl.comCode = sc.comCode AND rl.custCode = sc.custCode
WHERE rli.comCode = @i__logComCode AND rl.rlYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND rl.deliveryYN = ''Y'' '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND rl.custCode = @i__custCode'

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND rl.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND rl.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '
IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND rl.custCode = @i__custCode '


IF @i__clType <> ''
SET @sql = @sql + N' AND oi.clType  = @i__clType '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId  = @i__orderGroupId '

IF @i__carNo  <> ''
SET @sql = @sql + N' AND  og.carNo = @i__carNo '

IF @i__srCode <> ''
SET @sql = @sql + N' AND sc.srCode= @i__srCode '
IF @i__srCode <> ''
 SET @sql = @sql + N'  AND	ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b                         
                      WHERE  b.custcode = rl.custcode AND rl.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''')  LIKE ''%'' + @i__srCode + ''%'' '

SET @sql  = @sql + ' group by rl.rlNo , rl.comCode, rl.regYmd,rl.regHms,	rl.custCode,	rl.rlYmd' 


INSERT INTO #원장3 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
										,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
										,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice,costPrice,srCode,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30) ,@i__orderGroupId varchar(50)
											,@i__carNo varchar(50) ,@i__itemId bigint ,@i__itemNo varchar(50) ,@i__srCode varchar(50) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType ,@i__orderGroupId ,@i__carNo ,@i__itemId ,@i__itemNo ,@i__srCode ,@i__mainYN ,@mainCustCode

--일반 -> 보험전환 
SET @sql = N'

SELECT 
	rli.custCode, 
	a.clChnYmd,
	''출고'',
	rli.rlNo,
	a.regYmd,
	a.regHms,
	rli.orderSeq,
	-rli.rlCnt
	,ROUND(-a.salePrice,0)
	,ROUND(-a.sumPrice,0)
	,ROUND(-a.sumPrice * 0.1,0)
	,ROUND(-a.sumPrice*1.1,0)
	,a.itemId
	,i.itemNo
	,i.itemName
	,''''
	,og.carNo
	,og.carType
	,a.orderGroupId
	,a.clType
	,a.regUserId
	--,og.makerCode
	,ISNULL(cd.codeName, '''') makerCode
	,''출고(청구변경(일반)''
	,a.centerPrice
	,rli.costPrice
	,	 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b                           
                      WHERE  b.custcode = og.custcode AND a.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') AS srCode
	,rli.rlNo + ''(출고)''

FROM	dbo.e_orderItem a 
LEFT OUTER JOIN (SELECT x.comCode, MAX(x.rlno) rlNo, MAX(x.rlSeq) rlSeq, x.orderNo, x.orderSeq, SUM(x.CNT) rlCnt , MAX(ISNULL(xx.custCode,'''')) AS custCode, MAX(xx.rlYmd) AS rlYmd
					,AVG(x.costPrice) costPrice
				  	FROM dbo.e_rlItem x
					JOIN dbo.e_rl xx ON x.comCode = xx.comCode AND x.rlNo = xx.rlNo
					WHERE x.comCode = @i__logComCode 
					GROUP BY x.comCode, x.orderNo, x.orderSeq
				) rli ON a.comCode = rli.comCode AND a.orderNo = rli.orderNo AND a.orderSeq = rli.orderSeq --출고품목
LEFT OUTER JOIN (SELECT x.comCode, x.orderNo, x.orderSeq, SUM(x.cnt) clCnt 
			FROM dbo.e_clReqItem x
			JOIN dbo.e_clReq y ON x.comCode = y.comCode AND x.clReqNo = y.clReqNo
			WHERE x.comCode = @i__logComCode  AND y.clType = ''일반'' AND x.cnt > 0 
			GROUP BY x.comCode, x.orderNo, x.orderSeq
		 ) cri ON a.comCode = cri.comCode AND a.orderNO = cri.orderNo AND a.orderSeq = cri.orderSeq  --일반건으로 플러스 청구 요청되었으면서 
LEFT OUTER JOIN (SELECT x1.comCode, x1.orderNo, x1.orderSeq, SUM(x1.cnt) clCnt 
					FROM dbo.e_clReqItem x1
					JOIN dbo.e_clReq y1 ON x1.comCode = y1.comCode AND x1.clReqNo = y1.clReqNo
					WHERE x1.comCode =  @i__logComCode  AND y1.clType = ''일반'' AND x1.Cnt < 0
					GROUP BY x1.comCode, x1.orderNo, x1.orderSeq
		 ) cri1 ON a.comCode = cri1.comCode AND a.orderNO = cri1.orderNo AND a.orderSeq = cri1.orderSeq
--JOIN dbo.e_item i ON rli.comCode = i.comCode AND a.itemId = i.itemId
JOIN dbo.e_item i ON a.itemId = i.itemId
LEFT OUTER JOIN dbo.e_orderGroup og ON a.orderGroupId = og.orderGroupId AND a.comCode = og.comCode
LEFT OUTER JOIN dbo.e_srCust sc ON a.comCode = sc.comCode AND rli.custCode = sc.custCode
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = a.comCode AND cd.code = i.makerCode and  mCode = ''1000''
where  a.clType = ''보험'' AND a.minusClYN=''Y'' AND a.clChnYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND a.comCode = @i__logComCode AND (cri.clCnt > ISNULL(cri1.clCnt,0) * -1 ) '

--IF @i__custCode <> '' 
--SET @sql = @sql + N' AND rli.custCode = @i__custCode '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND  rli.custCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND rli.custCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '
IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND rli.custCode = @i__custCode '


IF @i__clType <> ''
SET @sql = @sql + N' AND a.clType = @i__clType '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND a.orderGroupId = @i__orderGroupId '

IF @i__carNo  <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

IF @i__itemId <> ''
SET @sql = @sql + N' AND a.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__srCode <> ''
SET @sql = @sql + N' AND sc.srCode= @i__srCode '

IF @i__srCode <> ''
SET @sql = @sql + N' AND 
 ISNULL(Replace(Stuff((SELECT '','' + b.srCode
                      FROM   dbo.e_srcust b                          
                      WHERE   b.custcode = og.custcode AND a.comcode = b.comcode
                      FOR xml path('''')), 1, 1, ''''), '','', '',''),'''') LIKE ''%'' + @i__srCode + ''%'' '


INSERT INTO #원장3 (custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice	,costPrice,srCode,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30)  ,@i__orderGroupId varchar(50)
											,@i__carNo varchar(50) ,@i__itemId bigint ,@i__itemNo varchar(50) ,@i__srCode varchar(50) ,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType ,@i__orderGroupId ,@i__carNo  ,@i__itemId ,@i__itemNo ,@i__srCode ,@i__mainYN ,@mainCustCode


--판매출고
SET @sql = N'
SELECT 
	si.plComCode, 
	si.regYmd,	
	CASE WHEN si.saleType = ''판매출고'' THEN ''판매출고''
		WHEN si.saleType = ''반품입고'' THEN ''판매출고(반품입고)''
		ELSE '''' END,
	si.saleNo,
	si.regYmd,
	si.regHms,

	si.saleSeq,
	CASE WHEN si.saleType = ''판매출고'' THEN si.qty
		WHEN si.saleType = ''반품입고'' THEN -si.qty
		ELSE si.qty END,	
	ROUND(si.saleUnitPrice,0),	
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*0.1,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*1.1,0) END,
 
	si.itemId,
	i.itemNo,
	ISNULL(i.itemName,i.itemNameEn),
	tcg.taxBillNo,
	'''',
	'''',
	'''',
	'''',
	--si.regUserId,
	''AUTO'',
	'''',
	si.saleType,
	si.centerPrice,
	si.costPrice,
	'''',
	si.saleNo + ''(saleNo)''

	
	
FROM	dbo.e_saleItem   si
--left outer JOIN dbo.e_item i ON si.itemId = i.itemId AND i.comCode = si.comCode
JOIN dbo.e_item i ON si.itemId = i.itemId
LEFT OUTER JOIN dbo.e_taxBillClGroup tcg ON tcg.comCode = si.comCode AND tcg.saleNo = si.saleNo AND tcg.saleSeq = si.saleSeq

WHERE si.comCode = @i__logComCode AND si.regYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND si.plComCode = @i__custCode '

--IF @i__custCode <> ''
--SET @sql = @sql + N' AND si.plComCode = CASE WHEN @i__mainYN = ''Y'' THEN @mainCustCode ELSE @i__custCode END'

IF @i__custCode <> '' AND @i__mainYN = 'Y'
SET @sql = @sql + N' AND si.plComCode IN (SELECT custCode FROM dbo.e_cust WHERE comCode = @i__logComCode AND mainCustCode = @mainCustCode) '
IF @i__custCode <> '' AND @i__mainYN <> 'Y'
SET @sql = @sql + N' AND si.plComCode = @i__custCode '


IF @i__itemId <> ''
SET @sql = @sql + N' AND si.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

IF @i__srCode <> ''
SET @sql = @sql + N' AND 1=2 '

IF @i__taxBillRegYN  = 'Y'
BEGIN
	SET @sql = @sql + N' AND ISNULL(tcg.taxBillNo,'''') <> '''' '
END
ELSE IF @i__taxBillRegYN  = 'N'
BEGIN
	SET @sql = @sql + N' AND ISNULL(tcg.taxBillNo,'''') = '''' '
END
ELSE
BEGIN
	SET @sql = @sql
END


INSERT INTO #원장3 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice	,costPrice,srCode,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50),@i__itemId bigint ,@i__itemNo varchar(50) 
							,@i__mainYN varchar(2) ,@mainCustCode varchar(20)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode,@i__itemId ,@i__itemNo ,@i__mainYN ,@mainCustCode


SELECT 
    a.custCode,
    cust.custName as custName,
    stdYmd,
    ledgType,
    summary,
    a.regYmd,
    a.regHms,
    seq,
    cnt,
    ROUND(unitPrice,0) unitPrice,
    ROUND(sumPrice,0) sumPrice,
    ROUND(taxPrice,0) taxPrice,
    ROUND(sumPriceTax,0) sumPriceTax,
    a.itemId,
    a.itemNo,
    a.itemName,
    a.memo,
    ISNULL(carNo,'') AS carNo ,
    ISNULL(a.carType,'') AS carType,
    orderGroupId,
    ISNULL(clType,'') as clType,
    a.regUserId,
   CASE WHEN a.regUserId = 'AUTO' 
		THEN 'AUTO'
		ELSE  u.userName END userName
	,ISNULL(a.makerCode,'') as makerCode 
	,a.ledgCateg
	,a.centerPrice
	,a.costPrice
	,srCode
	,summary2
	, d.codeName makerName
	,d2.codeName className
	,IIF(c.classCode = 'GN','', c.factoryNo) factoryNo
FROM #원장3 a
JOIN dbo.e_cust cust ON a.custCode = cust.custCode and cust.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_user u on u.userId = a.regUserId and u.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_item c ON  a.itemId = c.itemId
LEFT OUTER JOIN dbo.e_code d ON d.comCode = @i__logComCode AND d.mCode='1000' AND d.code = c.makerCode
LEFT OUTER JOIN dbo.e_code d2 ON d2.comCode = @i__logComCode AND d2.mCode='1100' AND d2.code = c.classCode
WHERE a.ledgType LIKE CASE WHEN @i__ledgType = '' THEN '%' ELSE '%' + @i__ledgType + '%' END
ORDER BY stdYmd, custName, a.regYmd, a.regHms
             
DROP TABLE #원장3

RETURN
/*********************************************************************************************************/
OUT_LIST:

/*
panErp.dbo.up_transactionList	@i__workingType='OUT_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2023-10-02',      @i__eYmd1='2023-10-26',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ000',   
@i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='',    @i__custOrderNo='',       @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',       @i__custCode=''

*/

CREATE TABLE #원장4 (
	idx int identity primary key , 
	custCode varchar(10) , 
	stdYmd varchar(10),--날짜
	ledgType varchar(50), --구분
	summary varchar(20),--적요
	regYmd varchar(10)
	,regHms varchar(8)
	,seq varchar(20) --순번
	,cnt varchar(20)
	,unitPrice money 
	, sumPrice money  --공급가액
	, taxPrice money --세액  
	, sumPriceTax money  --합계금액
	,itemId bigint 
	,itemNo varchar (50)
	,itemName varchar (200)  
	,memo varchar (2000) 
	,carNo varchar(100)
	, carType varchar(50) 
	,orderGroupId varchar( 30)
	, clType varchar(20)
	,regUserId varchar(50)
	,makerCode varchar(50)
	,custOrderNo varchar(100)
	,ledgCateg varchar(50)
	,rcvCustCode varchar(100) --납품처 
	,centerPrice money --센터가 
	,orderNo varchar(20)
	,orderSeq varchar(20) 
	,salePrice money
	,summary2 varchar(100)--적요
)

--입고
SET @sql = N'
SELECT 
	w.custCode,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(wi.placeRlYmd,w.whYmd) ELSE w.whYmd END AS whYmd,
	''주문'',
	w.whNo,
	w.regYmd,
	w.regHms,
	wi.whSeq,
	wi.cnt,
	ROUND(wi.whUnitPrice,0),
	ROUND(wi.whSumPrice,0),
	ROUND(wi.whSumPrice*0.1,0),
	ROUND(wi.whSumPrice *1.1,0),
	wi.itemId
	,i.itemNo
	,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
	WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
	ELSE i.itemNameEn END itemName
	--,wi.memo1
	,''판매출고(H)'' memo1
	,ISNULL(og.carNo ,'''')
	,ISNULL(og.carType,'''') 
	, og.orderGroupId
	, ''''
	,wi.regUserId
	,ISNULL(cd.codeName, '''') makerCode
	,ISNULL (p.custOrderNo,'''') custOrderNo
	,''입고''
	,ISNULL (cust.custName, '''') rcvCustCode
	,ISNULL(oi.centerPrice , wi.centerPrice) centerPrice
	,oi.orderNo
	,oi.orderSeq 
	,oi2.salePrice
	,w.whNo + ''(입고)''
FROM dbo.e_whItem wi 
JOIN dbo.e_wh w on w.comCode = wi.comCode AND w.whNo = wi.whNo
JOIN dbo.e_item i ON wi.itemId = i.itemId
LEFT OUTER JOIN dbo.e_orderItem oi on wi.comCode = oi.comCode and wi.orderNo = oi.orderNo and wi.orderSeq = oi.orderSeq
LEFT OUTER JOIN dbo.e_place p on p.comCode = wi.comCode and p.placeNo = wi.placeNo 
LEFT OUTER JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = wi.comCode 
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = wi.comCode AND cd.code = i.makerCode and  mCode = ''1000''
LEFT OUTER JOIN dbo.e_storageUseReqItem sui ON wi.comCOde = sui.comcode AND wi.storageUseReqNo = sui.storageUseReqNo AND wi.storageUseReqSeq = sui.reqSeq
LEFT OUTER JOIN dbo.e_orderItem oi2 ON sui.comcode = oi2.comCode AND sui.orderNo = oi2.orderNo AND sui.orderSeq = oi2.orderSeq
WHERE 1 = 1 AND ISNULL(wi.storageUseReqNo, '''') <> '''' '

IF @i__logComCode = 'ㄱ000' -- 팬오토인 경우 
BEGIN
	SET @sql = @sql + N' AND w.custCode IN (SELECT consignCustCode FROM dbo.e_storage WHERE comCode=@i__logComCode AND consignYn=''Y'') '  -- 위탁창고로 등록된 거래처만
	IF @i__custCode <> ''  --거래처로 조회한 경우 
		SET @sql = @sql + N' AND w.custCode = @i__custCode '
END
ELSE  --위탁한 업체인 경우  
BEGIN
	SET @sql = @sql + N' AND w.custCode = @i__logComCode '
END

IF @i__placeYmdYN = 'Y'
	SET @sql = @sql + N' AND wi.placeRlYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
	SET @sql = @sql + N' AND w.whYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
	SET @sql = @sql + N' AND wi.itemId = @i__itemId '

IF @i__itemNo <> ''
	SET @sql = @sql + N' AND i.itemNo = @i__itemNo '
print @sql

INSERT INTO #원장4 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms ,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
						,carNo, carType, orderGroupId, clType,regUserId,makerCode,custOrderNo,ledgCateg,rcvCustCode,centerPrice ,orderNo, orderSeq, salePrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50), @i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)   ,@i__orderGroupId varchar(50), @i__carNo varchar(30),@i__custOrderNo varchar(100) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__placeYmdYN ,@i__itemId	,@i__itemNo  ,@i__orderGroupId, @i__carNo ,@i__custOrderNo


--반출내역 
SET @sql = N'
SELECT 
	ISNULL(ro.custCode,'''') custCode,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(roi.placeWhYmd,ro.roYmd) ELSE ro.roYmd END AS roYmd,
	''*반품'',
	ro.roNo,
	ro.regYmd,
	ro.regHms,
	roi.roSeq,
	-roi.cnt,
	ROUND(roi.roUnitPrice,0),
	ROUND(-roi.roUnitPrice * roi.cnt,0),
	ROUND(-roi.roUnitPrice * roi.cnt*0.1,0),
	ROUND(-roi.roUnitPrice * roi.cnt * 1.1,0),
	roi.itemId,
	i.itemNo
	,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	--,roi.memo1
	,''반품입고(H)'' memo1
	,og.carNo 
	,og.carType 
	, og.orderGroupId
	, ''''
	,roi.regUserId
	,ISNULL(ro.custRoNo,'''') custRoNo
	,ISNULL(cd.codeName, '''') makerCode
	,''반출''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice
	,oi.orderNo
	,oi.orderSeq 
	,oi.salePrice
	,ro.roNo +''(반품)''
FROM e_roItem roi
JOIN dbo.e_ro ro ON roi.roNo = ro.roNo AND roi.comCode = ro.comCode 
LEFT OUTER JOIN dbo.e_orderItem oi on oi.orderNo = roi.orderNo and oi.orderSeq = roi.orderSeq  and oi.comCode = roi.comCode  --2023.10.04 위에거에서 변경 left outer 로 변경
JOIN dbo.e_item i ON  roi.itemId = i.itemId
LEFT OUTER JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = roi.comCode   --2023.10.04 위에거에서 변경 left outer 로 변경
LEFT OUTER JOIN dbo.e_place p on roi.comCode = p.comCode AND roi.placeNo = p.placeNo   --2023.10.04 위에거에서 변경 left outer 로 변경
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode   --2023.10.04 위에거에서 변경 left outer 로 변경
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = roi.comCode AND cd.code = i.makerCode and  mCode = ''1000''
JOIN dbo.e_storage stor ON ro.comCode = stor.comCode AND ro.storageCode = stor.storageCode AND  consignYn=''Y'' 
WHERE 1= 1 '
--WHERE ro.custCode = @i__logComCode '

IF @i__logComCode = 'ㄱ000' -- 팬오토인 경우 
BEGIN
	SET @sql = @sql + N' AND ro.custCode IN (SELECT consignCustCode FROM dbo.e_storage WHERE comCode=@i__logComCode AND consignYn=''Y'') '  -- 위탁창고로 등록된 거래처만
	IF @i__custCode <> ''  --거래처로 조회한 경우 
		SET @sql = @sql + N' AND ro.custCode = @i__custCode '
END
ELSE  --위탁한 업체인 경우  
BEGIN
	SET @sql = @sql + N' AND ro.custCode = @i__logComCode '
END


IF @i__placeYmdYN = 'Y'
	SET @sql = @sql + N' AND roi.placeWhYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
	SET @sql = @sql + N' AND ro.roYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
	SET @sql = @sql + N' AND roi.itemId = @i__itemId '

IF @i__itemNo <> ''
	SET @sql = @sql + N' AND i.itemNo = @i__itemNo '
print @sql
INSERT INTO #원장4 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms ,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
						,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq ,salePrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)  ,@i__orderGroupId varchar(50), @i__carNo varchar(30) ,@i__custOrderNo varchar(100)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN, @i__itemId	,@i__itemNo ,@i__orderGroupId , @i__carNo ,@i__custOrderNo 


-- 수동처리: 판매출고, 반품입고
SET @sql = N'
SELECT 
	stor.consignCustCode custCode, 
	convert(char(10), act.created, 121) stdYmd ,	  
	--CASE act.actionType WHEN ''RL'' THEN ''주문'' WHEN ''WH'' THEN ''반품'' ELSE '''' END ledgType, 
	CASE act.actionType WHEN ''rlod'' THEN ''주문'' WHEN ''whri'' THEN ''*반품'' ELSE act.actionType END ledgType, 
	CAST(act.idx as varchar(100)) summary, 
	convert(char(10), act.created, 121) regYmd ,          --등록 연월일
    convert(char(8), act.created, 108) regHms,           --등록 시분초
	'''' seq ,
	--act.procQty cnt ,
	--CASE act.actionType WHEN ''RL'' THEN act.procQty WHEN ''WH'' THEN -1*act.procQty ELSE '''' END cnt,
	CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END cnt,
	--0 unitPrice, 

	--ROUND(i.centerPrice*0.4,0) unitPrice,
	--ROUND(i.centerPrice*0.4,0) * (CASE act.actionType WHEN ''RL'' THEN act.procQty WHEN ''WH'' THEN -1*act.procQty ELSE '''' END) sumPrice, 
	--(ROUND(i.centerPrice*0.4,0) * (CASE act.actionType WHEN ''RL'' THEN act.procQty WHEN ''WH'' THEN -1*act.procQty ELSE '''' END)) * 0.1 taxPrice ,  
	--(ROUND(i.centerPrice*0.4,0) * (CASE act.actionType WHEN ''RL'' THEN act.procQty WHEN ''WH'' THEN -1*act.procQty ELSE '''' END)) * 1.1 sumPriceTax, 

	ROUND(act.unitPriceConsignAdjust,0) unitPrice,
	ROUND(act.unitPriceConsignAdjust * (CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END),0) sumPrice, 
	ROUND((act.unitPriceConsignAdjust * (CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END)) * 0.1,0) taxPrice ,  
	ROUND((act.unitPriceConsignAdjust * (CASE act.actionType WHEN ''rlod'' THEN act.procQty WHEN ''whri'' THEN -1*act.procQty ELSE '''' END)) * 1.1,0) sumPriceTax, 

	i.itemId ,
	i.itemNo ,
	CASE WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName  ELSE i.itemNameEn END itemName,
	--act.procMemo1 memo,
	--CASE act.actionType WHEN ''RL'' THEN ''수동출고'' WHEN ''WH'' THEN ''수동입고'' ELSE '''' END memo,
	CASE act.actionType WHEN ''rlod'' THEN ''판매출고(B)'' WHEN ''whri'' THEN ''반품입고(B)'' ELSE '''' END  memo,
	'''' carNo,
	'''' carType, 
	'''' orderGroupId, 
	'''' clType,
	'''' regUserId,
	'''' custOrderNo,
	ISNULL(cd.codeName, '''') makerCode,
	CASE act.actionType WHEN ''rlod'' THEN ''판매출고'' WHEN ''whri'' THEN ''반품입고'' ELSE '''' END  ledgCateg,
	'''' rcvCustCode,
	--i.centerPrice centerPrice,
	act.centerPrice ,
	'''' orderNo,
	'''' orderSeq
	,CAST(act.idx as varchar(100))+''(판매출고)'' summary2
FROM dbo.e_stockActions act
JOIN dbo.e_rack rk ON act.comCode = rk.comCode AND act.rackCode = rk.rackCode
JOIN dbo.e_storage stor ON rk.comCOde = stor.comCode AND rk.storageCode = stor.storageCode
JOIN dbo.e_item i ON act.itemId = i.itemId
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = act.comCode AND cd.code = i.makerCode and  mCode = ''1000''
WHERE 1 = 1 AND stor.consignYN = ''Y'' AND act.actionType IN (''rlod'', ''whri'')
  AND convert(char(10), act.created, 121)  BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__logComCode = 'ㄱ000' -- 팬오토인 경우 
BEGIN
	SET @sql = @sql + N' AND stor.consignCustCode IN (SELECT consignCustCode FROM dbo.e_storage WHERE comCode=@i__logComCode AND consignYn=''Y'') '  -- 위탁창고로 등록된 거래처만
	IF @i__custCode <> ''  --거래처로 조회한 경우 
		SET @sql = @sql + N' AND stor.consignCustCode = @i__custCode '
END
ELSE  --위탁한 업체인 경우  
BEGIN
	SET @sql = @sql + N' AND stor.consignCustCode = @i__logComCode  '
END

--WHERE stor.consignYN = ''Y'' AND stor.consignCustCode = @i__logComCode AND act.actionType IN (''rlod'', ''whri'')
--  AND convert(char(10), act.created, 121)  BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
	SET @sql = @sql + N' AND i.itemId = @i__itemId '

IF @i__itemNo <> ''
	SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

print @sql
INSERT INTO #원장4 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms ,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
						,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,summary2 )

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)  ,@i__orderGroupId varchar(50), @i__carNo varchar(30) ,@i__custOrderNo varchar(100)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN, @i__itemId	,@i__itemNo ,@i__orderGroupId , @i__carNo ,@i__custOrderNo 



--판매출고(e_saleItem) :  장윤상매니저가 WH_LIST에 만든것 기반으로 작성. hsg.2024.02.19 
SET @sql = N'
SELECT 
	si.comCode, 
	si.regYmd,	
	CASE WHEN si.saleType = ''판매출고'' THEN ''입고(판매내역)''
		WHEN si.saleType = ''반품입고'' THEN ''입고(반출판매내역)''
		ELSE '''' END,
	si.saleNo,
	si.regYmd,
	si.regHms,

	si.saleSeq,
	CASE WHEN si.saleType = ''판매출고'' THEN si.qty
		WHEN si.saleType = ''반품입고'' THEN -si.qty
		ELSE si.qty END,	
	ROUND(si.saleUnitPrice,0),	
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*0.1,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*1.1,0) END,
 
	si.itemId,
	i.itemNo,
	ISNULL(i.itemName,i.itemNameEn),
	'''',	'''',	'''',	'''',	'''',
	--si.regUserId,
	''AUTO'',	'''',	'''',
	si.saleType,
	ISNULL(cust.custName,'''') rcvCustCode,
	si.centerPrice,
	'''',	'''',   --orderNo, orderSeq
	si.saleNo + ''(saleNo)''	
	
FROM dbo.e_saleItem   si
JOIN dbo.e_item i ON si.itemId = i.itemId '
IF @i__logComCode IN ('ㄱ000', 'ㄱ121') -- 팬오토 또는 그린파츠인 경우 
	SET @sql = @sql + N' LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = ''ㄱ121'' AND pli.placeNo = si.plPlaceNo '
ELSE
	SET @sql = @sql + N' LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = @i__logComCode AND pli.placeNo = si.plPlaceNo '

SET @sql = @sql + N' left outer JOIN dbo.e_cust cust ON cust.comCode = pli.comCode AND cust.custCode = pli.rcvCustCode

WHERE si.regYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND pli.orderGroupId is null
'

IF @i__logComCode IN ('ㄱ000', 'ㄱ121') -- 팬오토 또는 그린파츠인 경우 
BEGIN
	SET @sql = @sql + N' AND si.plComCode = ''ㄱ121''  ' 
	IF @i__custCode <> ''  --거래처로 조회한 경우 
		SET @sql = @sql + N' AND si.comCode = @i__custCode '
END
ELSE  -- 위탁한 업체인 경우  
BEGIN
	SET @sql = @sql + N' AND si.comCode = @i__logComCode  '
END

--IF @i__custCode <> ''
--	SET @sql = @sql + N' AND si.comCode = @i__custCode '


IF @i__itemId <> ''
	SET @sql = @sql + N' AND si.itemId = @i__itemId '

IF @i__itemNo <> ''
	SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

ELSE
BEGIN
	SET @sql = @sql
END

INSERT INTO #원장4 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms ,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
						,carNo, carType, orderGroupId, clType,regUserId,custOrderNo,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,summary2 )

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)  ,@i__orderGroupId varchar(50), @i__carNo varchar(30) ,@i__custOrderNo varchar(100)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN, @i__itemId	,@i__itemNo ,@i__orderGroupId , @i__carNo ,@i__custOrderNo 




SELECT distinct 
    a.custCode,
    cust.custName as custName,
    stdYmd,
    ledgType,
    summary,
    a.regYmd,
    a.regHms,
    seq,
    a.cnt,
    ROUND(a.unitPrice,0) unitPrice,
    ROUND(a.sumPrice,0) sumPrice,
    ROUND(a.taxPrice,0) taxPrice,
    ROUND(sumPriceTax,0) sumPriceTax,
    a.itemId,
    a.itemNo,
    a.itemName,
    a.memo,
    ISNULL(carNo,'') AS carNo ,
    ISNULL(a.carType,'') AS carType,
    a.orderGroupId,
    ISNULL(clType,'') as clType,
    a.regUserId,
   -- u.userName as userName
    CASE WHEN a.regUserId = 'AUTO' 
		THEN 'AUTO'
		ELSE u.userName 
		END userName 
	,ISNULL(a.makerCode,'') as makerCode 
	,ISNULL(a.custOrderNo,'') as custOrderNo      
	,a.ledgCateg
	,a.rcvCustCode
	,a.centerPrice
	,a.orderNo 
	,a.orderSeq 
	,a.salePrice
		--,CASE WHEN wd1.wdNo IS NOT NULL THEN '완료(발주)'
	 --   WHEN wd2.wdNo IS NOT NULL THEN '완료(입고)' 
		--WHEN z.wdReqNo IS NOT NULL THEN '요청(발주)'
	 --   WHEN y.wdReqNo IS NOT NULL THEN '요청(입고)'
		--ELSE ''	END as withdrawStatus --출금상태
	,summary2
	, d.codeName makerName
	,d2.codeName className
	,IIF(c.classCode = 'GN','', c.factoryNo) factoryNo
FROM #원장4 a
LEFT OUTER JOIN dbo.e_cust cust ON a.custCode = cust.custCode and cust.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_user u on u.userId = a.regUserId and u.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = @i__logComCode AND pli.orderNo = a.orderNo AND pli.orderSeq = a.orderSeq 
LEFT OUTER JOIN dbo.e_item c ON  a.itemId = c.itemId
LEFT OUTER JOIN dbo.e_code d ON d.comCode = @i__logComCode AND d.mCode='1000' AND d.code = c.makerCode
LEFT OUTER JOIN dbo.e_code d2 ON d2.comCode = @i__logComCode AND d2.mCode='1100' AND d2.code = c.classCode
--LEFT OUTER JOIN (SELECT DISTINCT wrd1.comCode, wrd1.wdReqNo, wrd1.jobNo FROM dbo.e_wdReqDtl wrd1 --발주출금요청
--					      JOIN dbo.e_wdReq wr1 ON wrd1.comCode = wr1.comCode AND wrd1.wdReqNo = wr1.wdReqNo AND wr1.wdReqType ='발주출금'
--				) z ON pli.comCode = z.comCode AND pli.placeNo = z.jobNo	
--LEFT OUTER JOIN (SELECT DISTINCT wrd2.comCode, wrd2.wdReqNo, wrd2.jobNo,wrd2.jobSeq FROM dbo.e_wdReqDtl wrd2 --입고출금요청
--					      JOIN dbo.e_wdReq wr2 ON wrd2.comCode = wr2.comCode AND wrd2.wdReqNo = wr2.wdReqNo AND wr2.wdReqType ='입고출금'
--				) y ON pli.comCode = y.comCode AND a.summary = y.jobNo and a.seq = y.jobSeq
--LEFT OUTER JOIN dbo.e_withdraw wd1 ON z.comCode = wd1.comCode AND z.wdReqNo = wd1.wdReqNo --발주출금
--LEFT OUTER JOIN dbo.e_withdraw wd2 ON y.comCode = wd2.comCode AND y.wdReqNo = wd2.wdReqNo --입고출금


WHERE a.ledgType LIKE CASE WHEN @i__ledgType = '' THEN '%' ELSE '%' + @i__ledgType + '%' END
ORDER BY stdYmd, custName, regYmd, regHms
             
DROP TABLE #원장4

RETURN
/*********************************************************************************************************/
OUT_PL_LIST:



CREATE TABLE #원장5 (
	idx int identity primary key , 
	custCode varchar(10) , 
	stdYmd varchar(10),--날짜
	ledgType varchar(50), --구분
	summary varchar(20),--적요
	regYmd varchar(10)
	,regHms varchar(8)
	,seq varchar(20) --순번
	,cnt varchar(20)
	,unitPrice money 
	, sumPrice money  --공급가액
	, taxPrice money --세액  
	, sumPriceTax money  --합계금액
	,itemId bigint 
	,itemNo varchar (50)
	,itemName varchar (200)  
	,memo varchar (2000) 
	,carNo varchar(100)
	, carType varchar(50) 
	,orderGroupId varchar( 30)
	, clType varchar(20)
	,regUserId varchar(50)
	,makerCode varchar(50)
	,custOrderNo varchar(100)
	,ledgCateg varchar(50)
	,rcvCustCode varchar(100) --납품처 
	,centerPrice money --센터가 
	,orderNo varchar(20)
	,orderSeq varchar(20) 
	,salePrice money
	,summary2 varchar(100)--적요
)

--출고
SET @sql = N'
SELECT 
	rl.custCode,
	rl.rlYmd,
	''출고'',
	rl.rlNo,
	rl.regYmd,
	rl.regHms,
	rli.rlSeq
	,rli.cnt
	,ROUND(rli.rlUnitPrice,0)
	,ROUND(rli.rlSumPrice,0)
	,ROUND(rli.rlSumPrice*0.1,0)
	,ROUND(rli.rlSumPrice*1.1,0)
	,rli.itemId
	,i.itemNo
	--,ISNULL(i.itemName,i.itemNameEn)
	,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,rli.memo1
	,og.carNo
	,og.carType
	,og.orderGroupId 
	,oi.clType 
	,rli.regUserId
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerCode
	--,'''' custOrderNo
	,''출고''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice
	,oi.orderNo
	,oi.orderSeq
	,oi.salePrice


	,rl.rlNo + ''(출고)''
FROM	dbo.e_rlItem rli 
JOIN dbo.e_rl rl ON rl.rlNo = rli.rlNo AND rl.comCode = rli.comCode
LEFT OUTER JOIN dbo.e_orderItem oi ON oi.comCode = rli.comCode AND oi.orderNo = rli.orderNo AND oi.orderSeq = rli.orderSeq
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rli.comCode
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
JOIN dbo.e_item i ON rli.itemId = i.itemId 
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = rli.comCode AND cd.code = i.makerCode and  mCode = ''1000''
WHERE 1=1 AND rli.comCode = ''ㄱ121'' AND rl.custCode = @i__logComCode AND rl.rlYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '


IF @i__itemId <> ''
SET @sql = @sql + N' AND rli.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '


INSERT INTO #원장5 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,salePrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)   ,@i__itemId bigint ,@i__itemNo varchar(50)  ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__itemId ,@i__itemNo 

--반입
SET @sql = N'
SELECT 
	ri.custCode,
	ri.riYmd,
	''출고(반입)'',
	ri.riNo,
	ri.regYmd,
	ri.regHms,
	rii.riSeq,
	-rii.cnt,
	ROUND(rii.riUnitPrice,0),
	ROUND(-rii.riUnitPrice * rii.cnt,0),
	ROUND(-rii.riUnitPrice * rii.cnt*0.1,0),
	ROUND(-rii.riUnitPrice* rii.cnt*1.1,0)
	,rii.itemId
	,i.itemNo
	--,ISNULL(i.itemName,i.itemNameEn)
	,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,rii.memo1
	,og.carNo
	,og.carType
	,og.orderGroupId 
	,oi.clType 
	,rii.regUserId
	--,ISNULL(og.makerCode,'''') makerCode
	,ISNULL(cd.codeName, '''') makerCode
	--,'''' custOrderNo
	,''반입''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice

	,oi.orderNo
	,oi.orderSeq
	,oi.salePrice

	,ri.riNo + ''(반입)''
FROM dbo.e_riItem rii
JOIN dbo.e_ri ri ON rii.riNo = ri.riNo AND rii.comCode = ri.comCode 
left outer join dbo.e_orderItem oi on oi.orderNo = rii.orderNo and oi.orderSeq = rii.orderSeq  and oi.comCode = rii.comCode
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rii.comCode
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode
JOIN dbo.e_item i ON rii.itemId = i.itemId

LEFT OUTER JOIN (SELECT comCode, orderNo, orderSeq, AVG(costPrice) costPrice FROM dbo.e_rlitem WHERE comCode = @i__logComCode GROUP BY comCode, orderNo, orderSeq
				) rli ON rii.comCode = rli.comCode AND rii.orderNo = rli.orderNo AND rii.orderSeq = rli.orderSeq
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = rii.comCode AND cd.code = i.makerCode and  mCode = ''1000''

WHERE rii.comCode = ''ㄱ121'' AND ri.custCode = @i__logComCode AND ri.riYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '


IF @i__itemId <> ''
SET @sql = @sql + N' AND rii.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '


INSERT INTO #원장5 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,salePrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)   ,@i__itemId bigint ,@i__itemNo varchar(50)  ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__itemId ,@i__itemNo


--운송비
SET @sql = N'
SELECT 
	rl.custCode,
	rl.rlYmd,
	''출고(운송비)'',
	rl.rlNo,
	rl.regYmd,
	rl.regHms,

	''운송비'' --seq
	,1 --cnt
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1 ,0) 	
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1 ,0) 	
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1*0.1,0) 	
	,ROUND(ISNULL(max(rl.deliveryFee),''''),0)
	,0
	,''운송비''
	,''운송비''
	,MAX(rl.memo1)memo1
	,MAX(og.carNo)
	,MAX(og.carType)
	,MAX(og.orderGroupId )
	,MAX(oi.clType )
	,MAX(rl.uptUserId)
	,ISNULL(MAX(og.makerCode),'''') makerCode
	--,'''' custOrderNo
	,''출고(운송비)''
	,ISNULL (cust.custName, '''') rcvCustCode
	,0
	
	,oi.orderNo
	,''''
	,0

	,rl.rlNo + ''(운송비)''
FROM	dbo.e_rl rl 
JOIN dbo.e_rlItem rli ON rl.comCode = rli.comCode AND  rl.rlNo = rli.rlNo
LEFT OUTER JOIN dbo.e_orderItem oi ON oi.comCode = rli.comCode AND oi.orderNo = rli.orderNo AND oi.orderSeq = rli.orderSeq
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rli.comCode
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode


WHERE rli.comCode = ''ㄱ121'' AND rl.custCode = @i__logComCode  AND rl.rlYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND rl.deliveryYN = ''Y'' '


SET @sql  = @sql + ' group by rl.rlNo , rl.comCode, rl.regYmd,rl.regHms,	rl.custCode,	rl.rlYmd , cust.custName , oi.centerPrice ,oi.orderNo ,oi.orderSeq ,oi.salePrice' 


INSERT INTO #원장5 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,salePrice,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)   ,@i__itemId bigint ,@i__itemNo varchar(50)  ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__itemId ,@i__itemNo


--판매출고
SET @sql = N'
SELECT 
	si.plComCode, 
	si.regYmd,	
	CASE WHEN si.saleType = ''판매출고'' THEN ''판매출고''
		WHEN si.saleType = ''반품입고'' THEN ''판매출고(반품입고)''
		ELSE '''' END,
	si.saleNo,
	si.regYmd,
	si.regHms,

	si.saleSeq,
	CASE WHEN si.saleType = ''판매출고'' THEN si.qty
		WHEN si.saleType = ''반품입고'' THEN -si.qty
		ELSE si.qty END,	
	ROUND(si.saleUnitPrice,0),	
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*0.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*0.1,0) END,
	CASE WHEN si.saleType = ''판매출고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1,0)
		WHEN si.saleType = ''반품입고'' THEN ROUND(si.saleUnitPrice*si.qty*1.1*-1,0)
		ELSE  ROUND(si.saleUnitPrice*si.qty*1.1,0) END,
 
	si.itemId,
	i.itemNo,
	ISNULL(i.itemName,i.itemNameEn),
	'''',

	'''',
	'''',
	'''',
	'''',
	--si.regUserId,
	''AUTO'',	'''',
	si.saleType,
	ISNULL(cust.custName,'''') rcvCustCode,
	si.centerPrice,
	'''',	'''',   --orderNo, orderSeq
	si.saleNo + ''(saleNo)''

	
	
FROM	dbo.e_saleItem   si
JOIN dbo.e_item i ON si.itemId = i.itemId
LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = @i__logComCode AND pli.placeNo = si.plPlaceNo
LEFT OUTER JOIN dbo.e_cust cust ON cust.comCode = pli.comCode AND cust.custCode = pli.rcvCustCode



WHERE si.comCode = ''ㄱ121'' AND  si.plComCode = @i__logComCode  AND si.regYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '


IF @i__itemId <> ''
SET @sql = @sql + N' AND si.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '



INSERT INTO #원장5 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,rcvCustCode,centerPrice,orderNo,orderSeq,summary2)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)   ,@i__itemId bigint ,@i__itemNo varchar(50) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__itemId ,@i__itemNo 

/*
panErp.dbo.up_transactionList_yoonsang	@i__workingType='OUT_PL_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-04-01',      @i__eYmd1='2024-04-30',  
@i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㅈ008',    @i__logUserId='panauto',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='',    @i__custOrderNo='',    
@i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',   @i__taxBillRegYN ='',   @i__mainYN ='',       @i__custCode=''


*/



SELECT distinct 
    a.custCode,
    cust.custName as custName,
    stdYmd,
    ledgType,
    summary,
    a.regYmd,
    a.regHms,
    seq,
    a.cnt,
    ROUND(a.unitPrice,0) unitPrice,
    ROUND(a.sumPrice,0) sumPrice,
    ROUND(a.taxPrice,0) taxPrice,
    ROUND(sumPriceTax,0) sumPriceTax,
    a.itemId,
    a.itemNo,
    a.itemName,
    a.memo,
    ISNULL(carNo,'') AS carNo ,
    ISNULL(a.carType,'') AS carType,
    a.orderGroupId,
    ISNULL(clType,'') as clType,
    a.regUserId,
   -- u.userName as userName
    CASE WHEN a.regUserId = 'AUTO' 
		THEN 'AUTO'
		ELSE u.userName 
		END userName 
	,ISNULL(a.makerCode,'') as makerCode 
	,ISNULL(a.custOrderNo,'') as custOrderNo      
	,a.ledgCateg
	,a.rcvCustCode
	,a.centerPrice
	,a.orderNo 
	,a.orderSeq 
	,a.salePrice
		--,CASE WHEN wd1.wdNo IS NOT NULL THEN '완료(발주)'
	 --   WHEN wd2.wdNo IS NOT NULL THEN '완료(입고)' 
		--WHEN z.wdReqNo IS NOT NULL THEN '요청(발주)'
	 --   WHEN y.wdReqNo IS NOT NULL THEN '요청(입고)'
		--ELSE ''	END as withdrawStatus --출금상태
	,summary2
	, d.codeName makerName
	,d2.codeName className
	,IIF(c.classCode = 'GN','', c.factoryNo) factoryNo
FROM #원장5 a
LEFT OUTER JOIN dbo.e_cust cust ON a.custCode = cust.custCode and cust.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_user u on u.userId = a.regUserId and u.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_placeItem pli ON pli.comCode = @i__logComCode AND pli.orderNo = a.orderNo AND pli.orderSeq = a.orderSeq
LEFT OUTER JOIN dbo.e_item c ON  a.itemId = c.itemId
LEFT OUTER JOIN dbo.e_code d ON d.comCode = @i__logComCode AND d.mCode='1000' AND d.code = c.makerCode
LEFT OUTER JOIN dbo.e_code d2 ON d2.comCode = @i__logComCode AND d2.mCode='1100' AND d2.code = c.classCode
--LEFT OUTER JOIN (SELECT DISTINCT wrd1.comCode, wrd1.wdReqNo, wrd1.jobNo FROM dbo.e_wdReqDtl wrd1 --발주출금요청
--					      JOIN dbo.e_wdReq wr1 ON wrd1.comCode = wr1.comCode AND wrd1.wdReqNo = wr1.wdReqNo AND wr1.wdReqType ='발주출금'
--				) z ON pli.comCode = z.comCode AND pli.placeNo = z.jobNo	
--LEFT OUTER JOIN (SELECT DISTINCT wrd2.comCode, wrd2.wdReqNo, wrd2.jobNo,wrd2.jobSeq FROM dbo.e_wdReqDtl wrd2 --입고출금요청
--					      JOIN dbo.e_wdReq wr2 ON wrd2.comCode = wr2.comCode AND wrd2.wdReqNo = wr2.wdReqNo AND wr2.wdReqType ='입고출금'
--				) y ON pli.comCode = y.comCode AND a.summary = y.jobNo and a.seq = y.jobSeq
--LEFT OUTER JOIN dbo.e_withdraw wd1 ON z.comCode = wd1.comCode AND z.wdReqNo = wd1.wdReqNo --발주출금
--LEFT OUTER JOIN dbo.e_withdraw wd2 ON y.comCode = wd2.comCode AND y.wdReqNo = wd2.wdReqNo --입고출금


WHERE a.ledgType LIKE CASE WHEN @i__ledgType = '' THEN '%' ELSE '%' + @i__ledgType + '%' END
ORDER BY stdYmd, custName, regYmd, regHms
             
DROP TABLE #원장5

RETURN
/*********************************************************************************************************/









/*********************************************************************************************************/
/*
LIST_QRY: -- 이거 사용하려면 수정할게 많음. 2023.11.07

CREATE TABLE #원장 (
	idx int identity primary key , 
	custCode varchar(10) , 
	stdYmd varchar(10),--날짜
	ledgType varchar(50), --구분
	summary varchar(20),--적요
	regYmd varchar(10)
	,regHms varchar(8)
	,seq varchar(20) --순번
	,cnt varchar(20)
	,unitPrice money 
	, sumPrice money  --공급가액
	, taxPrice money --세액  
	, sumPriceTax money  --합계금액
	,itemId bigint 
	,itemNo varchar (50)
	,itemName varchar (200)  
	,memo varchar (2000) 
	,carNo varchar(100)
	, carType varchar(50) 
	,orderGroupId varchar( 30)
	, clType varchar(20)
	,regUserId varchar(50)
	,makerCode varchar(50)
	,custOrderNo varchar(100)
	,ledgCateg varchar(50)
	,rcvCustCode varchar(100) --납품처 
	,centerPrice money --센터가 
)

SET @sql = N'
SELECT 
	w.custCode,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(wi.placeRlYmd,w.whYmd) ELSE w.whYmd END AS whYmd,
	''입고'',
	w.whNo,
	w.regYmd,
	w.regHms,
	wi.whSeq,
	wi.cnt,
	ROUND(wi.whUnitPrice,0),
	ROUND(wi.whSumPrice,0),
	ROUND(wi.whSumPrice*0.1,0)  ,
	ROUND(wi.whSumPrice *1.1,0),
	wi.itemId
	,i.itemNo
	--,ISNULL(i.itemName,i.itemNameEn)
		,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,wi.memo1
	,ISNULL(og.carNo ,'''')
	,ISNULL(og.carType,'''') 
	, og.orderGroupId
	, ''''
	,wi.regUserId
	,ISNULL(og.makerCode,'''') makerCode
	,ISNULL (p.custOrderNo,'''') custOrderNo
	,''입고''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice centerPrice 
FROM dbo.e_whItem wi 
JOIN dbo.e_wh w on w.comCode = wi.comCode AND w.whNo = wi.whNo
--JOIN dbo.e_item i ON w.comCode = i.comCode AND wi.itemId = i.itemId
JOIN dbo.e_item i ON wi.itemId = i.itemId
--JOIN dbo.e_orderItem oi on wi.comCode = oi.comCode and wi.orderNo = oi.orderNo and wi.orderSeq = oi.orderSeq
LEFT OUTER JOIN dbo.e_orderItem oi on wi.comCode = oi.comCode and wi.orderNo = oi.orderNo and wi.orderSeq = oi.orderSeq
JOIN dbo.e_place p on p.comCode = wi.comCode and p.placeNo = wi.placeNo 
--JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = wi.comCode
LEFT OUTER JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = wi.comCode 
LEFT OUTER JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
WHERE wi.comCode = @i__logComCode '

IF @i__custCode <> ''
SET @sql = @sql + N' AND w.custCode = @i__custCode '

IF @i__placeYmdYN = 'Y'
SET @sql = @sql + N' AND wi.placeRlYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
SET @sql = @sql + N' AND w.whYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
SET @sql = @sql + N' AND wi.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '


INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,custOrderNo,ledgCateg,rcvCustCode,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50), @i__placeYmdYN varchar(5)
															,@i__itemId bigint ,@i__itemNo varchar(50)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__placeYmdYN ,@i__itemId	,@i__itemNo

--운송비 
SET @sql = N'
SELECT 
	p.custCode, 
	--placeDmdYmd,
	ISNULL(p.placeYmd, p.regYmd ) placeDmdYmd,
	''입고(운송비)'',
	placeNo
	,regYmd
	, regHms
	,''운송비''
	,1
	,ROUND(directCost/1.1,0)
	,ROUND(directCost /1.1,0)
	,ROUND(directCost /1.1 * 0.1,0)
	,ROUND(directCost,0)
	,0
	,''운송비''
	,''운송비''
	,''''
	,''''
	,''''
	,''''
	,''''
	,regUserId
	,ISNULL (p.custOrderNo,'''') custOrderNo
	,''운송비''
	,ISNULL(cust.custName,'''')　rcvCustCode
	,0
FROM dbo.e_place p
JOIN dbo.e_cust cust ON cust.comCode = p.comCode AND cust.custCode = p.custCode 
WHERE p.comCode = @i__logComCode AND directYN = ''Y''  AND ISNULL(p.placeYmd, p.regYmd)  BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__custCode <> ''
SET @sql = @sql + N' AND p.custCode = @i__custCode '

INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,custOrderNo, ledgCateg,rcvCustCode,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50)
													', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode

--반출내역 
SET @sql = N'
SELECT 
	oi.placeCustCode as custCode ,
	--ro.roYmd,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(roi.placeWhYmd,ro.roYmd) ELSE ro.roYmd END AS roYmd,
	''입고(반출)'',
	ro.roNo,
	ro.regYmd,
	ro.regHms,
	roi.roSeq,
	-roi.cnt,
	--0,
	ROUND(roi.roUnitPrice,0),
	ROUND(-roi.roUnitPrice * roi.cnt,0),
	ROUND(-roi.roUnitPrice * roi.cnt*0.1,0),
	ROUND(-roi.roUnitPrice * roi.cnt * 1.1,0),
	roi.itemId,
	i.itemNo
	--ISNULL(i.itemName,i.itemNameEn)
		,CASE WHEN ISNULL(oi.itemName, '''') <> '''' THEN oi.itemName 
		WHEN ISNULL(i.itemName, '''') <> '''' THEN i.itemName 
		ELSE i.itemNameEn END itemName
	,roi.memo1
	,og.carNo 
	,og.carType 
	, og.orderGroupId
	, ''''
	,roi.regUserId
	,ISNULL(og.makerCode,'''') makerCode
	,''반출''
	,ISNULL (cust.custName, '''') rcvCustCode
	,oi.centerPrice centerPrice
FROM e_roItem roi
JOIN dbo.e_ro ro ON roi.roNo = ro.roNo AND roi.comCode = ro.comCode 
 join dbo.e_orderItem oi on oi.orderNo = roi.orderNo and oi.orderSeq = roi.orderSeq  and oi.comCode = roi.comCode
--JOIN dbo.e_item i ON roi.comCode = i.comCode AND roi.itemId = i.itemId
JOIN dbo.e_item i ON  roi.itemId = i.itemId
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = roi.comCode 
JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
WHERE roi.comCode = @i__logComCode  '

 
IF @i__custCode <> ''
SET @sql = @sql + N' AND oi.placeCustCode = @i__custCode '

IF @i__placeYmdYN = 'Y'
SET @sql = @sql + N' AND roi.placeWhYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
SET @sql = @sql + N' AND ro.roYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

IF @i__itemId <> ''
SET @sql = @sql + N' AND roi.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '


print @sql
INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,rcvCustCode,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)
														,@i__itemId bigint ,@i__itemNo varchar(50)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN ,@i__itemId	,@i__itemNo


--반출페널티
SET @sql = N'
SELECT 
	oi.placeCustCode as custCode ,
	--ro.roYmd,
	CASE WHEN @i__placeYmdYN = ''Y'' THEN ISNULL(roi.placeWhYmd,ro.roYmd) ELSE ro.roYmd END AS roYmd,
	''입고(반출페널티)'',
	ro.roNo,
	ro.regYmd,
	ro.regHms,
	roi.roSeq,
	1,
	--0,
	ROUND(penaltyPrice/1.1,0),
	ROUND(penaltyPrice/1.1,0),
	ROUND(penaltyPrice/1.1*0.1,0),
	ROUND(penaltyPrice,0),
	0,
	''반품페널티'',
	''반품페널티''
	,''''
	,og.carNo 
	,og.carType 
	, og.orderGroupId
	, ''''
	,roi.uptUserId
	,ISNULL(og.makerCode,'''') makerCode
	,''반품페널티''                       
	,ISNULL (cust.custName, '''') rcvCustCode
	,0
FROM e_roItem roi
JOIN dbo.e_ro ro ON roi.roNo = ro.roNo AND roi.comCode = ro.comCode 
 join dbo.e_orderItem oi on oi.orderNo = roi.orderNo and oi.orderSeq = roi.orderSeq  and oi.comCode = roi.comCode
--JOIN dbo.e_item i ON roi.comCode = i.comCode AND roi.itemId = i.itemId
JOIN dbo.e_item i ON  roi.itemId = i.itemId
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = roi.comCode 
JOIN dbo.e_cust cust on cust.comCode = oi.comCode AND cust.custCode = og.custCode 
WHERE roi.comCode = @i__logComCode AND penaltyPrice >0'

IF @i__custCode <> ''
SET @sql = @sql + N' AND oi.placeCustCode = @i__custCode '

IF @i__placeYmdYN = 'Y'
SET @sql = @sql + N' AND roi.placeWhYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '
ELSE 
SET @sql = @sql + N' AND ro.roYmd BETWEEN  @i__sYmd1 AND @i__eYmd1 '

INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,rcvCustCode,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__placeYmdYN varchar(5)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode ,@i__placeYmdYN


--반입 
SET @sql = N'
SELECT 
	ri.custCode,
	ri.riYmd,
	''출고(반입)'',
	ri.riNo,
	ri.regYmd,
	ri.regHms,
	rii.riSeq,
	-rii.cnt,
	ROUND(rii.riUnitPrice,0),
	ROUND(-rii.riUnitPrice * rii.cnt,0),
	ROUND(-rii.riUnitPrice * rii.cnt*0.1,0),
	ROUND(-rii.riUnitPrice* rii.cnt*1.1,0)
	,rii.itemId
	,i.itemNo
	,ISNULL(i.itemName,i.itemNameEn)
	,rii.memo1
	,og.carNo
	,og.carType
	,og.orderGroupId 
	,oi.clType 
	,rii.regUserId
	,ISNULL(og.makerCode,'''') makerCode
	,''반입''
	,oi.centerPrice
FROM dbo.e_riItem rii
JOIN dbo.e_ri ri ON rii.riNo = ri.riNo AND rii.comCode = ri.comCode 
left outer join dbo.e_orderItem oi on oi.orderNo = rii.orderNo and oi.orderSeq = rii.orderSeq  and oi.comCode = rii.comCode
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rii.comCode
--JOIN dbo.e_item i ON rii.comCode = i.comCode AND rii.itemId = i.itemId
JOIN dbo.e_item i ON rii.itemId = i.itemId
WHERE rii.comCode = @i__logComCode AND ri.riYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__custCode <> ''
SET @sql = @sql + N' AND ri.custCode = @i__custCode '
IF @i__clType <> ''
SET @sql = @sql + N' AND oi.clType = @i__clType '

IF @i__itemId <> ''
SET @sql = @sql + N' AND rii.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30)
															,@i__itemId bigint ,@i__itemNo varchar(50)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType,@i__itemId	,@i__itemNo

						
--출고 
SET @sql = N'
SELECT 
	rl.custCode,
	rl.rlYmd,
	''출고'',
	rl.rlNo,
	rl.regYmd,
	rl.regHms,
	rli.rlSeq
	,rli.cnt
	,ROUND(rli.rlUnitPrice,0)
	,ROUND(rli.rlSumPrice,0)
	,ROUND(rli.rlSumPrice*0.1,0)
	,ROUND(rli.rlSumPrice*1.1,0)
	,rli.itemId
	,i.itemNo
	,ISNULL(i.itemName,i.itemNameEn)
	,rli.memo1
	,og.carNo
	,og.carType
	,og.orderGroupId 
	,oi.clType 
	,rli.regUserId
	,ISNULL(og.makerCode,'''') makerCode
	,''출고''
	,oi.centerPrice
FROM	dbo.e_rlItem rli 
JOIN dbo.e_rl rl ON rl.rlNo = rli.rlNo AND rl.comCode = rli.comCode
LEFT OUTER JOIN dbo.e_orderItem oi ON oi.comCode = rli.comCode AND oi.orderNo = rli.orderNo AND oi.orderSeq = rli.orderSeq
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rli.comCode
--JOIN dbo.e_item i ON rli.comCode = i.comCode AND rli.itemId = i.itemId 
JOIN dbo.e_item i ON rli.itemId = i.itemId 
WHERE rli.comCode = @i__logComCode AND rl.rlYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF @i__custCode <> ''
SET @sql = @sql + N' AND rl.custCode = @i__custCode'
IF @i__clType <> ''
SET @sql = @sql + N' AND oi.clType = @i__clType '

IF @i__itemId <> ''
SET @sql = @sql + N' AND rli.itemId = @i__itemId '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND i.itemNo = @i__itemNo '

INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30)
														,@i__itemId bigint ,@i__itemNo varchar(50) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType,@i__itemId	,@i__itemNo


--운송비
SET @sql = N'
SELECT 
	rl.custCode,
	rl.rlYmd,
	''출고'',
	rl.rlNo,
	rl.regYmd,
	rl.regHms,
	0 --seq
	,1 --cnt
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1 ,0) 	
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1 ,0) 	
	,ROUND (ISNULL(max(rl.deliveryFee),'''')/1.1*0.1,0) 	
	,ISNULL(max(rl.deliveryFee),'''')
	,''운송비''
	,''운송비''
	,''운송비''
	,MAX(rl.memo1)memo1
	,MAX(og.carNo)
	,MAX(og.carType)
	,MAX(og.orderGroupId )
	,MAX(oi.clType )
	,MAX(rl.uptUserId)
	,ISNULL(MAX(og.makerCode),'''') makerCode
	,''''
	,''출고(운송비)''
	,''''
	,''''

FROM	dbo.e_rl rl 
JOIN dbo.e_rlItem rli ON rl.comCode = rli.comCode AND  rl.rlNo = rli.rlNo
LEFT OUTER JOIN dbo.e_orderItem oi ON oi.comCode = rli.comCode AND oi.orderNo = rli.orderNo AND oi.orderSeq = rli.orderSeq
JOIN dbo.e_orderGroup og on og.orderGroupId = oi.orderGroupId and og.comCode = rli.comCode
WHERE rli.comCode = @i__logComCode AND rl.rlYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND rl.deliveryYN = ''Y'' '

IF @i__custCode <> ''
SET @sql = @sql + N' AND rl.custCode = @i__custCode'

IF @i__clType <> ''
SET @sql = @sql + N' AND oi.clType = @i__clType '

IF @i__orderGroupId <> ''
SET @sql = @sql + N' AND og.orderGroupId   = @i__orderGroupId '

IF @i__carNo  <> ''
SET @sql = @sql + N' AND og.carNo = @i__carNo '

SET @sql  = @sql + ' group by rl.rlNo , rl.comCode, rl.regYmd,rl.regHms,	rl.custCode,	rl.rlYmd' 

INSERT INTO #원장 (custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,custOrderNo,ledgCateg,rcvCustCode,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30)
														,@i__itemId bigint ,@i__itemNo varchar(50) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType,@i__itemId	,@i__itemNo


--일반 -> 보험전환 
SET @sql = N'

SELECT 
	rli.custCode, 
	a.clChnYmd,
	''출고'',
	rli.rlNo,
	a.regYmd,
	a.regHms,
	rli.orderSeq,
	-rli.rlCnt
	,ROUND(-a.salePrice,0)
	,ROUND(-a.sumPrice,0)
	,ROUND(-a.sumPrice * 0.1,0)
	,ROUND(-a.sumPrice*1.1,0)
	,a.itemId
	,i.itemNo
	,i.itemName
	,''''
	,og.carNo
	,og.carType
	,a.orderGroupId
	,a.clType
	,a.regUserId
	,og.makerCode
	,''출고(청구변경(일반)''
	,a.centerPrice
FROM	dbo.e_orderItem a 
JOIN (SELECT x.comCode, MAX(x.rlno) rlNo, MAX(x.rlSeq) rlSeq, x.orderNo, x.orderSeq, SUM(x.CNT) rlCnt , MAX(ISNULL(xx.custCode,'''')) AS custCode, MAX(xx.rlYmd) AS rlYmd
				  	FROM dbo.e_rlItem x
					JOIN dbo.e_rl xx ON x.comCode = xx.comCode AND x.rlNo = xx.rlNo
					WHERE x.comCode = @i__logComCode 
					GROUP BY x.comCode, x.orderNo, x.orderSeq
				) rli ON a.comCode = rli.comCode AND a.orderNo = rli.orderNo AND a.orderSeq = rli.orderSeq --출고품목
JOIN (SELECT x.comCode, x.orderNo, x.orderSeq, SUM(x.cnt) clCnt 
			FROM dbo.e_clReqItem x
			JOIN dbo.e_clReq y ON x.comCode = y.comCode AND x.clReqNo = y.clReqNo
			WHERE x.comCode = @i__logComCode  AND y.clType = ''일반'' AND x.cnt > 0 
			GROUP BY x.comCode, x.orderNo, x.orderSeq
		 ) cri ON a.comCode = cri.comCode AND a.orderNO = cri.orderNo AND a.orderSeq = cri.orderSeq  --일반건으로 플러스 청구 요청되었으면서 
LEFT OUTER JOIN (SELECT x1.comCode, x1.orderNo, x1.orderSeq, SUM(x1.cnt) clCnt 
					FROM dbo.e_clReqItem x1
					JOIN dbo.e_clReq y1 ON x1.comCode = y1.comCode AND x1.clReqNo = y1.clReqNo
					WHERE x1.comCode =  @i__logComCode  AND y1.clType = ''일반'' AND x1.Cnt < 0
					GROUP BY x1.comCode, x1.orderNo, x1.orderSeq
		 ) cri1 ON a.comCode = cri1.comCode AND a.orderNO = cri1.orderNo AND a.orderSeq = cri1.orderSeq
--JOIN dbo.e_item i ON rli.comCode = i.comCode AND a.itemId = i.itemId
JOIN dbo.e_item i ON a.itemId = i.itemId
JOIN dbo.e_orderGroup og ON a.orderGroupId = og.orderGroupId AND a.comCode = og.comCode
where  a.clType = ''보험'' AND a.minusClYN=''Y'' AND a.clChnYmd BETWEEN @i__sYmd1 AND @i__eYmd1 AND a.comCode = @i__logComCode AND (cri.clCnt > ISNULL(cri1.clCnt,0) * -1 ) '

IF @i__custCode <> '' 
SET @sql = @sql + N' AND rli.custCode = @i__custCode '
IF @i__clType <> ''
SET @sql = @sql + N' AND a.clType = @i__clType '

INSERT INTO #원장 (	custCode, stdYmd ,	  ledgType, summary, regYmd ,regHms 
									,seq ,cnt ,unitPrice, sumPrice, taxPrice ,  sumPriceTax, itemId ,itemNo ,itemName ,memo
									,carNo, carType, orderGroupId, clType,regUserId,makerCode,ledgCateg,centerPrice)

EXEC SP_EXECUTESQL  @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10)    ,@i__custCode varchar(50) ,@i__clType varchar(30) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__custCode, @i__clType


SELECT 
    a.custCode,
    cust.custName as custName,
    stdYmd,
    ledgType,
    summary,
    regYmd,
    regHms,
    seq,
    cnt,
    ROUND(unitPrice,0) unitPrice,
    ROUND(sumPrice,0) sumPrice,
    ROUND(taxPrice,0) taxPrice,
    ROUND(sumPriceTax,0) sumPriceTax,
    itemId,
    itemNo,
    itemName,
    a.memo,
    ISNULL(carNo,'') AS carNo ,
    ISNULL(carType,'') AS carType,
    orderGroupId,
    ISNULL(clType,'') as clType,
    a.regUserId,
  --  u.userName as userName
  CASE WHEN a.regUserId = 'AUTO' 
		THEN 'AUTO'
		ELSE u.userName 
		END userName 
	,ISNULL(makerCode,'') as makerCode 
	,ISNULL(custOrderNo,'') as custOrderNo      
	,a.ledgCateg
	,centerPrice
FROM #원장 a
left outer JOIN dbo.e_cust cust ON a.custCode = cust.custCode and cust.comCode = @i__logComCode
LEFT OUTER JOIN dbo.e_user u on u.userId = a.regUserId and u.comCode = @i__logComCode
WHERE a.ledgType LIKE CASE WHEN @i__ledgType = '' THEN '%' ELSE '%' + @i__ledgType + '%' END
ORDER BY stdYmd, custName, regYmd, regHms
             
DROP TABLE #원장

RETURN
*/
/********************************************************************************************************************************************************/

/*

panErp.dbo.up_transactionList	@i__workingType='OUT_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2023-10-02',      @i__eYmd1='2023-10-23',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㅇ413', 
@i__logUserId='아이피파츠',    @i__clType='',    @i__ledgType='',    @i__placeYmdYN='',    @i__custOrderNo='',       @i__itemNo ='',    @i__orderGroupId ='',    @i__carNo ='',   @i__srCode ='',       @i__custCode=''

*/
