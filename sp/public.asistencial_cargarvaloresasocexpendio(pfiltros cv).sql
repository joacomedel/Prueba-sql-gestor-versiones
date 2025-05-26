CREATE OR REPLACE FUNCTION public.asistencial_cargarvaloresasocexpendio(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
 

--VARIABLES
  vquery VARCHAR; 
  respuesta varchar;
  vcolumnas varchar;
  vwhere varchar;
  vreferencias varchar;
  vreferencias2 varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF iftableexists_fisica('comparacion_valores_practica') THEN
     
   DROP TABLE comparacion_valores_practica;

END IF;

vcolumnas = 'idcvpprimary BIGSERIAL PRIMARY KEY,
             idnomenclador VARCHAR,
             idcapitulo VARCHAR,
	     idsubcapitulo VARCHAR,
	     idpractica VARCHAR,
	     pdescripcion VARCHAR,
	     soniguales VARCHAR,
	     valorexpendio float,
             valorcoseguro float,
             fechainivigencia date,
             asocinvolucradas VARCHAR,
	     cvpfechaingreso timestamp default now(),
             coseguroanterior float,
             fechainivigenciaanterior date,
             fechafinvigenciaanterior date,
             fechamodificacion timestamp
	    ';
vreferencias = 'Referencias';
vreferencias2 = 'Referencias';
 
 


OPEN cursorarchi FOR select idasocconv, count(*) as cantidad,acdecripcion,replace(LOWER(replace(replace(replace(replace(replace(replace(acdecripcion,',',''),'.',''),')',''),'(',''),'-',''),' ','_')),'__','_') as columna 
		     from practicavalores 
                     JOIN asocconvenio USING(idasocconv)
                     where nullvalue(pvfechafinvigencia) and not internacion AND acseusaencoseguro AND  	(acfechafin >= current_Date OR nullvalue(acfechafin))
                          --and idasocconv IN (89,92,104,122,128) 
                     group by idasocconv,acdecripcion;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP

             vcolumnas = concat(vcolumnas, ', col_',relem.idasocconv,' FLOAT ',', cos_',relem.idasocconv,' varchar ');
             vwhere = concat(vwhere,' AND nullvalue(col_',relem.idasocconv,') ');
             vreferencias2 =  concat(vreferencias2,'*',relem.idasocconv,'-',relem.acdecripcion);
             vreferencias =  concat(vreferencias,' \n ', ' * col_',relem.idasocconv,' es la columna de  ',relem.acdecripcion);

	     FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;
   vquery = concat('create table comparacion_valores_practica ( ', vcolumnas,');');
   EXECUTE vquery;

RAISE NOTICE 'Conuslta (%)',vquery;

INSERT INTO comparacion_valores_practica(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion) (
SELECT nomen.idnomenclador       
      ,nomen.idcapitulo       
      ,nomen.idsubcapitulo       
      ,nomen.idpractica       
      ,replace(practica.pdescripcion,',','') as pdescripcion      
 FROM       (SELECT nomencladoruno.idnomenclador       ,nomencladoruno.idcapitulo       ,nomencladoruno.idsubcapitulo       ,nomencladoruno.idpractica       ,nomencladoruno.pmcantidad1 as cantidad1       ,nomencladoruno.pmcantidad2 as cantidad2       ,nomencladoruno.pmcantidad3 as cantidad3       ,nomencladoruno.pmcantgastos as cantigasto       ,nomencladoruno.pmhonorario1 as honorario1       ,nomencladoruno.pmhonorario2 as honorario2      ,nomencladoruno.pmhonorario3 as honorario3       ,nomencladoruno.pmgastos     as gastos       FROM nomencladoruno       
UNION       SELECT nomencladordos.idnomenclador       ,nomencladordos.idcapitulo       ,nomencladordos.idsubcapitulo       ,nomencladordos.idpractica       ,nomencladordos.pmcantidad1 as cantidad1       ,0                          as cantidad2       ,0                          as cantidad3       ,nomencladordos.pmcantgastos as cantigasto       ,nomencladordos.pmhonorario1 as honorario1       ,0                            as honorario2       ,0                             as honorario3       ,nomencladordos.pmgastos     as gastos       FROM nomencladordos ) as nomen       
NATURAL JOIN	practica
WHERE activo 
--AND idnomenclador = '07' 
--ORDER BY  practica.idnomenclador,practica.idcapitulo,practica.idsubcapitulo,practica.idpractica
--MaLaPi 23-06-2021 volves a descomentar estas lineas
UNION 
SELECT '' as idnomenclador,'' as idcapitulo,'' as idsubcapitulo,'' as idpractica,vreferencias as pdescripcion
);



OPEN cursorarchi FOR select idasocconv, count(*) as cantidad, acdecripcion as columna 
		     from practicavalores 
                     JOIN asocconvenio USING(idasocconv)
                     where nullvalue(pvfechafinvigencia) and not internacion AND acseusaencoseguro AND  	(acfechafin >= current_Date OR nullvalue(acfechafin))
                         --and idasocconv IN (89,92,104,122,128) 
                     group by idasocconv,acdecripcion;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP

	   	
              
             vquery = concat('UPDATE  comparacion_valores_practica SET cos_',relem.idasocconv,' = pv.pvfechainivigencia >= current_date - 365::integer,col_',relem.idasocconv,' = pv.importe 
             FROM practicavalores as pv 
             WHERE pv.idasocconv = ',relem.idasocconv,'  
		AND nullvalue(pv.pvfechafinvigencia) and not pv.internacion
		AND pv.idsubespecialidad = comparacion_valores_practica.idnomenclador
		AND pv.idcapitulo = comparacion_valores_practica.idcapitulo
		AND pv.idsubcapitulo = comparacion_valores_practica.idsubcapitulo
		AND pv.idpractica = comparacion_valores_practica.idpractica
               
');
		EXECUTE vquery;
	     FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;


	vquery = concat('DELETE FROM comparacion_valores_practica WHERE pdescripcion not ilike ''Referencias %''  ',vwhere);
	EXECUTE vquery;
	RAISE NOTICE 'Conuslta (%)',vquery;
--Agrego el valor de actual de coseguro

   UPDATE comparacion_valores_practica SET valorcoseguro = pv.importe, fechainivigencia = pv.pvfechainivigencia
   FROM practicavalores as pv 
     WHERE pv.idasocconv = 154  
		AND nullvalue(pv.pvfechafinvigencia) and not pv.internacion
		AND pv.idsubespecialidad = comparacion_valores_practica.idnomenclador
		AND pv.idcapitulo = comparacion_valores_practica.idcapitulo
		AND pv.idsubcapitulo = comparacion_valores_practica.idsubcapitulo
		AND pv.idpractica = comparacion_valores_practica.idpractica;

--Agrego el valor de anterior para coseguro
            
   UPDATE comparacion_valores_practica SET coseguroanterior = pv.importe,fechamodificacion = pv.fechaultimamodif
,fechainivigenciaanterior  = pv.pvmfechafinvigencia
,fechafinvigenciaanterior = pv.pvmfechafinvigencia
   FROM (
SELECT idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,fechamodif as fechaultimamodif,importe,pvmfechainivigencia,pvmfechafinvigencia
FROM practicavaloresmodificados 
WHERE (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,fechamodif) IN (
select idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,max(fechamodif) as fechaultimamodif
		     from practicavaloresmodificados 
                     where  not internacion AND idasocconv = 154
                     group by idsubespecialidad,idcapitulo,idsubcapitulo,idpractica
)
) as pv 
     WHERE pv.idsubespecialidad = comparacion_valores_practica.idnomenclador
		AND pv.idcapitulo = comparacion_valores_practica.idcapitulo
		AND pv.idsubcapitulo = comparacion_valores_practica.idsubcapitulo
		AND pv.idpractica = comparacion_valores_practica.idpractica;




UPDATE comparacion_valores_practica SET asocinvolucradas = pv.asoc_involucradas
FROM (
SELECT idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,pdescripcion,round(avg(importe)::numeric,2) as valorexpendio
,max(pvfechainivigencia) as fechainivigencia,text_concatenar( concat('-',idasocconv)) as asoc_involucradas
FROM practicavalores 
NATURAL JOIN 
	(SELECT nomencladoruno.idnomenclador as idsubespecialidad      ,nomencladoruno.idcapitulo       ,nomencladoruno.idsubcapitulo       ,nomencladoruno.idpractica,replace(practica.pdescripcion,',','') as pdescripcion           FROM nomencladoruno    
		NATURAL JOIN	practica
		WHERE activo     
		UNION      
	 SELECT nomencladordos.idnomenclador as idsubespecialidad      ,nomencladordos.idcapitulo       ,nomencladordos.idsubcapitulo       ,nomencladordos.idpractica ,replace(practica.pdescripcion,',','') as pdescripcion          FROM nomencladordos      
	NATURAL JOIN	practica
	WHERE activo  
	) as nomen
JOIN asocconvenio USING(idasocconv)
	 where nullvalue(pvfechafinvigencia) 
		and not internacion AND acseusaencoseguro
			AND (acfechafin >= current_Date OR nullvalue(acfechafin))
			AND pvfechainivigencia >= current_date - 365::integer -- Solo tomo los valores del ultimo año
                        AND importe > 0.01 --Saco las practicas que se expenden por presupuesto
                        --AND idasocconv <> 128 --Eliminar... es temporal
group by idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,pdescripcion
) as pv
 WHERE pv.idsubespecialidad = comparacion_valores_practica.idnomenclador
		AND pv.idcapitulo = comparacion_valores_practica.idcapitulo
		AND pv.idsubcapitulo = comparacion_valores_practica.idsubcapitulo
		AND pv.idpractica = comparacion_valores_practica.idpractica;

--Comparo los valores, puedo o no calcular el valor promedio 
--PERFORM asistencial_cargarvaloresasocexpendio_comparar(pfiltros);
--select * from comparacion_valores_practica

respuesta = 'oki';


return respuesta;
END;
$function$
