CREATE OR REPLACE FUNCTION public.w_crearusuarioweb_delegacion(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* SELECT  w_crearusuarioweb_delegacion('{"pnrodoc":"COMPLETAR", "ptipodoc":1, "pemail":"COMPLETAR"}')
* Este SP crea/actualiza un usuario_web desde la app con usuario empleado
* 1- vincula al afiliado el correo electronico informado a afiliaciones
* 2- si el afiliado tiene cuenta marca como verificado al correo y la contrasena la pisa con el numero de documento
* 3- si el afiliado NO tiene cuenta la crea
*/
DECLARE
       hubocambios	INTEGER ;
       rusuarioweb record ;
       remailexiste record ;
       rpersona record;
       vuwnombre character varying;
       vuwemailverificado timestamp;
       resp character varying;
	   param  character varying;
	   respuesta jsonb;
BEGIN
	IF (nullvalue(parametro->>'pnrodoc') OR nullvalue(parametro->>'ptipodoc') OR nullvalue(parametro->>'pemail')) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

    SELECT INTO rpersona *
    FROM persona
    WHERE nrodoc = TRIM(parametro->>'pnrodoc');

    --Verifico si es beneficiario y le permito utilizar el mismo email que el titular
    IF FOUND AND ((rpersona.barra >= 130 AND rpersona.barra <= 162) OR (rpersona.barra >= 30 AND rpersona.barra <= 40)) THEN
        -- SL 27/09/24 - Verifico si el email ya existe
        SELECT INTO remailexiste * 
        FROM w_usuarioweb
            LEFT JOIN w_usuarioafiliado ua USING(idusuarioweb)
        LEFT JOIN persona p USING(nrodoc, tipodoc)
        WHERE nrodoc <> TRIM(parametro->>'pnrodoc') AND (uwnombre = TRIM(parametro->>'pemail') OR (uwmail = TRIM(parametro->>'pemail') AND NOT nullvalue(uwemailverificado)));
    END IF;

    IF remailexiste IS NULL THEN
        -- SL 03/06/24 - Cambio consulta ya que la anterior no contempla empleados
        SELECT INTO rusuarioweb nrodoc, email, uwmail, barra, uw.idusuarioweb
        FROM persona
                LEFT JOIN w_usuarioafiliado ua USING(nrodoc)
                LEFT JOIN w_usuariorolwebsiges urws ON (nrodoc = dni)
                JOIN w_usuarioweb uw ON (ua.idusuarioweb = uw.idusuarioweb OR uw.idusuarioweb = urws.idusuarioweb)
        WHERE nrodoc = TRIM(parametro->>'pnrodoc')
        GROUP BY  nrodoc, email, uwmail, barra, uw.idusuarioweb;
            

        IF FOUND THEN
                --SL 13/12/24 - Agrego el caso de blanqueo de beneficiario, siempre utiliza DNI como uwnombre y no se le verifica el email ya que puede utilizar el del titular (caso menores de edad)
                IF (rpersona.barra >= 100 AND rpersona.barra <= 129) OR (rpersona.barra >= 1 AND rpersona.barra <= 29) THEN
                    vuwnombre = rpersona.nrodoc;
                    vuwemailverificado = null;
                ELSE
                    vuwnombre = parametro->>'pemail';
                    vuwemailverificado = NOW();
                END IF;

                IF rusuarioweb.barra <> 32 THEN
                    -- el afiliado tiene un usuario
                    UPDATE w_usuarioweb 
                    SET uwnombre = vuwnombre   --- el correo va a ser su nombre de usuario
                        ,uwcontrasenia = MD5(rusuarioweb.nrodoc)  -- la contraaseña es el DNI
                        ,uwmail = parametro->>'pemail' ---queda el correo informado a la delegacion
                        ,uwactivo = true
                        ,uwlimpiar = true
                        ,uwemailverificado	= vuwemailverificado ---queda verificada la pass
                    WHERE idusuarioweb = rusuarioweb.idusuarioweb; /* AND nullvalue(uwemailverificado)  */ 
                    --SL 29/05/24 - Comento el email verificado ya que hay casos que tiene verificado y no es el email

                    --Obtengo si se efectuaron cambios
                    GET DIAGNOSTICS hubocambios = ROW_COUNT;

                    IF hubocambios > 0 THEN
                        --SL 28/05/24 - Actualizo el email de la persona
                        UPDATE persona 
                        SET email=parametro->>'pemail'
                        WHERE nrodoc = parametro->>'pnrodoc';

                        --Si se efectuaron cambios respondo segun la barra
                        IF (rusuarioweb.barra >= 100 AND rusuarioweb.barra <= 129) OR (rusuarioweb.barra >= 1 AND rusuarioweb.barra <= 10) THEN
                            resp = 'El usuario fue blanqueado con exito! Para ingresar debera utilizar su DNI como usuario y contraseña. Por favor, cambiar la contraseña una vez dentro';
                        ELSE
                            resp = 'El usuario fue blanqueado con exito! Para ingresar debera utilizar su Email y DNI como usuario y contraseña. Por favor, cambiar la contraseña una vez dentro';
                        END IF;
                    ELSE	--No se pudo actualizar, entonces veo que sucedio
                                --SL 29/05/24 - Comento ya que no verifica si tiene (email verificado) y si entra aca es porque falló algo
                                /*
                        -- Valido si tiene el email verificado
                        IF nullvalue(rusuarioweb.uwemailverificado) THEN
                            --Error interno, llamar a soporte para ver que sucedio
                            RAISE EXCEPTION 'R-001: Hubo un error al actualizar el usuario, contactese con soporte.app@sosunc.net.ar';
                        ELSE	
                            --En caso de que el email este verificado respondo para que recupere contraseña por otro medio
                            RAISE EXCEPTION 'R-002: La cuenta existe con email verificado. El afiliado puede reestablecer su contraseña con el siguiente email %',rusuarioweb.email;
                        END IF;
                                */
                            RAISE EXCEPTION 'R-001: Hubo un error al actualizar el usuario, contactese con soporte.app@sosunc.net.ar';
                    END IF;
                ELSE
                    RAISE EXCEPTION 'R-202: Para restablecer la contraseña debe realizarlo desde SIGES o contactese con soporte.app@sosunc.net.ar ';
                END IF;
        ELSE 
                -- EL AFILIADO NO TIENE usuario
                param = concat ('{pnrodoc=',parametro->>'pnrodoc',', ptipodoc=',parametro->>'ptipodoc',', ppass=',MD5(parametro->>'pnrodoc'),', pemail=',parametro->>'pemail',', prolweb=',1,', elusuario=',parametro->>'pemail',',passmd5=',MD5(parametro->>'pnrodoc'),'}');
                SELECT INTO resp  w_crearusuarioweb(param);
                --Si se efectuaron cambios respondo segun la barra
                IF FOUND AND ((CAST(resp AS INTEGER) >= 100 AND CAST(resp AS INTEGER) <= 129) OR (CAST(resp AS INTEGER) >= 1 AND CAST(resp AS INTEGER) <= 29)) THEN
                    resp = 'El usuario fue creado con exito! Para ingresar debera utilizar su DNI como usuario y contraseña. Por favor, cambiar la contraseña una vez dentro';
                ELSE
                    resp = 'El usuario fue creado con exito! Para ingresar debera utilizar su Email y DNI como usuario y contraseña. Por favor, cambiar la contraseña una vez dentro';
                END IF;
        END IF;
    ELSE
     -- SL 09/10/24 - Si sucede esta excepcion es porque el email ya esta utilizado por esa persona y se encuentra verificado (Tiene que restablecer por su cuenta la contraseña) o el email se encuentra asociado a otra cuenta (Debera utilizar otro) 
        RAISE EXCEPTION 'R-300: El email ya se encuentra utilizado.';
    END IF;
	            
	respuesta = concat('{"mensaje":"',resp,'"}');
return respuesta;

end;
$function$
