CREATE OR REPLACE FUNCTION public.alerta_resultadosincro()
 RETURNS character varying
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
resultado = concat('<span><b>Centros Regionales Sincronizados.</b></span>');
resultado = concat(resultado,'<table border="10"><tr><th>CentroRegional</th><th>PtoVenta</th><th>FechaEmisionFactura</th></tr>');
 
OPEN calertas FOR select concat('<tr><td>',crdescripcion,'</td><td>',nrosucursal,'</td><td>',fechaemision,'</td></tr>' ) as fila 
 
                    from facturaventa 
                    join centroregional on(centro=idcentroregional)
                    where fechaemision=current_date-1
                    group by crdescripcion,fechaemision,nrosucursal   order by crdescripcion   ;    


FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
     
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table> '::text);
return resultado;
END;$function$
