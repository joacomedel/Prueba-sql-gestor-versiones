CREATE OR REPLACE FUNCTION public.modificaralcancecobertura_conemisiones()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

  respuesta BOOLEAN;
  elem RECORD;
  elemalcancecobertura RECORD;

  rverificafichamedica RECORD;
  rfiltros RECORD;
  pfiltros RECORD; 

  rconfiguracion RECORD;
  cconfiguracionespendientes refcursor;

BEGIN
   
  SELECT INTO elem * FROM temp_alta_modifica_alcance_cobertura ;
  IF nullvalue(elem.idcertdiscapacidad) THEN  --MaLaPi 22-09-2022 Si se llama sin un certificado hay que generar uno de uso interno
    SELECT INTO pfiltros sys_auditoriamedica_gestioncertificadosdiscusointerno(concat('{nrodoc=',elem.nrodoc,', tipodoc=',elem.tipodoc,'}')) as certificado; -- Para asegurarse que existe el certificado de discapacidad
    EXECUTE sys_dar_filtros(pfiltros.certificado) INTO rfiltros;
      UPDATE temp_alta_modifica_alcance_cobertura SET idcertdiscapacidad = rfiltros.idcertdiscapacidad,idcentrocertificadodiscapacidad = rfiltros.idcentrocertificadodiscapacidad;

  END IF;

