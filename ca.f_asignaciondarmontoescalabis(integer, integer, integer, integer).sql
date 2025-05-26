CREATE OR REPLACE FUNCTION ca.f_asignaciondarmontoescalabis(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
     --  canthijos integer;
       rliquidacion record;
       elconcepto record;
       elconceptoayuda record;
       rinfovinculo record;
BEGIN
--reemplazarparametrosmontohaberes<=montohaberes<=8400
--(integer, integer, integer, integer, varchar)
/*
     codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;
*/

--f_asignacion(#,&, ?,@)
SELECT INTO elmonto sum(monto)
FROM ((SELECT CASE  WHEN   asmonto <= 0 then 0 ELSE asmonto END as monto
    FROM
	(SELECT SUM(cemonto * ceporcentaje) as montohaberes
		FROM ca.conceptoempleado
		NATURAL JOIN ca.concepto
		NATURAL JOIN ca.conceptoliquidaciontipo
		WHERE idpersona=$3
              and (idconceptotipo = 1   or idconceptotipo=5
                   or idconceptotipo=2 or idconcepto=1105 or idconcepto =1135 or idconcepto =1194
                     or idconcepto =1185)
		      and idconcepto<>14   -- 14 Suplemento por zona desfavorable
            --  and idconcepto<>4    -- 4 premio
             -- and idconcepto<>33  -- 33	Suplemento premio
              and idconcepto <>1133  --horas  extras
              and idconcepto <>996 --horas  extras
              and idconcepto <>1151 --horas  extras
              and idconcepto <>1152 --horas  extras
              and idconcepto <>1156 --zona desfavorable farmacia

		      and idliquidacion=$1
              and idliquidaciontipo=$2
        )as t
		CROSS JOIN ca.asignacion
		NATURAL JOIN ca.asignaciontipo
		WHERE idconcepto=$4
--and (montohaberes<=30000  or idconcepto=28  ) and
and (montohaberes<=36804  or idconcepto=28  ) and
		      (montohaberes >=asmontodesde or nullvalue(asmontodesde) )and
		      ( montohaberes<=asmontohasta or nullvalue(asmontohasta) )
  )	UNION   SELECT 0 as monto ) as temp;

return 	elmonto;
END;
$function$
