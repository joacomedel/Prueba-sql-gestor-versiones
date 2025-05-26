CREATE OR REPLACE FUNCTION ca.cantidaddiaslaborablesempleado(date, date, integer)
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
indice integer;
indicefecha date;
dia integer;
cant integer;
esferiado record;
cantdiasrango integer;
elempleado integer;
lajornadadeldia record;
licampleado record;
horaentrada interval;
horasalida time;

clicencia INTEGER;
cllegadastarde INTEGER;
csalidasantes INTEGER;
cdiaslaborables INTEGER;
cdiasdespuesquince Integer;
cdiassalidaenhorario integer;
cllegadaantesjornada integer;
interv interval;
cdiasausente INTEGER;
empausente record;
cllegadaenhorario integer;
elidlicenciatipo integer;
elidlicencia  integer;
BEGIN

     SET search_path = ca, pg_catalog;
     fechainicio = $1;
     fechafin = $2;
     elempleado = $3;
     cant = 0;
     cantdiasrango = $2 - $1;
     indicefecha = $1;
     
    
     
   /*   CREATE TEMP TABLE "ca"."liquidaciondiasempleados" (
             idpersona INTEGER,
             fecha date,
             cantlicencia INTEGER,
             cantllegadastarde INTEGER,
             cantsalidasantes INTEGER,
             cantdiaslaborables INTEGER,
             cantdiastrabajos INTEGER,
             cantdiasdespuesquince INTEGER,
             cantdiassalidaenhorario integer
      );*/
     FOR indice IN 0..cantdiasrango LOOP
             /* inicializo contadores */
             clicencia = 0;
            
             csalidasantes  = 0;
             cdiaslaborables  = 0;
             cdiasdespuesquince  = 0;
             cdiassalidaenhorario = 0;
             cdiasausente = 0 ;
             cllegadastarde  = 0;
             cllegadaenhorario =0;
             cllegadaantesjornada = 0;
             dia = to_char(indicefecha,'d');
             /* Corroboro que el dia no se un dia FERIADO*/
             SELECT into esferiado * FROM feriado WHERE fefecha =indicefecha;
             IF NOT FOUND THEN
                          SELECT into lajornadadeldia  *  ,      to_char((jhhorainicio + interval '15 min'),'HH24:MI:SS')::interval as iniciocontolerancia ,   to_char((jhhorafin + interval '15 min'),'HH24:MI:SS')::interval as finjornadamasquince,   to_char(jhhorafin ,'HH24:MI:SS')::interval as horafin,
                                   to_char(jhhorainicio ,'HH24:MI:SS')::interval as iniciojornada
                           FROM ca.jornada NATURAL JOIN ca.jornadahorario  NAtural join ca.persona NATURAL JOIN ca.empleado
                                  WHERE idpersona = elempleado  and jorfechainicio <= indicefecha  and jorfechafin >= indicefecha and jhdia = dia and idempleadogrupo <>7;
                           /* Si es un dia correspondiente a su JORNADA LABORAL */
                           IF FOUND THEN
                                    cdiaslaborables = 1 ;
                                    elidlicenciatipo = 0;
                                    elidlicencia = 0;
                                    /* Me fijo si ese dia tiene una licencia*/
                                    select into licampleado *
                                    from ca.licencia
                                    NATURAL JOIN persona
                                    WHERE idpersona = elempleado  and lifechainicio <= indicefecha  and  lifechafin  >=  indicefecha
                                          and idlicenciatipo<>28 ; -- los permisos de 3 horas NO SON considerados como dias de licencia
                                    IF FOUND THEN
                                             /* Contar dia licencia*/
                                             clicencia = 1;
                                             elidlicencia = licampleado.idlicencia;
                                             elidlicenciatipo =licampleado.idlicenciatipo;
                                     ELSE
                                            SELECT into empausente * FROM ca.movimientos WHERE idpersona = elempleado   and mofecha = indicefecha;
                                             if FOUND THEN
                                                                   /* Verifico su movimientos de entrada y salida para ese dia */
                                                                   SELECT into horaentrada to_char(MIN(mohora),'HH24:MI:SS')::interval  FROM ca.movimientos WHERE idpersona = elempleado  and mofecha = indicefecha  and idmovimientotipos = 1;
                                                                   IF FOUND THEN
                                                                            /* COmparo los horarios de entrada para ver llegada tarde */
                                                                            IF (horaentrada::time >= lajornadadeldia.iniciocontolerancia::time) THEN
                                                                              /* La persona llego tarde*/
                                                                              cllegadastarde = 1;
                                                                            ELSE
                                                                                IF (horaentrada::time <= lajornadadeldia.iniciojornada::time) THEN
                                                                                   /* La persona llego antes*/
                                                                                   cllegadaantesjornada = 1;
                                                                                ELSE
                                                                                    cllegadaenhorario = 1;
                                                                                END IF;
                                                                            END IF;
                                                                   END IF;
                                                                   /* Verifico el horario de salida*/
                                                                   SELECT into horasalida to_char(MIN(mohora),'HH24:MI:SS')::interval FROM ca.movimientos  WHERE idpersona = elempleado and mofecha = indicefecha and idmovimientotipos = 2;
                                                                   IF FOUND THEN
                                                                              /* Comparo los horarios de salida para ver las salidas antes del horario */
                                                                              IF (horasalida::time < lajornadadeldia.horafin::time) THEN
                                                                                  /* La persona salio antes de la jornada*/
                                                                                  csalidasantes = 1;
                                                                              ELSE
                                                                                      /* La persona salio despues de l fin de la jornada */
                                                                                     IF (horasalida::time > lajornadadeldia.finjornadamasquince::time) THEN
                                                                                           /* La persona salio luego de los 15 minutos establecidos en  la jornada */
                                                                                            cdiasdespuesquince = 1;
                                                                                     else
                                                                                         cdiassalidaenhorario =1;
                                                                                     END IF;
                                                 
                                                                               END IF;
                                                                   END IF;
                                                      ELSE /*NO FICHO esta ausente*/
                                                              cdiasausente =1;
                                                      END IF;
                                    END IF;
             INSERT INTO liquidaciondiasempleados( idpersona ,   fecha ,  cantlicencia ,idlicencia,idlicenciatipo,cantdiastrabajados,cantllegadaenhorario, cantllegadastarde , canllegadaantesjornada,cantsalidasantes , cantdiaslaborables ,  cantdiasdespuesquince ,   cantdiassalidaenhorario , cantdiasausente )
             VALUES (elempleado,indicefecha, clicencia ,elidlicencia,elidlicenciatipo,( cdiaslaborables - clicencia - cdiasausente), cllegadaenhorario, cllegadastarde ,cllegadaantesjornada, csalidasantes , cdiaslaborables ,  cdiasdespuesquince ,   cdiassalidaenhorario ,cdiasausente);
                           END IF;
                        

              END IF;
             
                indicefecha = indicefecha +1;
                
     END LOOP;


return 	cant;
END;
$function$
