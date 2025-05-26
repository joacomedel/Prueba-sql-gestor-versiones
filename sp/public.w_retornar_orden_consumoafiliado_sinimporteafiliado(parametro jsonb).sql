CREATE OR REPLACE FUNCTION public.w_retornar_orden_consumoafiliado_sinimporteafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* Se quita el importe para que los prestadores no realicen el cobro nuevamente al afiliado
*{"codigo":"nroordencentro","info_sistema_solicita":"suap"}
*/
DECLARE
       respuestajson jsonb;
       respuestaimportejson jsonb;
      
begin
    
    SELECT INTO respuestajson *  FROM w_retornar_orden_consumoafiliado(parametro);

    --SL 12/05/25 - Elimino en detalleimportes el item "paga el afiliado"
    -- SELECT INTO respuestaimportejson jsonb_agg(item)
    -- FROM jsonb_array_elements(respuestajson->'detalleimportes') AS item
    -- WHERE (item->>'formapago') <> 'Paga el Afiliado';
    -- respuestajson = jsonb_set(respuestajson, '{detalleimportes}', respuestaimportejson);
    -- Modificar los importes de 'Paga el Afiliado' a 0

    --SL 12/05/25 - Harcodeo el importe en 0
    SELECT INTO respuestaimportejson jsonb_agg(
        CASE 
            WHEN (item->>'formapago') = 'Paga el Afiliado' 
            THEN jsonb_set(item, '{importe}', '0'::jsonb)
            ELSE item 
        END
    )
    FROM jsonb_array_elements(respuestajson->'detalleimportes') AS item;
    respuestajson = jsonb_set(respuestajson, '{detalleimportes}', respuestaimportejson);
    --SL 12/05/25 -------

    return respuestajson;

end;
$function$
