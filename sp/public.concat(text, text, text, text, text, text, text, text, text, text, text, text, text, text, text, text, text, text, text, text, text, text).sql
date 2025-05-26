CREATE OR REPLACE FUNCTION public.concat(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text)
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


	IF $5 is not null THEN 
 	 	   texto = texto || $5; 
	 END IF; 


	IF $6 is not null THEN 
 	 	   texto = texto || $6; 
	 END IF; 


	IF $7 is not null THEN 
 	 	   texto = texto || $7; 
	 END IF; 


	IF $8 is not null THEN 
 	 	   texto = texto || $8; 
	 END IF; 


	IF $9 is not null THEN 
 	 	   texto = texto || $9; 
	 END IF; 


	IF $10 is not null THEN 
 	 	   texto = texto || $10; 
	 END IF; 


	IF $11 is not null THEN 
 	 	   texto = texto || $11; 
	 END IF; 


	IF $12 is not null THEN 
 	 	   texto = texto || $12; 
	 END IF; 


	IF $13 is not null THEN 
 	 	   texto = texto || $13; 
	 END IF; 


	IF $14 is not null THEN 
 	 	   texto = texto || $14; 
	 END IF; 

IF $15 is not null THEN 
 	 	   texto = texto || $15; 
	 END IF; 

IF $16 is not null THEN 
 	 	   texto = texto || $16; 
	 END IF; 

IF $17 is not null THEN 
 	 	   texto = texto || $17; 
	 END IF; 

IF $18 is not null THEN 
 	 	   texto = texto || $18; 
	 END IF; 

IF $19 is not null THEN 
 	 	   texto = texto || $19; 
	 END IF; 

IF $20 is not null THEN 
 	 	   texto = texto || $20; 
	 END IF; 

IF $21 is not null THEN 
 	 	   texto = texto || $21; 
	 END IF; 

IF $22 is not null THEN 
 	 	   texto = texto || $22; 
	 END IF; 




  	 RETURN texto; 
  END $function$
