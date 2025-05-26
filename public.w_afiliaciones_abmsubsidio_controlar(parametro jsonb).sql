CREATE OR REPLACE FUNCTION public.w_afiliaciones_abmsubsidio_controlar(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* Busca la informacion de subsidios cargada desde la web
*/
DECLARE
--VARIABLES 
   vmontoctacte DOUBLE PRECISION;
--RECORD
      respuestajson jsonb;
      usuariojson jsonb;
      respuestajson_info jsonb; 
      rpersona RECORD;
	  rsector RECORD;
     
      rcontrola  record;
      vaccion varchar;
      vnrodoc varchar;
     
---idturno
begin
       vaccion = parametro->>'accion';
       
	select into usuariojson * FROM sys_dar_usuario_web(parametro);
    
	         IF nullvalue(parametro->>'w_nrodoc')   THEN 
                RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
             END IF;
              
             vnrodoc= parametro->>'w_nrodoc';
			 
			 SELECT INTO rcontrola sum(adsporciento) as sumaporciento ,nrodoctitu,tipodoctitu
			  FROM persona as p
		      JOIN w_afiliacion_declara_subsidio as wads ON nrodoc = nrodoctitu AND tipodoc = tipodoctitu
			  WHERE ( nrodoc = vnrodoc ) AND nullvalue(adsfechafinvigencia) 
            GROUP BY nrodoctitu,tipodoctitu;
			
			IF FOUND AND rcontrola.sumaporciento > 100 THEN
				RAISE EXCEPTION 'R-003, La suma de los porcentajes es superior a 100 es : % ()',rcontrola.sumaporciento;
			
			ELSE 
			
			--Genero el Orden segun los Porcentajes
			
			UPDATE w_afiliacion_declara_subsidio SET adsorden = t.orden
			FROM (
			SELECT wads.*,row_number() OVER (ORDER BY adsporciento DESC) as orden
						  FROM w_afiliacion_declara_subsidio as wads 
						  WHERE ( nrodoctitu = vnrodoc) AND nullvalue(adsfechafinvigencia) 

			) as t
			WHERE w_afiliacion_declara_subsidio.idafiliaciondeclarasubsidio = t.idafiliaciondeclarasubsidio;

			
			select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              SELECT sum(adsporciento) as sumaporciento,nrodoctitu,tipodoctitu
			  FROM persona as p
		      JOIN w_afiliacion_declara_subsidio as wads ON nrodoc = nrodoctitu AND tipodoc = tipodoctitu
			  WHERE ( nrodoc = vnrodoc ) AND nullvalue(adsfechafinvigencia) 
            GROUP BY nrodoctitu,tipodoctitu
            ) as t;

			END IF;
            
			
            respuestajson_info = concat( '{ "w_afiliacion_declara_accion":', respuestajson_info , '}');
            respuestajson = respuestajson_info;

      
		
       
        return respuestajson;

end;
$function$
