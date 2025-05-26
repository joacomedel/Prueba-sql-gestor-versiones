CREATE OR REPLACE FUNCTION public.existecolumtemp(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  	
    respuesta boolean;
  	latabla varchar;
  	elcampo varchar;
  	rtemporal record;
BEGIN
     respuesta = false;
     latabla = $1;
     elcampo = $2;

     SELECT INTO rtemporal *
     FROM information_schema.columns
     WHERE table_name= latabla AND column_name = elcampo;

     IF FOUND THEN
        respuesta = true;
     END IF;

     RETURN respuesta;
END;
$function$
