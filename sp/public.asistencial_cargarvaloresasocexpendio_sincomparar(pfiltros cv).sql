CREATE OR REPLACE FUNCTION public.asistencial_cargarvaloresasocexpendio_sincomparar(pfiltros character varying)
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
             fechainivigencia date,
             asocinvolucradas VARCHAR,
	     cvpfechaingreso timestamp default now()
	    ';
--vreferencias = 'Referencias';
--vreferencias2 = 'Referencias';

--Dejar en valorexpendio para expendio
 
vquery = concat('create table comparacion_valores_practica ( ', vcolumnas,');'); 
EXECUTE vquery;
RAISE NOTICE 'Conuslta (%)',vquery;

--Agrego el Promedio para las practicas que estan configuradas

INSERT INTO comparacion_valores_practica(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,valorexpendio,fechainivigencia,asocinvolucradas) (
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
);

--Agrego las configuraciones cuyo unico valor es 0.01 -es decir, solo se emiten por presupuesto
INSERT INTO comparacion_valores_practica(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,valorexpendio,fechainivigencia,asocinvolucradas) (

SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,nomen.pdescripcion,round(avg(importe)::numeric,2) as valorexpendio
,max(pvfechainivigencia) as fechainivigencia,text_concatenar( concat('-',idasocconv)) as asoc_involucrada
FROM (SELECT nomencladoruno.idnomenclador       ,nomencladoruno.idcapitulo       ,nomencladoruno.idsubcapitulo       ,nomencladoruno.idpractica,replace(practica.pdescripcion,',','') as pdescripcion           FROM nomencladoruno    
		NATURAL JOIN	practica
		WHERE activo     
		UNION      
	 SELECT nomencladordos.idnomenclador      ,nomencladordos.idcapitulo       ,nomencladordos.idsubcapitulo       ,nomencladordos.idpractica ,replace(practica.pdescripcion,',','') as pdescripcion          FROM nomencladordos      
	NATURAL JOIN	practica
	WHERE activo  
	) as nomen
NATURAL JOIN (SELECT idsubespecialidad as idnomenclador,idcapitulo,idsubcapitulo,idpractica,importe,pvfechainivigencia,idasocconv FROM  practicavalores ) as valores 
LEFT JOIN comparacion_valores_practica as cvp USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
WHERE nullvalue(cvp.idcvpprimary)

AND importe = 0.01
group by idnomenclador,idcapitulo,idsubcapitulo,idpractica,nomen.pdescripcion
);


--Dejo en cero el importe de las que no estan configurada por ninguna asosiacion 



INSERT INTO comparacion_valores_practica(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,valorexpendio,fechainivigencia,asocinvolucradas) (
SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,nomen.pdescripcion,0 as valorexpendio
,current_date as  fechainivigencia,concat('<se desactiva>') as asoc_involucradas
FROM (SELECT nomencladoruno.idnomenclador       ,nomencladoruno.idcapitulo       ,nomencladoruno.idsubcapitulo       ,nomencladoruno.idpractica,replace(practica.pdescripcion,',','') as pdescripcion           FROM nomencladoruno    
		NATURAL JOIN	practica
		WHERE activo     
		UNION      
	 SELECT nomencladordos.idnomenclador      ,nomencladordos.idcapitulo       ,nomencladordos.idsubcapitulo       ,nomencladordos.idpractica ,replace(practica.pdescripcion,',','') as pdescripcion          FROM nomencladordos      
	NATURAL JOIN	practica
	WHERE activo  
	) as nomen
LEFT JOIN comparacion_valores_practica as cvp USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
LEFT JOIN (
         SELECT idpractconvval,idsubcapitulo,idnomenclador,idcapitulo,idpractica
         FROM practconvval
         WHERE tvvigente AND idasocconv = 154 AND fijoh1 AND h1 = 0
         ) as config USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica) --MaLAPi 04-01-2023 Solo desactivo si es que ya no existe la configuracion de desactivacion
WHERE nullvalue(cvp.idcvpprimary) AND nullvalue(config.idpractconvval)
group by idnomenclador,idcapitulo,idsubcapitulo,idpractica,nomen.pdescripcion
);



respuesta = 'oki';

return respuesta;
END;
$function$
