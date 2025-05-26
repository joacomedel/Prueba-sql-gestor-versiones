CREATE OR REPLACE FUNCTION ca.f_diastrabajados(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       diasadescontar integer;
       diaslicencia integer;
       diaslaborables  integer;
       horastrab DOUBLE PRECISION;
       diaslictrat record;
       diastrabajados  integer;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     elmonto =0;
--f_diastrabajados(#,&, ?,@)
-- recupero la cantidad de dias tomados por licencia
       SELECT INTO diaslicencia CASE WHEN nullvalue(SUM(ceporcentaje)) THEN 0 ELSE SUM(ceporcentaje) END
       FROM ca.mapeolicenciaconcepto
       NATURAL JOIN ca.conceptoempleado
       WHERE idpersona =$3 and idliquidacion=$1;
       
-- recupero la cantidad de dias laborables
       SELECT INTO diaslaborables ceporcentaje
       FROM ca.conceptoempleado
       WHERE idpersona =$3 and idliquidacion=$1 and idconcepto=1045;
       
-- recupero la cantidad de dias que NO TRABAJO
       SELECT  INTO diasadescontar CASE WHEN nullvalue(SUM(ceporcentaje)) THEN 0 ELSE SUM(ceporcentaje) END
       FROM ca.conceptoempleado
       WHERE idpersona =$3 and idliquidacion=$1 and idconcepto=1121;

-- LA cantidad de dias que efectivamente se trabajaron es la cantidad de
-- dias laborables del mes - los correspondientes a los dias de licencia
       diastrabajados = diaslaborables - diaslicencia - diasadescontar;

       UPDATE  ca.conceptoempleado
       SET ceporcentaje = diastrabajados 
       WHERE  idpersona =$3 and idliquidacion=$1 and idconcepto=1084;

--
       UPDATE  ca.conceptoempleado
       SET ceporcentaje = diastrabajados
       WHERE  idpersona =$3 and idliquidacion=$1 and idconcepto=998;
       
       
       /**/
        SELECT INTO horastrab case when (cemonto<>0 and ceporcentaje<>0) then round ((cemonto/ceporcentaje)::numeric,2)
		else 0 end as valor FROM ca.conceptoempleado
 		WHERE  idpersona  = $3 and
		idconcepto = 100 and
		idliquidacion=$1;	
	
    	-- Actualizo el porcentaje del concepto premio segun los dias trabajados
        UPDATE ca.conceptoempleado
        SET ceporcentaje = (diastrabajados*horastrab)
        WHERE idpersona  = $3 and idconcepto = 4 and idliquidacion= $1 ;


         -- Si la Persona tiene licencia largo tratamiento el porcentaje es un 0.5
         SELECT INTO diaslictrat ceporcentaje
         FROM ca.conceptoempleado
         WHERE idconcepto =1112 and idpersona = $3 and idliquidacion=$1;
         IF FOUND THEN
                -- Actualizo el porcentaje del concepto premio segun los dias trabajados
               UPDATE ca.conceptoempleado
               SET ceporcentaje = (diastrabajados + (diaslictrat.ceporcentaje * 0.5) )
               WHERE idpersona  = $3 and idconcepto = 4 and idliquidacion= $1 ;

         END IF;



return 	elmonto;
END;

/*
UPDATE ca.conceptoempleado set ceporcentaje =t.diastrabajados   FROM (SELECT (ceporcentaje * cemonto)as diastrabajados  FROM conceptoempleado WHERE idpersona =? and idliquidacion=# and idconcepto=998) as t WHERE  idpersona =? and idliquidacion=# and ( idconcepto=1 or idconcepto =17 or idconcepto=4);
  UPDATE ca.conceptoempleado set cemonto =t.porcentaje FROM (  SELECT ceporcentaje as porcentaje  FROM ca.conceptoempleado    WHERE idpersona =? and idliquidacion=# and idconcepto=0  ) as t   WHERE  idpersona =? and idliquidacion=# and  idconcepto=998;UPDATE ca.conceptoempleado set ceporcentaje = t.porcentaje   FROM (  SELECT SUM(dias) as porcentaje FROM ( SELECT SUM(dias * propjornada )  as dias FROM (   SELECT ceporcentaje*(-1) as dias,idpersona   FROM ca.conceptoempleado    WHERE idpersona =? and idliquidacion=# and idconcepto=1084  UNION   sELECT  ceporcentaje as dias,idpersona  FROM ca.conceptoempleado      WHERE idpersona =? and idliquidacion=# and idconcepto=998  UNION SELECT 0,? ) as TEM NATURAL JOIN (SELECT   round ((cemonto/ceporcentaje)::numeric,2)as propjornada,idpersona  FROM ca.conceptoempleado  WHERE idpersona =? and idliquidacion=# and idconcepto=100 )  as e ) as up )as t WHERE  idpersona =? and idliquidacion=# and idconcepto=1018;
*/
$function$
