CREATE OR REPLACE FUNCTION public.far_cambiarestadoliquidacionitem(integer, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

BEGIN 

	 UPDATE far_liquidacionitemestado SET liefechafin = now()  WHERE idliquidacionitem=$1 AND idcentroliquidacionitem=$2 AND nullvalue(liefechafin);
	 INSERT INTO far_liquidacionitemestado(idcentroliquidacionitem,idliquidacionitem,idestadotipo,liedescripcion,liefechaini)
	 VALUES($2,$1,$3,$4,now());
    
  return true;
END;
$function$
