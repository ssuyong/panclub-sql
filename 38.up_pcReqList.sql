USE [panErp]
GO
/****** Object:  StoredProcedure [dbo].[up_pcReqList]    Script Date: 2026-05-14 오전 9:55:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[up_pcReqList]
/***************************************************************
설명 : 주문 접수 목록
       
작성 : 2023.08.21 bk
		 2023.08.24 bk - @i__procStep 수정
		 2023.08.30 yoonsang - @n__tkComCode, LIST_GV_QRY 추가
		 2023.11.21 hsg - @i__workingType = 'LIST_OUT' 인 경우 그린파츠 전용으로 쿼리. 
		                - LIST_GV_QRY 에 아이템수 추가 itemQty 
		 2023.11.24 hsg - 요청업체가 custCode에 없는 경우(그린파츠 등록안된업체) custName=미등록업체로 표기
		 2023.12.08 hsg - select 절 추가.deliWay,deliPayType,senderCustName,senderName,senderTel,senderAddr1,receiverCustName,receiverName,receiverTel,receiverAddr1
		 2024.01.18 supi - LIST_QRY에서 itemQty 누락된부분 추가
		 2024.01.25 supi - 마스터의 디테일을 참조하여 완료,일부완료,미완료의 처리상태 노출 및 조회가능하도록 추가
		 2024.01.27 supi - 팬오토측 처리상태 반환 추가
		 2024.02.15 supi - 요청담당자 아이디가 아니라 이름으로 나오도록 변경
		 2024.02.21 supi - LIST_QRY에서 orderNo 반환추가 (처리번호=>외부업체의 경우 생성된 주문번호)
		 2024.02.27 supi - 주문접수요청의 디테일에 처리나 거부가 0개일경우 미완료로 표기되던 부분을 마스터 상태를 조회해서 접수or 미완료중에 반환하도록 수정
		 2024.03.11 supi - 방문처 rcvlogisCode 반환추가
		 2024.03.12 supi - 디테일의 거부수 rejectCount 반환 추가
		 2024.03.14 supi - 처리품목 procCount 반환 추가
		 2024.04.05 supi - 부품id , 부품번호를 조회조건으로 검색기능 추가(디테일에 붙어있는 마스터만 조회됨) , 주문 삭제된 수량 노출추가
		 2025.02.07 yoonsang - @n__tkComCode = 'ㄱ121' 부분 ㄱ000으로 수정
ex)
select * from panErp.dbo._SPLOG order by created desc

select * from _SPLOG  where sp like '%up_pcReqList%' order by created desc

panErp.dbo.up_pcReqList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-01-05',      @i__eYmd1='2024-01-05',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',        @i__pcReqNo='',    @i__gvComCode='',    @i__gvMgr='',    @i__procUserId='',    @i__procStep='',    @i__gvPlacNo ='',    @i__logUserId='그린파츠'
panErp.dbo.up_pcReqList	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-01-05',      @i__eYmd1='2024-01-05',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',        @i__pcReqNo='',    @i__gvComCode='',    @i__gvMgr='',    @i__procUserId='',    @i__procStep='',    @i__gvPlacNo ='',    @i__logUserId='그린파츠'
***************************************************************/
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
	,@i__logUserId varchar(20) = ''    --로그인한 사용자아이디
	
	,@i__pcReqNo varchar(50) = '' 
	,@i__gvComCode varchar(20) = '' 
	,@i__gvMgr varchar(20) = '' 
	,@i__procUserId varchar(20) = '' 
	,@i__procStep varchar(10) = '' 
	,@i__gvPlacNo varchar(20) = ''
	,@i__procState varchar(100) = ''
	,@i__salePriceType varchar(10) = ''
	,@i__itemId varchar(50) = '' -- 디테일내에 원하는 부품아이디가 있는 마스터를검색하기 위한 조회변수
	,@i__itemNo varchar(50) = '' -- 디테일내에 원하는 부품번호가 있는 마스터를검색하기 위한 조회변수
AS

