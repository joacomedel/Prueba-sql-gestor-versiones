CREATE OR REPLACE FUNCTION public.auditoriaautomatica_vincular(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/*
SELECT * FROM auditoriaautomatica_desvincular('{fpvimporteingresado=383.0, anio=2019, nroregistro=153572
, pdescripcion=MALETTI PABLO JOSE, fpvcomentario=null, fpvmismoimporte=true, fpvquitado=true
, idprestador=517, accion=desvincularVerificaPrestador, fpvimportecalculado=383.0}') 
*/
  DECLARE

       ccursor refcursor;
       ccursororden refcursor;
      
        
        rfiltros RECORD;
        rusuario RECORD;
        elem RECORD;
	elemorden  RECORD;
        rprestador RECORD;
	rvalores RECORD;

	vimporte double precision;

  BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


OPEN ccursororden FOR SELECT idprestador,replace(pcuit,'-','') as pcuit,pcategoria,nroorden,centro,idasocconv,suap_colegio_medico.*
			FROM suap_colegio_medico
			LEFT JOIN ordenrecibo USING(idrecibo,centro)
			LEFT JOIN orden USING(nroorden,centro)
			LEFT JOIN ordvalorizada USING(nroorden,centro)
			LEFT JOIN prestador ON idprestador = nromatricula
                        WHERE idprestador = rfiltros.idprestador 
				AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio
                        ORDER BY idprestador
			--Limit 50
;
FETCH ccursororden INTO elemorden;
WHILE  found LOOP 
	
		IF nullvalue(elemorden.nroorden) THEN 
			--Error, la orden ya no existe en siges-Esto solo pasa con Ordenes de Consultas emitidas para MaLaPi o Karina pues las eliminamos
			SELECT INTO rprestador * FROM prestador 
						 LEFT JOIN practicavaloresxcategoria as pcv ON (nullvalue(pvxcfechafin) AND pcv.idasocconv = 89 AND pcv.idsubespecialidad = '12' 
							AND pcv.idcapitulo = '42' AND pcv.idsubcapitulo = '01' AND pcv.idpractica = '01' 
							AND pcv.pcategoria = prestador.pcategoria)
						WHERE elemorden.cuit_efector = replace(pcuit,'-','');
			IF FOUND THEN 
				
				INSERT INTO facturadebitoimputacionpendiente(nrocuentacgasto,idplancobertura,idnomenclador,idcapitulo,idsubcapitulo,idpractica
				,importedebito,nroregistro,anio,motivo,idmotivodebitofacturacion,fidtipo,idprestador) 
				VALUES ('50340','1','12','42','01','01',rprestador.importe,rfiltros.nroregistro,rfiltros.anio,'Esta Orden, se encuentra Anulada en la Institucion',13,8,rprestador.idprestador);
			END IF;

		END IF;

		IF nullvalue(elemorden.idprestador) OR (elemorden.pcuit <> elemorden.cuit_efector) THEN 
			--Error, el prestador no existe o se cambio 
		END IF;
		OPEN ccursor FOR SELECT * FROM obtenerdatosfichamedicaauditada(elemorden.nroorden,elemorden.centro,elemorden.idasocconv,elemorden.pcategoria,'A',null)
					   WHERE tipo <>14 AND  tipo <> 37			   
					;
		FETCH ccursor INTO elem;
		WHILE  found LOOP
		--Para cada Item de la Orden
		IF nullvalue(elem.idfichamedicapreauditada) THEN 
			vimporte = CASE WHEN nullvalue(elem.importexcategoria) THEN elem.importepv  ELSE elem.importexcategoria END;
			INSERT INTO fichamedicapreauditada_fisica(
				idnomenclador,idcapitulo,idsubcapitulo,idpractica,fmpacantidad,fmpaidusuario
				,iditem,centro,nroregistro,anio,nroorden,nrodoc,tipodoc,idprestador,idauditoriatipo,fechauso,importe,idplancobertura,
				fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,descripciondebito,importedebito,idmotivodebitofacturacion,tipo) 
			VALUES (elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elem.cantidad,rusuario.idusuario
				,elem.iditem,elem.centro,rfiltros.nroregistro,rfiltros.anio,elemorden.nroorden,elem.nrodoc,elem.tipodoc,elemorden.idprestador,6,elem.fechaemision,elem.importepv,elem.idplancovertura::integer
				,vimporte,'0',vimporte,NULL,'0',NULL,elem.tipo);
			PERFORM alta_modifica_preauditoria_odonto_v1(elemorden.nroorden,elemorden.centro);
		ELSE 
		RAISE NOTICE 'Ya existe!! (%) ',elem;

		END IF;
		
		fetch ccursor into elem;
		END LOOP;
		CLOSE ccursor;
		UPDATE suap_colegio_medico SET scmprocesado = now() WHERE idsuapcolegiomedico = elemorden.idsuapcolegiomedico;
fetch ccursororden into elemorden;
END LOOP;
CLOSE ccursororden;

UPDATE facturaprestadorverificar SET fpvdesvincular = false WHERE idprestador = rfiltros.idprestador  AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio;





   RETURN 'true';
  END;
$function$
