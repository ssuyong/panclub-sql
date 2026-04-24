--1.기본랙 업로드용 테이블
USE [panErp]
GO

IF OBJECT_ID('dbo.e_logisRackUpload', 'U') IS NOT NULL
	DROP TABLE dbo.e_logisRackUpload
GO

CREATE TABLE dbo.e_logisRackUpload
(
    uploadId        INT IDENTITY(1,1) PRIMARY KEY,
    batchNo         VARCHAR(50)   NOT NULL,   -- 업로드 묶음번호
    workingType     VARCHAR(20)   NOT NULL DEFAULT 'ADD',
    logComCode      VARCHAR(20)   NOT NULL,
    logUserId       VARCHAR(30)   NOT NULL,

    logisCode       VARCHAR(50)   NOT NULL,   -- 물류센터코드
    logisRackName   VARCHAR(200)  NOT NULL,   -- 기본랙명
    validYN         VARCHAR(1)    NOT NULL DEFAULT 'Y',
    memo            VARCHAR(600)  NULL,

    processYN       VARCHAR(1)    NOT NULL DEFAULT 'N',  -- N:미처리 Y:성공 E:실패
    resultCode      VARCHAR(20)   NULL,
    resultMsg       VARCHAR(500)  NULL,
    created         DATETIME      NOT NULL DEFAULT GETDATE(),
    processed       DATETIME      NULL
)
GO

--==================================================================
--2. 기본랙 일괄처리 프로시저
USE [panErp]
GO

IF OBJECT_ID('dbo.up_logisRackUploadBatch', 'P') IS NOT NULL
	DROP PROC dbo.up_logisRackUploadBatch
GO

CREATE PROC dbo.up_logisRackUploadBatch
    @i__batchNo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @uploadId        INT,
        @workingType     VARCHAR(20),
        @logComCode      VARCHAR(20),
        @logUserId       VARCHAR(30),
        @logisCode       VARCHAR(50),
        @logisRackName   VARCHAR(200),
        @validYN         VARCHAR(1),
        @memo            VARCHAR(600),
        @logisRackId     INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            uploadId,
            workingType,
            logComCode,
            logUserId,
            logisCode,
            logisRackName,
            validYN,
            ISNULL(memo, '')
        FROM dbo.e_logisRackUpload
        WHERE batchNo = @i__batchNo
          AND processYN = 'N'
        ORDER BY uploadId;

    OPEN cur;

    FETCH NEXT FROM cur INTO
        @uploadId, @workingType, @logComCode, @logUserId,
        @logisCode, @logisRackName, @validYN, @memo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @logisRackId = 0;

            IF ISNULL(@workingType, '') <> 'ADD'
            BEGIN
                UPDATE dbo.e_logisRackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '현재 업로드 배치는 ADD만 지원합니다.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @logisCode, @logisRackName, @validYN, @memo;
                CONTINUE;
            END

            IF ISNULL(@logisCode, '') = '' OR ISNULL(@logisRackName, '') = ''
            BEGIN
                UPDATE dbo.e_logisRackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '물류센터코드와 기본랙명을 입력하세요.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @logisCode, @logisRackName, @validYN, @memo;
                CONTINUE;
            END

            IF EXISTS (
                SELECT 1
                FROM dbo.e_logisRack
                WHERE comCode = @logComCode
                  AND logisCode = @logisCode
                  AND rackName = @logisRackName
            )
            BEGIN
                UPDATE dbo.e_logisRackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '동일한 이름의 기본랙이 이미 존재합니다.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @logisCode, @logisRackName, @validYN, @memo;
                CONTINUE;
            END

            EXEC dbo.up_logisRackAdd
                 @i__workingType   = @workingType,
                 @i__logComCode    = @logComCode,
                 @i__logUserId     = @logUserId,
                 @i__logisRackId   = 0,
                 @i__logisCode     = @logisCode,
                 @i__logisRackName = @logisRackName,
                 @i__memo          = @memo,
                 @i__validYN       = @validYN;

            SELECT @logisRackId = logisRackId
            FROM dbo.e_logisRack
            WHERE comCode = @logComCode
              AND logisCode = @logisCode
              AND rackName = @logisRackName;

            IF ISNULL(@logisRackId, 0) > 0
            BEGIN
                UPDATE dbo.e_logisRackUpload
                   SET processYN  = 'Y',
                       resultCode = 'OK',
                       resultMsg  = '성공',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;
            END
            ELSE
            BEGIN
                UPDATE dbo.e_logisRackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '기본랙 등록 후 결과 확인 실패',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;
            END
        END TRY
        BEGIN CATCH
            UPDATE dbo.e_logisRackUpload
               SET processYN  = 'E',
                   resultCode = 'ERR',
                   resultMsg  = ERROR_MESSAGE(),
                   processed  = GETDATE()
             WHERE uploadId = @uploadId;
        END CATCH;

        FETCH NEXT FROM cur INTO
            @uploadId, @workingType, @logComCode, @logUserId,
            @logisCode, @logisRackName, @validYN, @memo;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT *
    FROM dbo.e_logisRackUpload
    WHERE batchNo = @i__batchNo
    ORDER BY uploadId;
