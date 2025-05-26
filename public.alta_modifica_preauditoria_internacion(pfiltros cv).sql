CREATE OR REPLACE FUNCTION public.alta_modifica_preauditoria_internacion(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
       citems refcursor;
       uno record;
       rfiltros RECORD;
	   rverifica RECORD;
	   rpersona RECORD;
	   vusuario INTEGER;
	
BEGIN 
     --vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    IF rfiltros.accion = 'temporal' THEN 
		CREATE TEMP TABLE temp_alta_modifica_preauditoria_internacion AS
		(
			SELECT item.*,pre.idprestador,pre.pdescripcion as prestador_desc
			,pci.*
			,tp.* 
			,nrodoc,tipodoc
			,piiidnomenclador as idnomenclador
			,piiidcapitulo as idcapitulo
			,piiidsubcapitulo as idsubcapitulo
			,piiidpractica as idpractica
			,concat(piiidnomenclador,'.',piiidcapitulo,'.',piiidsubcapitulo,'.',piiidpractica) as codigo
			,item.piidescripcion as desc_imputacion
			,item.piiimporteitem as importeimputacion
			,debito.idprecargainternacionitemdebito
			,debito.idcentroprecargainternacionitemdebito
			,debito.piiddescripcion
			,debito.piiddescripcion as motivo
			,debito.piidimportedebito
			,debito.piidimportedebito as importedebito
			,debito.piididmotivodebitofacturacion
			,debito.piididmotivodebitofacturacion  as idmotivodebitofacturacion
			,'' as accion
			FROM precarga_internacion_item as item
			NATURAL JOIN factura
			LEFT JOIN precarga_internacion_item_debito as debito USING(idprecargainternacionitem,idcentroprecargainternacionitem)
			LEFT JOIN ftipoprestacion as tp ON fidtipoprestacion = piifidtipoprestacion
			LEFT JOIN persona as pe ON piinrodoc = nrodoc AND piitipodoc = tipodoc
			LEFT JOIN prestador as pre ON piiidprestador = pre.idprestador 
			LEFT JOIN plancoberturainternacion as pci ON piiidplancobinternacion = idplancobertura 
			--WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio 
			LIMIT 0
		);
	END IF;
	
	IF rfiltros.accion = 'listar' THEN 
		CREATE TEMP TABLE temp_alta_modifica_preauditoria_internacion AS
		(
			SELECT item.*,pre.idprestador,pre.pdescripcion as prestador_desc
			,pci.*
			,tp.* 
			,nrodoc,tipodoc
			,piiidnomenclador as idnomenclador
			,piiidcapitulo as idcapitulo
			,piiidsubcapitulo as idsubcapitulo
			,piiidpractica as idpractica
			,concat(piiidnomenclador,'.',piiidcapitulo,'.',piiidsubcapitulo,'.',piiidpractica,'-',pr.pdescripcion) as codigo
			,item.piidescripcion as desc_imputacion
			,item.piiimporteitem as importeimputacion
			,'' as accion
			FROM precarga_internacion_item as item
			NATURAL JOIN factura
			--LEFT JOIN precarga_internacion_item_debito USING(idprecargainternacionitem,idcentroprecargainternacionitem)
			LEFT JOIN ftipoprestacion as tp ON fidtipoprestacion = piifidtipoprestacion
			LEFT JOIN persona as pe ON piinrodoc = nrodoc AND piitipodoc = tipodoc
			LEFT JOIN prestador as pre ON piiidprestador = pre.idprestador 
			LEFT JOIN plancoberturainternacion as pci ON piiidplancobinternacion = idplancobertura 
			LEFT JOIN practica as pr ON concat(piiidnomenclador,'.',piiidcapitulo,'.',piiidsubcapitulo,'.',piiidpractica)  = concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) 
			WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio 
			AND nullvalue(item.piiborrado)
			
		);
	END IF;
	
	IF rfiltros.accion = 'listar_agrupado' THEN 
		CREATE TEMP TABLE temp_alta_modifica_preauditoria_internacion AS
		(
			SELECT piiidprestador as idprestador,pdescripcion,fidtipoprestacion,ftipoprestaciondesc
			,sum(piiimporteitem) as totalprestacion,sum(importedebito) as debito
			,sum(piiimporteitem) - sum(CASE WHEN nullvalue(importedebito) THEN 0 ELSE importedebito END) as apagar
			,0 as sumiva
			,sum(piiimporteitem) as prestacioniva
			FROM precarga_internacion_item as item
			NATURAL JOIN factura
                        LEFT JOIN (SELECT idprecargainternacionitem,idcentroprecargainternacionitem,sum(piidimportedebito) as  importedebito
                                   FROM precarga_internacion_item_debito
                                   WHERE nullvalue(piidborrado)
                                   GROUP BY idprecargainternacionitem,idcentroprecargainternacionitem
                         ) as debito USING(idprecargainternacionitem,idcentroprecargainternacionitem)
			LEFT JOIN ftipoprestacion as tp ON fidtipoprestacion = piifidtipoprestacion
			LEFT JOIN persona as pe ON piinrodoc = nrodoc AND piitipodoc = tipodoc
			LEFT JOIN prestador as pre ON piiidprestador = pre.idprestador 
			LEFT JOIN plancoberturainternacion as pci ON piiidplancobinternacion = idplancobertura 
			WHERE nroregistro = 9815 AND anio = 2010
            GROUP BY piiidprestador,pdescripcion,fidtipoprestacion,ftipoprestaciondesc
		);
	END IF;
	
	IF rfiltros.accion = 'listar_debito' THEN 
		CREATE TEMP TABLE temp_alta_modifica_preauditoria_internacion AS
		(
			SELECT item.*,pre.idprestador,pre.pdescripcion as prestador_desc
			,pci.*
			,tp.*  
			,debito.idprecargainternacionitemdebito
			,debito.idcentroprecargainternacionitemdebito
			,debito.piiddescripcion
			,debito.piiddescripcion as motivo
			,debito.piidimportedebito
			,debito.piidimportedebito as importedebito
			,debito.piididmotivodebitofacturacion
			,debito.piididmotivodebitofacturacion  as idmotivodebitofacturacion
			,mdf.mdfdescripcion as mdfdescripcion
			FROM precarga_internacion_item as item
			NATURAL JOIN precarga_internacion_item_debito as debito
			NATURAL JOIN factura
			LEFT JOIN ftipoprestacion as tp ON fidtipoprestacion = piifidtipoprestacion
			LEFT JOIN motivodebitofacturacion as mdf ON idmotivodebitofacturacion = piididmotivodebitofacturacion
			LEFT JOIN persona as pe ON piinrodoc = nrodoc AND piitipodoc = tipodoc
			LEFT JOIN prestador as pre ON piiidprestador = pre.idprestador 
			LEFT JOIN plancoberturainternacion as pci ON piiidplancobinternacion = idplancobertura 
			WHERE (idprecargainternacionitem = rfiltros.idprecargainternacionitem 
				AND idcentroprecargainternacionitem = rfiltros.idcentroprecargainternacionitem )
			    AND nullvalue(debito.piidborrado)
			LIMIT 100
		);
	END IF;
   
    IF rfiltros.accion = 'abm' THEN 
	 	OPEN citems FOR SELECT  * 
						FROM temp_alta_modifica_preauditoria_internacion;
	   FETCH citems INTO uno ;
	   -- RAISE NOTICE 'Adentro del cursor (%) ',uno.accion;
	     SELECT INTO rpersona * FROM persona WHERE nrodoc = uno.nrodoc;
	     SELECT INTO rverifica * FROM factura where nroregistro = uno.nroregistro AND anio = uno.anio;
		WHILE  found LOOP 
		 -- RAISE NOTICE 'La Accion (%) ',uno.accion;
		 IF uno.accion = 'agregar' THEN
		 		INSERT INTO precarga_internacion_item (nroregistro,anio,piinrodoc, piitipodoc, piiidnomenclador, piiidcapitulo, piiidsubcapitulo, piiidpractica
				,piifidtipoprestacion, piiidplancobinternacion, piiidprestador, piidescripcion, piiimporteitem)
				VALUES(uno.nroregistro,uno.anio,rpersona.nrodoc,rpersona.tipodoc,uno.idnomenclador,uno.idcapitulo,uno.idsubcapitulo,uno.idpractica,
					  uno.fidtipoprestacion,uno.idplancobertura,uno.idprestador,uno.desc_imputacion,uno.importeimputacion);
		 END IF;
		 IF uno.accion = 'modificar' THEN
		 		UPDATE precarga_internacion_item SET  
				piinrodoc = rpersona.nrodoc, piitipodoc = rpersona.tipodoc, piiidnomenclador = uno.idnomenclador, piiidcapitulo = uno.idcapitulo
				, piiidsubcapitulo = uno.idsubcapitulo
				, piiidpractica = uno.idpractica
				, piifidtipoprestacion = uno.fidtipoprestacion, piiidplancobinternacion = uno.idplancobertura, piiidprestador = uno.idprestador
				, piidescripcion = uno.desc_imputacion, piiimporteitem = uno.importeimputacion
				,nroregistro = uno.nroregistro, anio = uno.anio
				WHERE idprecargainternacionitem = uno.idprecargainternacionitem AND idcentroprecargainternacionitem = uno.idcentroprecargainternacionitem;

		 END IF;
		
		IF uno.accion = 'eliminar' THEN
		 	UPDATE precarga_internacion_item SET piiborrado = now() 
					WHERE idprecargainternacionitem = uno.idprecargainternacionitem AND idcentroprecargainternacionitem = uno.idcentroprecargainternacionitem;
		 END IF;
		 
		 IF uno.accion = 'agregar_debito' THEN
		 	INSERT INTO precarga_internacion_item_debito (idprecargainternacionitem, idcentroprecargainternacionitem, piiddescripcion, piidimportedebito, piididmotivodebitofacturacion) 
			VALUES(uno.idprecargainternacionitem,uno.idcentroprecargainternacionitem,uno.motivo,uno.importedebito,uno.idmotivodebitofacturacion);
		 END IF;
		 IF uno.accion = 'modificar_debito' THEN
		 UPDATE precarga_internacion_item_debito SET piiddescripcion = uno.motivo, piidimportedebito = uno.importedebito
		 , piididmotivodebitofacturacion = uno.idmotivodebitofacturacion
					WHERE idprecargainternacionitemdebito = uno.idprecargainternacionitemdebito AND idcentroprecargainternacionitemdebito = uno.idcentroprecargainternacionitemdebito;
		 END IF;
		 
		
		IF uno.accion = 'eliminar_debito' THEN
			--RAISE NOTICE 'Voy a eliminar (%) ',concat(uno.idprecargainternacionitemdebito,'-',uno.idcentroprecargainternacionitemdebito);
		 	UPDATE precarga_internacion_item_debito SET piidborrado = now() 
					WHERE idprecargainternacionitemdebito = uno.idprecargainternacionitemdebito AND idcentroprecargainternacionitemdebito = uno.idcentroprecargainternacionitemdebito;
		 END IF;
		  
		fetch citems into uno; 
		END LOOP;
		CLOSE citems;
		
		--Cargo toda la info en la temporal por si se necesita
		DROP TABLE temp_alta_modifica_preauditoria_internacion;
		
		
		
	END IF;
			   
     return 'Listo';
END;
$function$
