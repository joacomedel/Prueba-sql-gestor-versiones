CREATE OR REPLACE FUNCTION public.alta_modifica_solicitud_auditoria()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  
  cursorficha CURSOR FOR SELECT * FROM  temp_solicitudauditoriaitem;

  vidsolicitudauditoria bigint;
  vidcentrosolicitudauditoria integer;
  elem RECORD;
  raux record;

  rborrar record;
  rpidfmim RECORD;
  rsolicitud RECORD;
 

BEGIN

respuesta = true;



SELECT INTO rsolicitud * FROM temp_solicitudauditoria;
	IF FOUND THEN 
		IF rsolicitud.accion = 'replicar' THEN 
			INSERT INTO solicitudauditoria (sadiagnostico,nrodoc,tipodoc,idprestador,saidusuario) (
				select sadiagnostico,nrodoc,tipodoc,idprestador,sys_dar_usuarioactual() as saidusuario 
				FROM solicitudauditoria 
				WHERE idsolicitudauditoria = rsolicitud.idsolicitudauditoria 
					AND idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria 
			);
			vidsolicitudauditoria = currval('public.solicitudauditoria_idsolicitudauditoria_seq'::regclass);
			vidcentrosolicitudauditoria = centro();
			INSERT INTO solicitudauditoriaestado (idsolicitudauditoria,idcentrosolicitudauditoria,saefechafin,saeidusuario,idsolicitudauditoriaestadotipo,saeobservacion,saetdescripcion) 
				VALUES(vidsolicitudauditoria,vidcentrosolicitudauditoria,null,sys_dar_usuarioactual(),1,concat('Al replicar la solicitud',rsolicitud.idsolicitudauditoria,'-',rsolicitud.idcentrosolicitudauditoria),rsolicitud.saetdescripcion);
			INSERT INTO solicitudauditoriaitem (idsolicitudauditoria,idcentrosolicitudauditoria,idplancoberturas,idarticulo,idcentroarticulo,idmonodroga,saicobertura,saidosisdiaria,saipresentacion) 

			( SELECT vidsolicitudauditoria,vidcentrosolicitudauditoria,idplancoberturas,idarticulo,idcentroarticulo,idmonodroga,saicobertura,saidosisdiaria,saipresentacion
				FROM solicitudauditoriaitem 
				WHERE idsolicitudauditoria = rsolicitud.idsolicitudauditoria 
					AND idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria  
			);
	
		END IF;
		IF rsolicitud.accion = 'alta' THEN 
			INSERT INTO solicitudauditoria (sadiagnostico,nrodoc,tipodoc,idprestador,saidusuario) (
				select sadiagnostico,nrodoc,tipodoc,idprestador,sys_dar_usuarioactual() as saidusuario 
				FROM temp_solicitudauditoria LIMIT 1
			);

			rsolicitud.idsolicitudauditoria = currval('public.solicitudauditoria_idsolicitudauditoria_seq'::regclass);
			rsolicitud.idcentrosolicitudauditoria = centro();
			rsolicitud.safechaingreso = now();
			
                        IF not nullvalue(rsolicitud.idsolicitudauditoriaarchivo) THEN
                           UPDATE solicitudauditoria_archivos SET idsolicitudauditoria=rsolicitud.idsolicitudauditoria , idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria 
                           WHERE idsolicitudauditoriaarchivo = rsolicitud.idsolicitudauditoriaarchivo 
                                 AND idcentrosolicitudauditoriaarchivo = rsolicitud.idcentrosolicitudauditoriaarchivo;
                        END IF;
			INSERT INTO solicitudauditoriaestado (idsolicitudauditoria,idcentrosolicitudauditoria,saefechafin,saeidusuario,idsolicitudauditoriaestadotipo,saeobservacion,saetdescripcion) 
				VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,null,sys_dar_usuarioactual(),1,'Al ingresar la solicitud',rsolicitud.saetdescripcion);
	
		END IF;
		IF rsolicitud.accion = 'modifica' THEN 

			UPDATE solicitudauditoria SET sadiagnostico = rsolicitud.sadiagnostico
							,nrodoc = rsolicitud.nrodoc
							,tipodoc = rsolicitud.tipodoc
							,idprestador = rsolicitud.idprestador
							
			WHERE idsolicitudauditoria = rsolicitud.idsolicitudauditoria
				AND idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria;

                        IF not nullvalue(rsolicitud.idsolicitudauditoriaarchivo) THEN
                           UPDATE solicitudauditoria_archivos SET idsolicitudauditoria=rsolicitud.idsolicitudauditoria , idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria 
                           WHERE idsolicitudauditoriaarchivo = rsolicitud.idsolicitudauditoriaarchivo 
                                AND idcentrosolicitudauditoriaarchivo = rsolicitud.idcentrosolicitudauditoriaarchivo;
                        END IF;

		END IF;

		IF rsolicitud.accion = 'elimina' THEN 
			UPDATE solicitudauditoriaestado SET saefechafin = now()
					WHERE idsolicitudauditoria = rsolicitud.idsolicitudauditoria
						AND idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria
						AND nullvalue(saefechafin);
			INSERT INTO solicitudauditoriaestado (idsolicitudauditoria,idcentrosolicitudauditoria,saefechafin,saeidusuario,idsolicitudauditoriaestadotipo,saeobservacion,saetdescripcion) 
			VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,null,sys_dar_usuarioactual(),3,'Al ingresar la solicitud',rsolicitud.saetdescripcion);
		END IF;

open cursorficha;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP

IF rsolicitud.accion = 'alta' THEN 

	INSERT INTO solicitudauditoriaitem (idsolicitudauditoria,idcentrosolicitudauditoria,idplancoberturas,idarticulo,idcentroarticulo,idmonodroga,saicobertura,saidosisdiaria,saipresentacion) 
	VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,elem.idplancoberturas,elem.idarticulo,elem.idcentroarticulo,elem.idmonodroga,elem.saicobertura,elem.saidosisdiaria,elem.saipresentacion);
	
END IF;

IF rsolicitud.accion = 'modifica' THEN 

	UPDATE solicitudauditoriaitem SET idsolicitudauditoria = elem.idsolicitudauditoria
					  ,idcentrosolicitudauditoria = elem.idcentrosolicitudauditoria
					  ,idplancoberturas = elem.idplancoberturas
					  ,idarticulo = elem.idarticulo
					  ,idcentroarticulo = elem.idcentroarticulo
					  ,idmonodroga = elem.idmonodroga
					  ,saicobertura = elem.saicobertura
					  ,saidosisdiaria = elem.saidosisdiaria
					  ,saipresentacion =elem.saipresentacion
	WHERE  idsolicitudauditoriaitem = elem.idsolicitudauditoriaitem 
		AND idcentrosolicitudauditoriaitem = elem.idcentrosolicitudauditoriaitem;
		
END IF;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;


IF rsolicitud.accion = 'eliminarrseguimiento' THEN 
   PERFORM auditoriamedica_eliminarsolicitudes_confiltro(concat('{accion=eliminarrseguimiento, idsolicitudauditoria=',rsolicitud.idsolicitudauditoria,', idcentrosolicitudauditoria=',rsolicitud.idcentrosolicitudauditoria,'}'));

END IF;

END IF;
return respuesta;
END;
$function$
