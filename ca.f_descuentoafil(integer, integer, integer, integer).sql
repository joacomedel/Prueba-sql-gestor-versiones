CREATE OR REPLACE FUNCTION ca.f_descuentoafil(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
     
       montodescuentoafil  DOUBLE PRECISION;
    
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

              
               
             SELECT INTO  montodescuentoafil CASE WHEN nullvalue (SUM(ceporcentaje * cemonto) ) then 0
                       ELSE SUM(ceporcentaje * cemonto) END
                      FROM ca.conceptoempleado NATURAL JOIN CA.CONCEPTO
                      WHERE idpersona=$3 and idliquidacion =$1 and
                              idconceptotipo = 3 --Retenciones(jub, ley,sosunc, sosunc conyuge, apunc, amuc,inpaco
                      ;

               


return montodescuentoafil;
END;
$function$
