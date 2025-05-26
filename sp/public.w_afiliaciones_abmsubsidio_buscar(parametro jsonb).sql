CREATE OR REPLACE FUNCTION public.w_afiliaciones_abmsubsidio_buscar(parametro jsonb)
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
     
      vidlicencia bigint;
      rlicencia  record;
      vaccion varchar;
      vnrodoc varchar;
     
---idturno
begin
       vaccion = parametro->>'accion';
       
	select into usuariojson * FROM sys_dar_usuario_web(parametro);
    
	IF parametro->>'accion' = 'w_afiliacion_declara_accion' THEN
             IF nullvalue(parametro->>'w_nrodoc')   THEN 
                RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
             END IF;
              
             vnrodoc= parametro->>'w_nrodoc';
			 
            select INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
             from ( 
              SELECT CASE WHEN nullvalue(nrodoctitu) THEN p.nrodoc ELSE nrodoctitu END as nrodoctitu
				    ,CASE WHEN nullvalue(tipodoctitu) THEN p.tipodoc ELSE tipodoctitu END as tipodoctitu
				    ,adsorden,adsapellido,adsnombres,adsnrodoc,adstipodoc,adsvinculo,adsporciento
                    ,adsfechaingreso,adsfechafinvigencia
				    ,idafiliaciondeclarasubsidio
				    ,descrip as tipodocdescrip
			  FROM persona as p
		      LEFT JOIN w_afiliacion_declara_subsidio as wads ON (nrodoc = nrodoctitu AND tipodoc = tipodoctitu AND nullvalue(adsfechafinvigencia) )
			  LEFT JOIN tiposdoc as td ON (adstipodoc = td.tipodoc) 
				 WHERE ( nrodoc = vnrodoc ) AND nullvalue(adsfechafinvigencia) 
            ORDER BY idafiliaciondeclarasubsidio DESC
            ) as t;

			END IF;
			
            respuestajson_info = concat('{ "w_afiliacion_declara_accion":' , respuestajson_info , '}');
            respuestajson = respuestajson_info;

      
		
       
        return respuestajson;

end;
$function$
