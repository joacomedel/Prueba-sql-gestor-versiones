CREATE OR REPLACE FUNCTION public.alerta_auditoriamedica_segmedicamentos()
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	calertas REFCURSOR;
	ralerta RECORD;
	rusuario RECORD;
	resultado TEXT;
        

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
/*
select c.nrodoc,c.tipodoc,p.nombres,p.apellido,rtp.nrorecetario,rtp.centro,raobservacion,concat(u.nombre,' ',u.apellido) as usuarioalerta,mnombre,mpresentacion,rtp.rtpicantidadauditada 
from recetariotp_alertado
natural join recetariotpitem as rtp
natural join medicamento
JOIN consumo as c ON rtp.nrorecetario = c.nroorden AND c.centro = rtp.centro
JOIN persona as p USING(nrodoc,tipodoc)
LEFT JOIN usuario as u ON idusuario = idusuariocreacion
WHERE nullvalue(rafechafin)
*/

resultado = concat('<html><span><b>Recetarios Informados......</b></span>');
resultado = concat(resultado,'<table border="1" ><tr><th>Nro.Doc</th><th>Nrombre y Apellido</th><th>Nro.Recetario</th>
<th>Observacion</th><th>Notifico</th><th>Medicamento</th><th>Presentacion</th><th>Cant.Auditada</th><th>Cant.Vendida</th></tr>');
OPEN calertas FOR SELECT concat('<tr><td>','DNI:',c.nrodoc,'</td><td>',p.nombres,' ',p.apellido,'</td><td>',rtp.nrorecetario,'-',rtp.centro,'</td>'
,'<td>',raobservacion,'</td>','<td>',concat(u.nombre,' ',u.apellido),'</td>','<td>',mnombre,'</td>','<td>',mpresentacion,'</td>','<td>',rtp.rtpicantidadauditada,'</td>','<td>',far_cantconsumida_rtpi_v1(rtp.nrorecetario,rtp.centro),'</td>','</tr>') as fila
--,c.nrodoc,c.tipodoc,p.nombres,p.apellido,rtp.nrorecetario,rtp.centro,raobservacion,concat(u.nombre,' ',u.apellido) as usuarioalerta,mnombre,mpresentacion,rtp.rtpicantidadauditada 
			from recetariotp_alertado
			natural join recetariotpitem as rtp
			natural join medicamento
			JOIN consumo as c ON rtp.nrorecetario = c.nroorden AND c.centro = rtp.centro
			JOIN persona as p USING(nrodoc,tipodoc)
			LEFT JOIN usuario as u ON idusuario = idusuariocreacion
			WHERE nullvalue(rafechafin);
			FETCH calertas into ralerta;
WHILE  found LOOP

      resultado = concat(resultado,ralerta.fila,' '::text);
  

FETCH calertas into ralerta;
END LOOP;
close calertas;

resultado = concat(resultado,'</table></html>'::text);
return resultado;
END;
$function$
