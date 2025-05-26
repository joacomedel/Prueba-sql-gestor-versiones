CREATE OR REPLACE FUNCTION public.ordenventaimportes(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE
      importe double precision;
      elidobrasocial integer;
      elidplancobertura integer;
BEGIN
      /* La tabla TEMPORAL  "temorden" ccontiene nroorden, centro
      *  el primer parametro identifica el plan de cobertura
      *  el segundo parametro identifica la obrasocial
      */
      elidobrasocial = $1;
      elidplancobertura = $2;
      IF ( NOT nullvalue (elidobrasocial) ) THEN
            SELECT INTO importe SUM(oviimonto)
            FROM far_ordenventaitemimportes
            NATURAL JOIN far_plancobertura
            NATURAL JOIN far_ordenventaitem
            JOIN temfacturaorden ON (nroorden = idordenventa and idcentroordenventa = centro )
            WHERE idobrasocial = elidobrasocial
            GROUP BY idobrasocial;

     ELSE
            SELECT INTO importe SUM(oviimonto)
            FROM far_ordenventaitemimportes
            NATURAL JOIN far_plancobertura
            NATURAL JOIN far_ordenventaitem
            JOIN temfacturaorden ON (nroorden = idordenventa and idcentroordenventa = centro )
            WHERE idplancobertura = elidplancobertura
            GROUP BY idplancobertura;
     END IF;

return 	importe;
END;
$function$
