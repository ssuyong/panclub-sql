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
	AND m.definition LIKE '%classCode%'  -- 여기에 찾고자 하는 단어
ORDER BY 
    o.name;


	CREATE PROC [dbo].[up_itemList]  /***************************************************************  
	설명 : 상품 목록           작성 : 2022.11.10 함승구  - LIST_QRY         
	2023.02.14  -  위탁거래처 추가 @i__cosignCustCode      2023.03.06 hsg - srchEqualItemNo 추가 . itemNo가 like가 아닌 = 로 검색하도록 추가. 
	부품 찾는 팝업창이 뜨지 않도록..      2023.04.04 hsg - class에 중고,리퍼 추가      2023.05.13 hsg - dcExceptYN 추가. 할인제외      
	2023.06.07 hsg - #item 등록 시 order by절이 필요없어서 삭제      2023.06.09 hsg - 재고수량,재고위치 가져오는 쿼리 변경      
	2023.07.24 hsg - makerCode가 없을때 코드테이블과 조인하는상황 처리 수정 (JOIN -> LEFT OUTER JOIN)      
	2023.11.10 supi - @i__immediateRlYN 주문즉시출고 추가      2023.12.20 hsg - 품번,품명 조회시 앞에 와이드카드 넣은것 제거. 
	성능향상 위해..      2024.04.12 supi - 수동입출고에서 품번치고 엔터치는경우 workingType가 STOCKWRUP_LIST로 들어오며 그경우 바코드입력경우 
	반영되서 조회      2024.04.16 supi - 공유부품과 일반 부품 쿼리 하나로 합침      2024.05.08 hsg - 테스트업체(zzz) 인경우 comCode와 comName 비노출 처리 
	2024.09.13 hsg - comCode = 'ㄱ000' 으로 박혀있던 코드를 @ErpOperateComCode 값을 가져와서 설정. 코드 박혀있는것 제거하기 위해 함수 만들어 처리     
	- comName 가져오는 e_cust 를 join에서 left join으로 변경       2024.09.30 hsg - shareYN 값이 변경되어 수정. Y:관계사공유, A:4car사용업체 공유, 
	N:공유 안함    ex)  select * from panErp.dbo._SPLOG order by created desc    
	select * from _SPLOG where sp='panErp.dbo.up_itemList' order by created desc    panErp.dbo.up_itemList @i__workingType='STOCKWRUP_LIST',    
	@i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-08-19',      @i__eYmd1='2024-09-19',      @i__sYmd2='',    @i__eYmd2='',   
	@i__logComCode='ㄱ121',    @i__logUserId='pjy1196',    @i__itemId=0,    @i__itemCode='',    @i__itemNo='41007374528',    @i__factoryNo='',   
	@i__itemName='',      @i__classCode='',    @i__shareYN='',    @i__consignCustCode='',    @i__srchEqualItemNo='41007374528',    @i__makerCode='',   
	@i__immediateRlYN=''  go  panErp.dbo.up_itemList_hsgTEST @i__workingType='STOCKWRUP_LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',   
	@i__sYmd1='2024-08-19',      @i__eYmd1='2024-09-19',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',    @i__logUserId='pjy1196',   
	@i__itemId=0,    @i__itemCode='',    @i__itemNo='41007374528',    @i__factoryNo='',    @i__itemName='',      @i__classCode='',    
	@i__shareYN='',    @i__consignCustCode='',    @i__srchEqualItemNo='41007374528',    @i__makerCode='',    @i__immediateRlYN=''     
	panErp.dbo.up_itemList @i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2024-09-14',     
	@i__eYmd1='2024-10-14',      @i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㅋ127',      @i__logUserId='khs77',    @i__itemId=0,   
	@i__itemCode='',    @i__itemNo='',    @i__factoryNo='',    @i__itemName='',      @i__classCode='',    @i__shareYN='',    
	@i__consignCustCode='',    @i__srchEqualItemNo='',    @i__makerCode='',    @i__immediateRlYN=''    panErp.dbo.up_itemList 
	@i__workingType='LIST',    @i__page=0,    @i__qty=0,      @i__orderBy='',    @i__sYmd1='2025-05-18',      @i__eYmd1='2025-06-18',  
	@i__sYmd2='',    @i__eYmd2='',    @i__logComCode='ㄱ121',    @i__logUserId='jyspan',    @i__itemId=0,    @i__itemCode='',    
	@i__itemNo='003 990 9497',   @i__factoryNo='',    @i__itemName='',      @i__classCode='',    @i__shareYN='',    @i__consignCustCode='',   
	@i__srchEqualItemNo='003 990 9497',     @i__makerCode='',    @i__immediateRlYN=''     
	***************************************************************/   
	
	@i__workingType varchar(20) = '',   @i__page int = 1,       
	--페이지 : 몇번째 다음 부터   @i__qty int = 10,       --레코드 수 : 몇개 출력   @i__orderBy varchar(20) = '',   
	@i__ymdIgnoreYN varchar(1) = 'N',      @i__sYmd1 varchar(10) = '',   @i__eYmd1 varchar(10) = '',   @i__sYmd2 varchar(10) = '',   @i__eYmd2 varchar(10) = ''     ,@i__logComCode varchar(20) = ''    --로그인한 회사코드   ,@i__logUserId varchar(20) = ''    --로그인한 사용자아이디     ,@i__itemId bigint = 0   --   ,@i__itemCode varchar(20) = ''       ,@i__itemNo varchar(50) = ''      ,@i__factoryNo varchar(50) = ''   ,@i__itemName varchar(100) = ''   ,@i__makerCode varchar(100) = ''     ,@i__classCode varchar(10) = '' --클래스코드   ,@i__shareYN varchar(1) = '' -- 정보공유여부   ,@i__consignCustCode varchar(20) = '' -- 위탁거래처     ,@i__srchEqualItemNo varchar(50) = ''    ,@I__immediateRlYN varchar(1) =''    WITH RECOMPILE  AS    SET NOCOUNT ON   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      --로그--------------------------  INSERT INTO panErp.dbo._SPLOG( sp,params)   VALUES('panErp.dbo.up_itemList',    '@i__workingType='''+ISNULL(@i__workingType,'')+''',    @i__page='+cast(ISNULL(@i__page,0) as varchar(100))+',    @i__qty='+cast(ISNULL(@i__qty,0) as varchar(100))+',      @i__orderBy='''+ISNULL(@i__orderBy,'')+''',    @i__sYmd1='''+ISNULL(@i__sYmd1,'')+''',      @i__eYmd1='''+ISNULL(@i__eYmd1,'')+''',      @i__sYmd2='''+ISNULL(@i__sYmd2,'')+''',    @i__eYmd2='''+ISNULL(@i__eYmd2,'')+''',    @i__logComCode='''+cast(ISNULL(@i__logComCode,'') as varchar(100))+''',    @i__logUserId='''+cast(ISNULL(@i__logUserId,'') as varchar(100))+''',    @i__itemId='+cast(ISNULL(@i__itemId,'0') as varchar(100))+',    @i__itemCode='''+cast(ISNULL(@i__itemCode,'') as varchar(100))+''',    @i__itemNo='''+cast(ISNULL(@i__itemNo,'') as varchar(100))+''',    @i__factoryNo='''+cast(ISNULL(@i__factoryNo,'') as varchar(100))+''',    @i__itemName='''+cast(ISNULL(@i__itemName,'') as varchar(100))+''',      @i__classCode='''+ISNULL(@i__classCode,'')+''',    @i__shareYN='''+ISNULL(@i__shareYN,'')+''',    @i__consignCustCode='''+ISNULL(@i__consignCustCode,'')+''',    @i__srchEqualItemNo='''+ISNULL(@i__srchEqualItemNo,'')+''',    @i__makerCode='''+ISNULL(@i__makerCode,'')+''',    @i__immediateRlYN='''+ISNULL(@i__immediateRlYN,'')+''''     )  ---------------------------------    --DECLARE @subPage INT  --IF @i__page = 0   -- SET @subPage = 1  --ELSE  -- SET @subPage = (@i__page - 1) * @i__qty    SET @i__itemNo = REPLACE(@i__itemNo, ' ', '')  SET @i__srchEqualItemNo = REPLACE(@i__srchEqualItemNo, ' ', '')    DECLARE @sql nvarchar(max)  SET @sql = N''    IF @i__workingType = 'LIST' OR @i__workingType = 'STOCKWRUP_LIST'   GOTO LIST_QRY   --         RETURN  /*************************************************************************************************/  LIST_QRY:     -- SELECT * FROM [222.239.254.244,20486].partManager.dbo.T0000 WHERE C001='1000' AND C003 <> '**'  -- SELECT * FROM e_code WHERE mCode = '1000' AND code <>''    -- 카윈의 상품등록: 팬클럽에 등록이 안된 경우 등록처리, 수정된 경우 수정처리, 삭제된 경우 삭제 처리  --IF @i__logComCode = 'ㄱ000'  --BEGIN      --SELECT top 100 *    --FROM [222.239.254.244,20486].partManager.dbo.T0102 cw   ----LEFT      -- 등록   /*   INSERT INTO dbo.e_item( comCode , --itemId ,            itemCode , itemNo ,  factoryNo ,   carType ,  itemName , itemNameEn , makerCode ,      genuineYN ,       itemExchangeId  ,     brandCode, saleBrandCode, centerPrice , inPrice , salePrice , regUserId , regYmd,  regHms , uptUserId , uptYmd, uptHms,     productYear ,  home ,  equipPlace ,  color ,  shine ,       weight,  cbm  ,  width,  depth,  height     )    SELECT  'ㄱ000' , --@i__logComCode,   --회사코드     '',     cw.C001,   cw.C001,   cw.C003,   cw.C004,   cw.C005,   cw.C000,        CASE WHNE cw.C000=''AT'' THEN ''N'' ELSE ''Y'' END ,     0,     cw.C000, cw.C000,      cw.C010,      cw.C009, cw.C010,         '',         cw.C007,              '',    '',  cw.C013,  '',     '','','','','',     0, 0, 0, 0,0    FROM [222.239.254.244,20486].partManager.dbo.T0102 cw    LEFT OUTER JOIN dbo.e_item c ON c.comCode = 'ㄱ000' AND cw.C000 = c.makerCode AND cw.C001 = c.itemNo    WHERE c.itemId IS NULL       -- 수정   UPDATE c SET -- SELECT *      codeName = cw.C004     ,value1 = cw.C005     ,value2 = cw.C006     ,value3 = cw.C007    FROM [222.239.254.244,20486].partManager.dbo.T0000 cw    JOIN dbo.e_code c ON  c.comCode = 'ㄱ000' AND cw.C003 = c.code AND c.mCode = '1000' AND c.code <>''        WHERE (cw.C005 <> c.value1 OR cw.C006 <> c.value2 OR cw.C007 <> c.value3 )     -- 삭제   DELETE c -- SELECT *   FROM dbo.e_code c   LEFT OUTER JOIN [222.239.254.244,20486].partManager.dbo.T0000 cw  ON cw.C003 = c.code AND cw.C001='1000' AND cw.C003 <> '**'    WHERE  c.comCode = 'ㄱ000' AND c.mCode = '1000' AND c.code <>''      AND cw.C001 IS NULL     */    --END    CREATE TABLE #item(   comCode varchar(50) NOT NULL,   itemId bigint NOT NULL primary key,   itemCode varchar(50) NOT NULL,   itemNo varchar(50) NOT NULL,   factoryNo varchar(50) NOT NULL,   carType varchar(100) NOT NULL,   itemName varchar(100) NOT NULL,   itemNameEn varchar(100) NOT NULL,   makerCode varchar(20) NOT NULL,   brandCode varchar(20) NOT NULL,   saleBrandCode varchar(20) NOT NULL,   genuineYN varchar(1) NOT NULL,   itemExchangeId bigint NOT NULL,   centerPrice int NOT NULL,   inPrice int NOT NULL,   salePrice int NOT NULL,   regUserId varchar(30) NOT NULL,   regYmd varchar(10) NOT NULL,   regHms varchar(8) NOT NULL,   uptUserId varchar(30) NOT NULL,   uptYmd varchar(10) NOT NULL,   uptHms varchar(8) NOT NULL,   productYear varchar(20) NULL,   home varchar(50) NULL,   equipPlace varchar(100) NULL,   color varchar(50) NULL,   shine tinyint NULL,   weight numeric(6, 3) NULL,   cbm numeric(8, 5) NULL,   width numeric(5, 2) NULL,   depth numeric(5, 2) NULL,   height numeric(5, 2) NULL,   classCode varchar(10) NULL,   shareYN varchar(50) NULL,   consignCustCode varchar(50) NULL,   stockQty int,   stockPlace varchar(600)     ,dcExceptYN varchar(10)     ,immediateRlYN varchar(1)   )      --CREATE NONCLUSTERED INDEX TIX_item_itemNo ON #item(itemNo)   --CREATE NONCLUSTERED INDEX TIX_item_comCode ON #item(comCode)     --CREATE NONCLUSTERED INDEX TIX_item_consignCustCode ON #item(consignCustCode)     --자사 품목  SET @sql = N'  SELECT   a.comCode ,    a.itemId ,   a.itemCode ,   a.itemNo ,  --품번   a.factoryNo ,  --공장품번   a.carType , --차종   a.itemName ,   a.itemNameEn ,   a.makerCode , --제조사코드   a.brandCode,   a.saleBrandCode,   a.genuineYN , --정품여부   a.itemExchangeId  ,   a.centerPrice ,   a.inPrice ,   a.salePrice ,   a.regUserId ,   a.regYmd , a.regHms,   a.uptUserId ,   a.uptYmd, a.uptHms,   a.productYear , --생산년도   a.home , --원산지   a.equipPlace , --장착위치   a.color , --색상   a.shine , -- 광택0:알수없음, 1:광택, 2:무광택   a.weight, --무게   a.cbm  , -- cbm   a.width, --가로,폭,너비(앞에서 볼때 좌우로~)   a.depth, --세로(앞쪽에서 뒤쪽으로의 깊이~)   a.height --높이   ,a.classCode   ,a.shareYN   ,a.consignCustCode   ,ISNULL(stock.qtyValid,0) stockQty   ,''자사재고'' stockPlace   ,ISNULL(a.dcExceptYN, ''N'') dcExceptYN   ,ISNULL(a.immediateRlYN, ''N'') immediateRlYN    FROM dbo.e_item a  LEFT OUTER JOIN dbo.vw_storType_stock stock ON a.comCode = stock.comCode AND a.itemId = stock.itemId    WHERE 1= 1 AND (a.comCode = @i__logComCode OR      (a.shareYN= ''Y'' AND a.comCode IN (SELECT comCode FROM dbo.UF_GetGroupComCode(@i__logComCode))) OR      a.shareYN= ''A''      )  '    --AND (a.comCode = @i__logComCode OR  --    (a.shareYN= ''Y'' AND a.comCode <> @i__logComCode )   --    )   --,CASE WHEN a.shareYN = ''Y'' THEN ''관계사 공유''    --      WHEN a.shareYN = ''A'' THEN ''4car사용업체 공유''    --      ELSE ''공유 안함'' END shareYN  --,CASE WHEN a.shareYN = ''Y'' THEN ''Y'' ELSE '''' END shareYN   --,cust.custName comName   --,ISNULL(stock.stockQty,0) stockQty   --,ISNULL(stock.stockPlace,'''') stockPlace      --JOIN dbo.e_cust cust ON a.comCode = ''ㄱ000'' AND a.comCode = cust.custCode     --LEFT OUTER JOIN (  SELECT z.comCode, z.itemId, SUM(z.stockQty) stockQty, MAX(stockPlace) stockPlace  --      FROM   --      ( SELECT comCode, itemid, ISNULL(stockQty,0) stockQty   --        , STUFF((  --         SELECT DISTINCT '','' + storageName  --         FROM dbo.e_storage stor  --         WHERE stor.storageCode = sn.storCode  --         FOR XML PATH('''')  --       ),1,1,'''') AS stockPlace  --       FROM dbo.e_stockNow sn  --      )  z  --     GROUP BY z.comCode, z.itemId  --    ) stock ON a.itemID =  stock.itemId    IF @i__itemId <> ''  SET @sql = @sql + N'   AND a.itemId= @i__itemId '    IF @i__itemCode <> ''  SET @sql = @sql + ' AND a.itemCode LIKE '''+@i__itemCode+'%'' '   --SET @sql = @sql + ' AND a.itemCode LIKE ''%'+@i__itemCode+'%'' '       IF @i__itemNo <> ''    BEGIN   IF @i__workingType = 'STOCKWRUP_LIST'   --수동입출고에서의 경우   SET @sql = @sql + N'  AND a.itemNo IN (SELECT itemNo FROM dbo.UF_GetBarcodeItemNo('''+@i__itemNo+'''))  '    ELSE   SET @sql = @sql + N'  AND a.itemNo LIKE '''+@i__itemNo+'%'' '     --SET @sql = @sql + N'  AND a.itemNo LIKE ''%'+@i__itemNo+'%'' '  END    --IF @i__itemNo <> ''  --SET @sql = @sql + N'  AND a.itemNo LIKE '''+@i__itemNo+'%'' '   --SET @sql = @sql + N'  AND a.itemNo LIKE ''%'+@i__itemNo+'%'' '     IF @i__srchEqualItemNo <> '' AND @i__workingType <> 'STOCKWRUP_LIST'  BEGIN  -- IF @i__workingType = 'STOCKWRUP_LIST'   --수동입출고에서의 경우  -- SET @sql = @sql + N'  AND a.itemNo IN (SELECT itemNo FROM dbo.UF_GetBarcodeItemNo('''+@i__itemNo+'''))  '   -- ELSE   SET @sql = @sql + N'  AND a.itemNo = @i__srchEqualItemNo '   END    --IF @i__srchEqualItemNo <> ''  --SET @sql = @sql + N'  AND a.itemNo = @i__srchEqualItemNo '     IF @i__itemName <> ''  SET @sql = @sql + ' AND (a.itemName LIKE '''+@i__itemName+'%'' OR a.itemNameEn LIKE '''+@i__itemName+'%'' ) '   --SET @sql = @sql + ' AND (a.itemName LIKE '''+@i__itemName+'%'' OR a.itemNameEn LIKE '''+@i__itemName+'%'' ) '     IF @i__makerCode <> ''  SET @sql = @sql + N'   AND a.makerCode= @i__makerCode '    IF @i__classCode <> ''  SET @sql = @sql + N'   AND a.classCode= @i__classCode '    IF @i__shareYN <> ''  SET @sql = @sql + N'   AND a.shareYN= @i__shareYN '    if @i__consignCustCode <> ''  SET @sql = @sql + N'   AND a.consignCustCode= @i__consignCustCode '    if @i__immediateRlYN = 'Y'  SET @sql = @sql + N'   AND a.immediateRlYN= @i__immediateRlYN '    --SET @sql = @sql + N' ORDER BY a.itemNO , a.makerCode'    print @sql    INSERT INTO #item ( comCode , itemId , itemCode , itemNo ,  factoryNo ,  carType , itemName , itemNameEn , makerCode , brandCode, saleBrandCode, genuineYN , itemExchangeId  ,   centerPrice , inPrice , salePrice , regUserId , regYmd , a.regHms, uptUserId , uptYmd, a.uptHms, productYear , home , equipPlace ,  color , shine , weight, cbm  ,  width,  depth,  height    ,classCode ,shareYN ,consignCustCode, stockQty, stockPlace , dcExceptYN , immediateRlYN)  EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, @i__makerCode varchar(100), @i__classCode varchar(10), @i__shareYN varchar(50), @i__consignCustCode varchar(50), @i__srchEqualItemNo varchar(50) , @i__immediateRlYN varchar(1)',         @i__logComCode, @i__itemId, @i__makerCode, @i__classCode, @i__shareYN, @i__consignCustCode, @i__srchEqualItemNo, @i__immediateRlYN    /*          -- 공유품목        SET @sql = N'  SELECT   a.comCode ,   a.itemId ,   a.itemCode ,   a.itemNo ,  --품번   a.factoryNo ,  --공장품번   a.carType , --차종   a.itemName ,   a.itemNameEn ,   a.makerCode , --제조사코드   a.brandCode,   a.saleBrandCode,   a.genuineYN , --정품여부   a.itemExchangeId  ,   a.centerPrice ,   a.inPrice ,   a.salePrice ,   a.regUserId ,   a.regYmd , a.regHms,   a.uptUserId ,   a.uptYmd, a.uptHms,   a.productYear , --생산년도   a.home , --원산지   a.equipPlace , --장착위치   a.color , --색상   a.shine , -- 광택0:알수없음, 1:광택, 2:무광택   a.weight, --무게   a.cbm  , -- cbm   a.width, --가로,폭,너비(앞에서 볼때 좌우로~)   a.depth, --세로(앞쪽에서 뒤쪽으로의 깊이~)   a.height --높이   ,a.classCode   ,CASE WHEN a.shareYN = ''Y'' THEN ''Y'' ELSE '''' END shareYN   --,a.cnosignCustCode  -- 공유의 경우 위탁업체 정보 비노출   ,''ㄱㄱㄱㄱ'' consignCustCode   --,ISNULL(stock.stockQty,0) stockQty   --,ISNULL(stock.stockPlace,'''') stockPlace   ,ISNULL(stock.qtyValid,0) stockQty   ,''공유재고'' stockPlace     ,ISNULL(a.dcExceptYN, ''N'') dcExceptYN   ,ISNULL(a.immediateRlYN, ''N'') immediateRlYN  FROM dbo.e_item a  --JOIN dbo.e_cust cust ON a.comCode = cust.custCode   --LEFT OUTER JOIN ( SELECT comCode, itemid, ISNULL(SUM(stockQty),0) stockQty FROM dbo.e_stockNow GROUP BY comCode, itemId) stock ON a.comCode = stock.comCode AND a.itemID =  stock.itemId  --LEFT OUTER JOIN (   --    SELECT z.comCode, z.itemId, SUM(z.stockQty) stockQty, MAX(stockPlace) stockPlace  --         FROM   --         ( SELECT comCode, itemid, ISNULL(stockQty,0) stockQty   --             , STUFF((  --              SELECT DISTINCT '','' + storageName  --              FROM dbo.e_storage stor  --              WHERE stor.storageCode = sn.storCode  --              FOR XML PATH('''')  --            ),1,1,'''') AS stockPlace  --            FROM dbo.e_stockNow sn  --         )   --         z  --         GROUP BY z.comCode, z.itemId    --    --SELECT comCode, itemid, ISNULL(SUM(stockQty),0) stockQty   --    --  , STUFF((  --    --   SELECT DISTINCT '','' + storageName  --    --   FROM dbo.e_storage stor  --    --   WHERE stor.storageCode = sn.storCode  --    --   FOR XML PATH('''')  --    -- ),1,1,'''') AS stockPlace  --    -- FROM dbo.e_stockNow sn GROUP BY comCode, itemId  --    ) stock ON a.itemID =  stock.itemId  LEFT OUTER JOIN dbo.vw_storType_stock stock ON a.comCode = stock.comCode AND a.itemId = stock.itemId    WHERE 1= 1 AND a.shareYN= ''Y''    AND a.comCode <> @i__logComCode   '  IF @i__itemId <> ''  SET @sql = @sql + N'   AND a.itemId= @i__itemId '    IF @i__itemCode <> ''  SET @sql = @sql + ' AND a.itemCode LIKE '''+@i__itemCode+'%'' '   --SET @sql = @sql + ' AND a.itemCode LIKE ''%'+@i__itemCode+'%'' '       IF @i__itemNo <> ''    BEGIN   IF @i__workingType = 'STOCKWRUP_LIST'   --수동입출고에서의 경우   SET @sql = @sql + N'  AND a.itemNo IN (SELECT itemNo FROM dbo.UF_GetBarcodeItemNo('''+@i__itemNo+'''))  '    ELSE   SET @sql = @sql + N'  AND a.itemNo LIKE '''+@i__itemNo+'%'' '    --SET @sql = @sql + N'  AND a.itemNo LIKE ''%'+@i__itemNo+'%'' '  END    --IF @i__itemNo <> ''  --SET @sql = @sql + N'  AND a.itemNo LIKE '''+@i__itemNo+'%'' '   --SET @sql = @sql + N'  AND a.itemNo LIKE ''%'+@i__itemNo+'%'' '     IF @i__srchEqualItemNo <> '' AND @i__workingType <> 'STOCKWRUP_LIST'  BEGIN  -- IF @i__workingType = 'STOCKWRUP_LIST'   --수동입출고에서의 경우  -- SET @sql = @sql + N'  AND a.itemNo IN (SELECT itemNo FROM dbo.UF_GetBarcodeItemNo('''+@i__itemNo+'''))  '   -- ELSE   SET @sql = @sql + N'  AND a.itemNo = @i__srchEqualItemNo '    END    --IF @i__srchEqualItemNo <> ''  --SET @sql = @sql + N'  AND a.itemNo = @i__srchEqualItemNo '     IF @i__itemName <> ''  SET @sql = @sql + ' AND (a.itemName LIKE '''+@i__itemName+'%'' OR a.itemNameEn LIKE '''+@i__itemName+'%'' ) '   --SET @sql = @sql + ' AND (a.itemName LIKE ''%'+@i__itemName+'%'' OR a.itemNameEn LIKE ''%'+@i__itemName+'%'' ) '     IF @i__makerCode <> ''  SET @sql = @sql + N'   AND a.makerCode= @i__makerCode '    IF @i__classCode <> ''  SET @sql = @sql + N'   AND a.classCode= @i__classCode '      if @i__consignCustCode <> ''  SET @sql = @sql + N'   AND a.consignCustCode= @i__consignCustCode '    if @i__immediateRlYN = 'Y'  SET @sql = @sql + N'   AND a.immediateRlYN= @i__immediateRlYN '      --SET @sql = @sql + N' ORDER BY a.itemNO , a.makerCode'    print @sql    INSERT INTO #item ( comCode , itemId , itemCode , itemNo ,  factoryNo ,  carType , itemName , itemNameEn , makerCode , brandCode, saleBrandCode, genuineYN , itemExchangeId  ,   centerPrice , inPrice , salePrice , regUserId , regYmd , a.regHms, uptUserId , uptYmd, a.uptHms, productYear , home , equipPlace ,  color , shine , weight, cbm  ,  width,  depth,  height    ,classCode ,shareYN ,consignCustCode , stockQty, stockPlace , dcExceptYN ,immediateRlYN)  EXEC SP_EXECUTESQL @sql, N'@i__logComCode  varchar(20), @i__itemId bigint, @i__makerCode varchar(100), @i__classCode varchar(10), @i__shareYN varchar(1), @i__consignCustCode varchar(50), @i__srchEqualItemNo varchar(50) , @i__immediateRlYN varchar(1)',         @i__logComCode, @i__itemId, @i__makerCode, @i__classCode, @i__shareYN, @i__consignCustCode, @i__srchEqualItemNo , @i__immediateRlYN    */    --2024.09.13  DECLARE @ErpOperateComCode varchar(50) =  ''  SELECT @ErpOperateComCode= comCode from dbo.UF_ErpOperate('')      
	SELECT   CASE WHEN @i__logComCode = 'zzz' THEN '--' ELSE a.comCode END comCode,   --a.comCode ,   a.itemId ,   a.itemCode ,   
	a.itemNo ,  --품번   a.factoryNo ,  --공장품번   a.carType , --차종   CASE WHEN a.itemName = '' THEN a.itemNameEn ELSE a.itemName END itemName,   a.itemNameEn ,   a.makerCode , --제조사코드   a.brandCode,   a.saleBrandCode,   a.genuineYN , --정품여부   a.itemExchangeId  ,   a.centerPrice ,   a.inPrice ,   a.salePrice ,   a.regUserId ,   a.regYmd , a.regHms,   a.uptUserId ,   a.uptYmd, a.uptHms,   a.productYear , --생산년도   a.home , --원산지   a.equipPlace , --장착위치   a.color , --색상   a.shine , -- 광택0:알수없음, 1:광택, 2:무광택   a.weight, --무게   a.cbm  , -- cbm   a.width, --가로,폭,너비(앞에서 볼때 좌우로~)   a.depth, --세로(앞쪽에서 뒤쪽으로의 깊이~)   a.height --높이   ,ISNULL(a.classCode,'') classCode   ,
	CASE a.classCode WHEN 'GN' THEN '정품'                     
	WHEN 'AM' THEN '애프터마켓'          WHEN 'RM' THEN '재제조'          WHEN 'UD' THEN '중고'          WHEN 'RF' THEN '리퍼'          WHEN 'ET' THEN '기타'           ELSE '' END className   ,a.shareYN   ,ISNULL(a.consignCustCode,'') consignCustCode   --,cust.custName comName   ,CASE WHEN @i__logComCode = 'zzz' THEN '' ELSE cust.custName END comName   ,ISNULL(con.custName,'') consignCustName,a.stockQty   ,a.stockPlace     ,b.codeName AS makerName   ,a.dcExceptYN   ,a.immediateRlYN       FROM #item a   --JOIN dbo.e_cust cust ON cust.comCode = 'ㄱ000' AND a.comCode = cust.custCode   --품목소유거래처  LEFT JOIN dbo.e_cust cust ON cust.comCode = @ErpOperateComCode AND a.comCode = cust.custCode   --품목소유거래처. 2024.09.13 위거를 이걸로 변경.  LEFT JOIN dbo.e_cust con  ON a.comCode = con.comCode AND a.consignCustCode = con.custCode  --위탁거래처    LEFT OUTER JOIN dbo.e_code b ON a.comCode = b.comCode AND b.mCode='1000' AND a.makerCode = b.code -- 제조명 추가 장윤상  ORDER BY a.itemNo        RETURN  /*************************************************************************************************/    




	classCode 좀 있다가 하자, 

	SELECT t.name AS table_name,
       s.name AS schema_name,
       c.name AS column_name
FROM sys.columns c
JOIN sys.tables t   ON c.object_id = t.object_id
JOIN sys.schemas s  ON t.schema_id = s.schema_id
WHERE c.name = 'classCode'
ORDER BY s.name, t.name;

select * from dbo.e_itemHis
where comCode = 'ㄱ000';


select * from dbo.e_item
where itemNo in (
'51127178184',
'51117142156',
'51117210451',
'4G0807065AGRU',
'20488575259999',
'8K0821106A',
'21288015409999',
'20488022499999',
'5N0807217ERGRU',
'BB5Z16005A',
'20488045409999',
'20488009499999',
'8K0821106J',
'631019HS0A',
'20488000239744',
'5215933911'
) 
  --and classCode != 'GN'
;

--잘못 판단하여 다음과 같이 AM을 GN 으로 바꿈
--update dbo.e_item
set classCode = 'GN'
where itemNo in (
'51127178184',
'51117142156',
'51117210451',
'4G0807065AGRU',
'20488575259999',
'8K0821106A',
'21288015409999',
'20488022499999',
'5N0807217ERGRU',
'BB5Z16005A',
'20488045409999',
'20488009499999',
'8K0821106J',
'631019HS0A',
'20488000239744',
'5215933911'
) 
  and classCode != 'GN'
;


select ei.* 
from dbo.e_item ei
where itemNo in (
'20488000239744',
'20488009499999',
'20488022499999',
'20488045409999',
'20488575259999',
'21288015409999',
'4G0807065AGRU',
'51117142156',
'51117210451',
'51127178184',
'5215933911',
'5N0807217ERGRU',
'631019HS0A',
'8K0821106A',
'8K0821106J',
'BB5Z16005A'
) 
  and makerCode = 'AT'
order by itemNo;

makerCode가 AT인 첫번째 itemId, itemNo
--7239783		20488000239744



--classCode: GN->AM 복구
--update dbo.e_item
set classCode = 'AM'
--select * from dbo.e_item
where itemNo in (
'20488000239744',
'20488009499999',
'20488022499999',
'20488045409999',
'20488575259999',
'21288015409999',
'4G0807065AGRU',
'51117142156',
'51117210451',
'51127178184',
'5215933911',
'5N0807217ERGRU',
'631019HS0A',
'8K0821106A',
'8K0821106J',
'BB5Z16005A'
) 
  and makerCode = 'AT'


