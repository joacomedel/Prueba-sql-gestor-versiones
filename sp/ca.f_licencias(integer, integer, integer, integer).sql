CREATE OR REPLACE FUNCTION ca.f_licencias(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       cociente DOUBLE PRECISION;
       divisor DOUBLE PRECISION;
             elmonto DOUBLE PRECISION;
             valordia record;
       
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_basico(#,&, ?,@)

-- concepto porcentaje que trabaja de una jornada de 8 horas
--vivi 270911 SELECT INTO  divisor cemonto from ca.conceptoempleado WHERE idconcepto=998 and idpersona=$3 and idliquidacion=$1;

--Concepto Licencia
-- vivi 270911 SELECT INTO cociente  ceporcentaje from ca.conceptoempleado WHERE idconcepto=$4 and idpersona=$3 and idliquidacion=$1;

-- Retornar el monto que tenia el concepto
/*SELECT INTO elmonto CASE WHEN  nullvalue(cemonto) THEN 0 ELSE cemonto END
from ca.conceptoempleado
WHERE idconcepto=$4 and idpersona=$3 and idliquidacion=$1;
*/
/*301112
      SELECT INTO  lalicencia *
      from ca.conceptoempleado
      WHERE idconcepto=$4 and idpersona=$3 and idliquidacion=$1;
*/
  -- Recupero el valor del dia de trabajo 
--Dani modifico 30122013 para q obtenga el valor dia segun sea una liquidacion de sosunc o de farmacia
--esto proviene de la necesidad de descontar dias a un empleado concepto 1145

      if($2=1 or $2=6) then 
         SELECT INTO  valordia *
         from ca.conceptoempleado
          WHERE idconcepto=1 and idpersona=$3 and idliquidacion=$1 ;
     END IF;
      if($2=2 or $2=5) then 
        SELECT INTO  valordia *
         from ca.conceptoempleado
          WHERE idconcepto=1028 and idpersona=$3 and idliquidacion=$1 ;
     
     END IF;
RAISE notice 'esto tiene el valordia (%)',valordia;

    
     
         IF $4 = 1112 THEN
                 elmonto= 0.5 * valordia.cemonto;

     
 
          ELSE
                 IF ($4 = 1145 or $4 = 1186 or $4 = 1274) THEN --falta injustificada o Sancion Disciplinaria
               RAISE notice 'esto tiene el elmonto en el no es nulo y es concepto 1145(%)',elmonto;

                   elmonto= -1 * valordia.cemonto;
                 else
                    elmonto= valordia.cemonto;
                  END IF;
          END IF;
              
      

    /*  UPDATE ca.conceptoempleado SET cemonto = elmonto
      WHERE idconcepto=$4 and idpersona=$3 and idliquidacion=$1;*/

return elmonto;
END;
$function$
