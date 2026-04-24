--1) staging 테이블
USE [panErp]
GO

IF OBJECT_ID('dbo.e_stockMoveUpload', 'U') IS NOT NULL
    DROP TABLE dbo.e_stockMoveUpload
GO

CREATE TABLE dbo.e_stockMoveUpload
(
    uploadId            bigint IDENTITY(1,1) PRIMARY KEY,
    batchNo             varchar(30)    NOT NULL,
    rowNo               int            NOT NULL,

    itemId              bigint         NOT NULL,
    rackCode            varchar(50)    NOT NULL,
    afterRackCode       varchar(50)    NOT NULL,
    procQty             int            NOT NULL,
    procMemo            varchar(1000)  NULL,

    processStatus       varchar(20)    NOT NULL DEFAULT 'READY',  -- READY / PROCESSING / OK / ERR
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
--=================================================================
--2) item 요약 재계산 프로시저
USE [panErp]
GO

IF OBJECT_ID('dbo.up_stockItemRefreshOne', 'P') IS NOT NULL
    DROP PROC dbo.up_stockItemRefreshOne
GO

CREATE PROC dbo.up_stockItemRefreshOne
(
     @i__logComCode     varchar(20)
    ,@i__logUserId      varchar(30)
    ,@i__itemId         bigint
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @n__regYMD varchar(10), @n__regHMS varchar(8);
    SET @n__regYMD = CONVERT(char(10), GETDATE(), 121);
    SET @n__regHMS = CONVERT(char(8), GETDATE(), 108);

    DECLARE @stockWR TABLE
    (
        comCode varchar(50),
        itemId bigint,
        wrText varchar(200),
        PRIMARY KEY (comCode, itemId)
    );

    INSERT INTO @stockWR(comCode, itemId, wrText)
    SELECT TOP 1
           sat.comCode,
           sat.itemId,
           '[' + st.storageName + '] ' + rk.rackName + '  ' + CAST(sat.procQty as varchar(10)) + ' : ' + CONVERT(char(30), sat.created, 121)
    FROM dbo.e_stockActions sat
    JOIN dbo.e_rack rk
      ON sat.comCode = rk.comCode
     AND sat.rackCode = rk.rackCode
    JOIN dbo.e_storage st
      ON rk.comCode = st.comCode
     AND rk.storageCode = st.storageCode
    WHERE sat.actionType IN ('WH', 'RL', '발주입고', '납품출고', '반입', '반출', 'rlod', 'whri', 'rlna', 'whna')
      AND sat.comCode = @i__logComCode
      AND sat.itemId = @i__itemId
    ORDER BY sat.created DESC;

    DECLARE @stockInspec TABLE
    (
        comCode varchar(50),
        itemId bigint,
        inspecText varchar(200),
        PRIMARY KEY (comCode, itemId)
    );

    INSERT INTO @stockInspec(comCode, itemId, inspecText)
    SELECT TOP 1
           sat.comCode,
           sat.itemId,
           '[' + st.storageName + '] ' + rk.rackName + '  ' + CAST(sat.procQty as varchar(10)) + ' : ' + CONVERT(char(30), sat.created, 121)
    FROM dbo.e_stockActions sat
    JOIN dbo.e_rack rk
      ON sat.comCode = rk.comCode
     AND sat.rackCode = rk.rackCode
    JOIN dbo.e_storage st
      ON rk.comCode = st.comCode
     AND rk.storageCode = st.storageCode
    WHERE sat.actionType IN ('INSPEC', '실사', '수정입고', '수정출고')
      AND sat.comCode = @i__logComCode
      AND sat.itemId = @i__itemId
    ORDER BY sat.created DESC;

    IF EXISTS (
        SELECT 1
        FROM dbo.e_stockItem
        WHERE comCode = @i__logComCode
          AND itemId = @i__itemId
    )
    BEGIN
        UPDATE si
           SET stockQty   = ISNULL(v.stockQty, 0),
               locaMemo   = ISNULL(v.locaText, ''),
               wrMemo     = ISNULL(wr.wrText, ''),
               inspecMemo = ISNULL(isp.inspecText, ''),
               uptUserId  = @i__logUserId,
               uptYmd     = @n__regYMD,
               uptHms     = @n__regHMS
        FROM dbo.e_stockItem si
        LEFT JOIN dbo.vw_storItem_loca v
          ON si.comCode = v.comCode
         AND si.itemId  = v.itemId
        LEFT JOIN @stockWR wr
          ON si.comCode = wr.comCode
         AND si.itemId  = wr.itemId
        LEFT JOIN @stockInspec isp
          ON si.comCode = isp.comCode
         AND si.itemId  = isp.itemId
        WHERE si.comCode = @i__logComCode
          AND si.itemId  = @i__itemId;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.e_stockItem
        (
            comCode, itemId, stockQty, locaMemo, wrMemo, inspecMemo,
            regUserId, regYmd, regHms, uptUserId, uptYmd, uptHms
        )
        SELECT
            @i__logComCode,
            v.itemId,
            v.stockQty,
            v.locaText,
            wr.wrText,
            isp.inspecText,
            @i__logUserId, @n__regYMD, @n__regHMS,
            @i__logUserId, @n__regYMD, @n__regHMS
        FROM dbo.vw_storItem_loca v
        LEFT JOIN @stockWR wr
          ON v.comCode = wr.comCode
         AND v.itemId  = wr.itemId
        LEFT JOIN @stockInspec isp
          ON v.comCode = isp.comCode
         AND v.itemId  = isp.itemId
        WHERE v.comCode = @i__logComCode
          AND v.itemId  = @i__itemId;
    END
END
GO
--=================================================================
--3) 이동 전용 고속 배치 프로시저
USE [panErp]
GO

