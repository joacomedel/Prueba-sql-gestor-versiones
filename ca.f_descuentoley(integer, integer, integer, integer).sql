CREATE OR REPLACE FUNCTION ca.f_descuentoley(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
     
       montodescuentoley  DOUBLE PRECISION;
    
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

              
               
               SELECT INTO montodescuentoley SUM(ceporcentaje * cemonto)
                      FROM ca.conceptoempleado
                      WHERE idpersona=$3 and idliquidacion =$1 and
                            (idconcepto =200 -- jubilacion
                            or idconcepto = 201  -- ley 19032
                            or idconcepto = 202 -- sosunc
                            or idconcepto =  989  -- Ret de 4
                            or idconcepto =  1170  -- Rem y/o haber no sujeto Imp.gcias.Benef.Dto.PEN 1242/2013
                            or idconcepto =  1094  -- 	Embargo Judicial
                      ) ;
               


return montodescuentoley;
END;
$function$
