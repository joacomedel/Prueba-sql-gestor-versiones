CREATE OR REPLACE FUNCTION public.cerrarordenpagocontable(pidordenpagocontable bigint, pidcentroordenpagocontable integer, pidmultivac bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    rliq RECORD;
    xestado bigint;
   
BEGIN

	select idordenpagocontableestado into xestado from ordenpagocontableestado
	where nullvalue(opcfechafin) and idordenpagocontableestadotipo=5 and idordenpagocontable=pidordenpagocontable and idcentroordenpagocontable=pidcentroordenpagocontable;
        if not found then   -- La OPContable Aun No esta cerrada
          begin
         	insert into multivac.mapeoordenpagocontable(idordenpagocontable,idcentroordenpagocontable,idmultivac)
	        values(pidordenpagocontable,pidcentroordenpagocontable,pidmultivac);
                
                insert into ordenpagocontableestado(idordenpagocontable,idcentroordenpagocontable,idordenpagocontableestadotipo,opcdescripcion)
		values(pidordenpagocontable,pidcentroordenpagocontable,5,'Generado al Cerrar en Multivac la OPContable');

                select idordenpagocontableestadotipo into xestado from ordenpagocontableestado
	        where nullvalue(opcfechafin) and idordenpagocontableestadotipo<>5 and idordenpagocontable=pidordenpagocontable and idcentroordenpagocontable=pidcentroordenpagocontable;

	        if found then
		    update ordenpagocontableestado set opcfechafin=now()
		    where nullvalue(opcfechafin) and idordenpagocontableestadotipo<>5 and idordenpagocontable=pidordenpagocontable and idcentroordenpagocontable=pidcentroordenpagocontable;
     	        end if;
          end;
        end if;


	

	
	
	
     RETURN TRUE;
END;$function$
