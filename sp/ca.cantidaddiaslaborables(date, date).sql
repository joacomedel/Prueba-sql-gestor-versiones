CREATE OR REPLACE FUNCTION ca.cantidaddiaslaborables(date, date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/*
* La funcion devuelve la cantidad de dias laborables dentro de un rango de fecha ($1 $2)
* No se tienen en cuanta los sabados, domingo ni aquellos feriado que han sido cargados.
* OJO este procedimiento deberia modificarse teniendo en cuenta las jornadas por si un empleado trabaja los sabados o domingo
*PARAMETROS : $1 fecha ini
              $2 fecha fin

*/


DECLARE

fechainicio date;
fechafin date;
indice integer;
indicefecha date;
dia integer;
cant integer;
esferiado record;
cantdiasrango integer;
BEGIN

     SET search_path = ca, pg_catalog;
     fechainicio = $1;
     fechafin = $2;
     cant = 0;
     cantdiasrango = $2 - $1;
     indicefecha = $1;
     FOR indice IN 0..cantdiasrango LOOP
                /* 7 = sabdo 1=Domingo */

             --  RAISE NOTICE 'PEPE';
             dia = to_char(indicefecha,'d');
                if (dia <>7 and  dia <> 1 )THEN
                        SELECT into esferiado * FROM feriado WHERE fefecha =indicefecha;
                        IF NOT FOUND THEN
                               cant = cant +1;
                        END IF;
                END IF;
                indicefecha = indicefecha +1;
     END LOOP;


return 	cant;
END;
$function$
