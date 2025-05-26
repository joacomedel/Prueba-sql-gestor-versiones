CREATE OR REPLACE FUNCTION public.auditoriaautomatica_generardebitosparacoseguros(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
SELECT * FROM auditoriaautomatica_generardebitosparacoseguros('{fpvimporteingresado=383.0, anio=2019, nroregistro=153572
, pdescripcion=MALETTI PABLO JOSE, fpvcomentario=null, fpvmismoimporte=true, fpvquitado=true
, idprestador=517, accion=desvincularVerificaPrestador, fpvimportecalculado=383.0}') 
*/
  DECLARE

       ccursor refcursor;
       ccursororden refcursor;
      
        
        rfiltros RECORD;
        rusuario RECORD;
        elem RECORD;
        rinfo RECORD;
	elemorden  RECORD;
        rprestador RECORD;
	rvalores RECORD;

	vimporte double precision;
        vimportedebito double precision;
        vmotivodebito varchar;

  BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


OPEN ccursororden FOR SELECT idprestador,replace(pcuit,'-','') as pcuit,pcategoria,idrecibo,nroorden,centro,idasocconv,sum(importe) as importedeibo
			FROM suap_colegio_medico
			JOIN ordenrecibo USING(idrecibo,centro)
			JOIN importesrecibo USING(idrecibo,centro)
			JOIN orden USING(nroorden,centro)
			JOIN ordvalorizada USING(nroorden,centro)
			JOIN prestador ON idprestador = nromatricula
                        WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND idformapagotipos <> 6 AND idformapagotipos <> 1
                              AND scmdebitoconseguro = false AND nullvalue(scmfacturadaantes)
			GROUP BY idprestador,replace(pcuit,'-',''),pcategoria,idrecibo,nroorden,centro,idasocconv
                        ORDER BY idprestador
			--LIMIT 5
;
FETCH ccursororden INTO elemorden;
WHILE  found LOOP 
	
		--Verifico si exsite una practica en la que puedo hacer el debito completo, sino doy un error.
		SELECT INTO elem * FROM obtenerdatosfichamedicaauditada(elemorden.nroorden,elemorden.centro,elemorden.idasocconv,elemorden.pcategoria,'A',null)
					   WHERE tipo <>14 AND  tipo <> 37 AND fmpaiimportetotal >= elemorden.importedeibo;
		IF NOT FOUND THEN  --Se complico, el debito hay que repartirlo
			UPDATE suap_colegio_medico SET scmrepartirdebito = true WHERE idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
                ELSE  
			
                        IF not nullvalue(elem.idfichamedicapreauditada)  THEN 
			
				SELECT INTO rinfo  idfichamedicapreauditadaodonto ,idcentrofichamedicapreauditadaodonto ,idpiezadental ,idletradental ,idzonadental ,iditem ,centro ,fmpaifechaingreso ,fichamedicapreauditada.idfichamedicaitem
				,fichamedicapreauditada.idcentrofichamedicaitem ,fmpaporeintegro ,idfichamedicapreauditada ,idcentrofichamedicapreauditada 
				,idauditoriaodontologiacodigo ,idnomenclador ,idcapitulo ,idsubcapitulo ,idpractica ,fmpacantidad ,fmpaidusuario 
				,fmpafechaingreso ,idfichamedica ,idcentrofichamedica,fmpadescripcion,fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal
				,fmpaimportedebito,fmpadescripciondebito ,idmotivodebitofacturacion  
				FROM fichamedicapreauditadaitem 
				NATURAL JOIN fichamedicapreauditada  
				LEFT JOIN fichamedicapreauditadaodonto USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
				WHERE iditem = elem.iditem AND centro = elem.centro
				AND  idfichamedicapreauditada = elem.idfichamedicapreauditada;

				IF FOUND THEN 
				 IF  rinfo.fmpadescripciondebito not ilike '<<Falto restar Conseguro -Recibo:%' THEN  --Intento asegurarme no hacer 2 veces el debito del mismo coseguro
					vmotivodebito = concat('<<Falto restar Conseguro -Recibo:',elemorden.idrecibo,'-',elemorden.centro,' $',elemorden.importedeibo,'>> ',CASE WHEN nullvalue(rinfo.fmpadescripciondebito) THEN '' ELSE rinfo.fmpadescripciondebito END);
                                        vimportedebito = CASE WHEN nullvalue(rinfo.fmpaimportedebito) THEN 0 ELSE rinfo.fmpaimportedebito END + elemorden.importedeibo;
                                        vimporte = rinfo.fmpaiimportes - vimportedebito; 

					INSERT INTO fichamedicapreauditada_fisica(idfichamedicapreauditada,idcentrofichamedicapreauditada,idauditoriaodontologiacodigo,idnomenclador,idcapitulo,idsubcapitulo,idpractica,fmpacantidad,fmpaidusuario
					,fmpafechaingreso,iditem,centro,nroregistro,anio
					,nroorden,nrodoc,tipodoc,idprestador,idauditoriatipo,fechauso,importe,idplancobertura
					,fmpaifechaingreso,fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,descripciondebito,importedebito,idmotivodebitofacturacion,tipo) 
					VALUES (rinfo.idfichamedicapreauditada,rinfo.idcentrofichamedicapreauditada,rinfo.idauditoriaodontologiacodigo,rinfo.idnomenclador,rinfo.idcapitulo,rinfo.idsubcapitulo,rinfo.idpractica,rinfo.fmpacantidad,rinfo.fmpaidusuario
					,rinfo.fmpafechaingreso,rinfo.iditem,elem.centro,rfiltros.nroregistro,rfiltros.anio
					,elem.nroorden,elem.nrodoc,elem.tipodoc,elem.idprestador,1,elem.fechauso,elem.importeitem,elem.idplancovertura::integer
					,rinfo.fmpaifechaingreso,rinfo.fmpaiimportes,rinfo.fmpaiimporteiva,vimporte,vmotivodebito,vimportedebito,5,elem.tipo);

			                PERFORM alta_modifica_preauditoria_odonto_v1(elemorden.nroorden,elemorden.centro);

				END IF;	
                               END IF;
                            
                        END IF; 

			UPDATE suap_colegio_medico SET scmdebitoconseguro = true WHERE idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
			
                END IF;
		
		
		--UPDATE suap_colegio_medico SET scmprocesado = now() WHERE idsuapcolegiomedico = elemorden.idsuapcolegiomedico;
fetch ccursororden into elemorden;
END LOOP;
CLOSE ccursororden;

--UPDATE facturaprestadorverificar SET fpvdesvincular = false WHERE idprestador = rfiltros.idprestador  AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio;
   RETURN 'true';
  END;
$function$
