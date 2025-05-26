CREATE OR REPLACE FUNCTION public.amfichamedicaitempendienteestado_estado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE

    BEGIN

	IF TG_OP = 'INSERT' THEN
        UPDATE fichamedicaitempendienteestado SET fmipfechafin = now() 
        	WHERE idfichamedicaitempendiente = NEW.idfichamedicaitempendiente AND idcentrofichamedicaitempendiente = NEW.idcentrofichamedicaitempendiente 
		AND nullvalue(fmipfechafin) AND idfichamedicaemisionestadotipo <> NEW.idfichamedicaemisionestadotipo;
	IF FOUND THEN 
		
	END IF;
	END IF;
        return NEW;
    END;
    $function$
