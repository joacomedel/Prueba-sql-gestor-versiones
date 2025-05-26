CREATE OR REPLACE FUNCTION public.recetarioestadossetrefechafin()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
 
BEGIN
  UPDATE recetarioestados SET refechafin = now()
  WHERE recetarioestados.nrorecetario = NEW.nrorecetario AND recetarioestados.centro = NEW.centro AND nullvalue(refechafin);

  RETURN NEW;
END;
$function$
