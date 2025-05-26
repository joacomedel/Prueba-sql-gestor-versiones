CREATE OR REPLACE FUNCTION public.alta_modifica_auditoria_medica_pendientes_automaticos_interno(pid integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    	
        cconfiguracionespendientes refcursor;
        resultado boolean;
	elem record;
	rconfiguracion record;
	idtipopres integer;
	rverifica record;
        vfechavtoconfiguracion date;
        vfechaingresoconfiguracion date;
        rusuario record;

BEGIN
	resultado = true;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO rconfiguracion * FROM temp_configuracion WHERE id=pid;
--Verifico (2018-01-31) a (2018-01-31)
--Recupero las configuraciones 'MENSUALES' que pueden generar pendientes de emisiones. 
	
		vfechaingresoconfiguracion = rconfiguracion.fechaingresoconfiguracion;
		vfechavtoconfiguracion = rconfiguracion.fechavtoconfiguracion;
		-- Busco la configuraciones generadas
		SELECT  INTO elem * FROM fichamedica 
			NATURAL JOIN fichamedicaitem
			NATURAL JOIN fichamedicaemision
                        NATURAL JOIN fichamedicaemisionestado
			JOIN mapea_certdisc_alcancecobertura_fichamedicaitem USING(idfichamedicaitem,idcentrofichamedicaitem)
			WHERE nrodoc = rconfiguracion.nrodoc AND tipodoc = rconfiguracion.tipodoc AND idauditoriatipo=5 --'05389938' 
                                AND nullvalue(fichamedicaemisionestado.fmeefechafin) 
				AND idcertdiscapacidad = rconfiguracion.idcertdiscapacidad
				AND idcentrocertificadodiscapacidad = rconfiguracion.idcentrocertificadodiscapacidad
				AND idalcancecobertura = rconfiguracion.idalcancecobertura
				AND idcentroalcancecobertura =  rconfiguracion.idcentroalcancecobertura
				AND fmefechavto = vfechavtoconfiguracion
				AND fmepfecha = vfechaingresoconfiguracion;
			--idcertdiscapacidad,idcentrocertificadodiscapacidad,idalcancecobertura,idcentroalcancecobertura
		IF NOT FOUND THEN
			IF ( rconfiguracion.porcentaje<>0 AND rconfiguracion.cantidadperiodo<>0 ) THEN 
			-- BelenA 09/09/24 : Si la nueva configuracion no tiene datos en 0, creo los nuevos items de emisiones
					INSERT INTO fichamedicaitem  
		                            (fmiporreintegro,fmifechaauditoria,idprestador,idusuario,fmicantidad,fmidescripcion,idfichamedica,
		                            idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica
					    )                    
					   values(false,vfechaingresoconfiguracion,rconfiguracion.idprestador,CASE WHEN nullvalue(rconfiguracion.acidusuario) THEN rusuario.idusuario ELSE rconfiguracion.acidusuario END,rconfiguracion.cantidadperiodo
					   ,'Generado por SP alta_modifica_auditoria_medica_pendientes_automaticos',rconfiguracion.idfichamedica
					   ,rconfiguracion.idcentrofichamedica,rconfiguracion.idnomenclador,rconfiguracion.idcapitulo,rconfiguracion.idsubcapitulo
					   ,rconfiguracion.idpractica
					   );
		                            
					    elem.idcentrofichamedicaitem = centro();
		                            elem.idfichamedicaitem = currval('"public"."fichamedicaitem_idfichamedicaitem_seq"'::text::regclass);
					RAISE NOTICE ' Inserte un ITEM (%) - (%) ',elem.idcentrofichamedicaitem,elem.idfichamedicaitem;
					
					INSERT INTO fichamedicaemision(nrodoc,tipodoc,fmepfecha,idauditoriatipo,idfichamedicaitem
					,idcentrofichamedicaitem,fmepcantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,tipoprestacion,fmefechavto)
					VALUES(rconfiguracion.nrodoc,rconfiguracion.tipodoc,vfechaingresoconfiguracion,rconfiguracion.idauditoriatipo,elem.idfichamedicaitem
					,elem.idcentrofichamedicaitem,rconfiguracion.cantidadperiodo,rconfiguracion.idnomenclador
					,rconfiguracion.idcapitulo,rconfiguracion.idsubcapitulo,rconfiguracion.idpractica,7,vfechavtoconfiguracion);
		           
					SELECT INTO resultado * FROM cambiarestadofichamedica
		                       (elem.idfichamedicaitem::integer, elem.idcentrofichamedicaitem ,1,'DESDE EL SP alta_modifica_auditoria_medica_pendientes_automaticos'::varchar);	
			

					--Mapeo el pendiente de emision con el plan de cobertura
					INSERT INTO mapea_certdisc_alcancecobertura_fichamedicaitem(idcertdiscapacidad,idcentrocertificadodiscapacidad,idalcancecobertura,idcentroalcancecobertura,idfichamedicaitem,idcentrofichamedicaitem)
		                        VALUES (rconfiguracion.idcertdiscapacidad,rconfiguracion.idcentrocertificadodiscapacidad,rconfiguracion.idalcancecobertura,rconfiguracion.idcentroalcancecobertura,elem.idfichamedicaitem,elem.idcentrofichamedicaitem);
        	END IF;        
        ELSE 
                      UPDATE fichamedicaitem SET  
                           idprestador = rconfiguracion.idprestador
                          ,fmicantidad = rconfiguracion.cantidadperiodo
                          ,idnomenclador = rconfiguracion.idnomenclador
                          ,idcapitulo = rconfiguracion.idcapitulo
                          ,idsubcapitulo = rconfiguracion.idsubcapitulo
                          ,idpractica = rconfiguracion.idpractica
                       WHERE idfichamedicaitem = elem.idfichamedicaitem  
                          AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
               
                   /* Modifica la emision pendiente*/
                      UPDATE fichamedicaemision  SET
                        fmepcantidad = rconfiguracion.cantidadperiodo
                        ,idnomenclador = rconfiguracion.idnomenclador
                        ,idcapitulo = rconfiguracion.idcapitulo
                        ,idsubcapitulo = rconfiguracion.idsubcapitulo
                        ,idpractica = rconfiguracion.idpractica
                WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
 

                      -- Existe la configuración, por lo que verifico que el estado sea pendiente. 
                      IF elem.idfichamedicaemisionestadotipo <> 1 AND  elem.fmefechavto >= CURRENT_DATE THEN
                          SELECT INTO resultado * FROM cambiarestadofichamedica(elem.idfichamedicaitem::integer, elem.idcentrofichamedicaitem ,1,'DESDE EL SP alta_modifica_auditoria_medica_pendientes_automaticos Se vuelve a levantar'::varchar);	
                      END IF;
                END IF;

		SELECT INTO rverifica * FROM fichamedicaemision 
					WHERE idfichamedicaitem = elem.idfichamedicaitem 
						AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem
						AND fmefechavto < CURRENT_DATE;
                IF FOUND THEN 
		-- La configuracion ya esta vencida, por lo que no importa si se consumio hay que darla de baja
		SELECT INTO resultado * FROM cambiarestadofichamedica(elem.idfichamedicaitem::integer, elem.idcentrofichamedicaitem ,2,'DESDE EL SP alta_modifica_auditoria_medica_pendientes_automaticos'::varchar);	
		END IF;
		
		
		
	
	return resultado;
END;
$function$
