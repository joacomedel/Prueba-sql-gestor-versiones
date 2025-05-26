CREATE OR REPLACE FUNCTION public.cerrarliquidaciontarjeta(pidliquidacion integer, pidmultivac character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rliq RECORD;
    xestado bigint;
 id bigint;
 cen integer;
   
BEGIN

  id = pidliquidacion/100;
  cen = pidliquidacion%100;


	select idestadoliquidaciontarjeta into xestado from liquidaciontarjetaestado
	where nullvalue(ltefechafin) and idtipoestadoliquidaciontarjeta=2 and idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen;
        if not found then   -- La Liq Aun No esta cerrada
          begin
         	insert into mapeoliquidaciontarjeta(idliquidaciontarjeta,idcentroliquidaciontarjeta,idcomprobantemultivac)
	        values(id,cen,pidmultivac);
                
                insert into liquidaciontarjetaestado(idliquidaciontarjeta,idcentroliquidaciontarjeta,idtipoestadoliquidaciontarjeta)
		values(id,cen,2);

                select idestadoliquidaciontarjeta into xestado from liquidaciontarjetaestado
	        where nullvalue(ltefechafin) and idtipoestadoliquidaciontarjeta<>2 and idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen;

	        if found then
		    update liquidaciontarjetaestado set ltefechafin=now()
		    where idestadoliquidaciontarjeta=xestado and idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen and idtipoestadoliquidaciontarjeta<>2 and nullvalue(ltefechafin);
     	        end if;
          end;
        end if;

     RETURN TRUE;
END;
$function$
