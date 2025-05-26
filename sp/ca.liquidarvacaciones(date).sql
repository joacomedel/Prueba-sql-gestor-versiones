CREATE OR REPLACE FUNCTION ca.liquidarvacaciones(date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Procedimiento que calcula la cantidad de dias que corresponde de vacaciones
* PARAMETROS : $1 fecha
*/
DECLARE
lafecha date;

BEGIN

    SET search_path = ca, pg_catalog;
    lafecha =$1;
 /*   CREATE TEMP TABLE ca.liquidacionvacacionesempleados (
             idpersona INTEGER,
             codigo INTEGER,
             laboral varchar,
             fechadesde date,
             fechafin date,
             cantanios INTEGER,
             canmeses INTEGER,
             cantdias INTEGER,
             cantdiasvacaciones INTEGER

      );*/
    INSERT INTO liquidacionvacacionesempleados (idpersona,codigo,laboral,fechadesde,fechafin,cantanios,canmeses,cantdias) (
     SELECT idpersona,codigo,laboral,fechadesde,fechafin, cantanios,canmeses,cantdias
     FROM(
          SELECT idpersona, 1 as codigo, 'SOSUNC'as laboral,emfechadesde as fechadesde, to_date(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD') as fechafin,
          EXTRACT(YEAR FROM age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde)) as cantanios,
          EXTRACT(MONTH FROM  age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde))as canmeses,
          EXTRACT(DAY FROM age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde))as cantdias,

          (EXTRACT(YEAR FROM age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde)) * 360)+
          (EXTRACT(MONTH FROM  age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde)) * 30)+
          EXTRACT(DAY FROM age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde)) as cantidadtotaldias,
          age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha::timestamp) ,'-12','-31'),'YYYY-MM-DD'), emfechadesde) as fecha
          FROM ca.empleado
          UNION
          SELECT idpersona,idactividadlaboral as codigo ,aldescripcion as laboral,alfechainicio as fechadesde, alfechafin as fechafin,
          EXTRACT(YEAR FROM age(alfechafin, alfechainicio) ) as cantanios ,
          EXTRACT(MONTH FROM age(alfechafin, alfechainicio) ) as canmeses,
          EXTRACT(DAY FROM age(alfechafin, alfechainicio) ) as cantdias,
          (EXTRACT(YEAR FROM age(alfechafin, alfechainicio) ) * 360) + (EXTRACT(MONTH FROM age(alfechafin, alfechainicio) ) * 30) + (EXTRACT(DAY FROM age(alfechafin, alfechainicio) )) as cantidadtotaldias,
          age(alfechafin, alfechainicio)as fecha
          FROM ca.actividadlaboral
      
          UNION
          SELECT idpersona,idlicencia as codigo, ltdescripcion as laboral,lifechainicio as fechadesde, lifechafin as fechafin,
          -1* (EXTRACT(YEAR FROM age(lifechafin, lifechainicio) ) )as cantanios ,
          -1 *(   EXTRACT(MONTH FROM age(lifechafin, lifechainicio) ) )as canmeses,
          -1 * (   EXTRACT(DAY FROM age(lifechafin, lifechainicio) ) )as cantdias,
          (EXTRACT(YEAR FROM age(lifechafin, lifechainicio) ) * 360) + (EXTRACT(MONTH FROM age(lifechafin, lifechainicio) ) * 30) + (EXTRACT(DAY FROM age(lifechafin, lifechainicio) )) as cantidadtotaldias,
          age(lifechafin, lifechainicio)as fecha
          FROM ca.licencia
          NATURAL JOIN  ca.licenciatipo
          WHERE idlicenciatipo=26
      )as T
      NATURAL JOIN ca.persona
      NATURAL JOIN ca.empleado
      NATURAL JOIN ca.categoriaempleado
      NATURAL JOIN ca.grupoliquidacionempleado
      WHERE
           cefechainicio <=NOW()
           AND  (cefechafin>=NOW() or nullvalue(cefechafin))
           AND idgrupoliquidaciontipo = 1
           AND idcategoriatipo=1
      ORDER BY emlegajo::integer ASC
      );

      /* Se calculan los dias que corresponden de vacaciones */
      UPDATE liquidacionvacacionesempleados SET cantdiasvacaciones =T.diasvacaciones
      FROM (
           SELECT idpersona, Case WHEN (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) <5 THEN 20
                  WHEN (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) >=5  and (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) <10 THEN 25
                  WHEN (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) >=10 and (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) <15 THEN 30
                  WHEN (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) >=15 and (SUM(cantanios)+ ( (SUM(canmeses) + ( SUM(cantdias)/30 )) / 12) ) <20 THEN 35
           ELSE 40 END as diasvacaciones

           FROM liquidacionvacacionesempleados
           GROUP BY idpersona
     ) as T
     WHERE liquidacionvacacionesempleados.idpersona=T.idpersona;

 return true;
END;
$function$
