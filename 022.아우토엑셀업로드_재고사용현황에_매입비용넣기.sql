select * from _SPLOG
where created = '2025-10-28'   
  and sp = 'panErp.dbo.up_conStockRpt'
order by created desc;

exec sp_rename 'dbo.outo_conStock_202509', 'ssy_constock'


--0.¿¢¼¿¾÷·Îµå: ssy_constock
--1.ÀÎµ¦½º »ý¼º
CREATE INDEX IX_ssy_constock_item_reg_qty
ON dbo.ssy_constock (itemNo, regDate, qty)
INCLUDE (costPrice);

UPDATE STATISTICS dbo.ssy_constock WITH FULLSCAN;

--drop index IX_ssy_constock_item_reg_qty on dbo.ssy_constock

select * from ssy_constock --397


--2. °ËÁõ
SELECT vw.costPrice, si.*
FROM e_saleItem si
JOIN e_item ei ON ei.itemId = si.itemId
JOIN ssy_constock vw --WITH (INDEX = IX_ssy_constock_item_reg_qty)
  ON vw.itemNo = ei.itemNo
WHERE 1=1
  and si.regYmd = vw.regDate
  AND si.qty = vw.qty
  AND si.comCode = '¤·499'
OPTION (FORCE ORDER);--Áï½Ã°á°ú³ª¿È


--3.½ÇÇà

select @@TRANCOUNT

begin tran --8m2s 353
update si
set si.costPrice = vw.costPrice
FROM e_saleItem si
JOIN e_item ei ON ei.itemId = si.itemId
JOIN ssy_constock vw -- WITH (INDEX = IX_ssy_constock_item_reg_qty)
  ON vw.itemNo = ei.itemNo
WHERE si.regYmd = vw.regDate
  AND si.qty = vw.qty
  AND si.comCode = '¤·499'
OPTION (FORCE ORDER);

rollback tran

commit tran