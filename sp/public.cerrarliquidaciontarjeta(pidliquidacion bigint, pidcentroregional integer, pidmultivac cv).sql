CREATE OR REPLACE FUNCTION public.cerrarliquidaciontarjeta(pidliquidacion bigint, pidcentroregional integer, pidmultivac character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rliq RECORD;
    xestado bigint;
   
BEGIN

	select idestadoliquidaciontarjeta into xestado from liquidaciontarjetaestado
	where nullvalue(ltefechafin) and idtipoestadoliquidaciontarjeta=2 and idliquidacion=pidliquidacion and idcentroregional=pidcentroregional;
        if not found then   -- La Liq Aun No esta cerrada
          begin
         	--insert into multivac.mapeoliquidaciontarjeta(idliquidacion,idcomprobantemultivac)
                insert into mapeoliquidaciontarjeta(idliquidacion,idcomprobantemultivac)
	        values(pidliquidacion,pidmultivac);
                
                insert into liquidaciontarjetaestado(idliquidacion,idtipoestadoliquidaciontarjeta)
		values(pidliquidacion,2);

                select idestadoliquidaciontarjeta into xestado from liquidaciontarjetaestado
	        where nullvalue(ltefechafin) and idtipoestadoliquidaciontarjeta<>2 and idliquidacion=pidliquidacion;

	        if found then
		    update liquidaciontarjetaestado set ltefechafin=now()
		    where idestadoliquidaciontarjeta=xestado and idliquidacion=pidliquidacion and idcentroregional=pidcentroregional and idtipoestadoliquidaciontarjeta<>2 and nullvalue(ltefechafin);
     	        end if;
          end;
        end if;

	
     RETURN TRUE;
END;$function$
