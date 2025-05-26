CREATE OR REPLACE FUNCTION public.tesoreria_ctacteclientes_contemporal(pfechadesde date, pfechahasta date, pidclientectacte character varying, ptiporeporte character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
BEGIN
 
CREATE TEMP TABLE temp_tesoreria_ctacteclientes_contemporal 
AS (
	select fechamovimiento,fechavencimiento,movconcepto,impago,debe,haber,saldo 
,'1-fecha movimiento#fechamovimiento@2-fecha vencimiento#fechavencimiento@3-Concepto#movconcepto@4-Imp.Pagado#impago@5-Debe#debe@6-Haber#haber@7-Saldo#saldo' as mapeocampocolumna
	--SELECT *,concat( concat(nrocliente,'/'), barra) AS elnrocliente, concat(cuitini, cuitmedio, cuitfin) as cuitcliente
FROM cliente as c 
NATURAL JOIN clientectacte as ccta
LEFT JOIN (
SELECT idctacte, to_date(pfechadesde,'YYYY-MM-DD') as fechamovimiento,to_date('2017-02-21','YYYY-MM-DD') as fechavencimiento,'Saldo inicio' as  movconcepto,case when nullvalue(debe.debe) then 0 else debe.debe end as debe,
case when nullvalue(haber.haber) then 0 else haber.haber end as haber,
(case when nullvalue(debe.debe) then 0 else debe.debe end)+(case when nullvalue(haber.haber) then 0 else haber.haber end) as saldo,debe.impago-haber.impago as impago
FROM
(SELECT idclientectacte as idctacte,to_date(pfechadesde,'YYYY-MM-DD') as fechamovimiento,'Saldo inicio' as  movconcepto, sum(importe) as debe,sum(saldo) as impago
FROM ctactedeudacliente
WHERE fechamovimiento < to_date(pfechadesde,'YYYY-MM-DD')
GROUP BY idctacte
) as debe
LEFT JOIN
(SELECT idclientectacte as idctacte,to_date(pfechadesde,'YYYY-MM-DD') as fechamovimiento,'Saldo inicio' as  movconcepto, sum(importe) as haber,sum(saldo) as impago
from ctactepagocliente
WHERE fechamovimiento < to_date(pfechadesde,'YYYY-MM-DD')
GROUP BY idctacte
) as haber using (idctacte)

UNION

SELECT idclientectacte as idctacte,fechamovimiento,fechavencimiento,movconcepto, importe as debe,0 as haber,importe as saldo,
saldo as impago
FROM ctactedeudacliente
WHERE fechamovimiento between to_date(pfechadesde,'YYYY-MM-DD') and to_date(pfechahasta,'YYYY-MM-DD')

UNION

SELECT idclientectacte as idctacte,fechamovimiento,null as fechavencimiento,movconcepto, 0 as debe,importe as haber,importe as saldo,saldo as impago
FROM ctactepagocliente
where fechamovimiento between to_date(pfechadesde,'YYYY-MM-DD') and to_date(pfechahasta,'YYYY-MM-DD')

) as cta on (ccta.idclientectacte=cta.idctacte)

WHERE ccta.idclientectacte = pidclientectacte
ORDER BY fechamovimiento
);
     

return true;
END;
$function$
