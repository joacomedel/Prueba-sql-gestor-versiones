CREATE OR REPLACE FUNCTION public.w_cancelar_validacion_sosunc(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$



/* 
*/
DECLARE

	-- refcursor
   	carticulo refcursor;
   	ccoberturas refcursor;
   	ccoberturas2 refcursor;

   	carticulo2 RECORD;
   	rcobertura RECORD;
   	elem RECORD;
    consumo RECORD;
    auditoria RECORD;
    registro RECORD;
 
	respuestajson jsonb;
    respuestajson_info jsonb;
   	jsonafiliado jsonb;
	jsonconsumo jsonb;
	vidplancoberturas INTEGER;
	
BEGIN

		SELECT INTO registro * 
		FROM registro_coberturas_sosunc 
		WHERE 
			idvalidacion=parametro->>'NroReferencia' 
			AND rcsfechareceta=parametro->>'FechaReceta' 
			AND rcscrednumero=parametro->>'NroDocumento'
			AND idvalidacionestadotipo=1
			AND nullvalue(rcsfechafin);
		-- Si exute la validacion y esta esta en estado 1
		IF FOUND THEN
			-- CANCELAR VALIDACION 
			UPDATE registro_coberturas_sosunc SET idvalidacionestadotipo=3, rcsfechafin=now() WHERE idregistocoberturas=registro.idregistocoberturas AND idvalidacion=registro.idvalidacion;
			
			SELECT INTO registro *, 'autorizacion cancelada' as mensaje 
			FROM registro_coberturas_sosunc 
			WHERE idregistocoberturas=registro.idregistocoberturas AND idvalidacion=registro.idvalidacion;
			
			respuestajson_info = row_to_json(registro);

		ELSE
			respuestajson_info = '{ "mensaje" : "Autorizacón no encontra o ya cancelada" }';
		END IF;


	

	respuestajson=respuestajson_info;

	return respuestajson;

END;
$function$
