CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica_conemisiones()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  respuesta BOOLEAN;
  
  cursorficha CURSOR FOR SELECT * FROM  tempfichamedicainfo;
  elem RECORD;
  raux record;
  rverifica record;

  rborrar record;
  rpidfmim RECORD;
  rsolicituditem RECORD;
  rsolicitud RECORD;
  vidprestador BIGINT;
  
BEGIN

respuesta = true;

vidprestador =  7841; --MaLaPi por defecto va el prestador SELLO ILEGIBLE

open cursorficha;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP

 -- tabla temporal para poder acceder al id de la fichamedicainfomedicamento que se esta agregando/modificando
CREATE TEMP TABLE TEMP_IDFICHAMEDICAINFOMEDICAMENTO (idfichamedicainfomedicamento BIGINT);
INSERT INTO TEMP_IDFICHAMEDICAINFOMEDICAMENTO (idfichamedicainfomedicamento) VALUES (elem.idfichamedicainfomedicamento);
			  
 

select INTO rborrar * from fichamedicainfo WHERE idfichamedicatratamiento = elem.idfichamedicatratamiento 
                    AND idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento and
                idfichamedicainfo = elem.idfichamedicainfo  AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;

IF not nullvalue(elem.eliminar) AND elem.eliminar  THEN  
	elem.usuariologueado = sys_dar_usuarioactual();
       if (elem.usuariologueado=rborrar.fmiauditor OR sys_dar_usuarioactual() = 25) THEN 
                    -- Hay que eliminar el info
                  DELETE FROM fichamedicainfomedicamento
                       WHERE idfichamedicainfo = elem.idfichamedicainfo  AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo
                              and     idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento ;
                   DELETE FROM  fichamedicainfo
                              WHERE idfichamedicatratamiento = elem.idfichamedicatratamiento 
                               AND idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento and
                              idfichamedicainfo = elem.idfichamedicainfo  AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;
        end if;