SET NOCOUNT ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--로그--------------------------
INSERT INTO panErp.dbo._SPLOG( sp,params)
	VALUES('panErp.dbo.up_pcReqList', 
	'@i__workingType='''+ISNULL(@i__workingType,'')+''',
	 @i__page='+cast(ISNULL(@i__page,0) as varchar(100))+',
	 @i__qty='+cast(ISNULL(@i__qty,0) as varchar(100))+',	 
	 @i__orderBy='''+ISNULL(@i__orderBy,'')+''',
	 @i__ymdIgnoreYN='''+ISNULL(@i__ymdIgnoreYN,'')+''',
	 @i__sYmd1='''+ISNULL(@i__sYmd1,'')+''',	 
	 @i__eYmd1='''+ISNULL(@i__eYmd1,'')+''',	 
	 @i__sYmd2='''+ISNULL(@i__sYmd2,'')+''',
	 @i__eYmd2='''+ISNULL(@i__eYmd2,'')+''',
	 @i__logComCode='''+cast(ISNULL(@i__logComCode,'') as varchar(100))+''',
	 
	 @i__pcReqNo='''+cast(ISNULL(@i__pcReqNo,'') as varchar(100))+''',
	 @i__gvComCode='''+cast(ISNULL(@i__gvComCode,'') as varchar(100))+''',
	 @i__gvMgr='''+cast(ISNULL(@i__gvMgr,'') as varchar(100))+''',
	 @i__procUserId='''+cast(ISNULL(@i__procUserId,'') as varchar(100))+''',
	 @i__procStep='''+cast(ISNULL(@i__procStep,'') as varchar(100))+''',
	 @i__gvPlacNo ='''+cast(ISNULL(@i__gvPlacNo,'') as varchar(100))+''',
	 @i__logUserId='''+cast(ISNULL(@i__logUserId,'') as varchar(100))+''',
	 @i__itemId='''+cast(ISNULL(@i__itemId,'') as varchar(100))+''',
	 @i__itemNo='''+cast(ISNULL(@i__itemNo,'') as varchar(100))+''',
	 @i__procState='''+cast(ISNULL(@i__procState,'') as varchar(100))+''''
   )
---------------------------------


DECLARE @n__sYmd1 varchar(10),  @n__eYmd1 varchar(10)
SET @n__sYmd1 = @i__sYmd1
SET @n__eYmd1 = @i__eYmd1

IF @i__sYmd1 <> ''
	SET @n__sYmd1 = REPLACE(@i__sYmd1,'-','')
IF @i__eYmd1 <> ''
	SET @n__eYmd1 = REPLACE(@i__eYmd1,'-','')

DECLARE @n__tkComCode varchar(10) = ''
SET @n__tkComCode = (SELECT custCode FROM dbo.e_place WHERE comCode = @i__logComCode AND placeNo = @i__gvPlacNo)

IF @i__workingType = 'LIST_OUT'  --그린파츠 전용
	SET @n__tkComCode = 'ㄱ121'
	--SET @n__tkComCode = 'ㄱ000'

DECLARE @sql nvarchar(max)
SET @sql = N''

IF @i__workingType = 'LIST' 
	GOTO LIST_QRY   -- 주문요청처리자리스트

IF @i__workingType = 'LIST_GV' OR @i__workingType = 'LIST_OUT' 
	GOTO LIST_GV_QRY   -- 주문요청자 리스트
	


RETURN
/*************************************************************************************************/
LIST_QRY: 


SET @sql = N'
SELECT
    a.deliveryYN, --배송여부
	a.comCode , --주문접수(구매접수)거래처코드
	a.pcReqNo , --주문접수(구매접수)요청번호
	a.gvComCode , -- 요청업체코드
	a.gvPlacNo ,          --요청업체 발주번호
--	a.gvMgr ,  --요청업체 담당자
	(select userName from dbo.e_user where userId = a.regUserId AND comCode = a.gvComCode) gvMgr ,

	ISNULL(a.gvMemo,'''') gvMemo ,  --요청업체에서 작성한 메모
	ISNULL(a.procStep,'''') procStep ,  -- 접수단계 : 수락, 거부
	ISNULL(ur3.userName,'''') procUserId, --단계 등록자
	ISNULL(a.procDate,'''') procDate , --단계 처리일시
	a.rejectMemo , --거부사유
	ISNULL(a.inMemo1,'''') inMemo1,  --접수받은 업체 기타메모	
	a.regUserId,
	a.regYmd,
	a.regHmsg ,
	--a.uptUserId ,
	a.uptYmd,
	a.uptHmsg,
	ISNULL(ur.userName,'''') AS regUserName , --등록이름 
	ISNULL(cust.custName,''미등록업체'') AS gvCustName ,-- 요청업체이름 
	ISNULL(ur2.userName, '''') AS uptUserId 
	,ISNULL(a.deliWay			,'''') deliWay
	,ISNULL(a.deliPayType		,'''') deliPayType
	,ISNULL(a.senderCustName	,'''') senderCustName
	,ISNULL(a.senderName		,'''') senderName
	,ISNULL(a.senderTel			,'''') senderTel
	,ISNULL(a.senderAddr1		,'''') senderAddr1
	,ISNULL(a.receiverCustName	,'''') receiverCustName
	,ISNULL(a.receiverName		,'''') receiverName
	,ISNULL(a.receiverTel		,'''') receiverTel
	,ISNULL(a.receiverAddr1		,'''') receiverAddr1 , 
	pcri.itemQty,
	(SELECT IIF(MAX(IIF(ISNULL(pri.procStep,'''')='''',0,1)) =0 , ISNULL(a.procStep,''미완료''),  --디테일에 미처리 케이스뿐이라면 미완료
	   IIF(MAX(IIF(ISNULL(pri.procStep,'''') <> '''',0,1)) =0 , ''완료'' , ''일부완료''))  -- 처리 케이스는 있는데 미처리 케이스가 없다면 완료 , 있다면 일부완료
		FROM dbo.e_pcReqItem pri
		WHERE pri.pcReqNo= a.pcReqNo AND pri.comCode = @i__logComCode) procState

	 
	,(SELECT STRING_AGG(orderitem.orderNo ,'','')  
	from
	(SELECT  orderNo, pcReqNo FROM dbo.e_orderItem oi
	where pcReqNo = a.pcReqNo
	group by pcReqNo , orderNo) orderitem
	WHERE pcReqNo is not null
	group by pcReqNo) orderNo

	,rcvLogisCode
	,(SELECT SUM(IIF(pri.procStep=''거부'',1,0)) rejectCount FROM dbo.e_pcReqItem pri
		WHERE pri.pcReqNo= a.pcReqNo AND pri.comCode = @i__logComCode) rejectCount
	

	,IIF( a.gvPlacNo  = '''' ,
	     (SELECT count(*) FROM dbo.e_orderItem o 
	      JOIN dbo.e_pcReqItem pri ON pri.comCode = o.comCode AND pri.pcReqNo = o.pcReqNo AND pri.reqSeq = o.reqSeq AND pri.procStep in (''접수'', ''처리'')
	      WHERE a.comCode = o.comCode AND  a.pcReqNo = o.pcReqNo
	    ) ,
     	(SELECT count(*) FROM  dbo.e_pcReqItem pri 
	     WHERE a.gvComCode = pri.gvComCode AND a.gvPlacNo = pri.gvPlaceNo AND pri.procStep in (''접수'',''처리'') 
	    )) procCount  

	,(SELECT count(*) FROM dbo.d_orderItem o 
		JOIN dbo.e_pcReqItem pri ON pri.comCode = o.comCode AND pri.pcReqNo = o.pcReqNo AND pri.reqSeq = o.reqSeq
		WHERE a.comCode = o.comCode AND  a.pcReqNo = o.pcReqNo) orderDelCount
	,(select COUNT(*)
		from e_stockRack sr
		join e_item ei on ei.itemId = sr.itemId
		join e_rack er on er.comCode = sr.comCode
		  and er.rackCode = sr.rackCode
		  and er.validYN = ''Y''
		join e_storage sg on sg.comCode = sr.comCode
		  and sg.storageCode = er.storageCode
		join e_pcReqItem pri on pri.comCode = sr.comCode
		  and pri.itemId = sr.itemId
		left join e_pcReqItemRack prir on prir.comCode = sr.comCode
		  and prir.pcReqNo = pri.pcReqNo
		  and prir.reqSeq = pri.reqSeq
		  and prir.rackCode = sr.rackCode
		where sr.comCode = a.comCode
		  and pri.pcReqNo = a.pcReqNo--
		  and sr.stockQty > 0
		  and sg.storageCode in (''20250729001'',''20251127001'',''20251203001'',
								 ''20251224001'',''20260223001'',''20260327001'',
								 ''20260402001'',''20260416001'',''20260424001'',
								 ''250214001'',''250609001'',''250618001'',
								 ''250704001'',''250923001'',''250925002'',
								 ''251030001'',''251030002'')
		  and (
			(ISNULL(prir.pcReqNo,'''') = '''' --미접수
                AND sr.stockQty > 0
                AND ISNULL(pri.procStep, '''') = ''''
				) 
			 OR (ISNULL(prir.pcReqNo,'''') = '''' --거부
					--AND sr.stockQty > 0
					AND pri.procStep = ''거부''
					)
			 OR (ISNULL(prir.pcReqNo,'''') <> '''' ) --접수
			  )
		  ) inNamyangjuCount
FROM  dbo.e_pcReq  a
LEFT OUTER JOIN dbo.e_cust cust ON a.comCode = cust.comCode AND a.gvComCode = cust.custCode
LEFT OUTER JOIN dbo.e_user ur ON a.comCode = ur.comCode AND a.regUserId = ur.userID --등록자
LEFT OUTER JOIN dbo.e_user ur2 ON a.comCode = ur2.comCode AND a.uptUserId = ur2.userID --수정자
LEFT OUTER JOIN dbo.e_user ur3 ON a.comCode = ur3.comCode AND a.procUserId = ur3.userID --수정자 
JOIN (SELECT
			pcri.comCode, 
			pcri.pcReqNo,
	--pcri.gvComCode,  inMemo1 , 
		COUNT(*) itemQty  
		FROM dbo.e_pcReqItem pcri 
		GROUP BY pcri.comCode, pcri.gvComCode, pcri.pcReqNo ,pcri.inMemo1
		) pcri ON pcri.comCode = a.comCode AND pcri.pcReqNo = a.pcReqNo
WHERE 1= 1 AND a.comCode = @i__logComCode
'
IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
	SET @sql = @sql + ' AND a.regYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF  @i__pcReqNo <> ''
SET @sql = @sql + N'   AND a.pcReqNo=  @i__pcReqNo '

IF @i__gvComCode <> ''
SET @sql = @sql + N'   AND a.gvComCode = @i__gvComCode '

IF @i__gvMgr <> ''
SET @sql = @sql + N'   AND a.gvMgr= @i__gvMgr '

IF @i__procUserId <> ''
SET @sql = @sql + N'   AND a.procUserId = @i__procUserId '

IF @i__gvPlacNo <> ''
SET @sql = @sql + N'   AND a.gvPlacNo= @i__gvPlacNo '

IF @i__itemId <> ''
SET @sql = @sql + N' AND EXISTS  (SELECT 1 FROM dbo.e_pcReqItem ri 
			  WHERE ri.itemId = @i__itemId AND ri.pcReqNo = a.pcReqNo ) '

IF @i__itemNo <> ''
SET @sql = @sql + N' AND EXISTS  (SELECT 1 FROM dbo.e_pcReqItem ri
			  JOIN dbo.e_item i ON ri.itemId = i.itemId AND i.itemNo = @i__itemNo
			  WHERE ri.pcReqNo = a.pcReqNo ) '


IF @i__procStep = '접수'
BEGIN
	SET @sql = @sql + ' AND a.procStep =''접수'' '
END
ELSE IF @i__procStep = '거부'
BEGIN
	SET @sql = @sql + ' AND a.procStep =''거부'' '
END
ELSE 
BEGIN
	SET @sql = @sql + ''
END

IF @i__procState <> ''
SET @sql = @sql +N' AND EXISTS(SELECT 1 FROM (SELECT IIF(MAX(IIF(ISNULL(pri.procStep,'''')='''',0,1)) =0 , ''미완료'',  --디테일에 미처리 케이스뿐이라면 미완료
		   IIF(MAX(IIF(ISNULL(pri.procStep,'''') <> '''',0,1)) =0 , ''완료'' , ''일부완료'')) sta  -- 처리 케이스는 있는데 미처리 케이스가 없다면 완료 , 있다면 일부완료
			FROM dbo.e_pcReqItem pri
			WHERE pri.pcReqNo= a.pcReqNo AND pri.comCode = @i__logComCode) ps 
		WHERE ps.sta in (SELECT val FROM dbo.UF_SPLIT(@i__procState , ''^'')))   '
 


SET @sql = @sql + N' ORDER BY a.pcReqNo, a.regYmd'

print @sql
EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10), @i__pcReqNo varchar(50) , @i__gvComCode varchar (20) ,  @i__gvMgr varchar(20),
										@i__procUserId varchar (20), @i__procStep varchar (20)  , @i__gvPlacNo varchar (20) ,  @i__procState varchar(100) ,@i__itemNo varchar(50) , @i__itemId varchar(50)', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__pcReqNo , @i__gvComCode ,  @i__gvMgr ,@i__procUserId ,@i__procStep ,@i__gvPlacNo, @i__procState , @i__itemNo , @i__itemId


RETURN
/*************************************************************************************************/
LIST_GV_QRY: 


SET @sql = N'
SELECT
	a.deliveryYN, --배송여부
	a.comCode , --주문접수(구매접수)거래처코드
	a.pcReqNo , --주문접수(구매접수)요청번호
	a.gvComCode , -- 요청업체코드
	a.gvPlacNo ,          --요청업체 발주번호
	a.gvMgr ,  --요청업체 담당자
	

	a.gvMemo ,  --요청업체에서 작성한 메모
	ISNULL(a.procStep,''확인전'') AS procStep,  -- 접수단계 : 수락, 거부
	a.procUserId , --단계 등록자
	a.procDate, --단계 처리일시
	a.rejectMemo , --거부사유
	--a.inMemo1 ,  --접수받은 업체 기타메모	
	a.regUserId,
	a.regYmd,
	a.regHmsg ,
	--a.uptUserId ,
	a.uptYmd,
	a.uptHmsg,
	ISNULL(ur.userName,'''') AS regUserName , --등록이름 
	ISNULL(cust.custName,'''') AS gvCustName ,-- 요청업체이름 
	ISNULL(ur2.userName, '''') AS uptUserId 

	,ur.userName AS gvMgrName
	,ur2.userName AS procUserName
	,pcri.inMemo1 AS placeCustCode
	,pcri.itemQty 

	,ISNULL(a.deliWay			,'''') deliWay
	,ISNULL(a.deliPayType		,'''') deliPayType
	,ISNULL(a.senderCustName	,'''') senderCustName
	,ISNULL(a.senderName		,'''') senderName
	,ISNULL(a.senderTel			,'''') senderTel
	,ISNULL(a.senderAddr1		,'''') senderAddr1
	,ISNULL(a.receiverCustName	,'''') receiverCustName
	,ISNULL(a.receiverName		,'''') receiverName
	,ISNULL(a.receiverTel		,'''') receiverTel
	,ISNULL(a.receiverAddr1		,'''') receiverAddr1,
	(SELECT IIF(MAX(IIF(ISNULL(pri.procStep,'''')='''',0,1)) =0 ,ISNULL(a.procStep,''미완료''),  --디테일에 미처리 케이스뿐이라면 미완료
	   IIF(MAX(IIF(ISNULL(pri.procStep,'''') <> '''',0,1)) =0 , ''완료'' , ''일부완료''))  -- 처리 케이스는 있는데 미처리 케이스가 없다면 완료 , 있다면 일부완료
		FROM dbo.e_pcReqItem pri
		WHERE pri.pcReqNo= a.pcReqNo AND pri.gvComCode = @i__logComCode) procState
	,rcvLogisCode

FROM  dbo.e_pcReq  a
LEFT OUTER JOIN dbo.e_cust cust ON a.comCode = cust.comCode AND a.gvComCode = cust.custCode
LEFT OUTER JOIN dbo.e_user ur ON a.gvComCode = ur.comCode AND a.regUserId = ur.userId --요청자
LEFT OUTER JOIN dbo.e_user ur2 ON a.comCode = ur2.comCode AND a.procUserId = ur2.userID --수락자
JOIN (SELECT pcri.comCode, pcri.gvComCode, pcri.pcReqNo, inMemo1 
        , COUNT(*) itemQty  
		FROM dbo.e_pcReqItem pcri
		WHERE pcri.comCode = @n__tkComCode AND pcri.gvComCode = @i__logComCode
		GROUP BY pcri.comCode, pcri.gvComCode, pcri.pcReqNo ,pcri.inMemo1
		) pcri ON pcri.comCode = a.comCode AND pcri.pcReqNo = a.pcReqNo
WHERE 1= 1 AND a.comCode = @n__tkComCode AND a.gvComCode = @i__logComCode 
'
IF @i__ymdIgnoreYN <> 'Y' AND @i__sYmd1 <> ''
	SET @sql = @sql + ' AND a.regYmd BETWEEN @i__sYmd1 AND @i__eYmd1 '

IF  @i__pcReqNo <> ''
SET @sql = @sql + N'   AND a.pcReqNo=  @i__pcReqNo '

IF @i__gvComCode <> ''
SET @sql = @sql + N'   AND a.gvComCode = @i__gvComCode '

IF @i__gvMgr <> ''
SET @sql = @sql + N'   AND a.gvMgr= @i__gvMgr '

IF @i__procUserId <> ''
SET @sql = @sql + N'   AND a.procUserId = @i__procUserId '

IF @i__gvPlacNo <> ''
SET @sql = @sql + N'   AND a.gvPlacNo= @i__gvPlacNo '

IF @i__procStep = '접수'
BEGIN
	SET @sql = @sql + ' AND a.procStep =''접수'' '
END
ELSE IF @i__procStep = '거부'
BEGIN
	SET @sql = @sql + ' AND a.procStep =''거부'' '
END
ELSE 
BEGIN
	SET @sql = @sql + ''
END

IF @i__procState <> ''
SET @sql = @sql +N' AND  @i__procState IN (SELECT IIF(MAX(IIF(ISNULL(pri.procStep,'''')='''',0,1)) =0 , ''미완료'',  --디테일에 미처리 케이스뿐이라면 미완료
	   IIF(MAX(IIF(ISNULL(pri.procStep,'''') <> '''',0,1)) =0 , ''완료'' , ''일부완료''))  -- 처리 케이스는 있는데 미처리 케이스가 없다면 완료 , 있다면 일부완료
		FROM dbo.e_pcReqItem pri
		WHERE pri.pcReqNo= a.pcReqNo AND pri.gvComCode = @i__logComCode) '
 


SET @sql = @sql + N' ORDER BY a.pcReqNo, a.regYmd'

print @sql
EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__sYmd1 varchar(10), @i__eYmd1 varchar(10), @i__pcReqNo varchar(50) , @i__gvComCode varchar (20) ,  @i__gvMgr varchar(20),
										@i__procUserId varchar (20), @i__procStep varchar (20)  , @i__gvPlacNo varchar (20) ,@n__tkComCode varchar (20),  @i__procState varchar(10) ', 
						@i__logComCode, @i__sYmd1 , @i__eYmd1 ,@i__pcReqNo , @i__gvComCode ,  @i__gvMgr ,@i__procUserId ,@i__procStep ,@i__gvPlacNo ,@n__tkComCode,@i__procState


RETURN
/*************************************************************************************************/
/*
SELECT
	a.comCode , --주문접수(구매접수)거래처코드
	a.pcReqNo , --주문접수(구매접수)요청번호
	a.gvComCode , -- 요청업체코드
	a.gvPlacNo ,          --요청업체 발주번호
	a.gvMgr ,  --요청업체 담당자
	a.gvMemo ,  --요청업체에서 작성한 메모
	ISNULL(a.procStep,'확인전') AS procStep,  -- 접수단계 : 수락, 거부
	a.procUserId , --단계 등록자
	a.procDate, --단계 처리일시
	a.rejectMemo , --거부사유
	--a.inMemo1 ,  --접수받은 업체 기타메모	
	a.regUserId,
	a.regYmd,
	a.regHmsg ,
	--a.uptUserId ,
	a.uptYmd,
	a.uptHmsg,
	ISNULL(ur.userName,'') AS regUserName , --등록이름 
	ISNULL(cust.custName,'') AS gvCustName ,-- 요청업체이름 
	ISNULL(ur2.userName, '') AS uptUserId 

	,ur.userName AS gvMgrName
	,ur2.userName AS procUserName
	,pcri.inMemo1 AS placeCustCode
	, pcri.itemQty

FROM  dbo.e_pcReq  a
LEFT OUTER JOIN dbo.e_cust cust ON a.comCode = cust.comCode AND a.gvComCode = cust.custCode
LEFT OUTER JOIN dbo.e_user ur ON a.gvComCode = ur.comCode AND a.regUserId = ur.userId --요청자
LEFT OUTER JOIN dbo.e_user ur2 ON a.comCode = ur2.comCode AND a.procUserId = ur2.userID --수락자
JOIN (SELECT pcri.comCode, pcri.gvComCode, pcri.pcReqNo, inMemo1, COUNT(*) itemQty 
		FROM dbo.e_pcReqItem pcri
		WHERE pcri.comCode = 'ㄱ121' AND pcri.gvComCode = 'ㅇ102'
		GROUP BY pcri.comCode, pcri.gvComCode, pcri.pcReqNo ,pcri.inMemo1
		) pcri ON pcri.comCode = a.comCode AND pcri.pcReqNo = a.pcReqNo
WHERE 1= 1 AND a.comCode = 'ㄱ121' AND a.gvComCode = 'ㅇ102'
 AND a.regYmd BETWEEN '2023-11-01' AND '2023-11-30'  ORDER BY a.pcReqNo, a.regYmd

 */