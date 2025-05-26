CREATE OR REPLACE FUNCTION public.pruebacorrepa()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
	resultado boolean;
	
BEGIN
     
     resultado = true;
     CREATE TABLE lala_pa as (
SELECT concat('<tr><td>',far_articulo.idrubro,'</td><td>',rdescripcion,'</td><td>',count(*),'</td></tr>') as fila FROM far_fechaprecioarticulomodificado(20,365) NATURAL JOIN far_articulo NATURAL JOIN far_rubro GROUP BY far_articulo.idrubro,far_rubro.rdescripcion ORDER BY rdescripcion);
     return resultado;
END;
$function$
