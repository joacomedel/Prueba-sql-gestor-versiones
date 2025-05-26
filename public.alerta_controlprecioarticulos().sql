CREATE OR REPLACE FUNCTION public.alerta_controlprecioarticulos()
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
resultado = concat('<span><b>Precios por rubro, sin actualizar en los ultimos 20 dias.</b></span>');
resultado = concat(resultado,'<table border="1" ><tr><th>ID</th><th>Rubro</th><th>Cant.</th></tr>');
OPEN calertas FOR SELECT concat('<tr><td>',far_articulo.idrubro,'</td><td>',rdescripcion,'</td><td>',count(*),'</td></tr>') as fila 
			FROM far_fechaprecioarticulomodificado(20,365)
			NATURAL JOIN far_articulo
			NATURAL JOIN far_rubro
			GROUP BY far_articulo.idrubro,far_rubro.rdescripcion
			ORDER BY rdescripcion;
FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table> '::text);
return resultado;
END;
$function$
