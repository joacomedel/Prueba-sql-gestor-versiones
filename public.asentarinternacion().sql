CREATE OR REPLACE FUNCTION public.asentarinternacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

cursorinternacion CURSOR FOR
                select *
                       from ttinternacion;
nuevas refcursor;
nueva RECORD;
/*
idprestador
idplancobertura
malcance
nromatricula
mespecialidad
fechainternacion
tipointernacion
cantdias
diagnostico
lugarinternacion
*/
dato record;
respuesta boolean;
observacion varchar;
rusuario RECORD;

BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
    rusuario.idusuario = 25;
END IF;

    respuesta = false;
--  Llama a asentarOrden()
    --  crea la tabla temporal TTOrdenesGeneradas
    CREATE TEMP TABLE ttordenesgeneradas(
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;

	select * into respuesta
           from asentarorden(); --guarda en ttordenesgeneradas

if (respuesta) then
OPEN nuevas FOR SELECT * from ttordenesgeneradas;
   fetch nuevas into nueva;
   
-- Asienta en Orden Internacion
   open cursorinternacion;
   fetch cursorinternacion into dato;
   INSERT INTO ordinternacion
          VALUES (nueva.centro,nueva.nroorden,dato.idprestador,dato.idplancobertura,dato.malcance,
                 dato.nromatricula,dato.mespecialidad,dato.fechainternacion,dato.tipointernacion,
                 dato.cantdias,dato.diagnostico,dato.lugarinternacion);

    PERFORM alta_modifica_ficha_medica_internacion(nueva.nroorden,nueva.centro);

    -- BelenA voy a agregar que inserte tambien en cambioestadosorden 06-05-2024
    observacion='Orden de Internación generada desde ExpenderV2';

    INSERT INTO cambioestadosorden(nroorden,centro,idordenventaestadotipo,observacion,ceofechafin,ceoidusuario) VALUES (nueva.nroorden,nueva.centro,1,observacion,NULL,rusuario.idusuario);

   close nuevas;
   end if;
   close cursorinternacion;
   return respuesta;		
END;
$function$
