CREATE OR REPLACE FUNCTION public.calculardisponible_ctacteafil()
 RETURNS trigger
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
       vnrodoc varchar;
       vtipodoc integer;
       
BEGIN
  /* New function body */

   vnrodoc = NEW.nrodoc; 
   vtipodoc= NEW.tipodoc;
   PERFORM calcularmontosdisponibles(CONCAT('{nrodoc =',vnrodoc, 'tipodoc =', vtipodoc,'}'));
   

  RETURN NEW;
END;
$function$
