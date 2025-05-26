CREATE OR REPLACE FUNCTION ca.controlacceso_abmlicencias(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE

       ctemp_amlicencias refcursor;
       ctemp_amlicencias_pendientes refcursor;
       unlic record;
       unpendiente record;rlicenciaestado RECORD;
       rfiltros record;
       vusuario INTEGER;
       resultado varchar;
       vsaldo  INTEGER;vcantidaddias INTEGER;vcantidaddiasusado INTEGER;
BEGIN

      EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
      SELECT INTO vusuario sys_dar_usuarioactual();
      
    
      OPEN ctemp_amlicencias FOR SELECT persona.*,temp_amlicencias.* 
				FROM temp_amlicencias JOIN persona ON temp_amlicencias.idpersona = persona.idpersona;
      FETCH ctemp_amlicencias INTO unlic;
      WHILE FOUND LOOP

       IF unlic.accion = 'abm' THEN
            if (nullvalue(unlic.idlicencia) OR unlic.idlicencia = 0) THEN
              
		INSERT INTO licencia(idlicenciatipo,idpersona,lifechainicio,lifechafin,licantidaddias)
		VALUES(unlic.idlicenciatipo,unlic.idpersona,unlic.lifechainicio,unlic.lifechafin,unlic.licantidaddias);
		unlic.idlicencia = currval('licencia_idlicencia_seq'::regclass);
		INSERT INTO licenciaestado(idlicencia,idlicenciaestadotipo,leobservacion,leusuario) 
		VALUES (unlic.idlicencia,1,'Solicitud de Licencia',vusuario);
			
		
            ELSE -- Actualizo los datos existentes, solo se puede si la licencia esta solicitada
              SELECT INTO rlicenciaestado * FROM licenciaestado 
						WHERE idlicencia = unlic.idlicencia 
						AND nullvalue(lefechafin) AND idlicenciaestadotipo = 1;  
              IF FOUND THEN 
			UPDATE licencia SET idlicenciatipo = unlic.idlicenciatipo
					,idpersona = unlic.idpersona
					,lifechainicio =unlic.lifechainicio
					,lifechafin =unlic.lifechafin
					,licantidaddias = unlic.licantidaddias
			WHERE idlicencia = unlic.idlicencia;
              END IF; 
            END IF;
		
          END IF;
	 IF unlic.accion = 'aprobar' THEN
		--Si se trata de una licencia con bolsita, la bolsita se modifica cuando se aprueba la licencia
		UPDATE licenciaestado SET lefechafin = now() WHERE idlicencia = unlic.idlicencia  AND nullvalue(lefechafin);
		INSERT INTO licenciaestado(idlicencia,idlicenciaestadotipo,leobservacion,leusuario)  VALUES (unlic.idlicencia,2,'Aprobar la Licencia',vusuario);
                vcantidaddias = unlic.licantidaddias;
               
                 OPEN ctemp_amlicencias_pendientes FOR SELECT * FROM temp_amlicencias 
						NATURAL JOIN licenciatipoconfiguracion 
						NATURAL JOIN persona 
						WHERE ltccontidaddiassaldos > 0
						ORDER BY ltcfechacarga;
		 FETCH ctemp_amlicencias_pendientes INTO ctemp_amlicencias_pendientes;
		 WHILE FOUND LOOP
			IF ctemp_amlicencias_pendientes.ltccontidaddiassaldos >= vcantidaddias THEN 
				vsaldo = ctemp_amlicencias_pendientes.ltccontidaddiassaldos - vcantidaddias;
                                vcantidaddiasusado = vcantidaddias;
                                vcantidaddias = 0;
			ELSE 
				vcantidaddias = vcantidaddias - ctemp_amlicencias_pendientes.ltccontidaddiassaldos;
				vcantidaddiasusado = ctemp_amlicencias_pendientes.ltccontidaddiassaldos;
				vsaldo = 0;
			END IF;
			UPDATE licenciatipoconfiguracion SET ltccontidaddiassaldos = vsaldo,ltccontidaddiasusados = ltccontidaddiasusados + vcantidaddiasusado
			WHERE idlicenciatipoconfiguracion = ctemp_amlicencias_pendientes.idlicenciatipoconfiguracion;

		
			INSERT INTO licenciatipoconfiguracion_uso(ltcucantidaddias,ltcuusuariocarga,idlicenciatipoconfiguracion,idlicencia) 
			VALUES (vcantidaddiasusado,vusuario,ctemp_amlicencias_pendientes.idlicenciatipoconfiguracion,unlic.idlicencia);

		FETCH ctemp_amlicencias_pendientes INTO ctemp_amlicencias_pendientes;
		END LOOP;
		close ctemp_amlicencias_pendientes;
	 END IF; -- IF unlic.accion = 'aprobar' THEN
	 IF unlic.accion = 'cancelar' THEN

		 SELECT INTO rlicenciaestado * FROM licenciaestado 
						WHERE idlicencia = unlic.idlicencia 
						AND nullvalue(lefechafin);  
		IF FOUND THEN
			UPDATE licenciaestado SET lefechafin = now() WHERE idlicencia = unlic.idlicencia  AND nullvalue(lefechafin);
			INSERT INTO licenciaestado(idlicencia,idlicenciaestadotipo,leobservacion,leusuario)  VALUES (unlic.idlicencia,3,'Cancelar la Licencia',vusuario);

                	IF rlicenciaestado.idlicenciaestadotipo = 2 THEN  --Hay que reestablecer las bolsitas 
				UPDATE licenciatipoconfiguracion SET ltccontidaddiassaldos = ltccontidaddiassaldos + t.ltcucantidaddias
								,ltccontidaddiasusados = ltccontidaddiasusados - t.ltcucantidaddias
				FROM licenciatipoconfiguracion_uso as t
				WHERE  t.idlicencia = licenciatipoconfiguracion.idlicencia 
					AND t.idlicenciatipo = unlic.idlicenciatipo
					AND  licenciatipoconfiguracion.idlicencia = unlic.idlicencia;

				DELETE FROM licenciatipoconfiguracion_uso 
					WHERE idlicencia = unlic.idlicencia;

                	END IF;

		
		END IF;


	 END IF; -- IF unlic.accion = 'cancelar' THEN
	resultado = unlic.idlicencia;
      FETCH ctemp_amlicencias INTO unlic;
      END LOOP;
      close ctemp_amlicencias;


return resultado;


END;
$function$
