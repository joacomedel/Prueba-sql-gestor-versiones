CREATE OR REPLACE FUNCTION public.concat(text, text, text, text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$ 
   DECLARE 
  	texto text; 
  BEGIN 
  --RECORDAR ELIMINAR ESTA FUNCION ANTES DE MIGRAR EL MOTOR!! 
  	 texto = ''; 
 	IF $1 is not null THEN 
 	 	   texto = texto || $1; 
	 END IF; 


	IF $2 is not null THEN 
 	 	   texto = texto || $2; 
	 END IF; 


	IF $3 is not null THEN 
 	 	   texto = texto || $3; 
	 END IF; 


	IF $4 is not null THEN 
 	 	   texto = texto || $4; 
	 END IF; 



  	 RETURN texto; 
  END $function$
