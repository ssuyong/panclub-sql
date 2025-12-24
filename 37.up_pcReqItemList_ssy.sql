USE [panErp]
GO
/****** Object:  StoredProcedure [dbo].[up_pcReqItemList]    Script Date: 2025-12-24 오전 11:35:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[up_pcReqItemList_ssy]
/***************************************************************
설명 : 주문요청 품목 목록
       
작성 :
		2023.08.21 bk 
		2023.09.04 bk - dlvType 추가 
 	    2023.11.21 hsg - @i__workingType = 'LIST_OUT' 추가. 그린파츠 전용으로 쿼리. 
		2023.11.24 hsg - e_orderItem 주석처리
		2024.01.08 hsg - LIST_OUT 시 자회사(팬오토)에서 그린파츠로 발주하여 자동으로 등록된 주문접수 나오게 e_placeItem, e_item i2 를  left outer join 추가
		2024.01.24 supi - 주문요청 상세내역에서 랙에 가능수량 0인 랙은 제외되도록 수정
		2024.01.25 supi - 주문요청 상세내역 디테일 처리상태 노출 및 랙에 재고가 0개인것 비노출하고 상태가 초기상태가 아니거나 노출할 랙이 없을경우 창고 및 랙정보 빈값해서 1행만 노출되도록수정
		2024.01.27 supi - out 부분에 procStep 반환 추가및 주문 등록에서 @i__reqSeqArr매개변수를 url변수로 받아서 해당 부품만 노출되도록 추가
		2024.02.05 supi - 요청내역 및 접수내역에 센터가와 판매가 노출로 통일
		2024.02.07 supi - 주문요청수락시 주문요청의 디테일의 상태가 변경되어 그걸이용해서 주문등록에서 반환하는 데이터의 포멧을 가변했었는데 이부분이
						  사양이 변경되서 이제 주문등록페이지에서만 전달되는 매개변수인 @i__reqSeqArr에 값의 유무를 통해 가변하도록 변경
		2024.02.20 supi - 2중할인이슈로 할인가를 일단 센터가로 반환되도록 수정
		2024.03.04 supi - 반환에 제조사코드와 제조사명을 반환추가하여 주문접수에서 등록으로 넘어갈때 등록에서 제조사명이 뜨도록 수정
		2024.03.06 supi - 2중할인을 order-up.js에서 센터가받는걸로 하고 기존대로 할인가 반환으로 수정 (order-up.js업데이트 되면 프로시저반영
		2024.03.14 supi - 거부사유 rejectMemo 반환 추가
		2024.03.15 supi - 비사용중인 창고 제외 조건추가
		2024.05.29 supi - 처리자 반환추가
		2024.06.27 supi - pda 피킹 처리에 랙 구분을 위해 logisRackId 반환, storConsignCustCode(랙의 창고 위탁업체) 추가
		2024.07.22 hsg - 코리아오토파츠의 특정품목의 경우 outSalePrice 가 부품에 등록된 판매가로 노출되어야 해서 CASE문으로 수정
		2024.07.25 supi - 구분, 공장품번 반환 추가
		2024.09.19 hsg - @n__salePriceType 가져오는 부분 comCode = 'ㄱ000' 으로 박혀있던 코드를 @ErpOperateComCode 값을 가져와서 설정. 기본값도 '매입가'->'센터가', 코드 박혀있는것 제거하기 위해 함수 만들어 처리
		2024.09.19 supi - 전체목록 가독성을 위해 주문등록시 정보 받는부분을 분기하고 전체목록시 join을 한곳에서 하는방식으로 변경 및 code join시 comcode item속성에 영향받도록 수정
		2025.05.12 yoonsang - 'ㅌ089' 관련 outsaleprice 노출부분 브랜드별할인율이아닌 특정할인율을 가져오도록 변경 (김용원사장 재고문제처리과정)
							i2의 saleprice를 가져오지만 특정할인율적용된가격가져오도록 변경예정
		2025.05.16 yoonsang - ㅌ089 고정으로 넣었던것 ㅇ499 로 바꿈 및 item의 saleprice로 가져오던 outSalePrice를 할인율적용테이블가격으로 수정
		2025.05.30 yoonsang - has499 판단하는 과정에서 수량으로접근해야하는데 창고로만 접근해서 수량으로 수정함
ex)

select * from _SPLOG order by created desc
select * from _SPLOG where sp like '%up_pcReqItemList%' and params like '%20250808015%'
order by created desc

exec panErp.dbo.up_pcReqItemList @i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20240919058',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='supi20'
exec panErp.dbo.up_pcReqItemList_lw @i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20240919058',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='supi20'


exec panErp.dbo.up_pcReqItemList @i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20240919028',   @i__reqSeq ='',   @i__reqSeqArr ='1!2!3!4!5!6!7',    @i__logComCode='ㄱ121',    @i__logUserId='pjy1196'

exec panErp.dbo.up_pcReqItemList_lw @i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20240919028',   @i__reqSeq ='',   @i__reqSeqArr ='1!2!3!4!5!6!7',    @i__logComCode='ㄱ121',    @i__logUserId='pjy1196'


panErp.dbo.up_pcReqItemList	@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20240913019',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㅈ183',    @i__logUserId='제일파츠'
go
panErp.dbo.up_pcReqItemList_hsgTEst	@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20240913019',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㅈ183',    @i__logUserId='제일파츠'

panErp.dbo.up_pcReqItemList	@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250507019',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㅌ088',    @i__logUserId='테스트'

panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250507019',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'

panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250507019',   @i__reqSeq ='',   @i__reqSeqArr ='1',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'

panErp.dbo.up_pcReqItemList	@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',   
@i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250516005',   @i__reqSeq ='',   @i__reqSeqArr ='', 
@i__logComCode='ㅌ088',    @i__logUserId='테스트'

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',
@i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250526026',   @i__reqSeq ='',   @i__reqSeqArr ='1',    @i__logComCode='ㄱ121',  
@i__logUserId='baedg'

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',   
@i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250526009',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㅇ452',    @i__logUserId='유니피스'

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST_OUT',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',   
@i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250628003',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㅌ088',    @i__logUserId='테스트'

panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',
@i__eYmd2='',    @i__pcReqNo='20250629002',   @i__reqSeq ='',   @i__reqSeqArr ='1!1!2',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'

panErp.dbo.up_pcReqItemList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',   
@i__sYmd2='',    @i__eYmd2='',    @i__pcReqNo='20250629003',   @i__reqSeq ='',   @i__reqSeqArr ='1!1!2',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='', 
@i__eYmd2='',    @i__pcReqNo='20250710024',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='', 
@i__pcReqNo='20250808014',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'

panErp.dbo.up_pcReqItemList_test	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='',      @i__eYmd1='',      @i__sYmd2='',    @i__eYmd2='',  
@i__pcReqNo='20250808015',   @i__reqSeq ='',   @i__reqSeqArr ='',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan'


**************************************************************/
	@i__workingType varchar(20) = '',
	@i__page int = 1,       --페이지 : 몇번째 다음 부터
	@i__qty int = 10,       --레코드 수 : 몇개 출력
	@i__orderBy varchar(20) = '',
	@i__ymdIgnoreYN varchar(1) = 'N',
	
	@i__sYmd1 varchar(10) = '',
	@i__eYmd1 varchar(10) = '',
	@i__sYmd2 varchar(10) = '',
	@i__eYmd2 varchar(10) = ''

	,@i__logComCode varchar(20) = ''    --로그인한 회사코드
	,@i__logUserId varchar(20) = ''    --로그인한 사용자

	,@i__pcReqNo varchar(50) = ''   -- 요청번호
	,@i__reqSeq varchar(50) = ''   -- 요청번호
	,@i__reqSeqArr varchar(max) ='' --주문요청접수에서 수락누르면 주문등록으로 보내질 선택된 주문 요청아이템 순번
	
