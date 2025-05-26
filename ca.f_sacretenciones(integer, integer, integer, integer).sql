CREATE OR REPLACE FUNCTION ca.f_sacretenciones(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       elporcentaje DOUBLE PRECISION;
       rliqact record;
       rliqant record;
       rceliqant record;
BEGIN

--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_bruto(#,&, ?,@)
SELECT INTO elmonto *  FROM ca.f_remunerativo($1,$2,$3,$4);
IF ( ($2 = 3 or $2=4  ) -- SAC sosunc / farm
   and $3 = 3 -- VAS
   and ($4 = 204 or $4=203 or $4= 207)
   ) THEN -- Garantizar que se realicen los descuentos amuc apunc inpaco
       
        SELECT INTO rliqact * FROM ca.liquidacion WHERE idliquidacion = $1;
        SELECT INTO rliqant * FROM ca.liquidacion WHERE limes = rliqact.limes and lianio = rliqact.lianio and idliquidaciontipo <> rliqact.idliquidaciontipo ;
        IF FOUND THEN
                 -- busco en laliq de sueldos
                 SELECT INTO rceliqant *
                 FROM ca.conceptoempleado
                 WHERE idpersona = $3 and idliquidacion = rliqant.idliquidacion and idconcepto = $4;
                 IF NOT FOUND THEN
                        elporcentaje = 0;
                 ELSE
                        elporcentaje = rceliqant.ceporcentaje;
                 END IF;
                 ---- actualizo el porcentaje
                 UPDATE ca.conceptoempleado SET ceporcentaje = elporcentaje
                 WHERE idpersona = $3
                       and idliquidacion= $1
                       and idconcepto = $4;
                 
        END IF;
       
END IF;
        
return elmonto;
END;
$function$
