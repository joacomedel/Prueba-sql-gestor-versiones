CREATE OR REPLACE FUNCTION public.arreglar_ordenes_sao()
 RETURNS void
 LANGUAGE plpgsql
AS $function$declare
recibos cursor for SELECT *
FROM ordenrecibo
NATURAL JOIN (
SELECT nroorden,centro FROM ordenrecibo as r
JOIN temporalmacana ON r.idrecibo = temporalmacana.nrorecibo AND r.centro = 9) as t
ORDER BY idrecibo, centro;
rec record;

begin
open recibos;
fetch recibos into rec;
while FOUND loop
      update consumo set centro=9 where nroorden=rec.nroorden and centro=1;
      update importesorden set centro=9 where nroorden=rec.nroorden and centro=1;
      update ordvalorizada set centro=9 where nroorden=rec.nroorden and centro=1;
      update ordconsulta set centro=9 where nroorden=rec.nroorden and centro=1;
      update itemvalorizada set centro=9 where nroorden=rec.nroorden and centro=1;
      update item set centro=9 where item.iditem in ((select iditem from itemvalorizada where itemvalorizada.nroorden=rec.nroorden and itemvalorizada.centro=9));
      update cuentacorrientedeuda set idcomprobante=rec.nroorden*100+9 where idcomprobante=rec.nroorden*100+1;
fetch recibos into rec;
end loop;
close recibos;
end;
$function$