--MaLaPi 22-09-2022 sigue el proceso normal

     SELECT INTO elem * FROM temp_alta_modifica_alcance_cobertura ;
                 /*la cobertura se modifica*/

      IF not nullvalue(elem.idalcancecobertura) THEN

                -- BelenA 09/09/24 si ya existe el alcancecobertura, le modifico el estado tipo a la ficha medica emision para 
                SELECT into elemalcancecobertura *
                FROM alcancecobertura
                WHERE idalcancecobertura=elem.idalcancecobertura AND idcentroalcancecobertura=elem.idcentroalcancecobertura;
                IF FOUND THEN
                  IF ( NOT(elemalcancecobertura.periodo=elem.periodo) OR  ( elem.porcentaje='0' AND elem.cantidad='0' AND elem.cantidadtotal='0') ) THEN
                   -- BelenA 09/09/24 :Si modifico el periodo 
                   -- O si pongo todos los datos en 0 es una "anulacion" y ya no le va a crear nuevas ficha emisiones, a diferencia de como hacia antes
                    OPEN cconfiguracionespendientes FOR 

                        SELECT *
                        FROM mapea_certdisc_alcancecobertura_fichamedicaitem
                        LEFT JOIN fichamedicaemisionestado USING (idfichamedicaitem, idcentrofichamedicaitem)
                        WHERE idalcancecobertura=elem.idalcancecobertura AND idcentroalcancecobertura=elem.idcentroalcancecobertura 
                        AND idcertdiscapacidad=elem.idcertdiscapacidad AND idcentrocertificadodiscapacidad=elem.idcentrocertificadodiscapacidad
                        ORDER BY idfichamedicaitem;

                    FETCH cconfiguracionespendientes into rconfiguracion; 
                          WHILE FOUND LOOP
                            IF (rconfiguracion.idfichamedicaemisionestadotipo=1) THEN
                              UPDATE fichamedicaemisionestado
                              SET fmeefechafin=NOW(), idfichamedicaemisionestadotipo=6, fmeedescripcion='Modificado desde SP modificaralcancecobertura_conemisiones'
                              WHERE idfichamedicaitem=rconfiguracion.idfichamedicaitem::integer AND idcentrofichamedicaitem=rconfiguracion.idcentrofichamedicaitem 
                              AND nullvalue(fmeefechafin) AND idfichamedicaemisionestadotipo=1;
                            END IF;
                    
                    FETCH cconfiguracionespendientes into rconfiguracion;
                    END LOOP;
                      
                    close cconfiguracionespendientes;

                  END IF;
                END IF;
                -- BelenA 09/09/24 agregue todo lo anterior

                          UPDATE alcancecobertura  SET  
                      				cantidadperiodo = elem.cantidad
                      				, cantidadtotal = elem.cantidadtotal
                              , porcentaje = elem.porcentaje
                              , idnomenclador = elem.idnomenclador
                              , idcapitulo = elem.idcapitulo
                      				, idsubcapitulo = elem.idsubcapitulo
                      				, fecha_desde = elem.fecha_desde
                      				, fecha_hasta = elem.fecha_hasta
                      				, idpractica = elem.idpractica
                      				, seaudita = elem.seaudita
                      				, serepite = elem.serepite
                      				, prioridad = elem.prioridad
                      				, periodo = elem.periodo
                      				, idprestador = elem.idprestador
                              ,acidusuario = sys_dar_usuarioactual()
                              ,idplancoberturas = elem.idplancoberturas
                              ,acobservacionexpendio = elem.acobservacionexpendio
                              ,acobservacionauditoria = elem.acobservacionauditoria
                              ,acdiagnostico = elem.acdiagnostico
                              ,idmonodroga = elem.idmonodroga
                              ,idarticulo = elem.idarticulo
                              ,idcentroarticulo = elem.idcentroarticulo
                              WHERE idalcancecobertura = elem.idalcancecobertura 
                              and idcentroalcancecobertura=elem.idcentroalcancecobertura;
		ELSE 
			INSERT INTO alcancecobertura(acidusuario,cantidadtotal,cantidadperiodo,porcentaje,idnomenclador,idcapitulo,idsubcapitulo,fecha_desde,fecha_hasta,idpractica,seaudita,serepite,prioridad,periodo,idprestador,acobservacionauditoria,acobservacionexpendio,acdiagnostico,idplancoberturas,idmonodroga,idarticulo,idcentroarticulo)
                          VALUES (sys_dar_usuarioactual(),elem.cantidadtotal,elem.cantidad,elem.porcentaje,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.fecha_desde,elem.fecha_hasta,elem.idpractica,elem.seaudita,elem.serepite,elem.prioridad,elem.periodo,elem.idprestador,elem.acobservacionauditoria,elem.acobservacionexpendio,elem.acdiagnostico,elem.idplancoberturas,elem.idmonodroga,elem.idarticulo,elem.idcentroarticulo);
                      
			elem.idalcancecobertura = currval('alcancecobertura_idalcancecobertura_seq');
			elem.idcentroalcancecobertura = centro();
                        --MaLaPi 23-09-2022 Lo inserto en la tabla temporal por si lo necesitan otros proceso.
                       UPDATE temp_alta_modifica_alcance_cobertura SET idalcancecobertura = elem.idalcancecobertura,idcentroalcancecobertura = elem.idcentroalcancecobertura;
		
		END IF;
                    
                SELECT INTO rverificafichamedica * FROM mapea_certdisc_alcancecobertura 
						   LEFT JOIN alcancecobertura USING(idalcancecobertura,idcentroalcancecobertura)
						   WHERE idcertdiscapacidad =elem.idcertdiscapacidad  
								AND idcentrocertificadodiscapacidad = elem.idcentrocertificadodiscapacidad
								AND idalcancecobertura = elem.idalcancecobertura 
								AND idcentroalcancecobertura =elem.idcentroalcancecobertura; 
		IF NOT FOUND THEN
			INSERT INTO mapea_certdisc_alcancecobertura(idcertdiscapacidad,idcentrocertificadodiscapacidad,idalcancecobertura,idcentroalcancecobertura)
                        VALUES (elem.idcertdiscapacidad,elem.idcentrocertificadodiscapacidad,elem.idalcancecobertura,elem.idcentroalcancecobertura);
		END IF;

        
    
		select into respuesta * FROM alta_modifica_auditoria_medica_pendientes_automaticos(elem.nrodoc,elem.tipodoc);
return respuesta;
END;
$function$
