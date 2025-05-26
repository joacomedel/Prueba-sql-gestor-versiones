CREATE OR REPLACE FUNCTION ca.diastrabajdosinstitucion(integer, integer, integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       liq record;
       rangofechalsgh record;
       cantdias INTEGER;
       cantdiaslsgh INTEGER;
tienelic boolean;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     --f_funcion(#,&, ?,@)
/*Modifica Malapi 20-12-2012 para que en lugar de tomar el dia actual, tome el ultimo día de la liquidacion 
Esto puede tener problemas cuando la liq se inicia antes del primer dia de la liq. */
cantdiaslsgh=0;



     SELECT INTO liq * FROM ca.liquidacion WHERE idliquidacion = $1;
     
     SELECT  into cantdias (((date_trunc('month', (concat(liq.lianio ,'-',liq.limes,'-1'))::date ) + interval '1 month') - interval '1 day')::date  - emfechadesde::date)
     FROM ca.empleado
     WHERE idpersona =$3;

return cantdias;
END;
$function$