AS

SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--로그--------------------------
INSERT INTO panErp.dbo._SPLOG( sp,params)
	VALUES('panErp.dbo.up_pcReqItemList_ssy', 
	'@i__workingType='''+ISNULL(@i__workingType,'')+''',
	 @i__page='+cast(ISNULL(@i__page,0) as varchar(100))+',
	 @i__qty='+cast(ISNULL(@i__qty,0) as varchar(100))+',	 
	 @i__orderBy='''+ISNULL(@i__orderBy,'')+''',
	 @i__sYmd1='''+ISNULL(@i__sYmd1,'')+''',	 
	 @i__eYmd1='''+ISNULL(@i__eYmd1,'')+''',	 
	 @i__sYmd2='''+ISNULL(@i__sYmd2,'')+''',
	 @i__eYmd2='''+ISNULL(@i__eYmd2,'')+''',
	 @i__pcReqNo='''+cast(ISNULL(@i__pcReqNo,'') as varchar(100))+''',
	@i__reqSeq ='''+cast(ISNULL(@i__reqSeq,'') as varchar(100))+''',
	@i__reqSeqArr ='''+cast(ISNULL(@i__reqSeqArr,'') as varchar(100))+''',
	 @i__logComCode='''+cast(ISNULL(@i__logComCode,'') as varchar(100))+''',
	 @i__logUserId='''+ISNULL(@i__logUserId,'')+''''
   )
---------------------------------

--2024.09.19
DECLARE @ErpOperateComCode varchar(50) =  ''
SELECT @ErpOperateComCode= comCode from dbo.UF_ErpOperate('')

DECLARE @n__salePriceType varchar(10) = (SELECT ISNULL(salePriceType,'센터가') FROM dbo.e_cust WHERE comCode = @ErpOperateComCode  AND custCode = @i__logComCode)   -- ㄱ000 ->@ErpOperateComCode, 매입가->센터가. 2024.09.19 

IF ISNULL(@i__page, 0) = 0 	SET @i__page =1
IF ISNULL(@i__qty, 0) = 0 	SET @i__qty =100
SET @i__ymdIgnoreYN = ISNULL(@i__ymdIgnoreYN, '')

SET @i__orderBy = ISNULL(@i__orderBy, '')

DECLARE @subPage INT
SET @subPage = (@i__page - 1) * @i__qty

DECLARE @sql nvarchar(max)
SET @sql = N''

IF @i__workingType = 'LIST' AND  @i__reqSeqArr <> '' 
	GOTO PC_ITEM_LIST 

IF @i__workingType = 'LIST' 
	GOTO ALL_QRY   --전체목록

IF @i__workingType = 'LIST_OUT' 
	GOTO LIST_OUT   --그린파츠에 요청하는 업체에서 보는 목록
	

RETURN
/****************************************************************/
PC_ITEM_LIST:

--주문등록으로 넘겨질때 받는 주문등록에서 받는 정보값. LIST 정리차원에서 분기시킴
SELECT
	s.comCode ,
	s.pcReqNo ,
	s.reqSeq
	
	,s.gvComCode 
	,s.gvPlaceNo
	,IIF(s.gvPlaceSeq ='' , 0,s.gvPlaceSeq) gvPlaceSeq
	,s.inMemo1
	,ISNULL(i.itemId,i2.itemId) itemId
	,ISNULL(i.itemNo,i2.itemNo) itemNo
	,CASE WHEN ISNULL (i.itemName, '') <> '' THEN i.itemName 
		  WHEN ISNULL (i.itemNameEn, '') <> '' THEN  i.itemNameEn
		  WHEN ISNULL (i2.itemName, '') <> '' THEN i2.itemName 
		  WHEN ISNULL (i2.itemNameEn, '') <> '' THEN  i2.itemNameEn
		  ELSE '' END	 itemName	  

	,s.regUserId
	,s.created
	,s.uptUserId
	,s.modified 

	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
	      WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
		  ELSE 0  END cnt
	
	
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL (pli.UnitPrice,0) 
	      WHEN pli.placeNo IS NULL THEN ISNULL(i2.salePrice,0) * ISNULL(s.gvQty,0)
		  ELSE 0  END salePrice
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL (pli.sumPrice,0) 
	      WHEN pli.placeNo IS NULL THEN ISNULL(i2.salePrice,0) *ISNULL(s.gvQty,0)
		  ELSE 0  END sumPrice 
	,ISNULL(i.centerPrice,i2.centerPrice) centerPrice

	--,CASE WHEN EXISTS(SELECT 1 FROM dbo.e_storage s_s
	--                    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode  
	--					JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
	--					WHERE s_s.comCode = @i__logComCode AND s_s.consignCustCode = 'ㅋ004' AND s_s.storageCode = '579'
	--					  AND s_sr.itemid = i.itemId
	--				) THEN i.salePrice
	--      WHEN @n__salePriceType = '매입가' THEN 
	--			FORMAT(ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
	--			(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)),'0.00')
	--	  ELSE
	--			FORMAT(ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 ))),'0.00')
	--	  END  outSalePrice  -- 센터가인경우 센터가 * (1-할인율)

	--,CASE WHEN EXISTS(SELECT 1 FROM dbo.e_storage s_s
	--                    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode  
	--					JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
	--					WHERE s_s.comCode = @i__logComCode AND s_s.consignCustCode = 'ㅇ499'
	--					  AND s_sr.itemid = i2.itemId
	--				) THEN ROUND(i2.centerPrice * (1 - (ISNULL(osr.purRate/100,0))) ,0)
	--      WHEN @n__salePriceType = '매입가' THEN 
	--			FORMAT(ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
	--			(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)),'0.00')
	--	  ELSE
	--			FORMAT(ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 ))),'0.00')
	--	  END  outSalePrice  -- 센터가인경우 센터가 * (1-할인율)

	,CASE WHEN s.saleRate IS NULL THEN
		CASE
		WHEN stockCheck.hasNot499 = 1 THEN
			CASE 
				WHEN @n__salePriceType = '매입가' THEN 
					FORMAT(ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
					(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)),'0.00')
				ELSE 
					FORMAT(ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 ))),'0.00')
			END
		WHEN stockCheck.has499 = 1 THEN
			ROUND(i2.centerPrice * (1 - (ISNULL(osr.purRate/100,0))) ,0)
		ELSE
			CASE 
				WHEN @n__salePriceType = '매입가' THEN 
					FORMAT(ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
					(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)),'0.00')
				ELSE 
					FORMAT(ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 ))),'0.00')
			END
		END
	ELSE
		ROUND(i2.centerPrice * (1 - (ISNULL(s.saleRate/100,0))) ,0)	
	END AS outSalePrice

	,ISNULL (cust.custName, '') 	rcvCustName 
	,ISNULL (oi.dlvType, '') 	dlvType --배송유형
	
	
	,'' storageName
	,'' storageCode
	,'' rackName
	,'' rackCode
	,0  stockQty

	,ISNULL (s.procStep, '') procStep

	,ISNULL(i.makerCode,i2.makerCode) makerCode
	,b.codeName makerName
	,s.rejectMemo 
	,ISNULL(o.orderNo,ISNULL(do.orderNo ,'' ) ) orderNo -- 주문번호 or 삭제된 주문번호
	,IIF(o.orderNo is NULL ,IIF(do.orderNo is NULL , '' , '삭제됨') , '등록됨') orderStatus -- 주문상태
	,s.rcvLogisCode  -- yoonsagn 수령물류센터때문에 추가
	
	
	,IIF(IIF(i.comCode is null , i2.classCode , i.classCode )= 'GN','', i.factoryNo) factoryNo
	,cd.codeName className

	--,CASE WHEN EXISTS(SELECT 1 FROM dbo.e_storage s_s
	--                    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode  
	--					JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
	--					WHERE s_s.comCode = @i__logComCode AND s_s.consignCustCode = 'ㅇ499'
	--					  AND s_sr.itemid = i2.itemId
	--				) THEN 'ㅇ499' 
	--ELSE ''
	--END otherSaleType
	,CASE WHEN s.saleRate IS NULL THEN
		IIF(stockCheck.has499 = 1 AND stockCheck.hasNot499 = 0, 'ㅇ499', '') 
	 ELSE
		'ㅇ499'
	 END AS otherSaleType


FROM dbo.e_pcReqItem s

LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
LEFT OUTER JOIN dbo.e_item i ON pli.itemId = i.itemId  --원래 JOIN. 2023.11.24 hsg
LEFT OUTER JOIN dbo.e_cust  cust ON s.gvComCode = cust.comCode AND pli.rcvCustCode  = cust.custCode
LEFT OUTER JOIN dbo.e_orderItem oi ON s.gvComCode = oi.comCode AND pli.orderNo = oi.orderNo AND pli.orderSeq = oi.orderSeq   --원래 join. 2023.11.24 hsg
LEFT OUTER JOIN dbo.e_item i2 ON s.itemId = i2.itemId   --외부업체주문요청인경우. 2023.11.24 hsg 
  
LEFT JOIN dbo.e_orderItem o ON s.comCode = o.comCode AND s.pcReqNo = o.pcReqNo AND s.reqSeq = o.reqSeq
LEFT JOIN dbo.d_orderItem do ON s.comCode = do.comCode AND s.pcReqNo = do.pcReqNo AND s.reqSeq = do.reqSeq
LEFT JOIN dbo.e_code b ON b.comCode =  ISNULL(i.comCode , i2.comCode) AND b.mCode = '1000' AND b.code = IIF(i.comCode is null , i2.makerCode , i.makerCode)
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = ISNULL(i.comCode,i2.comCode)  AND cd.code =IIF(i.comCode is null , i2.classCode , i.classCode ) and  cd.mCode = '1100'

OUTER APPLY (
    SELECT
        MAX(CASE 
            WHEN s_s.consignCustCode = 'ㅇ499' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS has499,

        MAX(CASE 
            WHEN s_s.consignCustCode != 'ㅇ499' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS hasNot499
    FROM dbo.e_storage s_s
    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode
    JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
    WHERE s_s.comCode = 'ㄱ121'
      AND s_sr.itemId = i2.itemId
) stockCheck

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = 'ㄱ121' AND osr.custCode = 'ㅇ499' AND osr.itemId = i2.itemId
WHERE s.comCode = @i__logComCode 
AND (s.pcReqNo = @i__pcReqNo or @i__pcReqNo ='' )
AND (s.reqSeq in (select val from dbo.UF_SPLIT(@i__reqSeqArr , '!')))

ORDER BY pcReqNo, LEN(s.reqSeq), reqSeq

RETURN 
/***************************************************************/
ALL_QRY: 

/*
SET @sql = N'
SELECT
	s.comCode ,
	s.pcReqNo ,
	s.reqSeq
	
	,s.gvComCode 
	,s.gvPlaceNo
	,s.gvPlaceSeq
	,s.inMemo1
	--,ISNULL(i.itemId,0) itemId
	--,ISNULL(i.itemNo,'''') itemNo
	--,CASE WHEN ISNULL (i.itemName, '''') <> '''' THEN i.itemName 
	--	ELSE i.itemNameEn END itemName

	--외부업체주문요청이 있어서 위에서 아래로 변경, 2023.11.24 hsg
	,ISNULL(i.itemId,i2.itemId) itemId
	,ISNULL(i.itemNo,i2.itemNo) itemNo
	,CASE WHEN ISNULL (i.itemName, '''') <> '''' THEN i.itemName 
		  WHEN ISNULL (i.itemNameEn, '''') <> '''' THEN  i.itemNameEn
		  WHEN ISNULL (i2.itemName, '''') <> '''' THEN i2.itemName 
		  WHEN ISNULL (i2.itemNameEn, '''') <> '''' THEN  i2.itemNameEn
		  ELSE '''' END	 itemName	  

	,s.regUserId
	,s.created
	,s.uptUserId
	,s.modified 

	--,ISNULL(pli.cnt,0) cnt
	--,ISNULL (pli.UnitPrice,0) salePrice
	--,ISNULL (pli.sumPrice,0) sumPrice 
	--외부업체주문요청이 있어서 위에서 아래로 변경, 2023.11.24 hsg
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
	      WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
		  ELSE 0  END cnt
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL (pli.UnitPrice,0) 
	      WHEN pli.placeNo IS NULL THEN ISNULL(i2.salePrice,0) * ISNULL(s.gvQty,0)
		  ELSE 0  END salePrice
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL (pli.sumPrice,0) 
	      WHEN pli.placeNo IS NULL THEN ISNULL(i2.salePrice,0) *ISNULL(s.gvQty,0)
		  ELSE 0  END sumPrice 

	,ISNULL (cust.custName, '''') 	rcvCustName 
	,ISNULL (oi.dlvType, '''') 	dlvType --배송유형

	,stor.storageName  -- 수락할 창고, 랙, 수량등의 정보
	,stor.storageCode
	,r.rackName
	,r.rackCode
	,sr.stockQty
	,ISNULL (s.procStep, '''') procStep
--	,s.procQty
--	,s.procUserId
--	,s.procDate

FROM dbo.e_pcReqItem s
--JOIN dbo.e_pcReq pc ON  s.comCode = pc.comCode AND pc.pcReqNo = pc.pcReqNo
--JOIN dbo.e_item i ON oi.itemId = i.itemId
LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
LEFT OUTER JOIN dbo.e_item i ON pli.itemId = i.itemId  --원래 JOIN. 2023.11.24 hsg
LEFT OUTER JOIN dbo.e_cust  cust ON s.gvComCode = cust.comCode AND pli.rcvCustCode  = cust.custCode
LEFT OUTER JOIN dbo.e_orderItem oi ON s.gvComCode = oi.comCode AND pli.orderNo = oi.orderNo AND pli.orderSeq = oi.orderSeq   --원래 join. 2023.11.24 hsg
LEFT OUTER JOIN dbo.e_item i2 ON s.itemId = i2.itemId   --외부업체주문요청인경우. 2023.11.24 hsg 

JOIN dbo.e_stockRack sr ON CAST(ISNULL(i.itemId,i2.itemId) AS bigint) = sr.itemId AND s.comCode = sr.comCode   -- 품목의 아이디에 맞는 상품의 랙,창고 정보를 조인
LEFT OUTER JOIN dbo.e_rack r ON sr.rackCode = r.rackCode AND r.comCode = s.comCode
LEFT OUTER JOIN dbo.e_storage stor ON stor.storageCode = r.storageCode AND stor.comCode = s.comCode
'

SET @sql = @sql + N'   
WHERE 1= 1 AND s.comCode = @i__logComCode AND stor.consignCustCode <> s.gvComCode ' -- 주문한 업체의 위탁 창고 품목은 제외.? 2024.1.? hsg ?

IF @i__pcReqNo <> ''
SET @sql = @sql + N'   AND s.pcReqNo = @i__pcReqNo '

--IF @i__reqSeq <> ''
--SET @sql = @sql + N'   AND s.reqSeq = @i__reqSeq '

SET @sql = @sql + N' ORDER BY s.pcReqNo, LEN(s.reqSeq), s.reqSeq  '
--SET @sql = @sql + ' 
--					OFFSET ' + CAST(@subpage as VARCHAR(10)) + ' ROWS    --10번쨰 다음 부터
--					FETCH NEXT ' + CAST(@i__qty as VARCHAR(10)) + '   ROWS ONLY  --10개 레코드 출력
--					'
print @sql

EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20),
						@i__sYmd1 char(10),	@i__eYmd1 char(10) , @i__pcReqNo varchar(50), @i__reqSeq varchar(50) ', 
						@i__logComCode, @i__sYmd1,	@i__eYmd1, @i__pcReqNo, @i__reqSeq

*/


-- 주문 수락시 원래 상태가 변해서 해당 아이템을 봐도 주문등록에서 1행만 표시되었는데 사양이 변경되어서 @i__reqSeqArr매개변수 유무로
-- @i__reqSeqArr가 존재하면 랙정보가 없는 @t의 데이터를 반환하도록 변경
--주문 등록할떄 체크된 부품만 보내기 위한 부분임
 



-- 모든 주문에 디테일 정보를 @t에 보관.
-- 디테일중 procStep상태가 공백이면서 그 부품이 1개 이상인 랙의 정보를 t2에 저장
-- 머지해서 부품1개 이상인 공백상태의 부품에 조건에 해당하지 않는 부품도 1행으로 표시되도록 반환.
 
DECLARE @t TABLE (comCode varchar(20), pcReqNo varchar(20), reqSeq int , gvComCode varchar(20) , gvPlaceNo varchar(20),
				  gvPlaceSeq int , inMemo1 varchar(500), itemId varchar(50) , itemNo varchar(50) , itemName varchar(200),
				  regUserId varchar(20) , created datetime , uptUserId varchar(20) , modified datetime ,cnt int ,
				  salePrice money , sumPrice money , 
				  centerPrice money , outSalePrice money,
				  rcvCustName varchar(30) , dlvType varchar(50) , storageName varchar(50) ,
				  storageCode varchar(20) , rackName varchar(100), rackCode varchar(20), stockQty int , procStep varchar(10), makerCode varchar(10),rejectMemo varchar(500) , procUserName varchar(50)
				  ,rcvLogisCode varchar(10) , makerName varchar(20) , orderNo varchar(20),orderStatus  varchar(10) , factoryNo varchar(20) , className varchar(20)
				  ,stockRackCode varchar(50))
DECLARE @t2 TABLE (comCode varchar(20), pcReqNo varchar(20), reqSeq int , gvComCode varchar(20) , gvPlaceNo varchar(20),
				  gvPlaceSeq int , inMemo1 varchar(500), itemId varchar(50) , itemNo varchar(50) , itemName varchar(200),
				  regUserId varchar(20) , created datetime , uptUserId varchar(20) , modified datetime ,cnt int ,
				  salePrice money , sumPrice money ,
				  centerPrice money , outSalePrice money,
				  rcvCustName varchar(30) , dlvType varchar(50) , storageName varchar(50),
				  storageCode varchar(20) , rackName varchar(100), rackCode varchar(20), stockQty int , procStep varchar(10), makerCode varchar(10),rejectMemo varchar(500), procUserName varchar(50)
				  ,rcvLogisCode varchar(10) , logisRackId int , storConsignCustCode varchar(50), makerName varchar(20) , orderNo varchar(20),orderStatus  varchar(10) , factoryNo varchar(20) , className varchar(20)
				  ,stockRackCode varchar(50))

-- @t에 주문요청 디테일 입력
INSERT INTO @t (comCode , pcReqNo , reqSeq , gvComCode , gvPlaceNo , gvPlaceSeq , inMemo1, itemId , itemNo , itemName ,
				regUserId , created , uptUserId , modified , cnt , salePrice , sumPrice ,
				  centerPrice  , outSalePrice , rcvCustName , dlvType 
				 ,storageName,storageCode , rackName , rackCode , stockQty
				 ,procStep , makerCode,rejectMemo , procUserName
				 ,rcvLogisCode, makerName  , orderNo ,orderStatus   , factoryNo , className ,stockRackCode)

SELECT
	s.comCode ,
	s.pcReqNo ,
	s.reqSeq
	
	,s.gvComCode 
	,s.gvPlaceNo
	,s.gvPlaceSeq
	,s.inMemo1
	--,ISNULL(i.itemId,0) itemId
	--,ISNULL(i.itemNo,'''') itemNo
	--,CASE WHEN ISNULL (i.itemName, '''') <> '''' THEN i.itemName 
	--	ELSE i.itemNameEn END itemName

	--외부업체주문요청이 있어서 위에서 아래로 변경, 2023.11.24 hsg
	,ISNULL(i.itemId,i2.itemId) itemId
	,ISNULL(i.itemNo,i2.itemNo) itemNo
	,CASE WHEN ISNULL (i.itemName, '') <> '' THEN i.itemName 
		  WHEN ISNULL (i.itemNameEn, '') <> '' THEN  i.itemNameEn
		  WHEN ISNULL (i2.itemName, '') <> '' THEN i2.itemName 
		  WHEN ISNULL (i2.itemNameEn, '') <> '' THEN  i2.itemNameEn
		  ELSE '' END	 itemName	  

	,s.regUserId
	,s.created
	,s.uptUserId
	,s.modified 

	--,ISNULL(pli.cnt,0) cnt
	--,ISNULL (pli.UnitPrice,0) salePrice
	--,ISNULL (pli.sumPrice,0) sumPrice 
	--외부업체주문요청이 있어서 위에서 아래로 변경, 2023.11.24 hsg
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL(pli.cnt,0)
	      WHEN pli.placeNo IS NULL THEN ISNULL(s.gvQty,0)
		  ELSE 0  END cnt
	
	
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL (pli.UnitPrice,0) 
	      WHEN pli.placeNo IS NULL THEN ISNULL(i2.salePrice,0) * ISNULL(s.gvQty,0)
		  ELSE 0  END salePrice
	,CASE WHEN pli.placeNo IS NOT NULL THEN ISNULL (pli.sumPrice,0) 
	      WHEN pli.placeNo IS NULL THEN ISNULL(i2.salePrice,0) *ISNULL(s.gvQty,0)
		  ELSE 0  END sumPrice 
	,ISNULL(i.centerPrice,i2.centerPrice) centerPrice
--	,ISNULL(i.centerPrice,i2.centerPrice) outSalePrice

	--,IIF(@n__salePriceType = '매입가' , 
	--ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
	--(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)) ,
	--ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 )))) outSalePrice  -- 센터가인경우 센터가 * (1-할인율)

	--,CASE WHEN EXISTS(SELECT 1 FROM dbo.e_storage s_s
	--                    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode  
	--					JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
	--					WHERE s_s.comCode = @i__logComCode AND s_s.consignCustCode = 'ㅋ004' AND s_s.storageCode = '579'
	--					  AND s_sr.itemid = i.itemId
	--				) THEN i.salePrice
	--      WHEN @n__salePriceType = '매입가' THEN 
	--			ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
	--			(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)) 
	--	  ELSE
	--			ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 )))
	--	  END  outSalePrice  -- 센터가인경우 센터가 * (1-할인율)
	--,CASE WHEN EXISTS(SELECT 1 FROM dbo.e_storage s_s
	--                    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode  
	--					JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
	--					WHERE s_s.comCode = @i__logComCode AND s_s.consignCustCode = 'ㅇ499' 
	--					  AND s_sr.itemid = i2.itemId
	--				) THEN ROUND(i2.centerPrice * (1 - (ISNULL(osr.purRate/100,0))) ,0)
	--      WHEN @n__salePriceType = '매입가' THEN 
	--			ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
	--			(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)) 
	--	  ELSE
	--			ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 )))
	--	  END  outSalePrice  -- 센터가인경우 센터가 * (1-할인율)

	,
	CASE WHEN s.saleRate IS NULL THEN
		CASE
		WHEN stockCheck.hasNot499 = 1 THEN
			CASE 
				WHEN @n__salePriceType = '매입가' THEN 
					ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
					(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)) 
				ELSE 
					ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 )))
			END
		WHEN stockCheck.has499 = 1 THEN
			ROUND(i2.centerPrice * (1 - (ISNULL(osr.purRate/100,0))) ,0)
		ELSE
			CASE 
				WHEN @n__salePriceType = '매입가' THEN            
					ROUND((ISNULL(i.centerPrice,i2.centerPrice) *  dbo.UF_cCustPerItemRate(@i__logComCode ,s.gvComCode, ISNULL(i.itemId,i2.itemId) , 1)),0) *   --매입가인경우 (센터가 * 매입율(40?) * (1+마진율)
					(1+dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId) , 1)) 
				ELSE 
					ISNULL(i.centerPrice,i2.centerPrice) * (1 - (dbo.UF_sCustPerItemRate(@i__logComCode , s.gvComCode ,@n__salePriceType, ISNULL(i.itemId,i2.itemId), 1 )))
			END
		END
	ELSE	
		ROUND(i2.centerPrice * (1 - (ISNULL(s.saleRate/100,0))) ,0)
	END
	AS outSalePrice

	,ISNULL (cust.custName, '') 	rcvCustName 
	,ISNULL (oi.dlvType, '') 	dlvType --배송유형
	
	
	,'','','','',''
--	,stor.storageName  -- 수락할 창고, 랙, 수량등의 정보
--	,stor.storageCode
--	,r.rackName
--	,r.rackCode
--	,sr.stockQty

	,ISNULL (s.procStep, '') procStep
--	,s.procQty
--	,s.procUserId
--	,s.procDate
	,ISNULL(i.makerCode,i2.makerCode) makerCode
	,s.rejectMemo
	,u.userName
	,s.rcvLogisCode  -- yoonsagn 수령물류센터때문에 추가
	 ,b.codeName makerName
	 ,ISNULL(o.orderNo,ISNULL(do.orderNo ,'' ) ) orderNo -- 주문번호 or 삭제된 주문번호
	 ,IIF(o.orderNo is NULL ,IIF(do.orderNo is NULL , '' , '삭제됨') , '등록됨') orderStatus -- 주문상태
	 ,IIF(IIF(i.comCode is null , i2.classCode , i.classCode )= 'GN','', i.factoryNo) factoryNo
	 ,cd.codeName className
	 ,ISNULL(s.stockRackCode,'') AS stockRackCode
	

FROM dbo.e_pcReqItem s
--JOIN dbo.e_pcReq pc ON  s.comCode = pc.comCode AND pc.pcReqNo = pc.pcReqNo
--JOIN dbo.e_item i ON oi.itemId = i.itemId
LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
LEFT OUTER JOIN dbo.e_item i ON pli.itemId = i.itemId  --원래 JOIN. 2023.11.24 hsg
LEFT OUTER JOIN dbo.e_cust  cust ON s.gvComCode = cust.comCode AND pli.rcvCustCode  = cust.custCode
LEFT OUTER JOIN dbo.e_orderItem oi ON s.gvComCode = oi.comCode AND pli.orderNo = oi.orderNo AND pli.orderSeq = oi.orderSeq   --원래 join. 2023.11.24 hsg
LEFT OUTER JOIN dbo.e_item i2 ON s.itemId = i2.itemId   --외부업체주문요청인경우. 2023.11.24 hsg 
LEFT OUTER JOIN dbo.e_user u ON u.comCode = s.comCode AND u.userId = s.procUserId

LEFT JOIN dbo.e_code b ON b.comCode =  ISNULL(i.comCode , i2.comCode) AND b.mCode = '1000' AND b.code = IIF(i.comCode is null , i2.makerCode , i.makerCode)
LEFT OUTER JOIN dbo.e_code cd ON cd.comCode = ISNULL(i.comCode,i2.comCode)  AND cd.code =IIF(i.comCode is null , i2.classCode , i.classCode ) and  cd.mCode = '1100'
LEFT JOIN dbo.e_orderItem o ON s.comCode = o.comCode AND s.pcReqNo = o.pcReqNo AND s.reqSeq = o.reqSeq
LEFT JOIN dbo.d_orderItem do ON s.comCode = do.comCode AND s.pcReqNo = do.pcReqNo AND s.reqSeq = do.reqSeq

--JOIN dbo.e_stockRack sr ON CAST(ISNULL(i.itemId,i2.itemId) AS bigint) = sr.itemId AND s.comCode = sr.comCode    -- 품목의 아이디에 맞는 상품의 랙,창고 정보를 조인
--LEFT OUTER JOIN dbo.e_rack r ON sr.rackCode = r.rackCode AND r.comCode = s.comCode
--LEFT OUTER JOIN dbo.e_storage stor ON stor.storageCode = r.storageCode AND stor.comCode = s.comCode

OUTER APPLY (
    SELECT
        MAX(CASE 
            WHEN s_s.consignCustCode = 'ㅇ499' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS has499,

        MAX(CASE 
            WHEN s_s.consignCustCode != 'ㅇ499' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS hasNot499
    FROM dbo.e_storage s_s
    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode
    JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
    WHERE s_s.comCode = 'ㄱ121'
      AND s_sr.itemId = i2.itemId
) stockCheck

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = 'ㄱ121' AND osr.custCode = 'ㅇ499' AND osr.itemId = i2.itemId 

WHERE s.comCode = @i__logComCode 
AND (s.pcReqNo = @i__pcReqNo or @i__pcReqNo ='' )



 

--위에 요청 디테일 입력한 @t의 부품중에 랙 재고가 있는 데이터들은 랙 마다 한 행이 입력되도록 @t2에 입력
INSERT INTO @t2 (comCode , pcReqNo , reqSeq , gvComCode , gvPlaceNo , gvPlaceSeq , inMemo1, itemId , itemNo , itemName ,
				regUserId , created , uptUserId , modified , cnt , salePrice , sumPrice , centerPrice  , outSalePrice , rcvCustName , dlvType 
				, storageName,storageCode , rackName , rackCode , stockQty
				 ,procStep , makerCode ,rejectMemo,procUserName , rcvLogisCode , logisRackId , storConsignCustCode, makerName  , orderNo ,orderStatus   , factoryNo , className , stockRackCode)
SELECT t.comCode , t.pcReqNo , t.reqSeq , t.gvComCode , t.gvPlaceNo , t.gvPlaceSeq , t.inMemo1, t.itemId , t.itemNo , t.itemName ,
				t.regUserId , t.created , t.uptUserId , t.modified , t.cnt , salePrice , sumPrice , centerPrice  , outSalePrice , t.rcvCustName , t.dlvType 
				, stor.storageName,stor.storageCode , r.rackName , r.rackCode , sr.stockQty
				 ,t.procStep , t.makerCode ,t.rejectMemo,t.procUserName ,t.rcvLogisCode , r.logisRackId ,stor.consignCustCode, t.makerName  , t.orderNo ,t.orderStatus   , t.factoryNo , t.className ,t.stockRackCode
	   FROM  @t t
	   JOIN dbo.e_stockRack sr ON t.itemId = sr.itemId AND t.comCode = sr.comCode    -- 품목의 아이디에 맞는 상품의 랙,창고 정보를 조인
	   LEFT OUTER JOIN dbo.e_rack r ON sr.rackCode = r.rackCode AND r.comCode = t.comCode AND r.validYN = 'Y'
       LEFT OUTER JOIN dbo.e_storage stor ON stor.storageCode = r.storageCode AND stor.comCode = t.comCode AND stor.validYN = 'Y' AND stor.workableYN = 'Y'
	   WHERE stor.consignCustCode <> t.gvComCode  AND sr.stockQty <> 0 AND t.procStep = ''


-- @t2에 없는 데이터(재고가 없는 데이터)를 @t에서 다시 붙여넣어서 결과적으로 재고가 있는 데이터의 랙 리스크와 재고가 없는 부품(랙 정보 없는 1행)으로 @t2를 머지 
MERGE INTO @t2 as a 
USING (SELECT comCode , pcReqNo , reqSeq , gvComCode , gvPlaceNo , gvPlaceSeq , inMemo1, itemId , itemNo , itemName ,
				regUserId , created , uptUserId , modified , cnt , salePrice , sumPrice , centerPrice  , outSalePrice , rcvCustName , dlvType 
				, storageName,storageCode , rackName , rackCode , stockQty
				 ,procStep , makerCode , rejectMemo,procUserName ,rcvLogisCode, makerName  , orderNo ,orderStatus   , factoryNo , className
	   FROM  @t
	   ) as b
ON a.comCode = b.comCode AND a.itemId = b.itemId 
WHEN NOT MATCHED THEN
	INSERT (comCode , pcReqNo , reqSeq , gvComCode , gvPlaceNo , gvPlaceSeq , inMemo1, itemId , itemNo , itemName ,
		regUserId , created , uptUserId , modified , cnt , salePrice , sumPrice ,centerPrice  , outSalePrice , rcvCustName , dlvType 
				, storageName,storageCode , rackName , rackCode , stockQty
				,procStep , makerCode,rejectMemo,procUserName ,rcvLogisCode, makerName  , orderNo ,orderStatus   , factoryNo , className)
	VALUES(b.comCode , b.pcReqNo , b.reqSeq , b.gvComCode , b.gvPlaceNo , b.gvPlaceSeq , b.inMemo1, b.itemId , b.itemNo , b.itemName ,
		b.regUserId , b.created , b.uptUserId , b.modified , b.cnt , b.salePrice , b.sumPrice , b.centerPrice , b.outSalePrice , b.rcvCustName , b.dlvType 
				, b.storageName ,b.storageCode , b.rackName , b.rackCode , b.stockQty
				,b.procStep , b.makerCode,b.rejectMemo,procUserName ,rcvLogisCode, b.makerName  , b.orderNo ,b.orderStatus   , b.factoryNo , b.className);


SELECT t.comCode , t.pcReqNo , t.reqSeq , t.gvComCode , t.gvPlaceNo , t.gvPlaceSeq , t.inMemo1, t.itemId , t.itemNo , t.itemName ,
				t.regUserId , t.created , t.uptUserId , t.modified , t.cnt , t.salePrice , t.sumPrice , t.centerPrice  , t.outSalePrice 
				, t.rcvCustName , t.dlvType 
				, t.storageName,t.storageCode , t.rackName , t.rackCode , t.stockQty
				 ,t.procStep ,t.makerCode , t.makerName , t.rejectMemo,
				 t.orderNo -- 주문번호 or 삭제된 주문번호
				 ,t.orderStatus -- 주문상태
				 ,procUserName ,t.rcvLogisCode , t.logisRackId , t.storConsignCustCode
				 ,t.factoryNo
			  	 ,t.className
FROM @t2 t
 

WHERE (t.reqSeq in (select val from dbo.UF_SPLIT(@i__reqSeqArr , '!'))) OR @i__reqSeqArr = ''
AND (
    (ISNULL(t.stockRackCode, '') = '' 
         AND ISNULL(t.storConsignCustCode, '') NOT IN ('ㅇ499', 'ㅂ022','ㅇ479', 'ㅇ002', 'ㅂ184', 'ㅈ011', 'ㅂ186', 'ㄱ008'))
    OR
    (ISNULL(t.stockRackCode, '') = 'ㅇ499' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅇ499')
    OR
    (ISNULL(t.stockRackCode, '') = 'ㅂ022' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅂ022')
	OR
    (ISNULL(t.stockRackCode, '') = 'ㅇ479' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅇ479')
	OR
    (ISNULL(t.stockRackCode, '') = 'ㅇ002' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅇ002')
	OR
    (ISNULL(t.stockRackCode, '') = 'ㅂ184' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅂ184')
	OR
    (ISNULL(t.stockRackCode, '') = 'ㅈ011' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅈ011')
	OR
    (ISNULL(t.stockRackCode, '') = 'ㅂ186' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㅂ186')
	OR
    (ISNULL(t.stockRackCode, '') = 'ㄱ008' 
         AND ISNULL(t.storConsignCustCode, '') = 'ㄱ008')
)

ORDER BY pcReqNo, LEN(t.reqSeq), reqSeq

RETURN
/*************************************************************************************************/
LIST_OUT: 
 

SET @sql = N'
SELECT
	s.comCode ,
	s.pcReqNo ,
	s.reqSeq
	
	,s.gvComCode 
	,s.gvPlaceNo
	,s.gvPlaceSeq
	,s.inMemo1
	--,ISNULL(i.itemId,0) itemId
	--,ISNULL(i.itemNo,'''') itemNo
	--,CASE WHEN ISNULL (i.itemName, '''') <> '''' THEN i.itemName 
	--	ELSE i.itemNameEn END itemName
	,CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END itemId
	,CASE WHEN i.itemId IS NOT NULL THEN i.itemNO ELSE i2.itemNo END itemNo
	,CASE WHEN ISNULL (i.itemName, '''') <> '''' THEN i.itemName 
	      WHEN ISNULL (i2.itemName, '''') <> '''' THEN i2.itemName 
		  WHEN ISNULL (i.itemNameEn, '''') <> '''' THEN i.itemNameEn 
	      WHEN ISNULL (i2.itemNameEn, '''') <> '''' THEN i2.itemNameEn 
		  ELSE '''' END itemName

	,s.regUserId
	,s.created
	,s.uptUserId
	,s.modified 
	,s.gvQty cnt
	,0 salePrice
	,0 sumPrice 
	,'''' 	rcvCustName 
	,'''' 	dlvType --배송유형
	,ISNULL(s.gvMemo1,'''') gvMemo1
	,ISNULL (s.procStep, '''') procStep
	,i.centerPrice

	


,CASE
	WHEN s.saleRate IS NULL THEN
		CASE
			WHEN stockCheck.hasNot499 = 1 THEN
				CASE 
					WHEN @n__salePriceType = ''매입가'' THEN 
						ROUND(
					(i.centerPrice * dbo.UF_cCustPerItemRate(s.comCode, @i__logComCode, 
						CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END, 1)), 0
				) * 
				(1 + dbo.UF_sCustPerItemRate(s.comCode, @i__logComCode, @n__salePriceType, 
					CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END, 1))
					ELSE 
						i.centerPrice * 
				(1 - dbo.UF_sCustPerItemRate(s.comCode, @i__logComCode, @n__salePriceType, 
					CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END, 1))
				END
			WHEN stockCheck.has499 = 1 THEN
				ROUND(i.centerPrice * (1 - (ISNULL(osr.purRate/100,0))) ,0)
			ELSE
				CASE 
					WHEN @n__salePriceType = ''매입가'' THEN 
						ROUND(
					(i.centerPrice * dbo.UF_cCustPerItemRate(s.comCode, @i__logComCode, 
						CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END, 1)), 0
				) * 
				(1 + dbo.UF_sCustPerItemRate(s.comCode, @i__logComCode, @n__salePriceType, 
					CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END, 1))
					ELSE 
						i.centerPrice * 
				(1 - dbo.UF_sCustPerItemRate(s.comCode, @i__logComCode, @n__salePriceType, 
					CASE WHEN i.itemId IS NOT NULL THEN i.itemId ELSE i2.itemId END, 1))
				END
		END

ELSE
	ROUND(i.centerPrice * (1 - (ISNULL(s.saleRate/100,0))) ,0)
END AS outSalePrice


	,s.rejectMemo
	,b.codeName AS makerName
	,b2.codeName className 
	,IIF(i.classCode = ''GN'','''', i.factoryNo) factoryNo
	
FROM dbo.e_pcReqItem s
LEFT OUTER JOIN dbo.e_placeItem pli ON  s.gvComCode = pli.comCode AND s.gvPlaceNo = pli.placeNo AND s.gvPlaceSeq = pli.placeSeq 
LEFT OUTER JOIN dbo.e_item i ON s.itemId = i.itemId
LEFT OUTER JOIN dbo.e_item i2 ON pli.itemId = i2.itemId

--JOIN dbo.e_item i ON s.itemId = i.itemId
--LEFT OUTER JOIN dbo.e_cust  cust ON s.gvComCode = cust.comCode AND pli.rcvCustCode  = cust.custCode
--JOIN dbo.e_orderItem oi ON s.gvComCode = oi.comCode AND pli.orderNo = oi.orderNo AND pli.orderSeq = oi.orderSeq 
LEFT OUTER JOIN dbo.e_code b ON s.comCode = b.comCode AND b.mCode=''1000'' AND b.code = ISNULL(i.makerCode , i2.makerCode)
LEFT OUTER JOIN dbo.e_code b2 ON s.comCode = b2.comCode AND b2.mCode=''1100'' AND b2.code = ISNULL(i.classCode , i2.classCode)

OUTER APPLY (
    SELECT
        MAX(CASE 
            WHEN s_s.consignCustCode = ''ㅇ499'' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS has499,

        MAX(CASE 
            WHEN s_s.consignCustCode != ''ㅇ499'' AND s_sr.stockQty > 0 THEN 1 
            ELSE 0 
        END) AS hasNot499
    FROM dbo.e_storage s_s
    JOIN dbo.e_rack s_r ON s_s.comCode = s_r.comCode AND s_s.storageCode = s_r.storageCode
    JOIN dbo.e_stockRack s_sr ON s_r.comCode = s_sr.comCode AND s_r.rackCode = s_sr.rackCode
    WHERE s_s.comCode = ''ㄱ121''
      AND s_sr.itemId = i.itemId
) stockCheck

LEFT OUTER JOIN dbo.e_otherSaleRate osr ON osr.comCode = ''ㄱ121'' AND osr.custCode = ''ㅇ499'' AND osr.itemId = i.itemId 
'

SET @sql = @sql + N'   
WHERE 1= 1 AND s.gvComCode = @i__logComCode '

IF @i__pcReqNo <> ''
SET @sql = @sql + N'   AND s.pcReqNo = @i__pcReqNo '

--IF @i__reqSeq <> ''
--SET @sql = @sql + N'   AND s.reqSeq = @i__reqSeq '

SET @sql = @sql + N' ORDER BY s.pcReqNo, LEN(s.reqSeq), s.reqSeq  '

print @sql

EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20),
						@i__sYmd1 char(10),	@i__eYmd1 char(10) , @i__pcReqNo varchar(50), @i__reqSeq varchar(50)   , @n__salePriceType varchar(10)', 
						@i__logComCode, @i__sYmd1,	@i__eYmd1, @i__pcReqNo, @i__reqSeq  , @n__salePriceType


RETURN
/*************************************************************************************************/


