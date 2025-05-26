CREATE OR REPLACE FUNCTION ca.f_valorconceptofijo(integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$ 
DECLARE
 
       valor DOUBLE PRECISION;

BEGIN
      valor=0;

     -- Busco el monto del concepto

     SELECT INTO valor  ctmontominimo
     FROM ca.conceptotope 
     WHERE idconcepto =$1 and nullvalue(ctfechahasta);


return valor;
end;
$function$
