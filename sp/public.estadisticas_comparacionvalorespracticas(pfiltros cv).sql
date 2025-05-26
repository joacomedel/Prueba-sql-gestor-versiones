CREATE OR REPLACE FUNCTION public.estadisticas_comparacionvalorespracticas(pfiltros character varying)
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
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;

   ccursor refcursor;
   arvalores RECORD;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


-- Verifico si los valores son iguales	

--select * from f_dar_valores_comprar() limit 10;

open ccursor for select f_dar_valores_comprar as valor 
                  FROM f_dar_valores_comprar() 
                  LIMIT 10;
fetch ccursor into arvalores;
	while FOUND loop
                FOR i IN array_lower(arvalores.valor,1) .. array_upper(arvalores.valor,1) LOOP
		--for i IN 1..array_length(arvalores.valor) Loop
      		   --siniguales = 
      		   IF not nullvalue(i) THEN 
			RAISE NOTICE ' comparamos (%,%)',i,arvalores.valor[i];
		   END IF;
      		END Loop;

	end loop;
close ccursor;

/*
vcolumnas = 'idcvpprimary BIGSERIAL PRIMARY KEY,
             idnomenclador VARCHAR,
             idcapitulo VARCHAR,
	     idsubcapitulo VARCHAR,
	     idpractica VARCHAR,
	     pdescripcion VARCHAR
	    ';
vreferencias = 'Referencias';
 
 


OPEN cursorarchi FOR select idasocconv, count(*) as cantidad,acdecripcion,replace(LOWER(replace(replace(replace(replace(replace(replace(acdecripcion,',',''),'.',''),')',''),'(',''),'-',''),' ','_')),'__','_') as columna 
		     from practicavalores 
                     JOIN asocconvenio USING(idasocconv)
                     where nullvalue(pvfechafinvigencia) 
                     group by idasocconv,acdecripcion;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP

             vcolumnas = concat(vcolumnas, ', col_',relem.idasocconv,' FLOAT ');
             vwhere = concat(vwhere,' AND nullvalue(col_',relem.idasocconv,') ');
             vreferencias =  concat(vreferencias,' \n ', ' * col_',relem.idasocconv,' es la columna de  ',relem.acdecripcion);

	     FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;
   vquery = concat('create table comparacion_valores_practica ( ', vcolumnas,');');
   EXECUTE vquery;
INSERT INTO comparacion_valores_practica(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion) (
SELECT nomen.idnomenclador       
      ,nomen.idcapitulo       
      ,nomen.idsubcapitulo       
      ,nomen.idpractica       
      ,practica.pdescripcion      
 FROM       (SELECT nomencladoruno.idnomenclador       ,nomencladoruno.idcapitulo       ,nomencladoruno.idsubcapitulo       ,nomencladoruno.idpractica       ,nomencladoruno.pmcantidad1 as cantidad1       ,nomencladoruno.pmcantidad2 as cantidad2       ,nomencladoruno.pmcantidad3 as cantidad3       ,nomencladoruno.pmcantgastos as cantigasto       ,nomencladoruno.pmhonorario1 as honorario1       ,nomencladoruno.pmhonorario2 as honorario2      ,nomencladoruno.pmhonorario3 as honorario3       ,nomencladoruno.pmgastos     as gastos       FROM nomencladoruno       
UNION       SELECT nomencladordos.idnomenclador       ,nomencladordos.idcapitulo       ,nomencladordos.idsubcapitulo       ,nomencladordos.idpractica       ,nomencladordos.pmcantidad1 as cantidad1       ,0                          as cantidad2       ,0                          as cantidad3       ,nomencladordos.pmcantgastos as cantigasto       ,nomencladordos.pmhonorario1 as honorario1       ,0                            as honorario2       ,0                             as honorario3       ,nomencladordos.pmgastos     as gastos       FROM nomencladordos ) as nomen       
NATURAL JOIN	practica
WHERE activo 
--AND idnomenclador = '07' 
--ORDER BY  practica.idnomenclador,practica.idcapitulo,practica.idsubcapitulo,practica.idpractica
UNION 
SELECT '' as idnomenclador,'' as idcapitulo,'' as idsubcapitulo,'' as idpractica,vreferencias as pdescripcion
);



OPEN cursorarchi FOR select idasocconv, count(*) as cantidad, acdecripcion as columna 
		     from practicavalores 
                     JOIN asocconvenio USING(idasocconv)
                     where nullvalue(pvfechafinvigencia) 
                     group by idasocconv,acdecripcion;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP

	   	
              
             vquery = concat('UPDATE  comparacion_valores_practica SET col_',relem.idasocconv,' = pv.importe 
             FROM practicavalores as pv 
             WHERE pv.idasocconv = ',relem.idasocconv,'  
		AND nullvalue(pv.pvfechafinvigencia)  
                AND NOT pv.internacion 
		AND pv.idsubespecialidad = comparacion_valores_practica.idnomenclador
		AND pv.idcapitulo = comparacion_valores_practica.idcapitulo
		AND pv.idsubcapitulo = comparacion_valores_practica.idsubcapitulo
		AND pv.idpractica = comparacion_valores_practica.idpractica 
                AND pv.importe <> 0.01; ');
                
		EXECUTE vquery;
	     FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;
	vquery = concat('DELETE FROM comparacion_valores_practica WHERE pdescripcion not ilike ''Referencias %''  ',vwhere);
	EXECUTE vquery;

*/


respuesta = 'oki';


return respuesta;
END;
$function$
