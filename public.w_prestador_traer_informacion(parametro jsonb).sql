CREATE OR REPLACE FUNCTION public.w_prestador_traer_informacion(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"idprestador":"2375","accion":"vacio"}
*/
DECLARE
--VARIABLES 
  
--RECORD
      respuestajson jsonb;
      respuestajson_info jsonb;  
      respuestajson_msn jsonb;
      respuestajson_domi jsonb;
      respuestajson_contacto jsonb;
      rprestador RECORD;
      rprestador_info  RECORD;
      rformapagouw RECORD;
      vaccion varchar;
      
begin
       
       IF nullvalue(parametro->>'idprestador')  AND nullvalue(parametro->>'accion') THEN 
		RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
       END IF; 
       vaccion = parametro->>'accion';
       IF parametro->>'accion' = 'actualizar' THEN
             PERFORM w_prestador_agregar_informacion(parametro);
             respuestajson = '{ "respuesta":' || 'true' || '}';
           
       END IF;     
       IF parametro->>'accion' = 'prestador_buscar_accion' THEN
             IF nullvalue(parametro->>'idprestador')  AND parametro->>'idprestador' = '0' AND nullvalue(parametro->>'pfcuit')  THEN 
                RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
             END IF;
              
            select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              SELECT * FROM prestador WHERE replace(pcuit,'-','') ilike replace(parametro->>'pfcuit','-','') LIMIT 1
            ) as t;

            respuestajson_info = '{ "prestador_buscar_accion":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;

       END IF; 

     

       IF parametro->>'accion' = 'prestador_especialidad' THEN 
           select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              SELECT * FROM prestador_especialidad 
              WHERE peactivo ORDER BY petexto
            ) as t;

            respuestajson_info = '{ "prestador_especialidad":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       
       END IF;      
	
       IF parametro->>'accion' = 'prestador_agrupador' THEN 
           select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select idprestador as idprestadoragrupador,pdescripcion as pdescripcionagrupador  from prestador where pesagrupador ORDER BY pdescripcion
            ) as t;

            respuestajson_info = '{ "prestador_agrupador":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       
       END IF;      

       IF parametro->>'accion' = 'prestador_fiscal' THEN 
       SELECT INTO rprestador * FROM w_prestador_fiscal WHERE idprestador = parametro->>'idprestador' AND nullvalue(pffechafin);
       IF NOT FOUND THEN 
	--MaLaPi Hay que hacer la carga inicial en la estructura del sitio
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select idprestador,pnombrefantasia as pfrazonsocial,pdescripcion as pfdescripcion,replace(pcuit,'-','') as pfcuit,CASE WHEN nullvalue(pesagrupador) THEN false ELSE pesagrupador END as pfesagrupador from prestador WHERE idprestador = parametro->>'idprestador'
            ) as t;

            respuestajson_info = '{ "prestador_fiscal":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       ELSE 
	--MaLaPi Hay que enviar los datos vigentes
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select * from w_prestador_fiscal WHERE idprestador = parametro->>'idprestador' AND nullvalue(pffechafin)
            ) as t;

            respuestajson_info = '{ "prestador_fiscal":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       END IF;          
       END IF;

