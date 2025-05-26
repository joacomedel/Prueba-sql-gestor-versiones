CREATE OR REPLACE FUNCTION public.w_datoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*'{"doc":27091730,"ejecutar":"datoafiliado","uwnombre":"usucbrn"}'
*/
DECLARE
--VARIABLES 
 
--RECORD
    respuestajson jsonb;
    resp_json_afiliado jsonb;
    resp_json_beneficiario jsonb;
    resp_json_info_generaluno jsonb;
    respuestajson_info jsonb;
    nrodoc varchar;
	
    param  varchar;
    resp boolean;
eldoc  varchar;
			
begin
	param = concat('{nro=',parametro->>'doc',', nrodoc=',parametro->>'doc','} ');
	--RAISE NOTICE ' param  %',  param;
	SELECT INTO resp * FROM afiliaciones_datosgrupofamiliar(param);
	
	/* 
	* SELECT * FROM afiliaciones_datosgrupofamiliar('{nro=28272137, nrodoc=28272137}');
	* SELECT * FROM afiliado;
	* SELECT * FROM beneficiarios;
	* SELECT *  FROM info_generaluno;
	*/
	
	SELECT  INTO resp_json_afiliado array_to_json(array_agg(row_to_json(t)))
	FROM (
		SELECT  af.* , p.descrip as descriprov, l.descrip as descriloc  
        FROM afiliado af
            left join provincia p USING (idprovincia)
            left join localidad l USING (idlocalidad)
    ) as t ; 
	
	SELECT  INTO resp_json_beneficiario  array_to_json(array_agg(row_to_json(t)))
	FROM (
		SELECT  ben.*,  p.descrip as descriprov, l.descrip as descriloc
        FROM beneficiarios ben
            left join provincia p USING (idprovincia)
            left join localidad l USING (idlocalidad)
        order by barra ASC
	) as t ; 
	
	/* SELECT  INTO resp_json_info_generaluno array_to_json(array_agg(row_to_json(t)))
	FROM (
		SELECT  * FROM info_generaluno
	) as t ; 
	*/
	
	if resp_json_beneficiario isnull  then
		respuestajson = concat('{ "afiliado":', resp_json_afiliado, '}');
		-- respuestajson = '{ "afiliado":' || resp_json_afiliado ||  '}';
		-- ',"beneficiarios":' || resp_json_beneficiario || '}';
		-- ',"info_generaluno":' || resp_json_info_generaluno || '}';
		-- respuestajson = resp_json_afiliado;
	else
		respuestajson = concat('{ "afiliado":', resp_json_afiliado, ',"beneficiarios":', resp_json_beneficiario, '}');		 	
		-- respuestajson = '{ "afiliado":' || resp_json_afiliado ||  --'}';  
		-- ',"beneficiarios":' || resp_json_beneficiario || '}';
		-- ',"info_generaluno":' || resp_json_info_generaluno || '}';
		-- respuestajson = resp_json_afiliado;
	end if;
	
	return respuestajson;		
end;
$function$
