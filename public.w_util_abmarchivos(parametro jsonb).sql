CREATE OR REPLACE FUNCTION public.w_util_abmarchivos(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"nrodoc":"28272137","idlicenciatipo":1,"lifechainicio":"2020-01-01","w_licencia_accion":"nuevo","lifechafin":"2020-01-01","leobservacion":"2020-01-01","idlicencia":0}
* 13-07-2021 MaLaPi Agrego los datos del usuario
  {"accion":"w_licencia_accion","idpersona":"0","nrodoc":"28272137","pnombreapellido":"null","ejecutar":"rrhh_abmlicencias","w_idusuario":4874,"w_nrodoc":"28272137","w_idrol":3,"w_Nombre":"Pino, Maria Laura ","uwnombre":"usucbrn"}
*/
DECLARE
--VARIABLES 
   vmontoctacte DOUBLE PRECISION;
--RECORD
      respuestajson jsonb;
      usuariojson jsonb;
      respuestajson_info jsonb; 
      rpersona RECORD;
     
      vidarchivo bigint;
      rarchivo  record;
      vaccion varchar;
      vnrodoc varchar;
	  vyabusque boolean;
     
---idturno
begin
       vaccion = parametro->>'accion';
	   vyabusque = false;
       select into usuariojson * FROM sys_dar_usuario_web(parametro);

        IF (parametro->>'accion' = 'w_archivo_accion_nuevo') THEN
				INSERT INTO w_archivo (ardescripcion,arnombre, arubicacion, arextension, idusuarioweb, armd5nombre)
			     VALUES(parametro->>'ardescripcion',parametro->>'arnombre',parametro->>'arubicacion',parametro->>'arextension',(usuariojson->>'idusuario')::integer,concat(md5(arnombre),'.', arextension));
	 	  		 vidarchivo = currval('archivo_idarchivo_seq'::regclass);
				 
				 --MaLaPi se trata de una archivo para un formulario terapeutico
				 IF not nullvalue(parametro->>'idfichamedicainfoformulario') THEN 
				 	 INSERT INTO fichamedicainfoformularioarchivo (idarchivo,idcentroarchivo,idfichamedicainfoformulario,idcentrofichamedicainfoformulario)
				     VALUES(vidarchivo,centro(),parametro->>'idfichamedicainfoformulario',parametro->>'idcentrofichamedicainfoformulario');
				 END IF;
	
       END IF;
	   IF (parametro->>'accion' = 'w_archivo_accion_modificar') THEN
             
       END IF;
	
		IF parametro->>'accion' = 'w_archivo_accion_buscar' THEN
		    
			 --MaLaPi se trata de buscar archivos para un formulario en particular
				 IF not nullvalue(parametro->>'idfichamedicainfoformulario') THEN 
				 	vyabusque = true;
					select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             			from ( 
              				SELECT * 
							FROM w_archivo 
							NATURAL JOIN fichamedicainfoformularioarchivo
							WHERE idfichamedicainfoformulario = parametro->>'idfichamedicainfoformulario' 
							 	AND  idcentrofichamedicainfoformulario = parametro->>'idcentrofichamedicainfoformulario'
				        ) as t;
				 END IF;
		
		        IF not vyabusque THEN 
					  select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             			from ( 
              				SELECT * 
							FROM w_archivo 
							LIMIT 10
				        ) as t;
				END IF;
            

            respuestajson_info = concat('{ "w_archivo_accion_buscar":',respuestajson_info, '}');
            respuestajson = respuestajson_info;
			
    	END IF; 

       IF parametro->>'accion' = 'w_archivo_accion_buscar_licenciatipos' THEN
             
            --respuestajson_info = concat('{ "w_licencia_accion_buscar_licenciatipos":',respuestajson_info, '}');
            --respuestajson = respuestajson_info;

      
		
       END IF; 

	
	
        return respuestajson;

end;
$function$
