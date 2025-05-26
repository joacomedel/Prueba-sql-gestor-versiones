CREATE OR REPLACE FUNCTION public.sys_ejecutarconsulta(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	xidasiento bigint;
	curasiento refcursor;	
	rag_r RECORD;
        xfechaimputa DATE;
--RECORD  
        regasiento RECORD;
        rejerciciocontable RECORD;
        rasientodesbalanceado RECORD;
        rasientocondiferencia RECORD;
        ridsiges RECORD;
        rfiltros RECORD;
        rusuario RECORD;
BEGIN



--- OPEN curasiento FOR SELECT * FROM correr_consulta where not corrida order by ccconsulta LIMIT 1000;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
 

OPEN curasiento FOR  SELECT * FROM correr_consulta 
                     WHERE not corrida  
                           and (rusuario.idusuario = ccidusuario OR ccidusuario = 39 OR ccidusuario = 46) 
       AND        rfiltros.elproceso ilike cctipoproceso 
       LIMIT 450;
      --limit 50;



FETCH curasiento INTO regasiento;
WHILE FOUND LOOP
--BEGIN
EXECUTE concat('SELECT ',regasiento.ccconsulta);
UPDATE correr_consulta SET corrida = true WHERE idcconsunsulta = regasiento.idcconsunsulta;
--COMMIT;
--EXCEPTION
--WHEN OTHERS THEN
--ROLLBACK;
--raise notice 'program_error';
--END;

FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN true;
END;$function$
