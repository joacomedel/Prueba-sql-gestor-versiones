CREATE OR REPLACE FUNCTION ca.f_setdiasvacacionesnogozadas(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
      cantdias double precision;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_aguinaldo(#,&, ?,@)

--- Calcula la cantidad de dias trabajados por un empleado
            SELECT INTO cantdias (ceporcentaje * cemonto) FROM ca.conceptoempleado  WHERE idconcepto = 1150  and idliquidacion=$1 and idpersona=$3;
            
            UPDATE ca.conceptoempleado
            SET  ceporcentaje = cantdias
            WHERE idconcepto = 1068  and idliquidacion=$1 and idpersona=$3;

return 1;
END;
$function$
