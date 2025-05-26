CREATE OR REPLACE FUNCTION public.w_praxis_alta_controldosisafiliado_respuesta(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE

    respuestajson jsonb;
    respuestajson_info jsonb;
    jsonafiliado jsonb;

    idsolicitud character varying;

BEGIN

    respuestajson = parametro;

    --UPDATE solicitudauditoriaitem_ext SET saiidcontroldosisporafiliado_praxys = parametro::text WHERE idsolicitudauditoriaitem = 31639;
    --UPDATE solicitudauditoriaitem_ext SET saiidcontroldosisporafiliado_praxys = parametro->>'idControlDosisPorAfiliado', saipraxys = CURRENT_TIMESTAMP WHERE idsolicitudauditoriaitem = 31672;

    SELECT idsolicitudauditoriaitem FROM solicitudauditoriaitem NATURAL JOIN solicitudauditoriaitem_ext WHERE idfichamedicainfomedicamento = parametro->>'idfichamedicainfomedicamento' INTO idsolicitud;

    IF (idsolicitud IS NOT NULL) THEN

        UPDATE solicitudauditoriaitem_ext SET saiidcontroldosisporafiliado_praxys = parametro->>'idControlDosisPorAfiliado', saipraxys = CURRENT_TIMESTAMP WHERE idsolicitudauditoriaitem = idsolicitud;

    END IF;

    return respuestajson;

END;
$function$
