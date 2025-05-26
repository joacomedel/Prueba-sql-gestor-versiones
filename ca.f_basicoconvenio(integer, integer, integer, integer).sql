CREATE OR REPLACE FUNCTION ca.f_basicoconvenio(integer, integer, integer, integer)
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

--f_basicoconvenio(#,&, ?,@)
SELECT INTO  elmonto montobasico
	FROM ( SELECT (cemonto * ceporcentaje) as montobasico,idpersona 
		FROM ca.conceptoempleado 
		WHERE idpersona = $3 and
		idconcepto = 1044 and  
		idliquidacion=$1
        ) as M ;
return 	elmonto;
END;

/*
SELECT  (montobasico/cantidaddias) as monto FROM ( SELECT (cemonto * ceporcentaje) as montobasico,idpersona FROM ca.conceptoempleado WHERE idpersona = ? and   idconcepto = 1044 and  idliquidacion=# ) as M NATURAL JOIN (SELECT ceporcentaje  as cantidaddias,idpersona FROM ca.conceptoempleado WHERE idpersona =? and   idconcepto = 1045 and  idliquidacion=# ) as D

*/
$function$