IF parametro->>'accion' = 'prestador_dom_legal' OR parametro->>'accion' = 'prestador_dom_real' THEN 
       SELECT INTO rprestador * FROM w_prestador_domi WHERE idprestador = parametro->>'idprestador' AND nullvalue(pdfechafin) AND parametro->>'accion' ilike concat('%',pdtipo);
       IF NOT FOUND THEN 
	--MaLaPi Hay que hacer la carga inicial en la estructura del sitio
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select idprestador,pdomiciliolegal as pdcalle,pdescripcion as pfdescripcion,replace(pcuit,'-','') as pfcuit,CASE WHEN nullvalue(pesagrupador) THEN false ELSE pesagrupador END as pfesagrupador from prestador WHERE idprestador = parametro->>'idprestador'
            ) as t;

            respuestajson_info = '{ "' || vaccion || '":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       ELSE 
	--MaLaPi Hay que enviar los datos vigentes
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select * FROM w_prestador_domi WHERE idprestador = parametro->>'idprestador' AND nullvalue(pdfechafin) AND parametro->>'accion' ilike concat('%',pdtipo)
            ) as t;

             respuestajson_info = '{ "' || vaccion || '":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       END IF;          
       END IF;   

   
       IF parametro->>'accion' = 'w_prestador_asis' THEN 

        SELECT INTO rprestador * FROM w_prestador_asis WHERE idprestador = parametro->>'idprestador' AND nullvalue(pafechafin);
	IF NOT FOUND THEN 
	--MaLaPi Hay que hacer la carga inicial en la estructura del sitio

	ELSE 
	--MaLaPi Hay que enviar los datos vigentes
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select * from w_prestador_asis WHERE idprestador = parametro->>'idprestador' AND nullvalue(pafechafin)
            ) as t;

            respuestajson_info = '{ "w_prestador_asis":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       
         END IF;   
        END IF; 

        IF parametro->>'accion' = 'w_prestador_seguro' THEN 

        SELECT INTO rprestador * FROM w_prestador_seguro WHERE idprestador = parametro->>'idprestador' AND nullvalue(psfechafin);
	IF NOT FOUND THEN 
	--MaLaPi Hay que hacer la carga inicial en la estructura del sitio

	ELSE 
	--MaLaPi Hay que enviar los datos vigentes
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select * from w_prestador_seguro WHERE idprestador = parametro->>'idprestador' AND nullvalue(psfechafin)
            ) as t;

            respuestajson_info = '{ "w_prestador_seguro":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       
         END IF;   
        END IF; 

        IF parametro->>'accion' = 'w_prestador_banco' THEN 

        SELECT INTO rprestador * FROM w_prestador_banco WHERE idprestador = parametro->>'idprestador' AND nullvalue(pbfechafin);
	IF NOT FOUND THEN 
	--MaLaPi Hay que hacer la carga inicial en la estructura del sitio

	ELSE 
	--MaLaPi Hay que enviar los datos vigentes
          select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              select * from w_prestador_banco WHERE idprestador = parametro->>'idprestador' AND nullvalue(pbfechafin)
            ) as t;

            respuestajson_info = '{ "w_prestador_banco":' || respuestajson_info || '}';
            respuestajson = respuestajson_info;
       
         END IF;   
        END IF; 
/*
  
	SELECT INTO rprestador * 
		FROM w_prestador_fiscal
                LEFT JOIN w_prestador_asis USING(idprestador)
                LEFT JOIN w_prestador_seguro USING(idprestador)
                LEFT JOIN w_prestador_banco   USING(idprestador)
		WHERE idprestador = parametro->>'idprestador' AND nullvalue(pffechafin)
			AND nullvalue(pffechafin)
                        AND nullvalue(pafechafin) 
                        AND nullvalue(pffechafin)
                        AND nullvalue(psfechafin)
                        AND nullvalue(pbfechafin);


	IF FOUND THEN --Recupero la informacion de las relaciones a muchos
             select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              SELECT  * 
              FROM w_prestador_asis_info -- Son muchos de  w_prestador_asis
              WHERE idprestadorasis = rprestador.idprestadorasis
                 AND idprestador = parametro->>'idprestador'
                 AND nullvalue(paifechafin)
                 ) as t;


             select INTO respuestajson_contacto array_to_json(array_agg(row_to_json(t)))
             from ( 
                   SELECT  * 
                   FROM w_prestador_contacto -- Son muchos los vigentes
                   WHERE idprestador = parametro->>'idprestador'
                      AND nullvalue(pcfechafin)
                  ) as t;


            select INTO respuestajson_domi array_to_json(array_agg(row_to_json(t)))
             from ( 
                   SELECT  * 
                   FROM w_prestador_domi -- Son muchos los vigentes
                   WHERE idprestador = parametro->>'idprestador'
                      AND nullvalue(pdfechafin)
                  ) as t;

            select INTO respuestajson_msn array_to_json(array_agg(row_to_json(t)))
             from ( 
                   SELECT  * 
                   FROM w_prestador_msn 
                   WHERE idprestador = parametro->>'idprestador'  
                   ORDER BY pmfechaingreso                    
                  ) as t;
                
        END IF;
        END IF;
	respuestajson = row_to_json(rprestador);
	END IF;
*/
       return respuestajson;

end;
$function$
