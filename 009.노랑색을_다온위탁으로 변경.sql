select rackName, rackCode, storageCode 
  from dbo.e_rack
  where comCode = '¤¡121'
    and storageCode = '250923001'
  order by rackName asc;