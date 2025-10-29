DECLARE @val NVARCHAR(100) = N'A4-04-01-01-01';

IF OBJECT_ID('tempdb..#hits') IS NOT NULL DROP TABLE #hits;
CREATE TABLE #hits(
    schema_name SYSNAME,
    table_name  SYSNAME,
    column_name SYSNAME,
    data_type   SYSNAME,
    hit_count   INT
);

DECLARE 
    @schema SYSNAME, @table SYSNAME, @col SYSNAME, @type SYSNAME,
    @sql NVARCHAR(MAX), @cnt INT;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name, ty.name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND t.temporal_type = 0
  AND ty.name IN (N'char',N'nchar',N'varchar',N'nvarchar',N'text',N'ntext')  -- 문자열만
ORDER BY s.name, t.name, c.column_id;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @col, @type;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @cnt = COUNT(*) 
                 FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
                 WHERE ' + QUOTENAME(@col) + N' = @v';

    BEGIN TRY
        SET @cnt = 0;
        EXEC sp_executesql @sql, N'@v NVARCHAR(100), @cnt INT OUTPUT', @v=@val, @cnt=@cnt OUTPUT;

        IF @cnt > 0
        BEGIN
            INSERT INTO #hits(schema_name, table_name, column_name, data_type, hit_count)
            VALUES (@schema, @table, @col, @type, @cnt);
        END
    END TRY
    BEGIN CATCH
        -- 변환/접근 오류 등은 무시하고 다음 컬럼으로 진행
    END CATCH;

    FETCH NEXT FROM cur INTO @schema, @table, @col, @type;
END

CLOSE cur; DEALLOCATE cur;

SELECT * FROM #hits ORDER BY hit_count DESC, schema_name, table_name, column_name;