ELSE 
      SELECT INTO raux *  FROM fichamedicatratamiento
                        WHERE  idfichamedicatratamientotipo= elem.idfichamedicatratamientotipo
                        AND idfichamedica=elem.idfichamedica
                        AND idcentrofichamedica = elem.idcentrofichamedica;
      IF NOT FOUND THEN
      INSERT INTO fichamedicatratamiento (idfichamedicatratamientotipo,idfichamedica,idcentrofichamedica,fmtfechainicio) VALUES(
                  elem.idfichamedicatratamientotipo,elem.idfichamedica,elem.idcentrofichamedica,CASE WHEN nullvalue(elem.fmtfechainicio) THEN now() ELSE elem.fmtfechainicio END);
		         elem.idfichamedicatratamiento = currval('public.fichamedicatratamiento_idfichamedicatratamiento_seq');
        		 elem.idcentrofichamedicatratamiento = centro();

      ELSE
          update fichamedicatratamiento
                        set fmtfechainicio= CASE WHEN nullvalue(elem.fmtfechainicio) THEN fmtfechainicio ELSE elem.fmtfechainicio END
                        where idfichamedicatratamiento = raux.idfichamedicatratamiento
                        and idcentrofichamedicatratamiento = raux.idcentrofichamedicatratamiento;
          elem.idfichamedicatratamiento = raux.idfichamedicatratamiento;
          elem.idcentrofichamedicatratamiento = raux.idcentrofichamedicatratamiento;
      end if;

	IF nullvalue(elem.idfichamedicainfo) THEN
       INSERT INTO fichamedicainfo (fmifecha,fmiauditor,fmidescripcion,idfichamedicatratamiento,idcentrofichamedicatratamiento,idfichamedicainfotipos) 
      VALUES(CASE WHEN nullvalue(elem.fmifecha) THEN now() ELSE elem.fmifecha END,elem.fmiauditor,elem.fmidescripcion,elem.idfichamedicatratamiento,elem.idcentrofichamedicatratamiento
      ,elem.idfichamedicainfotipos);
		elem.idfichamedicainfo = currval('fichamedicainfo_idfichamedicainfo_seq');
        elem.idcentrofichamedicainfo = centro();
	ELSE
               UPDATE fichamedicainfo
                   SET  fmifecha = CASE WHEN nullvalue(elem.fmifecha) THEN fmifecha ELSE elem.fmifecha END
                  ,fmiauditor = elem.fmiauditor
                  ,fmidescripcion = elem.fmidescripcion
                  ,idfichamedicatratamiento = elem.idfichamedicatratamiento
                  ,idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento
                  ,idfichamedicainfotipos = elem.idfichamedicainfotipos
              WHERE idfichamedicatratamiento = elem.idfichamedicatratamiento 
              AND idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento and
              idfichamedicainfo = elem.idfichamedicainfo  AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;
      END IF;
 

    IF not nullvalue(elem.infomedicamentos) AND (elem.infomedicamentos) THEN  -- Se requiere generar Seguimiento de Medicamentos
		 IF nullvalue(elem.idfichamedicainfomedicamento) THEN
				INSERT INTO fichamedicainfomedicamento(idplancoberturas,idarticulo,idcentroarticulo,idmonodroga,idfichamedicainfo,idcentrofichamedicainfo,fmimcobertura,fmimdosisdiaria,fmimmpresentacion,fmimfechafin)
				VALUES(elem.idplancoberturas,elem.idarticulo,elem.idcentroarticulo,elem.idmonodroga,elem.idfichamedicainfo,elem.idcentrofichamedicainfo,elem.fmimcobertura,elem.fmimdosisdiaria,elem.fmimmpresentacion,elem.fmimfechafin);
				elem.idfichamedicainfomedicamento = currval('fichamedicainfomedicamento_idfichamedicainfomedicamento_seq'::regclass);
				elem.idcentrofichamedicainfomedicamento = centro();
			 ELSE
			UPDATE fichamedicainfomedicamento 
			SET idplancoberturas = elem.idplancoberturas
			  ,idarticulo = elem.idarticulo
			  ,idcentroarticulo = elem.idcentroarticulo
			  ,idmonodroga = elem.idmonodroga
			  ,fmimfechafin = elem.fmimfechafin
			  ,idfichamedicainfo = elem.idfichamedicainfo
			  ,idcentrofichamedicainfo = elem.idcentrofichamedicainfo
			  ,fmimcobertura = elem.fmimcobertura
			  ,fmimdosisdiaria =  elem.fmimdosisdiaria
			 ,fmimmpresentacion = elem.fmimmpresentacion
			WHERE idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento
			AND idcentrofichamedicainfomedicamento = elem.idcentrofichamedicainfomedicamento;
		   END IF;
		   
	   --MaLaPi 18-04-2020 Si viene seteado los campos de solicitud de adutoria, quiere decir que se esta generando desde una solicitud por lo que ya dejamos adutiada
       --MaLaPi 21-09-2022 Si viene de una Solicitud de Auditoria, hay que verificar si esa solicitud se creo desde un formularo
       IF not nullvalue(elem.idsolicitudauditoriaitem) THEN  
			UPDATE solicitudauditoriaitem SET idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento
					  ,idcentrofichamedicainfomedicamento = elem.idcentrofichamedicainfomedicamento
			WHERE  idsolicitudauditoriaitem = elem.idsolicitudauditoriaitem 
				AND idcentrosolicitudauditoriaitem = elem.idcentrosolicitudauditoriaitem;
			SELECT INTO rsolicituditem * FROM solicitudauditoriaitem WHERE  idsolicitudauditoriaitem = elem.idsolicitudauditoriaitem 
				AND idcentrosolicitudauditoriaitem = elem.idcentrosolicitudauditoriaitem; 
			--Verifico si estan todos los items de la solcitud vinculados, cambio de estado la solicitud
		       SELECT INTO rsolicitud * FROM solicitudauditoria 
						NATURAL JOIN solicitudauditoriaitem
						WHERE idsolicitudauditoria = rsolicituditem.idsolicitudauditoria 
							AND idcentrosolicitudauditoria = rsolicituditem.idcentrosolicitudauditoria 
							AND nullvalue(idsolicitudauditoriaitem);
			IF NOT FOUND THEN 
				RAISE NOTICE 'Ingreso aca';
				UPDATE solicitudauditoriaestado SET saefechafin = now() WHERE idsolicitudauditoria = rsolicituditem.idsolicitudauditoria AND idcentrosolicitudauditoria = rsolicituditem.idcentrosolicitudauditoria AND nullvalue(saefechafin);
				INSERT INTO solicitudauditoriaestado(idsolicitudauditoria,idcentrosolicitudauditoria,saefechafin,saeidusuario,idsolicitudauditoriaestadotipo,saeobservacion,saetdescripcion) 
				VALUES(rsolicituditem.idsolicitudauditoria,rsolicituditem.idcentrosolicitudauditoria,null,sys_dar_usuarioactual(),2,elem.saeobservacion,elem.fmidescripcion);
			END IF;
			-- Intento encontrar el prestador para cargarlo en la generacion de pendientes si hace falta
			SELECT INTO rsolicitud * FROM solicitudauditoria NATURAL JOIN prestador 
									WHERE idsolicitudauditoria = rsolicituditem.idsolicitudauditoria 
									AND idcentrosolicitudauditoria = rsolicituditem.idcentrosolicitudauditoria;
			IF FOUND THEN 
				vidprestador = rsolicitud.idprestador;
			END IF;
			
		END IF;
		--AT 13-07-2023 Modifico para que guarde siempre sin importar si genenarpendientes=false
		
                --IF not nullvalue(elem.generarpendientes) AND elem.generarpendientes = 'true' THEN

                 IF not nullvalue(elem.periodo) THEN
                
			--MaLaPi 23-09-2022 Verifico si ya no se habia generado un pendiente
                         RAISE NOTICE 'Probando ingreso ===========================';
			  CREATE TEMP TABLE TEMP_ALTA_MODIFICA_ALCANCE_COBERTURA (  NRODOC VARCHAR,  TIPODOC INTEGER,  IDDISC INTEGER,  FECHAVTODISC DATE,  IDALCANCECOBERTURA INTEGER,  IDCENTROALCANCECOBERTURA INTEGER,  CANTIDAD INTEGER,  CANTIDADTOTAL INTEGER,  PORCENTAJE INTEGER,  IDNOMENCLADOR VARCHAR,  IDCAPITULO VARCHAR,  IDSUBCAPITULO VARCHAR,  FECHA_DESDE DATE, FECHA_HASTA DATE, IDPRACTICA VARCHAR,  IDCERTDISCAPACIDAD INTEGER,  SEAUDITA BOOLEAN,  SEREPITE BOOLEAN,  PRIORIDAD INTEGER,  PERIODO VARCHAR,  IDCENTROCERTIFICADODISCAPACIDAD INTEGER,  IDPRESTADOR BIGINT,  FMIFECHAAUDITORIA DATE,  IDUSUARIO INTEGER,  FMIPORREINTEGRO BOOLEAN,  FMIDESCRIPCION VARCHAR,  IDFICHAMEDICA INTEGER,  IDCENTROFICHAMEDICA INTEGER,  IDFICHAMEDICAITEM INTEGER,   IDCENTROFICHAMEDICAITEM INTEGER,   FMICANTIDAD    INTEGER, ACCION VARCHAR,ACOBSERVACIONEXPENDIO VARCHAR,ACOBSERVACIONAUDITORIA VARCHAR,IDPLANCOBERTURAS CHARACTER VARYING DEFAULT '**'::CHARACTER VARYING,IDMONODROGA INTEGER,IDARTICULO BIGINT,IDCENTROARTICULO INTEGER, acdiagnostico VARCHAR  ) ;

                          --AT 13-07-2023 Agrego control por si vienen en null para setear x defecto en 0 
                            
                          IF nullvalue(elem.cantidadxperiodo) THEN elem.cantidadxperiodo=0; END IF;
                          IF nullvalue(elem.cantidadtotal) THEN elem.cantidadtotal=0; END IF;

			  INSERT INTO temp_alta_modifica_alcance_cobertura (accion,nrodoc,tipodoc,fecha_desde,fecha_hasta,periodo
				,acobservacionauditoria,acobservacionexpendio,idarticulo,idcentroarticulo,idmonodroga,idprestador
				,prioridad,seaudita,serepite,cantidad,porcentaje,cantidadtotal,idplancoberturas
				,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idusuario,fmiporreintegro,acdiagnostico ) 
				VALUES('ConfiguraEmisiones',elem.nrodoc,elem.tipodoc,elem.fmimfechafin,elem.fmimfechafin,elem.periodo
					   ,elem.acobservacionauditoria,elem.acobservacionexpendio,elem.idarticulo,elem.idcentroarticulo,elem.idmonodroga,vidprestador
					   ,elem.prioridad,elem.seaudita,elem.serepite,elem.cantidadxperiodo,elem.fmimcobertura,elem.cantidadtotal,elem.acidplancoberturas
					   ,'98','01','01','05',sys_dar_usuarioactual(),'false','');
 
			
			SELECT INTO rverifica * FROM mapea_fichamedicainfomedicamento_alcancecobertura 
			                       WHERE idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento
									AND idcentrofichamedicainfomedicamento = elem.idcentrofichamedicainfomedicamento;
			IF FOUND THEN
			 	UPDATE temp_alta_modifica_alcance_cobertura SET idcentroalcancecobertura = rverifica.idcentroalcancecobertura,idalcancecobertura = rverifica.idalcancecobertura;
			END IF;
			
			PERFORM from modificaralcancecobertura_conemisiones(); --se llama desde Auditoria Medica para configurar practicas
			SELECT INTO rverifica * FROM mapea_fichamedicainfomedicamento_alcancecobertura 
			                       WHERE idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento
									AND idcentrofichamedicainfomedicamento = elem.idcentrofichamedicainfomedicamento;
			IF NOT FOUND THEN
				SELECT INTO rverifica * FROM temp_alta_modifica_alcance_cobertura;
				INSERT INTO mapea_fichamedicainfomedicamento_alcancecobertura(idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento,idcentroalcancecobertura,idalcancecobertura) 
				VALUES(elem.idfichamedicainfomedicamento,elem.idcentrofichamedicainfomedicamento,rverifica.idcentroalcancecobertura,rverifica.idalcancecobertura);
			END IF;
				
		END IF; 
		
		
	  END IF;  -- Se requiere generar Seguimiento de Medicamentos

END IF;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;

return respuesta;
END;
$function$
