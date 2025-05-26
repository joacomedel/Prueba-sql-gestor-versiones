CREATE OR REPLACE FUNCTION public.ultimoidcontroldosispraxys(parametro jsonb)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    idsolicitud character varying;
    numerodoc character varying;
    idmono character varying;
    respuesta jsonb;

BEGIN

    SELECT nrodoc, idmonodroga

    FROM solicitudauditoriaitem_ext
    NATURAL JOIN solicitudauditoriaitem
    NATURAL JOIN solicitudauditoria
    NATURAL JOIN monodroga as md

    WHERE idfichamedicainfomedicamento = parametro->>'idfichamedicainfomedicamento'
    ORDER BY saipraxys DESC
    LIMIT 1
    INTO numerodoc, idmono;

    SELECT saiidcontroldosisporafiliado_praxys

    FROM solicitudauditoriaitem_ext
    NATURAL JOIN solicitudauditoriaitem
    NATURAL JOIN solicitudauditoria
    NATURAL JOIN monodroga as md

    WHERE saipraxys IS NOT NULL AND idmonodroga = idmono AND nrodoc = numerodoc
    ORDER BY saipraxys DESC
    LIMIT 1
    INTO idsolicitud;

    respuesta = parametro || jsonb_build_object('idControlDosisPraxys', idsolicitud);
    respuesta = respuesta || jsonb_build_object('idmono', numerodoc);
    respuesta = respuesta || jsonb_build_object('numerodoc', idmono);

    RETURN respuesta;

END;$function$