IF OBJECT_ID('dbo.up_stockMoveUploadBatchFast', 'P') IS NOT NULL
    DROP PROC dbo.up_stockMoveUploadBatchFast
GO

CREATE PROC dbo.up_stockMoveUploadBatchFast
(
     @i__batchNo        varchar(30)
    ,@i__logComCode     varchar(20)
    ,@i__logUserId      varchar(30)
    ,@i__chunkSize      int = 1000
    ,@i__stopOnError    varchar(1) = 'N'   -- Y / N
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    DECLARE
         @uploadId          bigint
        ,@itemId            bigint
        ,@rackCode          varchar(50)
        ,@afterRackCode     varchar(50)
        ,@procQty           int
        ,@procMemo          varchar(1000)
        ,@nowStorStockQty   int
        ,@moveStorStockQty  int
        ,@resultMsg         varchar(1000);

    DECLARE
         @totalCnt          int = 0
        ,@successCnt        int = 0
        ,@errorCnt          int = 0;

    DECLARE @changedItems TABLE
    (
        itemId bigint PRIMARY KEY
    );

    -------------------------------------------------------------------
    -- READY -> PROCESSING
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
    -- 대상 cursor
    -------------------------------------------------------------------
    DECLARE cur_move CURSOR LOCAL FAST_FORWARD FOR
        SELECT
             uploadId
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
        ,@itemId
        ,@rackCode
        ,@afterRackCode
        ,@procQty
        ,@procMemo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @totalCnt = @totalCnt + 1;
        SET @resultMsg = NULL;

        BEGIN TRY
            BEGIN TRAN;

            -------------------------------------------------------------------
            -- 검증
            -------------------------------------------------------------------
            IF ISNULL(@rackCode, '') = ''
                SET @resultMsg = N'출발랙이 비어 있습니다.';
            ELSE IF ISNULL(@afterRackCode, '') = ''
                SET @resultMsg = N'도착랙이 비어 있습니다.';
            ELSE IF @rackCode = @afterRackCode
                SET @resultMsg = N'출발랙과 도착랙이 같습니다.';
            ELSE IF ISNULL(@procQty, 0) <= 0
                SET @resultMsg = N'이동수량은 1 이상이어야 합니다.';
            ELSE IF NOT EXISTS (
                SELECT 1
                FROM dbo.e_rack
                WHERE comCode = @i__logComCode
                  AND rackCode = @rackCode
            )
                SET @resultMsg = N'출발랙이 존재하지 않습니다.';
            ELSE IF NOT EXISTS (
                SELECT 1
                FROM dbo.e_rack
                WHERE comCode = @i__logComCode
                  AND rackCode = @afterRackCode
            )
                SET @resultMsg = N'도착랙이 존재하지 않습니다.';

            IF @resultMsg IS NOT NULL
            BEGIN
                ROLLBACK TRAN;

                UPDATE dbo.e_stockMoveUpload
                   SET processStatus = 'ERR',
                       resultCode = 'ERR',
                       resultMsg = @resultMsg,
                       processedAt = GETDATE(),
                       modified = GETDATE()
                 WHERE uploadId = @uploadId;

                SET @errorCnt = @errorCnt + 1;

                IF @i__stopOnError = 'Y'
                    BREAK;

                FETCH NEXT FROM cur_move INTO
                     @uploadId, @itemId, @rackCode, @afterRackCode, @procQty, @procMemo;
                CONTINUE;
            END

            -------------------------------------------------------------------
            -- 출발랙 현재고 조회 + 잠금
            -------------------------------------------------------------------
            SELECT @nowStorStockQty = stockQty
            FROM dbo.e_stockRack WITH (UPDLOCK, ROWLOCK)
            WHERE comCode = @i__logComCode
              AND itemId = @itemId
              AND rackCode = @rackCode;

            IF ISNULL(@nowStorStockQty, 0) < @procQty
            BEGIN
                ROLLBACK TRAN;

                UPDATE dbo.e_stockMoveUpload
                   SET processStatus = 'ERR',
                       resultCode = 'ERR',
                       resultMsg = N'출발랙 재고가 부족하거나 재고정보가 없습니다.',
                       processedAt = GETDATE(),
                       modified = GETDATE()
                 WHERE uploadId = @uploadId;

                SET @errorCnt = @errorCnt + 1;

                IF @i__stopOnError = 'Y'
                    BREAK;

                FETCH NEXT FROM cur_move INTO
                     @uploadId, @itemId, @rackCode, @afterRackCode, @procQty, @procMemo;
                CONTINUE;
            END

            -------------------------------------------------------------------
            -- 1. 출발랙 이력 insert
            -------------------------------------------------------------------
            INSERT INTO dbo.e_stockActions
            (
                comCode, rackCode, itemId, actionType,
                procQty, beforeQty, afterQty, procMemo1, regUserId, created
            )
            VALUES
            (
                @i__logComCode, @rackCode, @itemId, 'move',
                @procQty * -1,
                @nowStorStockQty,
                @nowStorStockQty - @procQty,
                @procMemo,
                @i__logUserId,
                GETDATE()
            );

            -------------------------------------------------------------------
            -- 2. 출발랙 재고 차감
            -------------------------------------------------------------------
            UPDATE dbo.e_stockRack
               SET stockQty = stockQty - @procQty,
                   uptUserId = @i__logUserId,
                   modified = GETDATE()
             WHERE comCode = @i__logComCode
               AND itemId = @itemId
               AND rackCode = @rackCode;

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR(N'출발랙 재고 차감 실패', 16, 1);
            END

            -------------------------------------------------------------------
            -- 3. 도착랙 현재고 조회
            -------------------------------------------------------------------
            SELECT @moveStorStockQty = stockQty
            FROM dbo.e_stockRack WITH (UPDLOCK, ROWLOCK)
            WHERE comCode = @i__logComCode
              AND itemId = @itemId
              AND rackCode = @afterRackCode;

            SET @moveStorStockQty = ISNULL(@moveStorStockQty, 0);

            -------------------------------------------------------------------
            -- 4. 도착랙 이력 insert
            -------------------------------------------------------------------
            INSERT INTO dbo.e_stockActions
            (
                comCode, rackCode, itemId, actionType,
                procQty, beforeQty, afterQty, procMemo1, regUserId, created
            )
            VALUES
            (
                @i__logComCode, @afterRackCode, @itemId, 'move',
                @procQty,
                @moveStorStockQty,
                @moveStorStockQty + @procQty,
                @procMemo,
                @i__logUserId,
                GETDATE()
            );

            -------------------------------------------------------------------
            -- 5. 도착랙 재고 증가
            -------------------------------------------------------------------
            IF EXISTS (
                SELECT 1
                FROM dbo.e_stockRack
                WHERE comCode = @i__logComCode
                  AND itemId = @itemId
                  AND rackCode = @afterRackCode
            )
            BEGIN
                UPDATE dbo.e_stockRack
                   SET stockQty = stockQty + @procQty,
                       uptUserId = @i__logUserId,
                       modified = GETDATE()
                 WHERE comCode = @i__logComCode
                   AND itemId = @itemId
                   AND rackCode = @afterRackCode;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.e_stockRack
                (
                    comCode, itemId, rackCode, stockQty,
                    regUserId, created, uptUserId, modified
                )
                VALUES
                (
                    @i__logComCode, @itemId, @afterRackCode, @procQty,
                    @i__logUserId, GETDATE(), @i__logUserId, GETDATE()
                );
            END

            -------------------------------------------------------------------
            -- 완료
            -------------------------------------------------------------------
            IF NOT EXISTS (SELECT 1 FROM @changedItems WHERE itemId = @itemId)
                INSERT INTO @changedItems(itemId) VALUES (@itemId);

            UPDATE dbo.e_stockMoveUpload
               SET processStatus = 'OK',
                   resultCode = 'OK',
                   resultMsg = N'성공',
                   processedAt = GETDATE(),
                   modified = GETDATE()
             WHERE uploadId = @uploadId;

            COMMIT TRAN;
            SET @successCnt = @successCnt + 1;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRAN;

            UPDATE dbo.e_stockMoveUpload
               SET processStatus = 'ERR',
                   resultCode = 'EX',
                   resultMsg = LEFT(ERROR_MESSAGE(), 1000),
                   processedAt = GETDATE(),
                   modified = GETDATE()
             WHERE uploadId = @uploadId;

            SET @errorCnt = @errorCnt + 1;

            IF @i__stopOnError = 'Y'
                BREAK;
        END CATCH;

        FETCH NEXT FROM cur_move INTO
             @uploadId
            ,@itemId
            ,@rackCode
            ,@afterRackCode
            ,@procQty
            ,@procMemo;
    END

    CLOSE cur_move;
    DEALLOCATE cur_move;

    -------------------------------------------------------------------
    -- 변경된 itemId만 e_stockItem 재계산
    -------------------------------------------------------------------
    DECLARE @refreshItemId bigint;

    DECLARE cur_refresh CURSOR LOCAL FAST_FORWARD FOR
        SELECT itemId
        FROM @changedItems;

    OPEN cur_refresh;

    FETCH NEXT FROM cur_refresh INTO @refreshItemId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.up_stockItemRefreshOne
                 @i__logComCode = @i__logComCode,
                 @i__logUserId = @i__logUserId,
                 @i__itemId = @refreshItemId;
        END TRY
        BEGIN CATCH
            -- 요약 갱신 오류는 배치 전체를 죽이지 않음
            PRINT 'e_stockItem refresh error. itemId=' + CAST(@refreshItemId as varchar(30))
                + ', msg=' + ERROR_MESSAGE();
        END CATCH;

        FETCH NEXT FROM cur_refresh INTO @refreshItemId;
    END

    CLOSE cur_refresh;
    DEALLOCATE cur_refresh;

    -------------------------------------------------------------------
    -- 결과 반환
    -------------------------------------------------------------------
    SELECT
         @i__batchNo AS batchNo,
         @totalCnt AS processedCount,
         @successCnt AS successCount,
         @errorCnt AS errorCount;
END
GO
--=================================================================
--4) 실패건 재처리
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
--=================================================================
EXEC dbo.up_stockMoveUploadBatchFast
     @i__batchNo = '20260423_01',
     @i__logComCode = 'ㄱ121',
     @i__logUserId = 'ssuyong',
     @i__chunkSize = 15000,
     @i__stopOnError = 'N';