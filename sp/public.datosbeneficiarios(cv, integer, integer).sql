CREATE OR REPLACE FUNCTION public.datosbeneficiarios(character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  resultado boolean;
  rpersona RECORD;  

BEGIN
    SELECT INTO rpersona * FROM persona WHERE nrodoc = $1;
    IF FOUND THEN 
    if(rpersona.barra <= 99 ) THEN
        SELECT INTO resultado * FROM datosbenefiaciariososunc($1,rpersona.tipodoc,rpersona.barra);
       
    ELSE 
        SELECT INTO resultado * FROM datosbenefiaciarioreci($1,rpersona.tipodoc,rpersona.barra) ;
    
    END IF;
    END IF;
   RETURN resultado;
END;
$function$
