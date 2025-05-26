CREATE OR REPLACE FUNCTION public.w_app_reportedatos(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
select from w_app_reportedatos('{"idprestador":"5538", "reporte":"DebitosOPCWeb"}');
*/
DECLARE

       respuestajson jsonb;
      
--RECORD
	rdatosusu RECORD;
	rrespuesta RECORD;

	vaccion varchar;
begin 
	--Verifico que reciba todos los datos para operar
	IF (nullvalue(parametro->>'reporte')) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	vaccion = parametro->>'reporte';

	CASE vaccion
		WHEN 'DebitosOPCWeb'
			THEN 
				IF (nullvalue(parametro->>'idprestador')) THEN
					RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Busco los datos
				SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS respuestas
					FROM (	
						SELECT concat(idordenpagocontable,'|',idcentroordenpagocontable)as elidordenpago , to_char(opcfechaingreso ,'DD-MM-YYYY') as lafecha , 
						opcobservacion as opcobservacion_corta , * 
							FROM ordenpagocontable 
							NATURAL JOIN prestador 
							NATURAL JOIN ordenpagocontableestado 
						WHERE opcfechaingreso >='2019-01-01' 
							AND nullvalue(opcfechafin) 
							AND (idordenpagocontableestadotipo =5 OR idordenpagocontableestadotipo = 7) 
							AND idprestador = parametro->>'idprestador' 
							ORDER BY idordenpagocontable DESC	
					) AS t;
		WHEN 'recibosueldo'
			THEN 
				IF (nullvalue(parametro->>'nrodoc')) THEN
					RAISE EXCEPTION 'R-003, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Busco los datos
				SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS respuestas
					FROM (	
					SELECT idpersona,ca.liquidacion.*,ltdescripcion, limes AS limeshasta, lianio AS lianiohasta
					FROM ca.liquidacion 
						NATURAL JOIN ca.liquidaciontipo 
						NATURAL JOIN ca.liquidacioncabecera 
						NATURAL JOIN ca.persona 
					WHERE not nullvalue(lipublicada) 
						AND penrodoc ilike CONCAT('%',parametro->>'nrodoc','%')
					ORDER BY idliquidacion DESC
					) AS t;
		WHEN 'consumoturismo'
			THEN 
				IF (nullvalue(parametro->>'nrodoc')) THEN
					RAISE EXCEPTION 'R-003, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Busco los datos
				SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS respuestas
					FROM (	
					SELECT concatenar(concatenar(prestamo.idprestamo,'|'),prestamo.idcentroprestamo) as id, prestamo.idprestamo, prestamo.idcentroprestamo, 
						to_char(prestamo.fechaprestamo, 'DD/MM/YYYY') as fechaprestamo, prestamo.importeprestamo, turismounidad.tudescripcion, consumoturismo.ctfehcingreso 
						, consumoturismo.ctfechasalida, cttdescripcion 
					FROM prestamo 
						NATURAL JOIN consumoturismo 
						NATURAL JOIN consumoturismoestado cte 
						NATURAL JOIN turismounidad 
						JOIN consumoturismoestadotipo ctet ON cte.idconsumoturismoestadotipos = ctet.idconsumoturismoestadotipo 
					WHERE nullvalue(ctefechafin ) and idconsumoturismoestadotipo<>3 
						AND nrodoc ilike CONCAT('%',parametro->>'nrodoc','%') 
						AND nrodoc = parametro->>'nrodoc' 
					ORDER BY fechaprestamo
					) AS t;
		WHEN 'reintegros'
			THEN 
				IF (nullvalue(parametro->>'nrodoc')) THEN
					RAISE EXCEPTION 'R-007, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Busco los datos
				SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS respuestas
					FROM (	
					SELECT concatenar(concatenar(nroreintegro,'|'),idcentroregional) as id, nroreintegro, anio, idcentroregional,estadoreintegrodesc,to_char(fechacambio, 'DD/MM/YYYY') as lafechacambio,observacion,nrodoc,tipodoc, to_char(rfechaingreso, 'DD/MM/YYYY') as lafechaingreso,* 
					FROM reintegro 
						JOIN restados USING (nroreintegro, anio, idcentroregional) 
						NATURAL JOIN tipoestadosreintegro 
					WHERE nullvalue(refechafin) AND nrodoc = parametro->>'nrodoc'
					) AS t;
		WHEN 'facturaPagos'
			THEN 
				IF (nullvalue(parametro->>'nrodoc')) THEN
					RAISE EXCEPTION 'R-007, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
				END IF;

				--Busco los datos
				SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS respuestas
					FROM (	
                        SELECT * FROM 
                        ( select concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) as elidfactura ,concat(tipofactura,' ',
                            CASE WHEN tipocomprobante = 1 THEN ' B ' WHEN tipocomprobante = 2 THEN ' A ' ELSE ' ' END,nrosucursal,' - ',nrofactura) as nroconformato ,
                            nrofactura,nrosucursal,tipofactura,tipocomprobante,nrodoc,tipodoc,importeamuc+importeefectivo+importedebito+importecredito+importectacte+importesosunc as importetotal,
                            fechaemision,to_char(fechaemision,'DD-MM-YYYY') as txtfecha,formapago,anulada,fechacreacion,fvcae,fvcaefchvto ,
                            case when nullvalue(fvcae) THEN 'Impresa' ELSE 'Electronica' END as tipoemision 
                          from facturaventa 
                          LEFT JOIN facturaventa_wsafip 
                          USING(nrofactura,nrosucursal,tipofactura,tipocomprobante) 
                          WHERE (nullvalue(facturaventa_wsafip.nrofactura) or facturaventa_wsafip.fvamostrarweb) 
                        ) as t 
                        where nrodoc = parametro->>'nrodoc' ORDER BY fechaemision DESC
					) AS t;
		ELSE 
			IF (nullvalue(parametro->>'idpermiso') OR nullvalue(parametro->>'tipo') OR nullvalue(parametro->>'idrolweb')) THEN
				RAISE EXCEPTION 'R-008, Error al buscar datos, intentelo nuevamente mas tarde.';
			END IF;

			--Busco los datos
			SELECT INTO rrespuesta  array_to_json(array_agg(row_to_json(t))) AS respuestas
				FROM (	
					SELECT * 
					FROM w_app_reporte 
                    NATURAL JOIN w_app_reportepermiso
					WHERE idpermiso = parametro->>'idpermiso'
					AND ratipo = parametro->>'tipo'
                    AND idrolweb = parametro->>'idrolweb'
				) AS t;
	END CASE;

	--Verifico si encontre datos
	IF rrespuesta IS NOT NULL THEN
		respuestajson = rrespuesta.respuestas;
	END IF;

	return respuestajson;
end;
$function$
