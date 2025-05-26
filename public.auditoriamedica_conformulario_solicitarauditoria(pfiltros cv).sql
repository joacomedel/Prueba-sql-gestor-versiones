CREATE OR REPLACE FUNCTION public.auditoriamedica_conformulario_solicitarauditoria(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
        vidsolicitudauditoria bigint;
        vidcentrosolicitudauditoria integer;
        
        rfiltros RECORD;
        
        vfiltroid varchar;
        vparametrojson jsonb;
        vrespuestajson jsonb;
		
		vnroorden BIGINT;
		vcentro BIGINT;
		rorden RECORD;
		rformulariocompleto RECORD;
                rverifica RECORD;
		pfiltros2 VARCHAR;
      
BEGIN 

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     --rfiltros.nroformulario
       vnroorden = (rfiltros.nroformulario)::bigint / 100;
	   vcentro = (rfiltros.nroformulario)::bigint  % 100;

	   SELECT INTO rorden * FROM consumo 
	                        NATURAL JOIN persona
				NATURAL JOIN ordenrecibo 
				WHERE nroorden = vnroorden AND centro = vcentro;
		IF FOUND THEN
   
            SELECT INTO rformulariocompleto idsolicitudauditoria,idcentrosolicitudauditoria,fmifformulario FROM fichamedicainfoformulario 
                                                            WHERE nullvalue(fmiffechafin) AND fmifnroorden = vnroorden 
                                                            AND	fmifcentro = vcentro;
           IF FOUND THEN 

                      IF not nullvalue(rformulariocompleto.idsolicitudauditoria) THEN --Si ya existe la auditoria, es para marcar el archivo
                               --Vinculo con el archivo
                               SELECT INTO rverifica * FROM solicitudauditoria_archivos 
                                WHERE idsolicitudauditoria = rformulariocompleto.idsolicitudauditoria 
                                    AND idcentrosolicitudauditoria = rformulariocompleto.idcentrosolicitudauditoria;
                               IF FOUND THEN  
                                      UPDATE gestionarchivos SET gaarchivonombre = rfiltros.nombre, gaarchivodescripcion = concat(rfiltros.camino,rfiltros.nombre) 
                                                      WHERE idgestionarchivos = rverifica.idgestionarchivos AND idcentrogestionarchivos = rverifica.idcentrogestionarchivos;
                               ELSE
                                       INSERT INTO gestionarchivos (gaarchivonombre,gaarchivodescripcion) VALUES(rfiltros.nombre,concat(rfiltros.camino,rfiltros.nombre));
                                       INSERT INTO solicitudauditoria_archivos (idsolicitudauditoria,idcentrosolicitudauditoria,idgestionarchivos,idcentrogestionarchivos) 
                                       VALUES(rformulariocompleto.idsolicitudauditoria,rformulariocompleto.idcentrosolicitudauditoria,currval('gestionarchivos_idgestionarchivos_seq'::regclass), centro());
                               END IF;  

                      ELSE 

		      CREATE TEMP TABLE temp_solicitudauditoria AS (
			   SELECT *,''::text as accion,''::text as saetdescripcion FROM solicitudauditoria NATURAL JOIN solicitudauditoria_archivos  LIMIT 0
   			);
			 CREATE TEMP TABLE temp_solicitudauditoriaitem AS (
				 SELECT * FROM solicitudauditoriaitem LIMIT 0
 				);
 			INSERT INTO temp_solicitudauditoria (accion,nrodoc,idcentrosolicitudauditoriaarchivo,idsolicitudauditoria
									  ,saetdescripcion,saidusuario,idcentrosolicitudauditoria,nrorecetario,sadiagnostico
									  ,safechaingreso,idprestador,tipodoc,idsolicitudauditoriaarchivo,idcentro,idcentrogestionarchivos
									  ,idgestionarchivos )  
			VALUES('alta',rorden.nrodoc,NULL,NULL,concat('Creado desde Formulario Nro.',rfiltros.nroformulario),sys_dar_usuarioactual(),NULL,NULL,'Diagonostio','2022-09-08','7457',1,NULL,NULL,NULL,NULL);

			       pfiltros2 = concat('{ nroformulario=',rfiltros.nroformulario,', accion= ','traertratamientoformulario','}');
                   PERFORM auditoriamedica_conformulario_solicitarauditoria_darusos(pfiltros2);  
				   --SELECT * FROM  temp_auditoriamedica_planes_especiales;
				   
				   OPEN cvalorregistros FOR SELECT *,28 as idplancoberturas,'0' as saidosisdiaria,1 as saicobertura,'' as saipresentacion
										FROM temp_auditoriamedica_planes_especiales
			                            WHERE valor <> '' AND valor <> 'no' 
										ORDER BY clave;
				FETCH cvalorregistros INTO unvalorreg ;
				   UPDATE temp_solicitudauditoria SET sadiagnostico = unvalorreg.diagnostico; 
				WHILE  found LOOP 
				         IF trim(unvalorreg.clave) ilike '%dosis' OR trim(unvalorreg.clave) ilike '%unidades' THEN
					--Configuro segun la dosis ingresada
						UPDATE temp_solicitudauditoriaitem SET saidosisdiaria = trim(unvalorreg.valor) WHERE idmonodroga = unvalorreg.idmonodroga;
                                         ELSE
					 	INSERT INTO temp_solicitudauditoriaitem (idsolicitudauditoria,idcentrosolicitudauditoriaitem,idcentrosolicitudauditoria
										  ,idcentroarticulo,idmonodroga,idfichamedicainfomedicamento,idarticulo,idplancoberturas,saidosisdiaria
										  ,idsolicitudauditoriaitem,saipresentacion,idcentrofichamedicainfomedicamento,saicobertura )  
										  VALUES(NULL,NULL,NULL,NULL,unvalorreg.idmonodroga,NULL,NULL,unvalorreg.idplancoberturas,unvalorreg.saidosisdiaria,NULL,'Pesentacion No se',NULL,unvalorreg.saicobertura);

					 END IF;
				fetch cvalorregistros into unvalorreg;
				END LOOP;
				CLOSE cvalorregistros;
                                PERFORM  alta_modifica_solicitud_auditoria();
				--vinculo el Formulario con la Solicitud de Auditoria.
				vidsolicitudauditoria = currval('public.solicitudauditoria_idsolicitudauditoria_seq'::regclass);
			        vidcentrosolicitudauditoria = centro();
				UPDATE fichamedicainfoformulario SET idsolicitudauditoria = vidsolicitudauditoria,idcentrosolicitudauditoria = vidcentrosolicitudauditoria
				WHERE  nullvalue(fmiffechafin) AND fmifnroorden = vnroorden AND	fmifcentro = vcentro;

                                --MaLaPi 19-09-2022 Marco como usado el token 
                                UPDATE w_usuariowebtokensession   SET  	uwtksfechauso = now(),idsolicitudauditoria = vidsolicitudauditoria,idcentrosolicitudauditoria = vidcentrosolicitudauditoria
                                WHERE  uwtkscodigo = rfiltros.nroformulario AND nullvalue(uwtksfechauso);
                     END IF;
				
      END IF;
						 
   
   

     END IF;
     return 'Listo';
END;
$function$
