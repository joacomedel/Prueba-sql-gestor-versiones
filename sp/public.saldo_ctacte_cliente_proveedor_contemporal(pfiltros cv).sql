CREATE OR REPLACE FUNCTION public.saldo_ctacte_cliente_proveedor_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       --RECORD
	rfiltros RECORD;


BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


IF (rfiltros.idsaldoclienteprestador=2) THEN 

  CREATE TEMP TABLE temp_saldo_ctacte_cliente_proveedor_contemporal AS (
	SELECT sum(saldo) as saldo, pdescripcion   as prestador
FROM prestador as p NATURAL JOIN prestadorctacte as pcta
LEFT JOIN 

( 		
SELECT idctacte, to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento, case when nullvalue(debe.debe) then 0 else debe.debe end as debe,		
case when nullvalue(haber.haber) then 0 else haber.haber end as haber,	(case when nullvalue(debe.debe) then 0 else debe.debe end)-(case when nullvalue(haber.haber) then 0 else haber.haber end) as saldo	
FROM 
 (SELECT idprestadorctacte as idctacte,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento, sum(importe) as debe
	FROM ctactedeudaprestador 
	WHERE fechamovimiento::date < to_date(rfiltros.fechadesde,'YYYY-MM-DD')  GROUP BY idprestadorctacte) as debe  
  LEFT JOIN 
  (SELECT idprestadorctacte as idctacte,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento, sum(importe*(-1)) as haber
   FROM ctactepagoprestador 
   WHERE fechamovimiento::date < to_date(rfiltros.fechadesde,'YYYY-MM-DD')  GROUP BY idprestadorctacte) as haber USING (idctacte)  
   UNION
   SELECT idprestadorctacte as idctacte,fechamovimiento, importe as debe,0 as haber,importe as saldo
   FROM ctactedeudaprestador  
   WHERE fechamovimiento::date between to_date(rfiltros.fechadesde,'YYYY-MM-DD') AND to_date(rfiltros.fechahasta,'YYYY-MM-DD')
   UNION
   SELECT idprestadorctacte as idctacte,fechamovimiento,0 as debe,importe*(-1) as haber,importe as saldo
   FROM ctactepagoprestador  
   WHERE fechamovimiento::date between to_date(rfiltros.fechadesde,'YYYY-MM-DD') AND to_date(rfiltros.fechahasta,'YYYY-MM-DD')
   ) as cta on (pcta.idprestadorctacte=cta.idctacte)


 WHERE   true  AND fechamovimiento::date >= rfiltros.fechadesde AND fechamovimiento::date <= rfiltros.fechahasta  AND 
(idprestador = rfiltros.idprestador OR nullvalue(rfiltros.idprestador))
 GROUP BY pdescripcion

);


ELSE 
    CREATE TEMP TABLE temp_saldo_ctacte_cliente_proveedor_contemporal AS ( 
         SELECT sum(saldo) as saldo, denominacion   as cliente 
          FROM cliente as c NATURAL JOIN clientectacte as ccta 
          LEFT JOIN ( 		
           SELECT idctacte, to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento, case when nullvalue(debe.debe) then 0 else debe.debe end as debe,		
case when nullvalue(haber.haber) then 0 else haber.haber end as haber,	(case when nullvalue(debe.debe) then 0 else debe.debe end)-(case when nullvalue(haber.haber) then 0 else haber.haber end) as saldo	
           FROM 
          (SELECT idclientectacte as idctacte,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento, sum(importe) as debe
        	FROM ctactedeudacliente
	        WHERE fechamovimiento::date < to_date(rfiltros.fechadesde,'YYYY-MM-DD')  GROUP BY idclientectacte) as debe  
           LEFT JOIN 
          (SELECT idclientectacte as idctacte,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento, sum(importe*(-1)) as haber
           FROM ctactepagocliente
           WHERE fechamovimiento::date < to_date(rfiltros.fechadesde,'YYYY-MM-DD')  GROUP BY idclientectacte) as haber  USING (idctacte)  
           UNION
           SELECT idclientectacte as idctacte,fechamovimiento, importe as debe,0 as haber,importe as saldo
           FROM ctactedeudacliente 
           WHERE fechamovimiento::date between to_date(rfiltros.fechadesde,'YYYY-MM-DD') AND to_date(rfiltros.fechahasta,'YYYY-MM-DD')
          UNION
          SELECT idclientectacte as idctacte,fechamovimiento,0 as debe,importe*(-1) as haber,importe as saldo
          FROM ctactepagocliente  
          WHERE fechamovimiento::date between to_date(rfiltros.fechadesde,'YYYY-MM-DD') AND to_date(rfiltros.fechahasta,'YYYY-MM-DD')
   ) as cta on (ccta.idclientectacte=cta.idctacte)


       WHERE   true  AND fechamovimiento::date >= rfiltros.fechadesde AND fechamovimiento::date <= rfiltros.fechahasta  AND 
          ((lower(concat(cuitini,cuitmedio,cuitfin)) SIMILAR TO  lower(rfiltros.cuitcliente))  OR nullvalue(rfiltros.cuitcliente))
       GROUP BY denominacion



); 
 
END IF;
	
return true;
END;
$function$
