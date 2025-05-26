CREATE OR REPLACE FUNCTION ca.f_calculaimportededucciones(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       topodescley DOUBLE PRECISION;
       losimportes record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_bruto(#,&, ?,@)
SELECT INTO topodescley ca.f_retencionesley($1,$2,$3,null);


IF ($4 = 387) THEN -- cta cte asistencial
		   SELECT INTO losimportes ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null),
					 ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null) as bruto,
 					(ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null)-ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null))*0.4 as tope,
 					SUM(cemonto*ceporcentaje) as importededucciones
 			FROM ca.conceptoempleado
 			NATURAL JOIN ca.liquidacion
 			NATURAL JOIN ca.concepto
		    WHERE idconceptotipo=8
 			and idliquidacion=$1 and idpersona=$2
 			and idconcepto = 387 
			group by idpersona,idliquidacion,idliquidaciontipo ;


END IF;

IF ($4 = 360) THEN -- turismo
		   SELECT INTO losimportes ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null),
					 ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null) as bruto,
 					(ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null)-ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null))*0.4 as tope,
 					SUM(cemonto*ceporcentaje) as importededucciones
 			FROM ca.conceptoempleado
 			NATURAL JOIN ca.liquidacion
 			NATURAL JOIN ca.concepto
		    WHERE idconceptotipo=8
 			and idliquidacion=$1 and idpersona=$2
 			and (
 				idconcepto = 387 or
   				idconcepto = 360 
 				)
			group by idpersona,idliquidacion,idliquidaciontipo ;



END IF;

IF ($4 = 990) THEN -- cta prestamo impaco
		   SELECT INTO losimportes ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null),
					 ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null) as bruto,
 					(ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null)-ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null))*0.4 as tope,
 					SUM(cemonto*ceporcentaje) as importededucciones
 			FROM ca.conceptoempleado
 			NATURAL JOIN ca.liquidacion
 			NATURAL JOIN ca.concepto
		    WHERE idconceptotipo=8
 			and idliquidacion=$1 and idpersona=$2
 			and (
 				idconcepto = 387 or
   				idconcepto = 360 or
   				idconcepto = 990 
 				)
			group by idpersona,idliquidacion,idliquidaciontipo ;
END IF;


IF ($4 = 991) THEN -- cta prestamo amuc
		   SELECT INTO losimportes ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null),
					 ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null) as bruto,
 					(ca.f_bruto(idliquidacion,idliquidaciontipo,idpersona,null)-ca.f_retencionesley(idliquidacion,idliquidaciontipo,idpersona,null))*0.4 as tope,
 					SUM(cemonto*ceporcentaje) as importededucciones
 			FROM ca.conceptoempleado
 			NATURAL JOIN ca.liquidacion
 			NATURAL JOIN ca.concepto
		    WHERE idconceptotipo=8
 			and idliquidacion=$1 and idpersona=$2
 			and (
 				idconcepto = 387 or
   				idconcepto = 360 or
   				idconcepto = 990 or
   				idconcepto = 991
 				)
			group by idpersona,idliquidacion,idliquidaciontipo ;
END IF;



return elmonto;
END;
$function$
