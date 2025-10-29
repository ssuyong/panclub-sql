DECLARE @v   NVARCHAR(100) = N'250925002';
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT * FROM (
                SELECT N' + QUOTENAME(s.name + N'.' + t.name,'''') + N' AS table_name,
                       N' + QUOTENAME(c.name,'''') + N' AS column_name,
                       COUNT_BIG(*) AS hit_count
                FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N'
                WHERE ' +
                CASE 
                  WHEN ty.name IN (N'char',N'nchar',N'varchar',N'nvarchar',N'text',N'ntext')
                      THEN N'TRY_CONVERT(NVARCHAR(4000),' + QUOTENAME(c.name) + N') = @v'
                  WHEN ty.name IN (N'tinyint',N'smallint',N'int',N'bigint')
                      THEN QUOTENAME(c.name) + N' = TRY_CONVERT(' + ty.name + N', @v)'
                  WHEN ty.name IN (N'decimal',N'numeric',N'money',N'smallmoney',N'float',N'real')
                      THEN QUOTENAME(c.name) + N' = TRY_CONVERT(NUMERIC(38,10), @v)'
                  WHEN ty.name IN (N'date',N'datetime',N'datetime2',N'smalldatetime',N'time')
                      THEN QUOTENAME(c.name) + N' = TRY_CONVERT(' + ty.name + N', @v)'
                  ELSE N'1=0'
                END + 
                N'
            ) X WHERE X.hit_count > 0'
        AS NVARCHAR(MAX)),                 -- ★ 집계 대상만 NVARCHAR(MAX)
        N' UNION ALL '                     -- ★ 구분자는 MAX가 아닌 리터럴
    )
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND t.temporal_type = 0
  AND ty.name NOT IN (N'timestamp',N'rowversion',N'image',N'varbinary',N'binary',N'sql_variant',N'xml');

EXEC sp_executesql @sql, N'@v NVARCHAR(100)', @v=@v;