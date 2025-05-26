CREATE OR REPLACE FUNCTION public.w_generar_token_usuarioweb(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"idusuarioweb":"123", 
"tokenn":"fgh87gfh7",
"vtokenv":30,
"NroDocumento":null,
"vaccion": "verificarEmail o contraseña"
}
*/
DECLARE
--VARIABLES 
	vtokenv varchar;
    vtokenn varchar;
    vaccion varchar;
    vidusuarioweb varchar;
    vcambios integer := 0;
--RECORD
    respuestajson jsonb;
    rpersona RECORD;
    rtoken RECORD;
    rtokenexistente RECORD;
    ruwverificador RECORD;
    rwusuario RECORD;
    emailrepetido RECORD;

    --ds 23/01/24 creo sp para gestionar el token de w_usuarioweb
    BEGIN
    --PARAMETROS
        vidusuarioweb = TRIM(parametro->>'idusuarioweb');
        vtokenn = parametro->>'tokenn'; --token a insertar nuevo
        vtokenv = parametro->>'tokenv'; --token para verificar
        vaccion = parametro->>'vaccion'; 
        

        -- verifico que los parametros estén completos
        IF nullvalue(vidusuarioweb) OR (nullvalue(vtokenn) AND nullvalue(vtokenv) AND nullvalue(vaccion)) THEN 
            RAISE EXCEPTION 'R-001, Los parametros están incompletos.  %', parametro;
        END IF;   

            -- busco los datos del usuario
            SELECT INTO rwusuario idusuarioweb, pa.nrodoc AS panrodoc, barra, uwnombre, uwemailverificado, pa.nombres, pa.apellido, 
				CASE 
    				WHEN LENGTH(uwverificador) > 7 THEN null
    				WHEN (NOT nullvalue(uwverificador) AND vaccion = 'buscarToken') THEN 'abc' 
    			ELSE uwverificador END AS uwverificador,
				TRIM(BOTH ' ' FROM COALESCE(urws.dni, idusuarioweb::VARCHAR)) AS nrodoc, uwtipo AS tipousr, 
                CASE WHEN NOT nullvalue(uwmail) AND NOT nullvalue(uwemailverificado) AND (uwmail = vidusuarioweb OR uwnombre = vidusuarioweb) THEN uwmail ELSE email END AS uwmail, pa.email AS pemail 
                FROM w_usuarioweb                     
                LEFT JOIN w_usuarioafiliado usa USING (idusuarioweb)    
                LEFT JOIN w_usuariorolwebsiges AS urws USING (idusuarioweb) -- ds 21/05/24 se saca left join con usuariorolwebsiges hasta arraglar los datos de esa tabla
        
                -- LEFT JOIN persona as pe ON (pe.nrodoc = urws.dni)                                                   
                LEFT JOIN persona pa USING (nrodoc, tipodoc)  
                LEFT JOIN usuario AS us ON (us.dni = urws.dni)              
                    WHERE uwactivo AND (
                        (NOT nullvalue(uwemailverificado) AND (uwnombre = vidusuarioweb OR LOWER(uwmail) = LOWER(vidusuarioweb) OR LOWER(login) = LOWER(vidusuarioweb) )) OR 
                        (LOWER(pa.email) = LOWER(vidusuarioweb) ) OR ((vaccion = 'verificarEmail' OR vaccion = 'buscarToken') AND idusuarioweb = vidusuarioweb));

            IF rwusuario.idusuarioweb IS NULL THEN 
                RAISE EXCEPTION 'R-002: No se ha podido enviar el email ya que no cuenta con el email verificado o no coincide el dato ingresado';
            END IF;

            IF(vaccion <> 'buscarToken') THEN 
            
                -- si no se envió un token nuevo se le genera uno nuevo
            IF (nullvalue(vtokenv)) THEN

                -- Verifico si ya existe un email igual y que ya esté verificado
			    SELECT uwmail INTO emailrepetido
			    FROM w_usuarioweb 
			    WHERE LOWER(uwmail) = LOWER(parametro->>'destino') AND uwemailverificado IS NOT NULL;

                -- Si el email existe se envia una excepción de que ya existe
			    IF emailrepetido IS NOT NULL THEN
				    RAISE EXCEPTION 'R-004: Este email ya se encuentra verificado, si no fuiste vos comunícate con nosotros a soporte.app@sosunc.net.ar';
                END IF;

                IF ((rwusuario.barra >= 100 AND rwusuario.barra <= 129) OR (rwusuario.barra >= 1 AND rwusuario.barra <= 10)) THEN
                       RAISE EXCEPTION 'R-005: Solo los usuarios titulares pueden verificar su email';
                END IF;


                     
                -- IF rwusuario.idusuarioweb IS NOT NULL THEN 
                UPDATE w_usuarioweb 
                    SET uwverificador = vtokenn
                WHERE (idusuarioweb = rwusuario.idusuarioweb AND (uwverificador IS NULL OR LENGTH(uwverificador) >= 7));

         

            --si se envió un token nuevo se verifica si el token es correcto
            ELSE 
                IF(md5(rwusuario.uwverificador) = vtokenv) THEN 
                     -- actualizo en null el token que ya se verificó

                    -- verifico el uwmail sea el mismo que en persona en caso de que no esté verificado
                    -- UPDATE w_usuarioweb 
                    --     SET uwmail = rwusuario.pemail, uwemailverificado = now() 
                    -- WHERE (idusuarioweb = rwusuario.idusuarioweb AND LOWER(uwmail) <> LOWER(rwusuario.pemail));
           
                    -- -- en caso de que los emails son lo mismo y el de usuario web no está verificado se actualiza la fecha de verificación
                    -- UPDATE w_usuarioweb 
                    --     SET uwemailverificado = now() 
                    -- WHERE (idusuarioweb = rwusuario.idusuarioweb AND LOWER(uwmail) = LOWER(rwusuario.pemail) AND nullvalue(uwemailverificado));

					CASE vaccion 		
						WHEN 'verificarEmail' THEN  				
						-- Verifico que exista un destino y le hago las actualizaciones correspondientes

							IF(NOT nullvalue(parametro->>'destino')) THEN 
                        		UPDATE w_usuarioweb 
                            	SET uwmail = LOWER(parametro->>'destino')
                        		WHERE (idusuarioweb = rwusuario.idusuarioweb);

                        		UPDATE persona 
                            	SET email = LOWER(parametro->>'destino')
                        		WHERE (nrodoc = rwusuario.panrodoc);
                    		END IF;
							
						WHEN 'recuperarContrasena' THEN  				
						-- LLamo SP que busca el informe 				
							UPDATE w_usuarioweb 
                            	SET uwmail = rwusuario.pemail
                        	WHERE (idusuarioweb = rwusuario.idusuarioweb AND (uwmail <> rwusuario.pemail OR nullvalue(uwmail)) AND nullvalue(uwemailverificado));

							UPDATE persona 
                            	SET email = rwusuario.uwmail
                        	WHERE (nrodoc = rwusuario.panrodoc AND email <> rwusuario.uwmail AND NOT nullvalue(rwusuario.uwemailverificado));
						ELSE 
					END CASE;

					UPDATE w_usuarioweb SET uwverificador = NULL WHERE (idusuarioweb = rwusuario.idusuarioweb);
					UPDATE w_usuarioweb SET uwemailverificado = now() WHERE (idusuarioweb = rwusuario.idusuarioweb AND nullvalue(uwemailverificado));

                ELSE
                    RAISE EXCEPTION 'R-003: Código inválido';
                END IF;

                -- verifico que se hayan actualizdo los datos en el UPDATE anterior
                SELECT INTO rwusuario  uwmail, uwnombre, uwemailverificado, idusuarioweb, uwtipo AS tipousr, TRIM(BOTH ' ' FROM COALESCE(dni, idusuarioweb::VARCHAR)) AS nrodoc
                    FROM w_usuarioweb 
					LEFT JOIN w_usuariorolwebsiges AS urws USING (idusuarioweb)
                WHERE (idusuarioweb = rwusuario.idusuarioweb);           
            END IF;
            
            END IF;

    
        respuestajson = row_to_json(rwusuario);
        RETURN respuestajson;
    END;
$function$
