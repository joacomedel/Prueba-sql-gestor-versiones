CREATE OR REPLACE FUNCTION public.far_info_cantidadarticulosvendidos(bigint, integer, timestamp without time zone, timestamp without time zone)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
       elidarticulo bigint;
       elidcentroarticulo integer;
       lafechaini timestamp;
       lafechafin  timestamp;
       lacant integer;
       resultado varchar;
      
BEGIN
      -----bigint, integer, date, date
      elidarticulo = $1;
      elidcentroarticulo = $2;
      lafechaini = $3;
      lafechafin = $4;
      -- IF (rordenventa.idordenventatipo<>3 and rordenventa.idordenventatipo<>5  and rordenventa.idordenventatipo<>6)  THEN --no es presupuesto, SI vale, no regalo
      SELECT  INTO lacant SUM(ovicantidad)
	FROM far_ordenventa
	NATURAL JOIN far_ordenventaitem
	NATURAL JOIN far_ordenventaestado
	WHERE idordenventaestadotipo <> 2 and nullvalue(ovefechafin)
            and ovfechaemision::date  >=lafechaini and ovfechaemision::date <=lafechafin
            and idarticulo = elidarticulo and idcentroarticulo = elidcentroarticulo
            and idordenventatipo <> 3  and idordenventatipo <> 6
      group by idarticulo, idcentroarticulo;
      IF nullvalue(lacant) THEN lacant =0; END IF;
     
      resultado = concat('{ cantVendidas=',lacant);
      SELECT  INTO lacant SUM(ovicantidad)
	FROM far_ordenventa
	NATURAL JOIN far_ordenventaitem
	NATURAL JOIN far_ordenventaestado
	WHERE idordenventaestadotipo <> 2 and nullvalue(ovefechafin)
            and ovfechaemision::date  >=lafechaini and ovfechaemision::date <=lafechafin
            and idarticulo = elidarticulo and idcentroarticulo = elidcentroarticulo
            and idordenventatipo = 5 -- Vales
      group by idarticulo, idcentroarticulo;
      IF nullvalue(lacant) THEN lacant =0; END IF;
      resultado = concat(resultado,' ,','cantVale=',lacant);
      resultado = concat(resultado,' }');

return resultado;
END;
$function$
