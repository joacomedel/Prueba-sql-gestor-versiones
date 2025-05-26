CREATE OR REPLACE FUNCTION public.w_pruebaws(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE
      
       respuesta character varying;
begin
      respuesta = 'Pepe';
      return respuesta;

end;
$function$
