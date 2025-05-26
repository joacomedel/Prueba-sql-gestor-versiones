CREATE OR REPLACE FUNCTION public.alerta_ingresodhs()
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	calertas REFCURSOR;
	ralerta RECORD;
	rusuario RECORD;
	resultado TEXT;
        

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
resultado = concat('<span><b>Datos de DHs</b></span>');
resultado = concat(resultado,'<table border="1">
<tr><th>Tipo Archivo</th><th>Nro.Liquidacion</th><th>Concepto</th><th>Cantidad Lineas</th><th>Suma Importe</th></tr>');
 
							
OPEN calertas FOR 

SELECT  concat('<tr><td>','DH21','</td><td>',nroliquidacion,'</td><td>',nroconcepto,'</td><td>',sum(cantidadlineas),'</td><td>',sum(importe),'</td></tr>') as fila
		FROM dh21
                WHERE mesingreso = date_part('month', current_date -30) and anioingreso=date_part('year', current_date - 30)
                AND (nroconcepto=372 OR nroconcepto=387 OR nroconcepto=202  OR nroconcepto=357) 
                GROUP BY nroconcepto, nroliquidacion
union
SELECT  concat('<tr><td>',0,'</td><td>',count(*),'</td><td>',0,'</td><td>',nroliquidacion,'</td><td>','DH49','</td></tr>') as fila
		FROM dh49
                WHERE mesingreso = date_part('month', current_date -30) and anioingreso=date_part('year', current_date - 30)
                and nroliquidacion not ilike '32%'
                GROUP BY  nroliquidacion;
 

FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'<br></br>');
 

resultado = concat(resultado,'<table border="1">
<tr><th>Nro.Liquidacion</th><th>Concepto</th><th>Cantidad Recibos</th><th>Importe Total</th></tr>');

OPEN calertas FOR SELECT concat('<tr><td>',nroliquidacion,'</td><td>',case when concepto=360 then 372 else concepto end ,'</td><td>',count(*),'</td><td>',round(sum(informedescuentoplanillav2.importe)::numeric, 2),'</td></tr>') as fila 
	 FROM informedescuentoplanillav2 	
         WHERE mes = date_part('month', current_date -30) and anio=date_part('year', current_date - 30)
        GROUP BY informedescuentoplanillav2.concepto, informedescuentoplanillav2.nroliquidacion;
FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;
/*
SELECT count(*) cantidadrecibos,case when concepto=360 then 372 else concepto end, round(sum(informedescuentoplanillav2.importe)::numeric, 2) importetotal, nroliquidacion 
 FROM informedescuentoplanillav2 	
 WHERE mes = date_part('month', current_date -30) and anio=date_part('year', current_date - 30)
 GROUP BY informedescuentoplanillav2.concepto, informedescuentoplanillav2.nroliquidacion;
*/

resultado = concat(resultado,'</table> '::text);
return resultado;
END;

$function$
