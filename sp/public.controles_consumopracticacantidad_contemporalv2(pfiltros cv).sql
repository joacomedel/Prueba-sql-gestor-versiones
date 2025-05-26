CREATE OR REPLACE FUNCTION public.controles_consumopracticacantidad_contemporalv2(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	pidsubcapitulo varchar;
	pidpractica varchar;
        pidsubespecialidad varchar;
        pidcapitulo varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF not nullvalue(rfiltros.idsubespecialidad) AND LENGTH(rfiltros.idsubespecialidad) < 2 THEN 
pidsubespecialidad = lpad(rfiltros.idsubespecialidad,2,'0');
ELSE 
	pidsubespecialidad = rfiltros.idsubespecialidad;
END IF;

IF not nullvalue(rfiltros.idcapitulo) AND LENGTH(rfiltros.idcapitulo) < 2 THEN 
pidcapitulo = lpad(rfiltros.idcapitulo,2,'0');
ELSE 
	pidcapitulo = rfiltros.idcapitulo;
END IF;

IF not nullvalue(rfiltros.idsubcapitulo) AND LENGTH(rfiltros.idsubcapitulo) < 2 THEN 
	--RAISE NOTICE 
	pidsubcapitulo = lpad(rfiltros.idsubcapitulo,2,'0');
ELSE 
	pidsubcapitulo = rfiltros.idsubcapitulo;
END IF;
--MaLaPi 30-10-2018 Las practicas pueden tener entre 2 y 4 caracteres. 
IF not nullvalue(rfiltros.idpractica) AND LENGTH(rfiltros.idpractica) < 2 THEN 
	--RAISE NOTICE 
	pidpractica = lpad(rfiltros.idpractica,2,'0');
ELSE 
	IF LENGTH(rfiltros.idpractica) > 2 AND LENGTH(rfiltros.idpractica) < 4 THEN 
		pidpractica = lpad(rfiltros.idpractica,4,'0');
	ELSE 
		pidpractica = rfiltros.idpractica;
	END IF;
END IF;

/*RAISE NOTICE ' idsubespecialidad     % ',pidsubespecialidad ;

RAISE NOTICE ' idcapitulo     % ',pidcapitulo ;

RAISE NOTICE ' idsubcapitulo     % ',pidsubcapitulo ;

RAISE NOTICE '     pidpractica % ', pidpractica;

*/
 IF iftableexists('temp_controles_consumopracticacantidad_contemporalv2') THEN
     DROP  TABLE temp_controles_consumopracticacantidad_contemporalv2;
 END IF;

CREATE TEMP TABLE temp_controles_consumopracticacantidad_contemporalv2
AS (
	SELECT DISTINCT extract(YEAR FROM age(t.fechaemision, persona.fechanac)) as edad ,persona.sexo,persona.nombres,persona.apellido,persona.nrodoc,t.idsubespecialidad,t.idcapitulo,t.idsubcapitulo,t.idpractica,ctdescripcion,pdescripcion,descripcion,nrocuentac,desccuenta,cregional,pp.acdecripcion,idprestador, elprestador, t.idasocconv,importeemision,cantidad, t.laorden,
CASE WHEN not nullvalue(bs.nrodoc) THEN  concat('DNI:',ts.nrodoc,'/',ts.barra)
                                                     WHEN not nullvalue(br.nrodoc) THEN  concat('DNI:',tr.nrodoc,'/',tr.barra) 
                                                     ELSE  concat('DNI:',persona.nrodoc,'/',persona.barra)   END as titular,fechaemision,
extract(YEAR FROM fechaemision) as año, extract(MONTH FROM fechaemision) as mes,extract(DAY FROM fechaemision) as dia ,fechauso, login

	  ,'1-Edad#edad@2-Sexo#sexo@3-Nombres#nombres@4-Apellido#apellido@5-Nrodoc#nrodoc@6-Nomenclador#idsubespecialidad@7-Capitulo#idcapitulo@8-SubCapitulo#idsubcapitulo@9-Practica#idpractica@10-Tipo Orden#ctdescripcion@11-Nombre#pdescripcion@12-Plan Cobertura#descripcion@13-Centro Regional#cregional@14-Asoc.#acdecripcion@15-ID_Prestador#idprestador@16-Prestador#elprestador@17-Cantidad#cantidad@18-Importe Emision#importeemision@19-Nro.Orden#laorden@20-FechaEmision#fechaemision@21-Emitido Por#login@22-Fecha de Uso#fechauso@23-Año#año@24-Mes#mes@25-Dia#dia@26-Titular#titular'::text as mapeocampocolumna 
	     FROM
		(SELECT idprestador, elprestador,  nrodoc,0.01 as importeemision,'12' as idsubespecialidad, '42' AS idcapitulo,'01' AS idsubcapitulo, '01' AS idpractica, ctdescripcion,   'CONSULTA MEDICA(B)' as pdescripcion,   '' as descripcion,'' as nrocuentac,'Ordenes Médicas' as desccuenta,'' as idplancobertura,orden.idasocconv,concat( to_char(centroregional.idcentroregional,'99'),' - ' , centroregional.crdescripcion)  As CRegional, count(ordconsulta.nroorden) as cantidad,max(fechaemision) as fechaemision, fechauso, text_concatenar(concat(orden.nroorden,'-',orden.centro)) as laorden, login
		FROM orden 
                LEFT JOIN (SELECT idprestador,pdescripcion as elprestador, nroorden,centro ,tipo,fechauso FROM ordenesutilizadas JOIN prestador USING (idprestador) )as p USING ( nroorden,centro ,tipo) 
		natural join ordenrecibo
        left join recibousuario using(idrecibo, centro) 
        left join (select idusuario, login from usuario) as usuario  USING(idusuario)
		NATURAL JOIN consumo  
		NATURAL JOIN ordconsulta 
		JOIN comprobantestipos ON comprobantestipos.idcomprobantetipos = orden.tipo 
		JOIN centroregional ON centroregional.idcentroregional = orden.centro
		LEFT JOIN ordenestados     ON(ordconsulta.nroorden = ordenestados.nroorden AND ordconsulta.centro=ordenestados.centro)    
		WHERE orden.fechaemision >= to_date(rfiltros.fechadesde,'yyyy-MM-dd')     
			AND orden.fechaemision <= to_date(rfiltros.fechahasta,'yyyy-MM-dd') 
			AND nullvalue(ordenestados.nroorden)  
			AND nullvalue(ordenestados.centro) 
                        --- VAS
                        AND (nullvalue(rfiltros.nrodoc) OR consumo.nrodoc = rfiltros.nrodoc )
                        --- VAS

		GROUP BY idprestador, elprestador,  nrodoc,orden.idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,ctdescripcion,pdescripcion,descripcion
		,nrocuentac,desccuenta,idcentroregional,idplancobertura,crdescripcion, p.fechauso, usuario.login    
		UNION    
		SELECT idprestador, elprestador,  nrodoc,sum(importe) as importeemision,item.idnomenclador as idsubespecialidad, item.idcapitulo, item.idsubcapitulo, item.idpractica,ctdescripcion, practica.pdescripcion,plancobertura.descripcion, practica.nrocuentac,cuentascontables.desccuenta,itemvalorizada.idplancovertura AS  idplancobertura,orden.idasocconv,    (concat(to_char(centroregional.idcentroregional,'99') ,' - ' ,centroregional.crdescripcion) ) As CRegional, sum(item.cantidad) as cantidad,max(fechaemision) as fechaemision, fechauso, text_concatenar(concat(orden.nroorden,'-',orden.centro)) as laorden, login
		FROM orden 
                LEFT JOIN (SELECT idprestador,pdescripcion as elprestador, nroorden,centro ,tipo,fechauso FROM ordenesutilizadas JOIN prestador USING (idprestador) )as p USING ( nroorden,centro ,tipo)
		natural join ordenrecibo
        left join recibousuario using(idrecibo, centro)
        left join (select idusuario, login from usuario) as usuario  USING(idusuario)
		NATURAL JOIN consumo 
		NATURAL JOIN ordvalorizada 
		NATURAL JOIN itemvalorizada 
		NATURAL JOIN item 
		NATURAL JOIN practica 
		JOIN plancobertura    ON (itemvalorizada.idplancovertura=plancobertura.idplancobertura)  
		NATURAL JOIN  cuentascontables 
		JOIN comprobantestipos ON comprobantestipos.idcomprobantetipos = orden.tipo 
		JOIN centroregional ON (centroregional.idcentroregional = orden.centro)    
		LEFT JOIN ordenestados ON(ordvalorizada.nroorden = ordenestados.nroorden AND ordvalorizada.centro=ordenestados.centro)    
		WHERE orden.fechaemision >= to_date(rfiltros.fechadesde,'yyyy-MM-dd')     
			AND orden.fechaemision <= to_date(rfiltros.fechahasta,'yyyy-MM-dd') 
			AND nullvalue(ordenestados.nroorden)      AND nullvalue(ordenestados.centro)  
                         --- VAS
                        AND (nullvalue(rfiltros.nrodoc) OR consumo.nrodoc = rfiltros.nrodoc )
                        --- VAS 
		GROUP BY idprestador, elprestador,  nrodoc,orden.idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,ctdescripcion,pdescripcion,descripcion,nrocuentac,desccuenta,    
			idcentroregional,crdescripcion,itemvalorizada.idplancovertura, p.fechauso, usuario.login 
	) as t    
	NATURAL JOIN persona

           LEFT JOIN benefsosunc bs ON (bs.nrodoc = persona.nrodoc)  -- analizo si es un beneficiario y busco al titular
                                        LEFT JOIN persona  ts ON (ts.nrodoc = bs.nrodoctitu) --- titular del benef sosunc

                                        LEFT JOIN benefreci br ON (br.nrodoc = persona.nrodoc)   -- analizo si es un beneficiario y busco al titular
                                        LEFT JOIN persona  tr ON (tr.nrodoc = br.nrodoctitu) --- titular del benef sosunc      
        JOIN (SELECT DISTINCT asocconvenio.idasocconv,asocconvenio.acdecripcion FROM asocconvenio) as pp ON(t.idasocconv=pp.idasocconv)  
    /* Se comenta porque duplica filas y no trae los valores correctos -- PA 2025-05-08
   LEFT  JOIN practicavalores pv ON(t.idasocconv=pv.idasocconv 
                                         AND t.idsubespecialidad=pv.idsubespecialidad
                                         AND t.idcapitulo=pv.idcapitulo
                                         AND t.idsubcapitulo=pv.idsubcapitulo AND t.idpractica=pv.idpractica)  
   
  */
	WHERE   (t.idsubespecialidad = pidsubespecialidad OR nullvalue(pidsubespecialidad)) 
		AND (t.idcapitulo = pidcapitulo OR nullvalue(pidcapitulo))   
		AND (t.idsubcapitulo = pidsubcapitulo OR nullvalue(pidsubcapitulo))   
		AND (t.idpractica = pidpractica OR nullvalue(pidpractica)) 
		AND (nullvalue(rfiltros.idplancobertura ) OR idplancobertura = rfiltros.idplancobertura ) 
	    --- VAS 280325 AND (nullvalue(rfiltros.nrodoc) OR persona.nrodoc = rfiltros.nrodoc )
	

);
    IF iftableexists_fisica('temp_consumo_practicas_290824') THEN
           INSERT INTO temp_consumo_practicas_290824 (edad,	sexo,	nombres,	apellido,	nrodoc,	idsubespecialidad,	idcapitulo,	idsubcapitulo,	idpractica, ctdescripcion,	pdescripcion,	descripcion,	nrocuentac,	desccuenta,	cregional,	acdecripcion,	idprestador	,elprestador,	idasocconv,	importeemision,	cantidad,	laorden,	titular,	fechaemision, fechauso, login)(
                 SELECT edad,	sexo,	nombres,	apellido,	nrodoc,	idsubespecialidad,	idcapitulo,	idsubcapitulo,	idpractica, ctdescripcion,	pdescripcion,	descripcion,	nrocuentac,	desccuenta,	cregional,	acdecripcion,	idprestador	,elprestador,	idasocconv,	importeemision,	cantidad,	laorden,	titular,	fechaemision, fechauso, login
               FROM temp_controles_consumopracticacantidad_contemporalv2 
           );

      ELSE
           CREATE TABLE temp_consumo_practicas_290824
           AS (
               SELECT edad,	sexo,	nombres,	apellido,	nrodoc,	idsubespecialidad,	idcapitulo,	idsubcapitulo,	idpractica,	ctdescripcion, pdescripcion,	descripcion,	nrocuentac,	desccuenta,	cregional,	acdecripcion,	idprestador	,elprestador,	idasocconv,	importeemision,	cantidad,	laorden,	titular,	fechaemision,fechauso,login
               FROM temp_controles_consumopracticacantidad_contemporalv2       );
      END IF;
 

return true;
END;$function$
