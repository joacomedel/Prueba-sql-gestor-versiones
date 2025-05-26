CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_des_vinasoc(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* 
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
--SELECT convenios_migrarnomencladoryvalores_des_vinasoc({accion=lala,asociaciones_siges=152@153@151@1010@1011@1012,codigopractica=12.25.01.53});
--SELECT * FROM  convenios_migrarnomencladoryvalores_des_vinasoc('{accion=limpiar,asociaciones_siges=152@153@151@1010@1011@1012,codigopractica=12.25.01.53}');
--SELECT * FROM migrarnomencladoryvalores_des;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;



vcolumnas = 'idcvpprimary BIGSERIAL PRIMARY KEY,
             idnomenclador VARCHAR,
             idcapitulo VARCHAR,
	     	 idsubcapitulo VARCHAR,
	     	 idpractica VARCHAR,
	     	 pdescripcion VARCHAR,
			 idasocconv VARCHAR,
	     	 soniguales VARCHAR,
	     	 valorexpendio float,
             fechainivigencia date,
             asocinvolucradas VARCHAR,
	     	 cvpfechaingreso timestamp default now()
	    ';
 
vquery = concat('create table migrarnomencladoryvalores_des ( ', vcolumnas,');'); 
IF not iftableexists_fisica('migrarnomencladoryvalores_des')   THEN
   EXECUTE vquery;
	RAISE NOTICE 'Conuslta (%)',vquery;
END IF;

IF iftableexists_fisica('migrarnomencladoryvalores_des') AND rfiltros.accion = 'limpiar'  THEN
   DELETE FROM migrarnomencladoryvalores_des;
END IF;

IF iftableexists_fisica('migrarnomencladoryvalores_des') AND rfiltros.accion = 'eliminar'  THEN
   DROP TABLE migrarnomencladoryvalores_des;
END IF;

--Dejo en cero el importe de las asociaciones que no le deben dar valor a una practica

INSERT INTO migrarnomencladoryvalores_des(idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,valorexpendio,fechainivigencia,asocinvolucradas) (
SELECT DISTINCT idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica,replace(practica.pdescripcion,',','') as pdescripcion,0 as valorexpendio
,current_date as  fechainivigencia,rfiltros.asociaciones_siges as asoc_involucradas
from practconvval 
NATURAL JOIN practica
where concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = rfiltros.codigopractica 
	 AND  tvvigente  AND idasocconv <> ALL(string_to_array(rfiltros.asociaciones_siges, '@'))
	--(rfiltros.asociaciones_siges)

);

respuesta = 'oki';

return respuesta;
END;
$function$
