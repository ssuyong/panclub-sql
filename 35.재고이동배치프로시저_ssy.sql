USE [panErp]
GO

IF OBJECT_ID('dbo.e_stockMoveUpload', 'U') IS NOT NULL
    DROP TABLE dbo.e_stockMoveUpload
GO

CREATE TABLE dbo.e_stockMoveUpload
(
    uploadId            bigint IDENTITY(1,1) PRIMARY KEY,
    batchNo             varchar(30)    NOT NULL,   -- 업로드 묶음번호
    rowNo               int            NOT NULL,   -- 엑셀 행번호 또는 순번

    comCode             varchar(20)    NOT NULL,   -- 회사코드
    itemId              bigint         NOT NULL,
    rackCode            varchar(50)    NOT NULL,   -- 출발랙
    afterRackCode       varchar(50)    NOT NULL,   -- 도착랙
    procQty             int            NOT NULL,   -- 이동수량
    procMemo            varchar(1000)  NULL,       -- 메모

    processStatus       varchar(20)    NOT NULL DEFAULT 'READY',  
    -- READY / PROCESSING / OK / ERR

    resultCode          varchar(20)    NULL,
    resultMsg           varchar(1000)  NULL,

    processedAt         datetime       NULL,
    regUserId           varchar(30)    NULL,
    created             datetime       NOT NULL DEFAULT GETDATE(),
    modified            datetime       NULL
)
GO

CREATE INDEX IX_e_stockMoveUpload_01
ON dbo.e_stockMoveUpload(batchNo, processStatus, uploadId)
GO
--==========================================================
USE [panErp]
GO

IF OBJECT_ID('dbo.up_stockMoveUploadBatch', 'P') IS NOT NULL
    DROP PROC dbo.up_stockMoveUploadBatch
GO

