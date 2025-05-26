CREATE OR REPLACE FUNCTION public.alta_modifica_solicitud_auditoria_empadronamiento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  
  cursorficha CURSOR FOR SELECT * FROM  temp_solicitudauditoriaitem;
  DECLARE cursorficha_update CURSOR FOR SELECT * FROM  temp_solicitudauditoriaitem FOR UPDATE;
  cursos_temp_solicitudauditoriadiagnosticoempadronamiento CURSOR FOR SELECT * FROM temp_solicitudauditoriadiagnosticoempadronamiento;

  vidsolicitudauditoria bigint;
  vidcentrosolicitudauditoria integer;
  
  vidsolicitudauditoriaitem bigint;
  vidcentrosolicitudauditoriaitem integer;
  
  elem RECORD;
  raux record;
  idsolicitudauditoriaitem_aux integer;
  idcentrosolicitudauditoriaitem_aux integer;

  rborrar record;
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
				VALUES(vidsolicitudauditoria,vidcentrosolicitudauditoria,null,sys_dar_usuarioactual(),1,concat('res. 310/04 - (replica) - ',rsolicitud.saetdescripcion),rsolicitud.saetdescripcion);
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
			
			--Adriano 31-01-2024
			--Este update es util ya que, en otra consulta posterior a este SP, se accede a esta misma tabla temporal para obtener el id y centro de la solicitud de auditoria
			UPDATE temp_solicitudauditoria SET idsolicitudauditoria = rsolicitud.idsolicitudauditoria, idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria;			
			
                        IF not nullvalue(rsolicitud.idsolicitudauditoriaarchivo) THEN
                           UPDATE solicitudauditoria_archivos SET idsolicitudauditoria=rsolicitud.idsolicitudauditoria , idcentrosolicitudauditoria = rsolicitud.idcentrosolicitudauditoria 
                           WHERE idsolicitudauditoriaarchivo = rsolicitud.idsolicitudauditoriaarchivo 
                                 AND idcentrosolicitudauditoriaarchivo = rsolicitud.idcentrosolicitudauditoriaarchivo;
                        END IF;
			INSERT INTO solicitudauditoriaestado (idsolicitudauditoria,idcentrosolicitudauditoria,saefechafin,saeidusuario,idsolicitudauditoriaestadotipo,saeobservacion,saetdescripcion) 
				VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,null,sys_dar_usuarioactual(),1,concat('res. 310/04 - (ingreso) - ',rsolicitud.saetdescripcion),rsolicitud.saetdescripcion);
	
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
			VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,null,sys_dar_usuarioactual(),3,concat('res. 310/04 - (ingreso) - ',rsolicitud.saetdescripcion),rsolicitud.saetdescripcion);
		END IF;

open cursorficha;
OPEN cursorficha_update;
FETCH cursorficha_update INTO elem;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP

IF rsolicitud.accion = 'alta' THEN 

	INSERT INTO solicitudauditoriaitem (idsolicitudauditoria,idcentrosolicitudauditoria,idplancoberturas,idarticulo,idcentroarticulo,idmonodroga,saicobertura,saidosisdiaria,saipresentacion) 
	VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,elem.idplancoberturas,elem.idarticulo,elem.idcentroarticulo,elem.idmonodroga,elem.saicobertura,elem.saidosisdiaria,elem.saipresentacion);	
		
	idsolicitudauditoriaitem_aux := currval('solicitudauditoriaitem_idsolicitudauditoriaitem_seq');
	idcentrosolicitudauditoriaitem_aux := centro();
	
	INSERT INTO solicitudauditoriaitem_ext (idsolicitudauditoriaitem,idcentrosolicitudauditoriaitem,comprsxdia,cantidadtotal)
	VALUES (idsolicitudauditoriaitem_aux, idcentrosolicitudauditoriaitem_aux,elem.comprsxdia,elem.cantidadtotal);

	vidsolicitudauditoriaitem = currval('solicitudauditoriaitem_idsolicitudauditoriaitem_seq'::regclass);
	vidcentrosolicitudauditoriaitem = centro();

	--Adriano 31-01-2024
	--Este update es util ya que, en otra consulta posterior a este SP, se accede a esta misma tabla temporal para obtener el id y centro de la solicitud de auditoria
	UPDATE temp_solicitudauditoriaitem
	SET idsolicitudauditoriaitem = vidsolicitudauditoriaitem, idcentrosolicitudauditoriaitem = vidcentrosolicitudauditoriaitem
	WHERE CURRENT OF cursorficha_update ;
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
FETCH cursorficha_update INTO elem;
END LOOP;
CLOSE cursorficha;
CLOSE cursorficha_update;

OPEN cursos_temp_solicitudauditoriadiagnosticoempadronamiento;
FETCH cursos_temp_solicitudauditoriadiagnosticoempadronamiento INTO elem;
WHILE FOUND LOOP
	IF rsolicitud.accion = 'alta' THEN 	
		INSERT INTO solicitudauditoriadiagnosticoempadronamiento (idsolicitudauditoria,idcentrosolicitudauditoria,iddiagnosticoempadronamiento)
		VALUES(rsolicitud.idsolicitudauditoria,rsolicitud.idcentrosolicitudauditoria,elem.iddiagnosticoempadronamiento);
	END IF;
	FETCH cursos_temp_solicitudauditoriadiagnosticoempadronamiento INTO elem;
END LOOP;

IF rsolicitud.accion = 'eliminarrseguimiento' THEN
   PERFORM auditoriamedica_eliminarsolicitudes_confiltro(concat('{accion=eliminarrseguimiento, idsolicitudauditoria=',rsolicitud.idsolicitudauditoria,', idcentrosolicitudauditoria=',rsolicitud.idcentrosolicitudauditoria,'}'));

END IF;

END IF;
return respuesta;
END;
$function$
