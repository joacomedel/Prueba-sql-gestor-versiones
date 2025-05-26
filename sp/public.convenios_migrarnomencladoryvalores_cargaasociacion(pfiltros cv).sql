CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_cargaasociacion(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalores refcursor;
       unvalor record;
        rfiltros RECORD;
		rprestador RECORD;
        vfiltroid varchar;
		vusuario INTEGER;
		vidprestador BIGINT;
		vidasocconv INTEGER;
		vidconvenio INTEGER;
BEGIN 
-- Este proceso no carga anexo de valores para la asociacion, tampoco modifica valores de los anexos de valores
-- SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion=altamodificaasociacion}');
     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
	 	OPEN cvalores FOR SELECT * ,true as procesar 
					 ,concat(' Cuit:',cuit,' telefono:',contacto_telefono,' correo:',contacto_correo
					,' Especialidad:',especialidad,' Lugar Atencion:',lugar_atencion,' Localidad:',localidad
					,' Grilla:',grilla,' Responsable Facturacion:',responsable_facturacion) as descextendida
				FROM asociacion_para_migrar 
				LEFT JOIN (SELECT DISTINCT idasocconv,acdecripcion 
				 	   FROM asocconvenio 
					   WHERE acactivo
                                ) as asoc ON idasocconv = id_siges
				WHERE nullvalue(apmfechaproceso)
								;
	 
	   FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
		          vidprestador = 1;
				  vidasocconv = trim(unvalor.id_siges)::integer;
				   SELECT INTO rprestador * FROM prestador WHERE replace(pcuit,'-','') = trim(unvalor.cuit) AND trim(unvalor.cuit) <> '';
					IF FOUND THEN
					  vidprestador = rprestador.idprestador;
					END IF;
					
		          IF not nullvalue(unvalor.idasocconv) THEN
				 --La asociacion existe en Siges... Solo la modificamos
				   
				    UPDATE asocconvenio SET  
					--acdecripcion, acfechaini, acfechafin, idasocconv,idconvenio, acactivo, aconline, acvalorsindecimal
					--, acfechamodificacion, acidusuariocarga, acidusuariomodifica, acseusaencoseguro, NO SE PUEDEN MODIFICAR
					asdescripext = concat(asdescripext,' ',unvalor.descextendida)
					,accuit = unvalor.cuit
					,acidprestador = vidprestador
					,accontacto_telefono = unvalor.contacto_telefono
					,accontacto_correo = unvalor.contacto_correo
					,acespecialidad = unvalor.especialidad
					,aclugar_atencion = unvalor.lugar_atencion
					,aclocalidad = unvalor.localidad 
					,acgrilla = unvalor.grilla
					,acresponsable = unvalor.responsable_facturacion
					WHERE idasocconv = unvalor.idasocconv AND acactivo;
					
					--Agrego a la asociacion para que se pueda usar en todos los centros regionales
				INSERT INTO asocconveniocentroregional(idasocconv,idconvenio,idcentroregional) 
				(
					SELECT cent.idasocconv as idasocconv,cent.idconvenio as idconvenio,idcentroregional	 
					FROM 
					(SELECT idcentroregional,idasocconv,idconvenio 
					 FROM centroregional 
					 ,(SELECT DISTINCT idasocconv,idconvenio 
                      FROM asocconvenio
					  WHERE idasocconv = unvalor.idasocconv ) as asociacion
						WHERE cremiteordenprestacion 
					) as cent
					 LEFT JOIN (SELECT idcentroregional,idasocconv,idconvenio 
							   FROM asocconveniocentroregional
							   WHERE nullvalue(accrfechafin) AND idasocconv = unvalor.idasocconv ) as conf USING(idcentroregional,idasocconv,idconvenio)
					WHERE nullvalue(conf.idasocconv) 
 				ORDER BY idcentroregional
				);
				--Vinculo La asociacion para que soporte los planes de cobertura
				INSERT INTO convenioplancob(idplancobertura, idasocconv, idplancoberturas, cpcfechaini, idconvenio)  
				( SELECT cent.idplancobertura,cent.idasocconv,cent.idplancoberturas,'2022-01-01'::date as cpcfechaini,cent.idconvenio
					FROM 
					(SELECT idplancoberturas,idplancobertura,idasocconv,idconvenio 
					 FROM plancobertura 
					 ,(SELECT DISTINCT idasocconv,idconvenio FROM asocconvenio  WHERE idasocconv = unvalor.idasocconv ) as asociacion
					) as cent
					  LEFT JOIN (SELECT idplancoberturas,idplancobertura,idasocconv,idconvenio 
							   FROM convenioplancob
							   WHERE nullvalue(cpcfechafin) AND idasocconv = unvalor.idasocconv ) as conf USING(idplancoberturas,idplancobertura,idasocconv,idconvenio)
					WHERE nullvalue(conf.idasocconv) 
 				);
					
					
					UPDATE asociacion_para_migrar SET apmfechaproceso = now() WHERE idasociacionparamigrar = unvalor.idasociacionparamigrar;
					RAISE NOTICE 'Listo con (%) ',concat(unvalor.responsable_facturacion);
				 END IF;
				 IF nullvalue(unvalor.idasocconv) THEN
				 --La asociacion no existe en Siges... Hay que darla de alta
				 --Doy de Alta un Convenio para la Asociacion
				 -- ciniciovigencia, cfinvigencia,cfechafirma, cdenominacion, telefono, cuitini, cuitmedio, cuitfin
				 INSERT INTO convenio (ciniciovigencia, cfinvigencia,cfechafirma, cdenominacion, telefono,cdescripcionextendida, cuitmedio) 
				 VALUES('2022-01-01','9999-12-31','2022-01-01',unvalor.responsable_facturacion,unvalor.contacto_telefono,unvalor.descextendida,unvalor.cuit);
				 vidconvenio = currval('"public"."convenio_idconvenio_seq"'::text::regclass);
				 --Doy de Alta la asociacion, la pongo como que se toma para coseguros
				 INSERT INTO asocconvenio (idconvenio,acdecripcion, acfechaini, acfechafin, idasocconv, asdescripext, acidusuariocarga,acseusaencoseguro 
										   ,accuit, acidprestador, accontacto_telefono, accontacto_correo, acespecialidad
										   ,aclugar_atencion, aclocalidad, acgrilla, acresponsable) 
				 VALUES(vidconvenio,unvalor.responsable_facturacion,'2022-01-01','9999-12-31',vidasocconv,unvalor.descextendida,vusuario,true
					   ,unvalor.cuit,vidprestador,unvalor.contacto_telefono,unvalor.contacto_correo,unvalor.especialidad
						,unvalor.lugar_atencion,unvalor.localidad,unvalor.grilla,unvalor.responsable_facturacion);
				--Agrego a la asociacion para que se pueda usar en todos los centros regionales
				INSERT INTO asocconveniocentroregional(idasocconv,idconvenio,idcentroregional) 
				(
					SELECT vidasocconv as idasocconv,vidconvenio as idconvenio,idcentroregional	 
					FROM centroregional 
					WHERE cremiteordenprestacion ORDER BY idcentroregional
				);
				--Vinculo La asociacion para que soporte los planes de cobertura
				INSERT INTO convenioplancob (idplancobertura, idasocconv, idplancoberturas, cpcfechaini, idconvenio)  
				( select idplancobertura,vidasocconv as idasocconv,idplancoberturas,'2022-01-01'::date as cpcfechaini, vidconvenio as idconvenio
				  from plancobertura  
				);
				UPDATE asociacion_para_migrar SET apmfechaproceso = now() WHERE idasociacionparamigrar = unvalor.idasociacionparamigrar;
				RAISE NOTICE 'Listo con (%) , se cargo nueva ',concat(unvalor.responsable_facturacion);
				 END IF;
				fetch cvalores into unvalor;
				END LOOP;
				CLOSE cvalores;
			   
     return 'Listo';
END;
$function$
