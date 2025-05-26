CREATE OR REPLACE FUNCTION ca.f_asignaciondarmontoescala(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       montoliq DOUBLE PRECISION;
       impzona DOUBLE PRECISION;
       elmontocomp  DOUBLE PRECISION;
     --  canthijos integer;
         rmontoliqmat record;
       recliquidacion record;
       elconcepto record;
       elconceptoayuda record;
       rinfovinculo record;
       rmonto record;
       elmes integer ;
       elanio integer;
       elidliqcomplementaria integer;
     
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
 --------------------------------------------------------------------------
  ------------    VERIFICO SI SE TRATA de una liq complementaria -----------
  --------------------------------------------------------------------------
  SELECT INTO elidliqcomplementaria tliqcomp.idliquidacion
  FROM ca.liquidacion as tliq
--Agrego Dani el 27-02-2018 para contemplar q no tenga una liq complementaria asociada
  left JOIN ca.liquidacion as tliqcomp ON (tliq.idliqcomplementaria=tliqcomp.idliquidacion)
  WHERE tliq.idliquidacion = $1;
  
 --------------------------------------------------------------------------
 ------------    VERIFICO SI SE LA PERSONA ESTA EN LIC. MATERNIDAD -----------
 --------------------------------------------------------------------------
 impzona = 0;  -- valor de la zona
 SELECT INTO rmontoliqmat  (cemonto * ceporcentaje) as montomaternidad , *
 FROM ca.conceptoempleado
 WHERE idliquidacion = $1 and idconcepto = 1105 and idpersona= $3;
 IF FOUND THEN -- hay que restar el valor de la zona
        SELECT  INTO impzona case when nullvalue( (coporcentaje * ca.f_basico($1,$2, $3,$4) * rmontoliqmat.ceporcentaje )) then 0 else (coporcentaje * ca.f_basico($1,$2, $3,$4) * rmontoliqmat.ceporcentaje ) end as impzona
        FROM ca.concepto
        WHERE idconcepto = 14;
 END IF;
  
 SELECT INTO elmonto sum(monto)
 FROM ((SELECT CASE  WHEN   asmonto <= 0 then 0 ELSE asmonto END as monto
    FROM
	(SELECT SUM(cemonto * ceporcentaje) as montohaberes
		FROM ca.conceptoempleado
		NATURAL JOIN ca.concepto
		NATURAL JOIN ca.conceptoliquidaciontipo
		NATURAL JOIN ca.liquidacion
		WHERE idpersona=$3
              and (idconceptotipo = 1    -- Adicionales
                   or idconceptotipo=5   -- Basicos
                   or idconceptotipo=2   -- Suplemento
                   or idconcepto=1105    -- Bruto para Licencia por Maternidad
                   or idconcepto =1135   -- Art. 22 (bis) Adicional Voluntario
                   or idconcepto =1194   -- Asignacion Extraordinaria art. 22 bis C.C.T. 659?
                   or idconcepto =1185   -- Acta Acuerdo Abril 2014-15
                   or idconcepto =1212   -- vas 11/17 Acta acuerdo 2017/2018
                   or idconcepto =1218   --vas 11/17  Asignacion extraordinaria
                   or idconcepto =1175   --  Fdo. Comp. Falla Caja Art 23
                   or idconcepto =1226   -- vas 26/07 Julieta
                   or idconcepto =1046   -- vas 26/07 Julieta
                   or idconcepto =1222   -- vas 26/07 Julieta
                   or idconcepto =1211   -- vas 30/10/18 Julieta

                   )
	      and idconcepto<>14   -- 14 Suplemento por zona desfavorable
            --  and idconcepto<>4    --  premio
             -- and idconcepto<>33  -- 	Suplemento premio
              and idconcepto <>1133  -- Horas Extras 100%
              and idconcepto <>996 -- Horas Extras  50%
              and idconcepto <>1151 -- Zona Desfavorable
              and idconcepto <>1152 -- titulo farmaceutico
              and idconcepto <>1156 --zona desfavorable farmacia
	      and ( (idliquidacion=$1  and idliquidaciontipo=$2)
	            OR (not nullvalue(elidliqcomplementaria)  and idliquidacion = elidliqcomplementaria)
                   )
		
        )as t
		CROSS JOIN ca.asignacion
		NATURAL JOIN ca.asignaciontipo
		WHERE idconcepto=$4
              --and (montohaberes<=30000  or idconcepto=28  ) and
             -- and ((montohaberes-impzona)<=47393  or idconcepto=28  ) and ---- (***)
                and ((montohaberes-impzona)<=41959  or idconcepto=28  ) and ---- (***)
		      ((montohaberes-impzona) >=asmontodesde or nullvalue(asmontodesde) )and
		      ( (montohaberes-impzona)<=asmontohasta or nullvalue(asmontohasta) )
  )	UNION   SELECT 0 as monto ) as temp;




        -- Busco si se liquidaco el concepto
        SELECT INTO montoliq  cemonto FROM ca.conceptoempleado
        WHERE idliquidacion = elidliqcomplementaria and idconcepto = $4 and idpersona= $3;
        IF FOUND THEN
           elmonto = elmonto - montoliq;

         END IF;

   

return 	elmonto;
END;
$function$
