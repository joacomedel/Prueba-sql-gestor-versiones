CREATE OR REPLACE FUNCTION public.vincula_solicitud_auditoria_seguimiento_medicamento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  
  cursorficha CURSOR FOR SELECT * FROM  temp_solicitudauditoriaitem;

  vidsolicitudauditoria bigint;
  vidcentrosolicitudauditoria integer;
  vtxtoobservacion text;
  elem RECORD;
  rsolicitud RECORD;
 

BEGIN

respuesta = true;

open cursorficha;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP

IF elem.accion = 'vincularSolicitudAuditoria' THEN 
	UPDATE solicitudauditoriaitem SET idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento
					  ,idcentrofichamedicainfomedicamento = elem.idcentrofichamedicainfomedicamento
	WHERE  idsolicitudauditoriaitem = elem.idsolicitudauditoriaitem 
		AND idcentrosolicitudauditoriaitem = elem.idcentrosolicitudauditoriaitem;

	vidsolicitudauditoria = elem.idsolicitudauditoria;
	vidcentrosolicitudauditoria = elem.idcentrosolicitudauditoria ;
	vtxtoobservacion = elem.idcentrosolicitudauditoria ;
END IF;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;
--Verifico si estan todos los items de la solcitud vinculados, cambio de estado la solicitud
SELECT INTO rsolicitud * FROM solicitudauditoria 
		   NATURAL JOIN solicitudauditoriaitem
		   WHERE idsolicitudauditoria = vidsolicitudauditoria 
			AND idcentrosolicitudauditoria = vidcentrosolicitudauditoria 
			AND nullvalue(idfichamedicainfomedicamento);
IF NOT FOUND THEN 

UPDATE solicitudauditoriaestado SET saefechafin = now() WHERE idsolicitudauditoria = vidsolicitudauditoria AND idcentrosolicitudauditoria = vidcentrosolicitudauditoria AND nullvalue(saefechafin);
INSERT INTO solicitudauditoriaestado(idsolicitudauditoria,idcentrosolicitudauditoria,saefechafin,saeidusuario,idsolicitudauditoriaestadotipo,saeobservacion,saetdescripcion) 
VALUES(vidsolicitudauditoria,vidcentrosolicitudauditoria,null,sys_dar_usuarioactual(),2,'Al auditar todas los items de la auditoria',vtxtoobservacion);



END IF;
return respuesta;
END;
$function$
