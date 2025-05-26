CREATE OR REPLACE FUNCTION ca.cantidaddiaslaborables(date, date, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/*
* La funcion devuelve la cantidad de dias laborables dentro de un rango de fecha ($1 $2)
* No se tienen en cuanta los sabados, domingo ni aquellos feriado que han sido cargados.
* OJO este procedimiento deberia modificarse teniendo en cuenta las jornadas por si un empleado trabaja los sabados o domingo
*PARAMETROS : $1 fecha ini
              $2 fecha fin

*/
DECLARE

fechainicio date;
fechafin date;
elempleado integer;
cursorempleado refcursor;
unempleado record;
resp integer;
BEGIN

     SET search_path = ca, pg_catalog;
     fechainicio = $1;
     fechafin = $2;
     elempleado = $3;
   

   /*   CREATE TEMP TABLE "ca"."liquidaciondiasempleados" (
             idpersona INTEGER,
             fecha date,
             cantlicencia INTEGER,
             cantllegadastarde INTEGER,
             cantsalidasantes INTEGER,
             cantdiaslaborables INTEGER,
             cantdiasdespuesquince INTEGER,
             cantdiassalidaenhorario integer
      );*/
    /* Recupero cada uno de los empleados */

IF not public.iftableexists('liquidaciondiasempleados') THEN

CREATE TEMP TABLE liquidaciondiasempleados (
             idlicencia INTEGER,
             idlicenciatipo INTEGER,
             idpersona INTEGER,
             fecha date,
             cantlicencia INTEGER,
             cantllegadastarde INTEGER,
             cantsalidasantes INTEGER,
             cantdiaslaborables INTEGER,
             cantdiasdespuesquince INTEGER,
             cantdiassalidaenhorario integer,
             cantdiasausente  integer,
             canllegadaantesjornada integer,
            cantllegadaenhorario integer,
            cantdiastrabajados INTEGER

      );
ELSE 

    DELETE FROM liquidaciondiasempleados;
END IF;

    if(elempleado = 0 ) then
                   OPEN cursorempleado FOR SELECT   emlegajo::bigint as leg,empleado.*  FROM empleado order by leg asc ;
    ELSE
                   OPEN cursorempleado FOR SELECT  *  FROM empleado WHERE idpersona = elempleado;
    END IF;
    FETCH cursorempleado INTO unempleado;
    WHILE FOUND LOOP
                   SELECT INTO resp  cantidaddiaslaborablesempleado(fechainicio,fechafin,unempleado.idpersona);
                   FETCH cursorempleado INTO unempleado;
    END LOOP;

 return 1;
END;
$function$
