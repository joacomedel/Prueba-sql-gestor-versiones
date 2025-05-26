CREATE OR REPLACE FUNCTION ca.f_farmantiguedadanios(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     elmonto=0;
     --f_funcion(#,&, ?,@)
   UPDATE ca.conceptoempleado set ceporcentaje =T.ant FROM
	(  SELECT extract(YEAR from age( emfechainicioantiguedad)) as ant
	   FROM ca.empleado   WHERE idpersona=$3 ) as T
	WHERE idpersona=$3 and
	idliquidacion=$1 and
	idconcepto=1071; 
	UPDATE ca.conceptoempleado set  ceporcentaje = T.porc FROM (  
	  SELECT CASE WHEN (ceporcentaje < 25 and ceporcentaje >0)  THEN   ((2*ceporcentaje)+5)*0.01
             WHEN (ceporcentaje =0)  THEN 0
             WHEN (ceporcentaje >=25)  THEN 0.5
	   END as porc
		FROM ca.conceptoempleado
		WHERE idpersona=$3 and
		idliquidacion=$1 and 
		idconcepto=1071
   )as T
	WHERE idconcepto =1050 and
	idpersona=$3 and
	idliquidacion=$1;

return elmonto;
END;
$function$
