CREATE OR REPLACE FUNCTION public.actualizabandejaimpresion(pidcomprobantetipos integer, pcantidad integer, pbiip character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

       rbandeja record;
       rconfig record;
       recargar boolean;

begin
recargar = false;

	SELECT INTO rconfig cacantidadorden, catiempo, idconfiguraautogestion, cacantidadpaginas, caconamuc, idcomprobantetipos
		FROM configuraautogestion
		WHERE idcomprobantetipos =  pidcomprobantetipos AND cacantidadorden=pcantidad;
	IF FOUND THEN 
		UPDATE configurabandejaimpresion SET 
			bicantidad = bicantidad - rconfig.cacantidadpaginas 
			WHERE biip = pbiip;
                SELECT INTO rbandeja * FROM configurabandejaimpresion WHERE biip = pbiip; 
	        IF FOUND THEN 
                     recargar = rbandeja.bicantidad < 50;
                END IF;      
	END IF;

return recargar;
end;
$function$
