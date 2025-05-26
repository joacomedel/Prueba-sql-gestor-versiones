CREATE OR REPLACE FUNCTION public.calcularitemsnotadebito(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES 
 totaldebito FLOAT;
 importeiva FLOAT; 
 
--RECORD 
 riva RECORD;

BEGIN

 SELECT INTO totaldebito round(CAST (SUM(debitofacturaprestador.importe) AS numeric), 2) FROM factura NATURAL JOIN debitofacturaprestador  NATURAL JOIN informefacturacionnotadebito WHERE nroinforme=$1 AND idcentroinformefacturacion = $2 ;
 SELECT INTO riva * FROM tipoiva WHERE idiva = $3;

 SELECT INTO importeiva round(CAST (SUM(debitofacturaprestador.importe) AS numeric), 2) 
        FROM factura NATURAL JOIN debitofacturaprestador NATURAL JOIN informefacturacionnotadebito
	WHERE nroinforme=$1 AND idcentroinformefacturacion = $2 AND fidtipoprestacion = 29;
 
 CREATE TEMP TABLE temp_itemnotadebito AS ( 

	SELECT round(CAST (SUM(debitofacturaprestador.importe)/(CASE WHEN (riva.porcentaje=0) THEN 1 ELSE riva.porcentaje END) AS numeric), 2) AS subtotal, ifi.nrocuentac AS idconcepto,ifi.nrocuentac, concat(ifi.nrocuentac,' - ',ifi.descripcion,' Iva del ', riva.porcentaje*100, ' %') as iditem, cantidad, riva.idiva, riva.porcentaje as ivaporcentaje , case when nullvalue(importeiva) THEN 0 ELSE importeiva END as ivaimporte, 
round(CAST (((SUM(debitofacturaprestador.importe)/CASE WHEN (riva.porcentaje=0) THEN 1 ELSE riva.porcentaje END)+(case when nullvalue(importeiva) THEN 0 ELSE importeiva END)) AS numeric), 2)
 AS importe , $1 AS nroinforme ,$2 AS idcentroinformefacturacion
	FROM factura NATURAL JOIN debitofacturaprestador 
        NATURAL JOIN informefacturacionnotadebito JOIN informefacturacionitem as ifi USING(nroinforme,idcentroinformefacturacion)	
	WHERE nroinforme=$1 AND idcentroinformefacturacion = $2 AND fidtipoprestacion = 29
	GROUP BY ifi.nrocuentac,ifi.descripcion,cantidad,idiva
	 ); 


  INSERT INTO temp_itemnotadebito (subtotal,importe, idconcepto, nrocuentac, iditem, cantidad, idiva, ivaporcentaje,ivaimporte,nroinforme,idcentroinformefacturacion)
  SELECT round(CAST(totaldebito - SUM(subtotal+ivaimporte) AS numeric), 2),round(CAST(totaldebito - SUM(subtotal+ivaimporte) AS numeric), 2), ifi.nrocuentac AS idconcepto,ifi.nrocuentac, concat(ifi.nrocuentac,' - ',ifi.descripcion)  as iditem, ifi.cantidad, 1, 0 ,0,$1,$2
	FROM temp_itemnotadebito  JOIN  informefacturacionitem AS ifi USING(nroinforme,idcentroinformefacturacion) 
  GROUP BY ifi.nrocuentac,ifi.descripcion, ifi.cantidad;

 
 
RETURN TRUE;


END;
    $function$
