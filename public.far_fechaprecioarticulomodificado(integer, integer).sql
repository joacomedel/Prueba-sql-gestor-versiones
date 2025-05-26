CREATE OR REPLACE FUNCTION public.far_fechaprecioarticulomodificado(integer, integer)
 RETURNS SETOF far_precioarticulo
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  pcantdias  alias for  $1; 
  pcantdiashasta alias for $2;

--REGISTROS
  elem record;
  rlospreciosart far_precioarticulo%rowtype; 


BEGIN
    FOR  rlospreciosart in  SELECT  far_precioarticulo.*
    FROM far_precioarticulo 
    NATURAL JOIN far_articulo 
    NATURAL JOIN far_lote
    WHERE aactivo AND idcentrolote = 99 AND lstock > 0 AND (pafechaini < (CURRENT_DATE-pcantdias) AND nullvalue(pafechafin)) 
               AND pafechaini >=  (CURRENT_DATE-pcantdiashasta)
    ORDER BY idrubro
 loop
return next rlospreciosart;
end loop;
return;
END;
$function$
