CREATE OR REPLACE FUNCTION public.far_cantidadarticulosvendidos(bigint, integer, date, date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
       elidarticulo bigint;
       elidcentroarticulo integer;
       lafechaini date;
       lafechafin  date;
       lacant integer;
      
BEGIN
      -----bigint, integer, date, date
      elidarticulo = $1;
      elidcentroarticulo = $2;
      lafechaini = $3;
      lafechafin = $4;
      
      SELECT  INTO lacant SUM(ovicantidad)
      FROM far_ordenventa
      NATURAL JOIN far_ordenventaitem
      NATURAL JOIN far_ordenventaestado
      WHERE idordenventaestadotipo <> 2 and nullvalue(ovefechafin)
            and ovfechaemision::date  >=lafechaini and ovfechaemision::date <=lafechafin
            and idarticulo = elidarticulo and idcentroarticulo = elidcentroarticulo
      group by idarticulo, idcentroarticulo;
      IF nullvalue(lacant ) THEN lacant =0; END IF;

return lacant;
END;
$function$
