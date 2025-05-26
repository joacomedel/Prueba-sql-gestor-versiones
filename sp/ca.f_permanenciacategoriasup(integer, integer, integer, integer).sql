CREATE OR REPLACE FUNCTION ca.f_permanenciacategoriasup(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar) (#,&,?,@)

/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/


--f_permanenciacategoriasub(#,&, ?,@)

SELECT INTO elmonto  sum (t.monto)
from ( SELECT (camonto * (CASE  WHEN (extract(YEAR FROM age( CURRENT_DATE,cefechainicio) )>=2)
                THEN 1 ELSE 0  END ) )as monto
                FROM ca.categoria
                NATURAL JOIN ca.categoriaempleado
                NATURAL JOIN ca.categoriatipoliquidacion
                NATURAL JOIN ca.categoriatipo
                WHERE idpersona = $3
			and  CURRENT_DATE >= cefechainicio
			and (nullvalue(cefechafin) or CURRENT_DATE <=cefechafin )
			and idcategoriatipo = 1
			and caprioridad = 1
			and idliquidaciontipo=$2
       UNION
       SELECT 0 as monto
) as t;

return elmonto;
END;

/*
SELECT sum (t.monto)as monto from ( SELECT (camonto * (CASE  WHEN (extract(YEAR FROM age( CURRENT_DATE,cefechainicio) )>=2)  THEN 1 ELSE 0  END ) )as monto FROM ca.categoria NATURAL JOIN ca.categoriaempleado NATURAL JOIN ca.categoriatipoliquidacion NATURAL JOIN ca.categoriatipo WHERE idpersona = ? and  CURRENT_DATE >= cefechainicio and (nullvalue(cefechafin) or CURRENT_DATE <=cefechafin ) and idcategoriatipo = 1 and caprioridad = 1 and idliquidaciontipo=& UNION SELECT 0 as monto ) as t

*/
$function$
