CREATE OR REPLACE FUNCTION public.far_traerinforecetariotpv1()
 RETURNS SETOF inforecetariotp
 LANGUAGE plpgsql
AS $function$DECLARE

	rtp inforecetariotp;	
	rparam RECORD;


BEGIN

PERFORM arreglarestadorecetariotpitem();
SELECT INTO rparam * FROM ttt_recetariotp LIMIT 1;

IF FOUND THEN 
        IF not nullvalue(rparam.nrorecetario) THEN 
             PERFORM  cambiar_estado_recetariotp(rparam.nrorecetario::integer,rparam.centro);
        END IF; 

	for rtp in 

		SELECT 
		 concat(to_char(r.centro, '0000') , '-' ,  to_char(r.nrorecetario , '00000000') 
                 , ' Fecha Vto RTP.: ' ,to_char(rtpfechavto,'DD-MM-YYYY'))  as elrecetario,
		  r.nrorecetario ,
		  r.centro ,
		  diagnostico ,
		  idfichamedica ,
		  idcentrofichamedica ,
		  cantidademitida ,
		  cantidadauditada ,
		  r.idusuario ,
		  rtpfechavto ,
		  rtpfechaauditoria ,
		  idvalidacion ,
		  idcentrovalidacion ,
		  m.nromatricula ,
		  m.malcance ,
		  m.mespecialidad ,
		  concat(pres.pdescripcion,' - ', m.nromatricula ,' - ',initcap(m.mespecialidad::text), ' (',m.malcance::text ,')') as  mdescripcion ,
		  pres.idprestador ,
		  fechaemision ,
		  concat(usuario.nombre ,' ' , usuario.apellido) as elauditor
		FROM recetariotp as r  
		NATURAL JOIN recetarioestados  as re
        	NATURAL JOIN recetario 
            
		JOIN consumo as c ON c.nroorden = r.nrorecetario AND c.centro = r.centro AND c.nrodoc=rparam.nrodoc AND c.tipodoc = rparam.tipodoc		

                LEFT JOIN usuario ON r.idusuario = usuario.idusuario 		
		LEFT JOIN matricula AS m ON (r.nromatricula = m.nromatricula
		 AND r.malcance = m.malcance AND r.mespecialidad=m.mespecialidad)			
		LEFT JOIN prestador as pres ON (m.idprestador = pres.idprestador) 		
		WHERE fechaemision <= rparam.fechafin 
		      AND fechaemision >= rparam.fechainicio  
		      AND c.nrodoc=rparam.nrodoc 
		      AND c.tipodoc = rparam.tipodoc 
		      AND not (c.anulado)
                      AND recetario.fechaemision <= rparam.fechafin AND recetario.fechaemision >= rparam.fechainicio
                      AND (nullvalue(refechafin) AND (re.idtipocambioestado=4 OR re.idtipocambioestado=1  OR re.idtipocambioestado=6)) 
                      AND (nullvalue(rparam.nrorecetario) OR r.nrorecetario= rparam.nrorecetario)
                      AND (nullvalue(rparam.centro) OR r.centro= rparam.centro)
                 
		    /*KR 16-05-17 esto lo voy a ver cuando vaya a buscar los items del recetario. Se supone además que si ya no tengo cantidades para consumir el recetario cambio ya de estado*/

/* AND (CASE WHEN not nullvalue(r.idvalidacion) THEN far_cantconsumida_rtpi_v1(idrecetariotpitem,idcentrorecetariotpitem) 
		             ELSE null END < rtpicantidadauditada 
		           OR nullvalue(idvalidacion))		
		      */
		loop

		return next rtp;

	end loop;

END IF;
end;$function$
