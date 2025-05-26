CREATE OR REPLACE FUNCTION ca.f_horaextrascincuenta(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
      
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_bruto(#,&, ?,@)
SELECT INTO elmonto CASE WHEN nullvalue( ca.f_valorhora ($1,$2,$3,$4) )THEN 0
       ELSE  (ca.f_valorhora ($1,$2,$3,$4)*1.5) END;
return elmonto ;
END;
$function$
