CREATE OR REPLACE FUNCTION ca.f_fechainiciocategoria(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/*calcula la fecha de inicio mas vieja de una de categoria y persona dadas, siempre y cuando no tenga huecos entre fechas*/
DECLARE
       valor date;

BEGIN
   /*  idpersona = $1; 
     idcategroia = $2;
     */


SELECT cefechainicio,cefechafin
	FROM ca.categoriaempleado
	NATURAL JOIN ca.empleado
	
	WHERE idpersona= 263 and idcategoria=5
 order by cefechainicio desc;

return 	valor;
END;

/*
SELECT SUM(cemonto*ceporcentaje) as monto FROM ca.conceptoempleado NATURAL JOIN ca.concepto NATURAL JOIN ca.liquidacion WHERE idpersona= ? and (idconceptotipo = 1 OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 5 OR  idconceptotipo =10 ) and idliquidacion= #

*/
$function$
