CREATE OR REPLACE FUNCTION public.far_espadre_rtpi(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 --VARIABLES
  respuesta BOOLEAN DEFAULT false;
--RECORD
  elem RECORD;  
   
BEGIN
  
  SELECT INTO elem * FROM recetariotpitem WHERE idrecetarioitempadre = $1  AND idcentrorecetariotpitem= $2;
  IF FOUND THEN 
     respuesta = true; 
  END IF; 
 


return respuesta;
END;$function$
