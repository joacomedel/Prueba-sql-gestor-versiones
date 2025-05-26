CREATE OR REPLACE FUNCTION public.w_abmenviomensaje(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$


/*
    ds - 31/01/2025
    {"accion":"nuevo","emcontenido":"<div></div>","emdestino":"email@gmail.com","emdescripcioncorta":"asunto correo","emremitente":"no-responder@sosunc.net.ar"},
    {"accion":"obtener_mensaje_estado","idEstadoTipo":"1","idTipoMensaje":"1"},
    {"accion":"cambiar_estado","idEnvioMensaje":"1","idEstadoNuevo":"2"}
*/
DECLARE
--VARIABLES
    respuestajson jsonb;
    respuestajson_info jsonb;
    mensajesestado jsonb;
    vaccion varchar;
    vorigen varchar;
    vidnuevomensaje bigint;
BEGIN

SET search_path TO public;

  vaccion = parametro->>'accion';
    -- vorigen = parametro->>'origen';
    --------------- Nuevo envio mensaje ---------------
    IF (vaccion = 'nuevo') THEN

        INSERT INTO public.w_enviomensaje (idenviomensajetipo, emcontenido, emdestino, emdescripcioncorta, emremitente)
            VALUES(CAST(parametro->>'idenviomensajetipo' AS BIGINT),parametro->>'emcontenido',parametro->>'emdestino',parametro->>'emdescripcioncorta', parametro->>'emremitente') RETURNING idenviomensaje INTO vidnuevomensaje;

        INSERT INTO public.w_enviomensajeestado (idenviomensaje)
            VALUES(vidnuevomensaje); 
        
          respuestajson_info = concat('{ "mensaje":' , '"Mensaje Enviado Correctamente"' , ', "idenviomensaje": ', vidnuevomensaje, '}');
    END IF;
    --------------- obtener mensajes dependiendo del estado ---------------
    IF (vaccion = 'obtener_mensaje_estado') THEN

        SELECT INTO mensajesestado idenviomensaje, emcontenido, emdestino, emdescripcioncorta, emremitente		
            FROM w_enviomensaje AS em
                LEFT JOIN w_enviomensajeestado USING (idenviomensaje)
                LEFT JOIN w_enviomensajeestadotipo USING (idenviomensajeestadotipo)
                LEFT JOIN w_enviomensajetipo USING (idenviomensajetipo)
            WHERE 
                idenviomensajeestadotipo = parametro->>'idEstadoTipo'
                AND idenviomensajetipo = parametro->>'idTipoMensaje'
                AND 
                    nullvalue(emefechafin)
        GROUP BY idenviomensaje, emefechainicio
        ORDER BY emefechainicio ASC
        LIMIT 40;

        respuestajson_info = concat('{ "mensajesestado":' , row_to_json(mensajesestado) '}');
    END IF;
    --------------- cambiar mensaje a estado recibido por parametro  ---------------
	IF (vaccion = 'cambiar_estado') THEN
      UPDATE w_enviomensajeestado SET emefechafin = now() WHERE idenviomensaje = parametro->>'idEnvioMensaje';
      INSERT INTO w_enviomensajeestado (idenviomensaje, idenviomensajeestadotipo) VALUES (parametro->>'idEnvioMensaje', parametro->>'idEstadoNuevo');
    END IF;
   
   respuestajson = COALESCE(respuestajson_info, '{}');


    RETURN respuestajson;
END;

$function$
