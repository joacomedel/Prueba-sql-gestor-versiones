CREATE OR REPLACE FUNCTION public.sumardiaslaborables(date, integer)
 RETURNS date
 LANGUAGE plpgsql
AS $function$/*
* La funcion devuelve la fecha de inicio mas "X"($2) dias laborables
* No se tienen en cuanta los sabados, domingo ni aquellos feriado que han sido cargados.
* OJO este procedimiento deberia modificarse teniendo en cuenta las jornadas por si un empleado trabaja los sabados o domingo
*PARAMETROS : $1 fecha ini
              $2 fecha fin

*/


DECLARE

fechainicio date;
diasasumar integer;
indice integer;
indicefecha date;
dia integer;
fechasalida date;
esferiado record;
cantdiasrango integer;
BEGIN

     SET search_path = ca, pg_catalog;
     fechainicio = $1;
     diasasumar = $2;
     fechasalida = $1;


     indice= 1;
     while indice<=diasasumar LOOP
                /* 7 = sabado 1=Domingo */
             fechasalida=fechasalida::date + 1 days;
             --  RAISE NOTICE 'PEPE';
             dia = to_char(fechasalida,'d');
             if (dia <>7 and  dia <> 1 )THEN
                        SELECT into esferiado * FROM feriado WHERE fefecha =indicefecha;
                        IF NOT FOUND THEN
                               indice = indice +1;
                        END IF;
              END IF;
              
     END LOOP;


return 	fechasalida;
END;
$function$
