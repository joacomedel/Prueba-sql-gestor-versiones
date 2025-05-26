CREATE OR REPLACE FUNCTION public.w_afiliaciones_abmsubsidio(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* Carga y busca la informacion de subsidios cargada desde la web
*/
DECLARE
--VARIABLES 
   vmontoctacte DOUBLE PRECISION;
--RECORD
      respuestajson jsonb;
	  controlajson jsonb;
      usuariojson jsonb;
      respuestajson_info jsonb; 
      rpersona RECORD;
     
      rdeclarasubsidio  record;
      vaccion varchar;
      vnrodoc varchar;
     
---idturno
begin
       vaccion = parametro->>'accion';
       
	   select into usuariojson * FROM sys_dar_usuario_web(parametro);
	   
	   IF (parametro->>'accion' = 'w_afiliacion_declara_accion_nuevo') THEN

                SELECT INTO rpersona * FROM persona 
				WHERE (nrodoc = parametro->>'nrodoctitu' OR nrodoc = parametro->>'w_nrodoc');
                IF FOUND THEN 
					INSERT INTO w_afiliacion_declara_subsidio(nrodoctitu,tipodoctitu
							,adsapellido,adsnombres,adsnrodoc,adstipodoc,adsvinculo,adsporciento) 
						VALUES(rpersona.nrodoc,rpersona.tipodoc
							   ,parametro->>'adsapellido',parametro->>'adsnombres',parametro->>'adsnrodoc'
						   	,(parametro->>'adstipodoc')::integer,parametro->>'adsvinculo',(parametro->>'adsporciento')::real);
                 		SELECT INTO controlajson w_afiliaciones_abmsubsidio_controlar(parametro);
					ELSE
                     RAISE EXCEPTION 'R-001, No se encuentra la persona.  %',parametro;  
                 END IF;
                    
       END IF;
	 IF (parametro->>'accion' = 'w_afiliacion_declara_accion_modificar') THEN
                SELECT INTO rpersona * FROM persona 
				                       JOIN w_afiliacion_declara_subsidio ON (nrodoc = nrodoctitu AND tipodoc = tipodoctitu) 
									   WHERE (nrodoc = parametro->>'nrodoctitu' OR nrodoc = parametro->>'w_nrodoc')
									   AND idafiliaciondeclarasubsidio = parametro->>'idafiliaciondeclarasubsidio';
                IF FOUND THEN 
				        UPDATE w_afiliacion_declara_subsidio SET adsfechafinvigencia = now()
                        WHERE idafiliaciondeclarasubsidio = parametro->>'idafiliaciondeclarasubsidio';

						INSERT INTO w_afiliacion_declara_subsidio(nrodoctitu,tipodoctitu,adsapellido
																  ,adsnombres,adsnrodoc,adstipodoc,adsvinculo,adsporciento) 
						VALUES(rpersona.nrodoc,rpersona.tipodoc
							   ,parametro->>'adsapellido',parametro->>'adsnombres',parametro->>'adsnrodoc'
							   ,(parametro->>'adstipodoc')::integer,parametro->>'adsvinculo',(parametro->>'adsporciento')::real);

                 		SELECT INTO controlajson w_afiliaciones_abmsubsidio_controlar(parametro);
				 ELSE
                            RAISE EXCEPTION 'R-001, No se encuentra la declaracion para ser modificada.  %',parametro;  
                 END IF;
                    
       END IF;
	   
	   IF (parametro->>'accion' = 'w_afiliacion_declara_accion_eliminar') THEN
                SELECT INTO rpersona * FROM persona 
				                       JOIN w_afiliacion_declara_subsidio ON (nrodoc = nrodoctitu AND tipodoc = tipodoctitu) 
									   WHERE (nrodoc = parametro->>'nrodoctitu' OR nrodoc = parametro->>'w_nrodoc')
									   AND idafiliaciondeclarasubsidio = parametro->>'idafiliaciondeclarasubsidio';
                IF FOUND THEN 
				        UPDATE w_afiliacion_declara_subsidio SET adsfechafinvigencia = now()
                        WHERE idafiliaciondeclarasubsidio = parametro->>'idafiliaciondeclarasubsidio';
						
						
                 ELSE
                            RAISE EXCEPTION 'R-001, No se encuentra la declaracion para ser eliminada.  %',parametro;  
                 END IF;
                    
       END IF;
	   IF (parametro->>'accion' = 'w_afiliacion_declara_accion_eliminar' 
		   OR parametro->>'accion' = 'w_afiliacion_declara_accion_nuevo' 
             OR parametro->>'accion' = 'w_afiliacion_declara_accion_modificar') THEN 
				SELECT INTO rdeclarasubsidio * 
				FROM w_afiliacion_declara_subsidio 
				WHERE idafiliaciondeclarasubsidio = parametro->>'idafiliaciondeclarasubsidio' 
					AND nullvalue(adsfechafinvigencia);
					
			 
			 
	         respuestajson_info = concat('{ "', vaccion  , '":' , row_to_json(rdeclarasubsidio) , '}');
		     respuestajson = respuestajson_info ;
        END IF;

		IF parametro->>'accion' = 'w_afiliacion_declara_accion' THEN
            SELECT INTO respuestajson w_afiliaciones_abmsubsidio_buscar(parametro);
    	END IF; 

       IF parametro->>'accion' = 'w_afiliacion_declara_accion_tipodoc' THEN
             
            select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              SELECT * FROM  public.tiposdoc
			
            ) as t;

            respuestajson_info = concat('{ "w_afiliacion_declara_accion_tipodoc":' , respuestajson_info , '}');
            respuestajson = respuestajson_info;
      
		
       END IF; 
	   return respuestajson;

end;
$function$
