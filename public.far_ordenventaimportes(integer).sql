CREATE OR REPLACE FUNCTION public.far_ordenventaimportes(integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE
      elidvalorescaja integer;
      importe double precision;

BEGIN
      /* La tabla TEMPORAL  "temorden" ccontiene nroorden, centro
      *  el primer parametro identifica el elidvalorescja
      */

      elidvalorescaja = $1;
      importe = 0;
      
      --- calculo el importe efectivo
      IF(elidvalorescaja = 0)THEN
              SELECT INTO importe SUM(oviimonto)
              FROM far_ordenventaitemimportes
              NATURAL JOIN far_ordenventaitem
              JOIN temporden ON (nroorden = idordenventa and idcentroordenventa = centro )
              WHERE idvalorescaja = 0
              GROUP BY idvalorescaja;
      END IF;

      --- calculo el importe en cta cte
      IF(elidvalorescaja = 3 )THEN
               SELECT INTO importe SUM(oviimonto)
               FROM far_ordenventaitemimportes
               NATURAL JOIN far_ordenventaitem
               JOIN temporden ON (nroorden = idordenventa and idcentroordenventa = centro )
               WHERE idvalorescaja <> 0
               GROUP BY idvalorescaja;
      END IF;
      
      IF nullvalue(importe) THEN 
            importe =0;
      END IF;

return 	importe;
END;
$function$
