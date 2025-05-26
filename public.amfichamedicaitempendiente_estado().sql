CREATE OR REPLACE FUNCTION public.amfichamedicaitempendiente_estado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
    rverifica RECORD;
    regusuario RECORD;
    BEGIN
         select into regusuario * from log_tconexiones where idconexion=current_timestamp;
        SELECT INTO rverifica * FROM fichamedicaitempendienteestado 
		WHERE idfichamedicaitempendiente = NEW.idfichamedicaitempendiente AND idcentrofichamedicaitempendiente = NEW.idcentrofichamedicaitempendiente 
		AND nullvalue(fmipfechafin);
	IF NOT FOUND THEN 
		INSERT INTO fichamedicaitempendienteestado(idfichamedicaitempendiente,idcentrofichamedicaitempendiente,idfichamedicaemisionestadotipo,fmipidusuario) 
		VALUES(NEW.idfichamedicaitempendiente,NEW.idcentrofichamedicaitempendiente,1,regusuario.idusuario);

	END IF;
        return NEW;
    END;
    $function$
