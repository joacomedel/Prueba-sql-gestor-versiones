CREATE OR REPLACE FUNCTION public.ctacte_controlarmovimiento(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD                  
rbanco RECORD; 

--VARIABLES 
vidbanco BIGINT;
                          
BEGIN
 
SELECT INTO rbanco * FROM banco_temp;     

IF (nullvalue(rbanco.idbanco)) THEN
-- El banco no existe y es nuevo
     SELECT INTO vidbanco max(idbanco)+1 FROM banco;
     INSERT INTO banco (idbanco, nombrebanco,bacodigoentidad,baactivo) VALUES (vidbanco,rbanco.nombrebanco,rbanco.bacodigoentidad,rbanco.baactivo);
     
ELSE
     UPDATE banco SET nombrebanco = rbanco.nombrebanco, baactivo= rbanco.baactivo, bacodigoentidad= rbanco.bacodigoentidad
	WHERE idbanco =rbanco.idbanco;
  
END IF;
 

return varchar;

END;$function$
