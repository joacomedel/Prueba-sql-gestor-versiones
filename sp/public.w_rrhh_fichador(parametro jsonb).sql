CREATE OR REPLACE FUNCTION public.w_rrhh_fichador(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/* {"nrodoc":"28272137","w_rrhh_fichador_accion":"entrada","w_nrodoc":"28272137"} */
DECLARE
--RECORD
      respuestajson jsonb;
      usuariojson jsonb;
      respuestajson_info jsonb; 
      rpersona RECORD;
      vnrodoc varchar;
begin
       select into usuariojson * FROM sys_dar_usuario_web(parametro);
		
		vnrodoc = parametro->>'nrodoc';
		
	   SELECT INTO rpersona * FROM ca.persona WHERE penrodoc = vnrodoc;
	   IF NOT FOUND THEN 
	   		RAISE EXCEPTION 'R-001, No se encuentra la persona.  %',parametro;  
	   ELSE
	   		 IF (parametro->>'w_rrhh_fichador_accion' = 'entrada') THEN
				INSERT INTO ca.movimientos(idpersona,mofecha,mohora,idmovimientotipos,idrelojs,moingreso,moobservacion)  
				VALUES(rpersona.idpersona,current_date,date_trunc('minute', current_timestamp)::time,1,5,'Automatico','Automatico');
        		INSERT INTO ca.auditoriamovimiento(idpersonaauditor,amfecha,amhora,idmovimientotipo,idreloj,idmovimiento,ammotivo) 
				VALUES(rpersona.idpersona,current_date,date_trunc('minute', current_timestamp)::time,1,5,currval(('ca.movimientos_idmovimiento_seq'::text)::regclass),'Automatico');
		
	   		END IF;
			
			 IF (parametro->>'w_rrhh_fichador_accion' = 'salida') THEN

				INSERT INTO ca.movimientos(idpersona,mofecha,mohora,idmovimientotipos,idrelojs,moingreso,moobservacion)  
				VALUES(rpersona.idpersona,current_date,date_trunc('minute', current_timestamp)::time,2,5,'Automatico','Automatico');
        		INSERT INTO ca.auditoriamovimiento(idpersonaauditor,amfecha,amhora,idmovimientotipo,idreloj,idmovimiento,ammotivo) 
				VALUES(rpersona.idpersona,current_date,date_trunc('minute', current_timestamp)::time,2,5,currval(('ca.movimientos_idmovimiento_seq'::text)::regclass),'Automatico');
		
	   		END IF;
			
			
			 SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              	SELECT * FROM ca.movimientos 
				 WHERE idmovimiento = currval(('ca.movimientos_idmovimiento_seq'::text)::regclass) 
				 	
			) as t;
			
			--RAISE EXCEPTION 'R-002, No se encuentra la persona.  %',respuestajson_info ;  
			
			respuestajson_info = concat('{ "w_rrhh_fichador":',respuestajson_info, '}');
            respuestajson = respuestajson_info;
       
	END IF;
	
	    return respuestajson;

end;
$function$
