CREATE OR REPLACE FUNCTION public.practconvval_cambiavigencia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN

IF TG_OP = 'UPDATE' THEN 
    IF NEW.tvvigente = FALSE THEN
         NEW.pcvsis = now(); 
    ELSE
        NEW.pcvfechamodifica = now();
    END IF;
END IF;

IF TG_OP = 'INSERT' THEN 
    IF NEW.tvvigente = TRUE THEN
         NEW.pcvsis = now(); 
         NEW.pcvfechamodifica = now();
    END IF;
END IF;


RETURN NEW;
END;
$function$
