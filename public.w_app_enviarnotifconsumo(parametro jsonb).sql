CREATE OR REPLACE FUNCTION public.w_app_enviarnotifconsumo(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*{"NroAfiliado":"13331364","Barra":"30","NroDocumento":"13331364","TipoDocumento":"DNI","Track":null,"ApellidoEfector":"","NombreEfector":"","Diagnostico":"","token":"suap1234","info_consumio_token":"suap","FechaConsumo":"2024-03-11 00:00:00","CuilEfector":"27271432416","MatriculaEfector":"4297","CategoriaEfector":"B","ApellidoPrescriptor":"","NombrePrescriptor":"","CuilPrescriptor":"27271432416","MatriculaNacionalPrescriptor":"","MatriculaProvincialPrescriptor":"4297","EspecialidadPrescriptor":"","codigo_consumo_prestador":"CMN15878247","marcadetiempo":"2024-03-11T19:54:19-03:00","timeout":80,"contexto_atencion":"Ambulatorio","punto_atencion_id":"1072","punto_atencion":"Clu00ednica de Imu00e1genes","punto_atencion_CUIT":"","ConsumosWeb":[{"CodigoConvenio":"12.42.01.07"}],"uwnombre":"usucmn","ttl_session":"XB13DZA8d8oxrZodELmJMrNH5tvNs\/Zgd18E2J8wANimaiIiUqJmy6gh1Ozz1PCASWns11RHi78\/QFZGG26IatWv44GK1n1ekmn7fcXvZSYDWbAU5CHNh0jPWYoPvISGiblXanOgqg=="}
*/
DECLARE
--VARIABLES 
	jbmensaje JSONB;
	vnrodoc CHARACTER VARYING;
--RECORD
	rdatosafil RECORD;
	rdatosprest RECORD;
	rdatos RECORD;
begin
	IF(NOT nullvalue(parametro->>'nroorden')) THEN
		-- Busco los datos del afiliado
		SELECT INTO rdatosafil * FROM persona 
			NATURAL JOIN w_usuarioafiliado
			NATURAL JOIN w_usuarioweb
		WHERE nrodoc IN (
			SELECT 
					CASE WHEN not nullvalue(b.nrodoctitu)   THEN  b.nrodoctitu  
						WHEN not nullvalue(b.nrodoctitu)   THEN  br.nrodoctitu  
						WHEN (nullvalue(b.nrodoctitu) AND nullvalue(b.nrodoctitu)) THEN  p.nrodoc END as titu
			FROM persona p 
			LEFT JOIN benefsosunc b USING (nrodoc,tipodoc)
			LEFT JOIN benefreci br USING (nrodoc,tipodoc)
			WHERE nrodoc = parametro->>'NroDocumento' OR nrodoc = parametro->>'NroAfiliado');

		--Verifico que parametro tiene el valor para devolverlo en el mensaje
		IF parametro->>'NroDocumento' IS NOT NULL THEN
			vnrodoc = parametro->>'NroDocumento';
		ELSE
			vnrodoc = parametro->>'NroAfiliado';
		END IF;

		IF FOUND THEN 
			-- Busco los datos del prestador
			SELECT INTO rdatosprest * FROM prestador 
			WHERE replace(pcuit,'-','') ilike parametro->>'CuilEfector' AND pcuit <> '30-59050964-3';

			IF NOT FOUND THEN 
			--El consumo es por una emision de orden
					jbmensaje = jsonb_build_object(
							'idusuarioweb', rdatosafil.idusuarioweb,
							'tag', 'tag',
							'mensaje',concat('Se emitió la orden: ', 
							parametro->>'centro', '-',parametro->>'nroorden', 
							' ➡︎ Afiliado/a: ', vnrodoc),
							'link', '',
							'sensible', false,
							'interno', false
						);
				ELSE
				--El consumo es por validacion online
					jbmensaje = jsonb_build_object(
							'idusuarioweb', rdatosafil.idusuarioweb,
							'tag', 'tag',
							'mensaje', 
								concat('Se registró la emisión de la orden: ',
								 parametro->>'centro', '-',parametro->>'nroorden', 
								 ' ➡︎ Afiliado/a: ', vnrodoc,
								 '. Prestador/a: ', rdatosprest.pdescripcion, ' - ', rdatosprest.pcuit),
							'link', '',
							'sensible', false,
							'interno', false
						);
				END IF;
				--Envio la notificacion
				SELECT INTO rdatos w_enviarNotificacionPush(jbmensaje);
		END IF;
	END IF;
	return true;
end;
$function$