END
GO

--=================================================================
--3. 랙 업로드용 테이블
USE [panErp]
GO

IF OBJECT_ID('dbo.e_rackUpload', 'U') IS NOT NULL
	DROP TABLE dbo.e_rackUpload
GO

CREATE TABLE dbo.e_rackUpload
(
    uploadId        INT IDENTITY(1,1) PRIMARY KEY,
    batchNo         VARCHAR(50)   NOT NULL,
    workingType     VARCHAR(20)   NOT NULL DEFAULT 'ADD',
    logComCode      VARCHAR(20)   NOT NULL,
    logUserId       VARCHAR(30)   NOT NULL,

    storageCode     VARCHAR(50)   NOT NULL,   -- 창고코드
    rackName        VARCHAR(200)  NOT NULL,   -- 랙명
    barcode         VARCHAR(50)   NULL,
    validYN         VARCHAR(1)    NOT NULL DEFAULT 'Y',
    memo            VARCHAR(600)  NULL,

    logisCode       VARCHAR(50)   NULL,       -- 자동조회 결과 저장
    logisRackId     INT           NULL,       -- 자동매핑 결과 저장

    processYN       VARCHAR(1)    NOT NULL DEFAULT 'N',   -- N:미처리 Y:성공 E:실패
    resultCode      VARCHAR(20)   NULL,
    resultMsg       VARCHAR(500)  NULL,
    created         DATETIME      NOT NULL DEFAULT GETDATE(),
    processed       DATETIME      NULL
)
GO

--=================================================================
--4. 랙 일괄처리 프로시저
USE [panErp]
GO

IF OBJECT_ID('dbo.up_rackUploadBatch', 'P') IS NOT NULL
	DROP PROC dbo.up_rackUploadBatch
GO

