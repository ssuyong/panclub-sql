select * from it_1014--2392


select itemNo, sum(qty), max(purRate)
from it_1014
group by itemNo
order by itemNo
;--2392


select itemNo, sum(qty) qty, max(purRate) purRate --2360
from (
select it.itemNo, it.qty, osr.purRate 
from it_1014 it
join e_item i on i.itemNo = it.itemNo and i.classCode = 'GN'
join e_otherSaleRate osr 
	on osr.comCode = '¤¡121' 
	and osr.custCode = '¤·479'
	and osr.itemId = i.itemId
) a
group by itemNo
order by itemNo



--select it.itemNo, sum(it.qty) qty, max(osr.purRate) purRate
select it.itemNo, count(*) --2365
from it_1014 it
join e_item i on i.itemNo = it.itemNo and i.classCode = 'GN'
join e_otherSaleRate osr 
	on osr.comCode = '¤¡121' 
	and osr.custCode = '¤·479'
	and osr.itemId = i.itemId
group by it.itemNo


select * from it_1014 it
join e_item i on i.itemNo = it.itemNo and i.classCode = 'GN'
join e_otherSaleRate osr on osr.comCode = '¤¡121' and osr.custCode = '¤·479' and osr.itemId = i.itemId
where it.itemNo = '9J1260403A'

select *
from e_item i
where i.itemNo in ('C2S48022')


