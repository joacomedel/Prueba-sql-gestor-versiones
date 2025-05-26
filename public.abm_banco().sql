CREATE OR REPLACE FUNCTION public.abm_banco()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD                  
rbanco RECORD; 
relbanco RECORD; 

--VARIABLES 
vidbanco BIGINT;
                          
BEGIN
 
SELECT INTO rbanco * FROM banco_temp;     

IF (nullvalue(rbanco.idbanco)) THEN
--el banco es nuevo y se quiere guardar 
  --KR 12-09-22 Modifique el proceso, el idbanco de la tabla NO es el codigo de la entidad bancaria
  SELECT INTO relbanco * FROM banco WHERE bacodigoentidad = rbanco.bacodigoentidad;
  IF FOUND THEN 
    RAISE EXCEPTION 'Existe otra entidad bancaria con ese codigo de banco. No es posible guardar el dato !  (%)',relbanco; 
  ELSE 
-- El banco no existe 
     SELECT INTO vidbanco max(idbanco)+1 FROM banco;
     INSERT INTO banco (idbanco, nombrebanco,bacodigoentidad,baactivo) VALUES    (vidbanco,rbanco.nombrebanco,rbanco.bacodigoentidad,rbanco.baactivo);
  END IF;   
ELSE
     UPDATE banco SET nombrebanco = rbanco.nombrebanco, baactivo= rbanco.baactivo, bacodigoentidad= rbanco.bacodigoentidad
	WHERE idbanco =rbanco.idbanco;
  END IF;


return true;

END;$function$