CREATE PROC dbo.up_rackUploadBatch
    @i__batchNo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @uploadId        INT,
        @workingType     VARCHAR(20),
        @logComCode      VARCHAR(20),
        @logUserId       VARCHAR(30),
        @storageCode     VARCHAR(50),
        @rackName        VARCHAR(200),
        @barcode         VARCHAR(50),
        @validYN         VARCHAR(1),
        @memo            VARCHAR(600),
        @logisCode       VARCHAR(50),
        @logisRackId     INT,
        @rackCode        VARCHAR(50);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            uploadId,
            workingType,
            logComCode,
            logUserId,
            storageCode,
            rackName,
            ISNULL(barcode, ''),
            validYN,
            ISNULL(memo, '')
        FROM dbo.e_rackUpload
        WHERE batchNo = @i__batchNo
          AND processYN = 'N'
        ORDER BY uploadId;

    OPEN cur;

    FETCH NEXT FROM cur INTO
        @uploadId, @workingType, @logComCode, @logUserId,
        @storageCode, @rackName, @barcode, @validYN, @memo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @logisCode   = NULL;
            SET @logisRackId = 0;
            SET @rackCode    = NULL;

            IF ISNULL(@workingType, '') <> 'ADD'
            BEGIN
                UPDATE dbo.e_rackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '현재 업로드 배치는 ADD만 지원합니다.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @storageCode, @rackName, @barcode, @validYN, @memo;
                CONTINUE;
            END

            IF ISNULL(@storageCode, '') = '' OR ISNULL(@rackName, '') = ''
            BEGIN
                UPDATE dbo.e_rackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '창고코드와 랙명을 입력하세요.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @storageCode, @rackName, @barcode, @validYN, @memo;
                CONTINUE;
            END

            SELECT @logisCode = ISNULL(s.logisCode, '')
            FROM dbo.e_storage s
            WHERE s.comCode = @logComCode
              AND s.storageCode = @storageCode;

            IF @logisCode IS NULL
            BEGIN
                UPDATE dbo.e_rackUpload
                   SET processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '존재하지 않는 창고코드입니다.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @storageCode, @rackName, @barcode, @validYN, @memo;
                CONTINUE;
            END

            IF EXISTS (
                SELECT 1
                FROM dbo.e_rack
                WHERE comCode = @logComCode
                  AND storageCode = @storageCode
                  AND rackName = @rackName
            )
            BEGIN
                UPDATE dbo.e_rackUpload
                   SET logisCode  = @logisCode,
                       processYN  = 'E',
                       resultCode = 'ERR',
                       resultMsg  = '해당 창고에 이미 동일한 이름의 랙이 존재합니다.',
                       processed  = GETDATE()
                 WHERE uploadId = @uploadId;

                FETCH NEXT FROM cur INTO
                    @uploadId, @workingType, @logComCode, @logUserId,
                    @storageCode, @rackName, @barcode, @validYN, @memo;
                CONTINUE;
            END

            IF ISNULL(@logisCode, '') <> ''
            BEGIN
                SELECT @logisRackId = lr.logisRackId
                FROM dbo.e_logisRack lr
                WHERE lr.comCode = @logComCode
                  AND lr.logisCode = @logisCode
                  AND lr.rackName = @rackName;

                IF ISNULL(@logisRackId, 0) = 0
                BEGIN
                    UPDATE dbo.e_rackUpload
                       SET logisCode  = @logisCode,
                           processYN  = 'E',
                           resultCode = 'ERR',
                           resultMsg  = '기본랙 자동매핑 실패: 창고의 물류센터에 해당 랙명이 기본랙으로 등록되어 있지 않습니다.',
                           processed  = GETDATE()
                     WHERE uploadId = @uploadId;

                    FETCH NEXT FROM cur INTO
                        @uploadId, @workingType, @logComCode, @logUserId,
                        @storageCode, @rackName, @barcode, @validYN, @memo;
                    CONTINUE;
                END
            END
            ELSE
            BEGIN
                SET @logisRackId = 0;
            END

            EXEC dbo.up_rackAdd
                 @i__workingType = @workingType,
                 @i__logComCode  = @logComCode,
                 @i__logUserId   = @logUserId,
                 @i__storageCode = @storageCode,
                 @i__rackCode    = '',
                 @i__rackName    = @rackName,
                 @i__barcode     = @barcode,
                 @i__memo        = @memo,
                 @i__validYN     = @validYN,
                 @i__logisRackId = @logisRackId;

            SELECT @rackCode = rackCode
            FROM dbo.e_rack
            WHERE comCode = @logComCode
              AND storageCode = @storageCode
              AND rackName = @rackName;

            IF ISNULL(@rackCode, '') <> ''
            BEGIN
                UPDATE dbo.e_rackUpload
                   SET logisCode   = @logisCode,
                       logisRackId = @logisRackId,
                       processYN   = 'Y',
                       resultCode  = 'OK',
                       resultMsg   = '성공',
                       processed   = GETDATE()
                 WHERE uploadId = @uploadId;
            END
            ELSE
            BEGIN
                UPDATE dbo.e_rackUpload
                   SET logisCode   = @logisCode,
                       logisRackId = @logisRackId,
                       processYN   = 'E',
                       resultCode  = 'ERR',
                       resultMsg   = '랙 등록 후 결과 확인 실패',
                       processed   = GETDATE()
                 WHERE uploadId = @uploadId;
            END
        END TRY
        BEGIN CATCH
            UPDATE dbo.e_rackUpload
               SET processYN  = 'E',
                   resultCode = 'ERR',
                   resultMsg  = ERROR_MESSAGE(),
                   processed  = GETDATE()
             WHERE uploadId = @uploadId;
        END CATCH;

        FETCH NEXT FROM cur INTO
            @uploadId, @workingType, @logComCode, @logUserId,
            @storageCode, @rackName, @barcode, @validYN, @memo;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT *
    FROM dbo.e_rackUpload
    WHERE batchNo = @i__batchNo
    ORDER BY uploadId;
END
GO
--==================================================================
EXEC dbo.up_logisRackUploadBatch @i__batchNo = '20260423_01'

EXEC dbo.up_rackUploadBatch @i__batchNo = '20260423_02'
