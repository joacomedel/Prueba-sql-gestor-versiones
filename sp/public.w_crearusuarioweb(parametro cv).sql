CREATE OR REPLACE FUNCTION public.w_crearusuarioweb(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
* SELECT  w_crearusuarioweb('{pnrodoc=NRODOC, ptipodoc=TIPODOC, ppass=CONTRASEÑA, pemail=EMAIL, prolweb=1, elusuario=USUARIO}')
* SIN COMILLAS !!
* Recibe como parametros el  numero de documento, tipo documento y mail
* Retorna boolean true si se a creado el usuario correctamente
*/
DECLARE
       rfiltros record ;
       rverif record ;
       rpersona RECORD;
       rusuario RECORD;
       rusuariosiges RECORD;
       rempleadodocente RECORD;
       datoUsuarioWeb RECORD;
       rcontrolusuario record ;
       fechaverif TIMESTAMP WITHOUT TIME ZONE;
       pwdtempo character varying;
       idusuariosecuencia integer;
       respuesta character varying;
begin
/* Busco los datos de la persona*/
       EXECUTE sys_dar_filtros($1) INTO rfiltros;
	 	
            SELECT INTO rpersona estados.idestado, estados.descrip AS estado, persona.*
            FROM persona 
                LEFT JOIN afilsosunc USING (nrodoc, tipodoc)
                LEFT JOIN estados on (afilsosunc.idestado=estados.idestado) 
            WHERE nrodoc = rfiltros.pnrodoc; -- AND  fechafinos >= now();

			-- update persona set email=pemail  WHERE nrodoc=rfiltros.pnrodoc and tipodoc=rfiltros.ptipodoc;
            -- SL 24/07/24 - Agrego condicion para permitir la creacion si se encuentra en compensacion
			IF FOUND AND (rpersona.fechafinos >= now() OR (rpersona.barra <> 35 AND rpersona.barra <> 36 AND rpersona.idestado = 3)) THEN 
				-- IF (rpersona.barra>10) THEN		--SL 30/05/24 - Comento ya que ahora los beneficiarios pueden tener cuenta
					--SL 17/06/24 - Agrego condicion para empleados que no tienen barra 32
					SELECT INTO rempleadodocente * FROM usuario WHERE dni = rfiltros.pnrodoc;
					IF FOUND THEN
						--Piso la barra para que entre como empleado, ya que debe tener otra barra pero traba en SOSUNC
						rpersona.barra = 32;
					END IF;
									
					IF (rpersona.barra=32) THEN
					/* Busco el usuario siges */
							SELECT INTO rusuariosiges * FROM usuario WHERE dni=rfiltros.pnrodoc and tipodoc=rfiltros.ptipodoc;
							IF not FOUND THEN
								/* no existe el usuario siges */
								-- INSERT INTO usuario(contrasena,dni,nombre,tipodoc,apellido,login,umail,usamenudinamico)
										-- VALUES(rfiltros.passTrip,rpersona.nrodoc,rpersona.nombres,rpersona.tipodoc,rpersona.apellido,rfiltros.elusuario,rfiltros.pemail,true);
								RAISE EXCEPTION 'R-001: No existe el usuario en SIGES, el mismo primero debe darse de alta ya que es un empleado';
							END IF;
							SELECT INTO rusuario * FROM usuarioconfiguracion WHERE dni=rpersona.nrodoc;
							IF not FOUND THEN
								INSERT INTO usuarioconfiguracion(dni,ucactivo)VALUES(rpersona.nrodoc,true);
							END IF;

							SELECT INTO rusuario * FROM w_usuariorolwebsiges WHERE dni=rpersona.nrodoc and idrolweb=rfiltros.prolweb;
							IF not FOUND THEN
								/*afiliado de sosunc solo insertamos por ahora*/
								INSERT INTO w_usuarioweb(uwnombre,uwcontrasenia, uwmail, uwsuscripcionnl, uwactivo, uwemailverificado)VALUES(rusuariosiges.login, md5(rusuariosiges.contrasena), rfiltros.pemail, true, true, now());
								idusuariosecuencia = currval('w_usuarioweb_idusuarioweb_seq');

								INSERT INTO w_usuariorolwebsiges(dni,idrolweb,idusuarioweb)VALUES(rpersona.nrodoc,1, idusuariosecuencia);
								INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)VALUES(idusuariosecuencia, 1);
								INSERT INTO w_usuariorolwebsiges(dni,idrolweb,idusuarioweb)VALUES(rpersona.nrodoc,13, idusuariosecuencia);
								INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)VALUES(idusuariosecuencia, 13);

								--! SL 30/05/24 - Reever caso
								INSERT INTO w_usuarioafiliado(nrodoc,tipodoc,idusuarioweb)VALUES(rpersona.nrodoc, rpersona.tipodoc, idusuariosecuencia);

								--SL 28/05/24 - Actualizo el email de la persona
								UPDATE persona 
								SET email=rfiltros.pemail 
								WHERE nrodoc=rfiltros.pnrodoc;
							ELSE
								RAISE EXCEPTION 'R-004: Los datos ingresados ya están asociados a una cuenta existente.';
							END IF;	
						respuesta = rpersona.barra;
					ELSE /* USUARIO AFILIADO*/

                        fechaverif = now();
                        -- Si es benef, piso el usuario y siempre es el nrodoc
                    	IF ((rpersona.barra >= 100 AND rpersona.barra <= 129) OR (rpersona.barra >= 1 AND rpersona.barra <= 29)) THEN
                            rfiltros.elusuario = rfiltros.pnrodoc;
                            fechaVerif = null;  --Si es beneficiario no verifico el email
                        END IF;

						SELECT INTO rcontrolusuario * 
						FROM w_usuarioweb 
						LEFT join w_usuarioafiliado USING(idusuarioweb)
						WHERE uwnombre = rfiltros.elusuario; 

						IF ( NOT FOUND  OR (not nullvalue(rcontrolusuario.nrodoc) AND rcontrolusuario.nrodoc=rfiltros.pnrodoc ))THEN -- El nombre de usuario no esta siendo utilizado o por la persona que esta creando la cuenta
								SELECT INTO rusuario *
								FROM w_usuarioafiliado  WHERE nrodoc=rfiltros.pnrodoc and tipodoc=rfiltros.ptipodoc;
								IF NOT FOUND THEN  /*CREO EL USUARIO*/
									SELECT INTO rcontrolusuario * 
									FROM w_usuarioweb 
									WHERE uwnombre = rfiltros.elusuario  and not(idusuarioweb = rusuario.idusuarioweb); 

									--Verifico los datos del afiliado (Da error y corta ejecucion si falta algun dato)
									PERFORM w_datoafiliado(json_build_object('doc', rfiltros.pnrodoc)::jsonb);

                                    INSERT INTO w_usuarioweb(uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar,uwemailverificado)   
                                    VALUES(rfiltros.elusuario,rfiltros.passMd5,rfiltros.pemail,true,null,true,false,fechaVerif);
                                    idusuariosecuencia = currval('w_usuarioweb_idusuarioweb_seq');  
                            
									IF (rpersona.barra = 35 OR rpersona.barra = 36) THEN  	--Si es adherente se pone rol 26
										INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)VALUES(idusuariosecuencia, 26);
									ELSEIF (rpersona.barra >= 130 AND rpersona.barra <= 160) THEN 	--Si es reci se pone rol 37
										INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)VALUES(idusuariosecuencia, 37);
									ELSEIF ((rpersona.barra >= 100 AND rpersona.barra <= 129) OR (rpersona.barra >= 1 AND rpersona.barra <= 29)) THEN 	--Si es benef se pone rol 36
										INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)VALUES(idusuariosecuencia, 36);
									ELSE --Si es Afiliado se pone rol 1
										INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)VALUES(idusuariosecuencia, 1);
									END IF;
									INSERT INTO w_usuarioafiliado(nrodoc,tipodoc,idusuarioweb)                                
										VALUES(rpersona.nrodoc,rpersona.tipodoc,idusuariosecuencia);

									--SL 28/05/24 - Actualizo el email de la persona
									UPDATE persona 
									SET email=rfiltros.pemail 
									WHERE nrodoc=rfiltros.pnrodoc;

									respuesta = rpersona.barra;
								ELSE /*ACTUALIZO LOS DATOS DEL USUARIO*/
																/*
										UPDATE w_usuarioweb 
										SET uwnombre = rfiltros.elusuario 
											,uwcontrasenia = rfiltros.passMd5
											,uwmail = rfiltros.pemail 
											,uwactivo = true
											,uwlimpiar = true
										WHERE idusuarioweb =  rusuario.idusuarioweb;   
									respuesta = 'El usuario existia y se actualizaron sus datos: usuario/pass/email';
																*/
														-- SL 20/05/24 - Modifico para que no toque la cuenta y solo avise que ya existe.
                                    RAISE EXCEPTION 'R-010: Los datos ingresados ya están asociados a una cuenta existente.';
								END IF;
					    ELSE 
                            RAISE EXCEPTION 'R-006: Los datos ingresados ya están asociados a una cuenta existente.';
                            -- respuesta = 'R-003: Ya existe una cuenta con ese nombre de usuario';
					    END IF;	                       
				END IF;
			-- ELSE 
				-- RAISE EXCEPTION 'R-002: Solo usuarios titulares pueden tener cuenta';
				-- respuesta = 'R-002: Solo usuarios titulares pueden tener cuenta';
			-- END IF;                      
		ELSE 
			RAISE EXCEPTION 'R-011: No se encontro la persona con DNI, % o no se encuentra activo.', rfiltros.pnrodoc;
		END IF;                      
return respuesta;

end;$function$
