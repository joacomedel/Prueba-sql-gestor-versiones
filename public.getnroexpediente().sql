CREATE OR REPLACE FUNCTION public.getnroexpediente()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Funcion que devuelve el nro de expediente consecutivo para un determinado centro*/
DECLARE
	
    ridrecibo BIGINT;
	siguiente INTEGER;
BEGIN

     SELECT INTO siguiente MAX(enumero)+1
     FROM expediente WHERE idcentrodocumento = centro() AND eanio =  extract(year from now()) ;
     IF(nullvalue(siguiente)) THEN 
         siguiente = 1;
     END IF; 

RETURN siguiente;
END;
$function$