CREATE PROC dbo.up_stockMoveUploadBatch
(
     @i__batchNo        varchar(30)
    ,@i__logComCode     varchar(20)
    ,@i__logUserId      varchar(30)
    ,@i__chunkSize      int = 500
    ,@i__stopOnError    varchar(1) = 'N'   -- Y면 오류 시 중단
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    DECLARE 
         @uploadId          bigint
        ,@comCode           varchar(20)
        ,@itemId            bigint
        ,@rackCode          varchar(50)
        ,@afterRackCode     varchar(50)
        ,@procQty           int
        ,@procMemo          varchar(1000)
        ,@oStatus           varchar(3)
        ,@oResults          varchar(250)
        ,@errMsg            varchar(1000);

    DECLARE
         @totalCnt          int = 0
        ,@successCnt        int = 0
        ,@errorCnt          int = 0;

    -------------------------------------------------------------------
    -- 1. READY 건 중 일부를 PROCESSING 으로 선점
    -------------------------------------------------------------------
    ;WITH cte AS
    (
        SELECT TOP (@i__chunkSize) *
        FROM dbo.e_stockMoveUpload WITH (READPAST, UPDLOCK, ROWLOCK)
        WHERE batchNo = @i__batchNo
          AND processStatus = 'READY'
        ORDER BY uploadId
    )
    UPDATE cte
       SET processStatus = 'PROCESSING',
           modified = GETDATE(),
           regUserId = ISNULL(regUserId, @i__logUserId);

    -------------------------------------------------------------------
    -- 2. 처리 대상 cursor
    -------------------------------------------------------------------
    DECLARE cur_move CURSOR LOCAL FAST_FORWARD FOR
        SELECT
             uploadId
            ,comCode
            ,itemId
            ,rackCode
            ,afterRackCode
            ,procQty
            ,ISNULL(procMemo, '이동(BULK)')
        FROM dbo.e_stockMoveUpload
        WHERE batchNo = @i__batchNo
          AND processStatus = 'PROCESSING'
        ORDER BY uploadId;

    OPEN cur_move;

    FETCH NEXT FROM cur_move INTO
         @uploadId
        ,@comCode
        ,@itemId
        ,@rackCode
        ,@afterRackCode
        ,@procQty
        ,@procMemo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @totalCnt = @totalCnt + 1;
        SET @oStatus = 'OK';
        SET @oResults = '';
        SET @errMsg = '';

        BEGIN TRY

            -------------------------------------------------------------------
            -- 3. 사전 검증
            -------------------------------------------------------------------
            IF ISNULL(@rackCode, '') = ''
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '출발랙이 비어 있습니다.';
            END
            ELSE IF ISNULL(@afterRackCode, '') = ''
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '도착랙이 비어 있습니다.';
            END
            ELSE IF @rackCode = @afterRackCode
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '출발랙과 도착랙이 같습니다.';
            END
            ELSE IF ISNULL(@procQty, 0) <= 0
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '이동수량은 1 이상이어야 합니다.';
            END
            ELSE IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.e_rack
                    WHERE comCode = @i__logComCode
                      AND rackCode = @rackCode
                 )
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '출발랙이 존재하지 않습니다.';
            END
            ELSE IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.e_rack
                    WHERE comCode = @i__logComCode
                      AND rackCode = @afterRackCode
                 )
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '도착랙이 존재하지 않습니다.';
            END
            ELSE IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.e_stockRack
                    WHERE comCode = @i__logComCode
                      AND itemId = @itemId
                      AND rackCode = @rackCode
                      AND stockQty >= @procQty
                 )
            BEGIN
                SET @oStatus = 'Err';
                SET @oResults = '출발랙 재고가 부족하거나 재고정보가 없습니다.';
            END

            -------------------------------------------------------------------
            -- 4. 실제 이동 처리
            -------------------------------------------------------------------
            IF @oStatus = 'OK'
            BEGIN
                EXEC dbo.up_stockItemAdd
                     @i__workingType = 'ADD'
                    ,@i__logComCode = @i__logComCode
                    ,@i__logUserId = @i__logUserId
                    ,@i__actionType = 'move'
                    ,@i__itemid = @itemId
                    ,@i__rackCode = @rackCode
                    ,@i__procQty = @procQty
                    ,@i__procMemo = @procMemo
                    ,@i__afterRackCode = @afterRackCode
                    ,@iReturnType = 'O'
                    ,@oStatus = @oStatus OUTPUT
                    ,@oResults = @oResults OUTPUT;
            END

            -------------------------------------------------------------------
            -- 5. 결과 기록
            -------------------------------------------------------------------
            IF ISNULL(@oStatus, 'Err') = 'OK'
            BEGIN
                UPDATE dbo.e_stockMoveUpload
                   SET processStatus = 'OK',
                       resultCode = 'OK',
                       resultMsg = '성공',
                       processedAt = GETDATE(),
                       modified = GETDATE()
                 WHERE uploadId = @uploadId;

                SET @successCnt = @successCnt + 1;
            END
            ELSE
            BEGIN
                UPDATE dbo.e_stockMoveUpload
                   SET processStatus = 'ERR',
                       resultCode = ISNULL(@oStatus, 'Err'),
                       resultMsg = LEFT(ISNULL(@oResults, '처리 실패'), 1000),
                       processedAt = GETDATE(),
                       modified = GETDATE()
                 WHERE uploadId = @uploadId;

                SET @errorCnt = @errorCnt + 1;

                IF @i__stopOnError = 'Y'
                    BREAK;
            END

        END TRY
        BEGIN CATCH
            SET @errMsg = ERROR_MESSAGE();

            UPDATE dbo.e_stockMoveUpload
               SET processStatus = 'ERR',
                   resultCode = 'EX',
                   resultMsg = LEFT(ISNULL(@errMsg, '예외 발생'), 1000),
                   processedAt = GETDATE(),
                   modified = GETDATE()
             WHERE uploadId = @uploadId;

            SET @errorCnt = @errorCnt + 1;

            IF @i__stopOnError = 'Y'
                BREAK;
        END CATCH;

        FETCH NEXT FROM cur_move INTO
             @uploadId
            ,@comCode
            ,@itemId
            ,@rackCode
            ,@afterRackCode
            ,@procQty
            ,@procMemo;
    END

    CLOSE cur_move;
    DEALLOCATE cur_move;

    -------------------------------------------------------------------
    -- 6. 결과 반환
    -------------------------------------------------------------------
    SELECT
         @i__batchNo AS batchNo
        ,@totalCnt AS processedCount
        ,@successCnt AS successCount
        ,@errorCnt AS errorCount;
END
GO
--==========================================================
USE [panErp]
GO

IF OBJECT_ID('dbo.up_stockMoveUploadResetErr', 'P') IS NOT NULL
    DROP PROC dbo.up_stockMoveUploadResetErr
GO

CREATE PROC dbo.up_stockMoveUploadResetErr
(
     @i__batchNo       varchar(30)
    ,@i__resetStatus   varchar(20) = 'ERR'
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.e_stockMoveUpload
       SET processStatus = 'READY',
           resultCode = NULL,
           resultMsg = NULL,
           processedAt = NULL,
           modified = GETDATE()
     WHERE batchNo = @i__batchNo
       AND processStatus = @i__resetStatus;

    SELECT @@ROWCOUNT AS resetCount;
END
GO
--==========================================================
EXEC dbo.up_stockMoveUploadBatch
     @i__batchNo = '20260422_01',
     @i__logComCode = 'ㄱ121',
     @i__logUserId = 'ssuyong',
     @i__chunkSize = 15000,
     @i__stopOnError = 'N';

--실패건 재처리
EXEC dbo.up_stockMoveUploadResetErr
     @i__batchNo = '20260422_01',
     @i__resetStatus = 'ERR';

EXEC dbo.up_stockMoveUploadBatch
     @i__batchNo = '20260422_01',
     @i__logComCode = 'ㄱ121',
     @i__logUserId = 'ssuyong',
     @i__chunkSize = 15000,
     @i__stopOnError = 'N';


