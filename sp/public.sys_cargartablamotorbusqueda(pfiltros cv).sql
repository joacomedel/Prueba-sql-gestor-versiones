CREATE OR REPLACE FUNCTION public.sys_cargartablamotorbusqueda(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
       primero boolean;
        
        rfiltros RECORD;
        rusuario RECORD;
      
BEGIN 
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

     IF not iftableexists(rfiltros.tabla) THEN  
       RAISE NOTICE 'Voy a crear la tabla (%)',rfiltros.tabla;
       PERFORM 'CREATE TABLE '||rfiltros.tabla||' AS TABLE temp_cargartablamotorbusqueda;';
       --PERFORM 'CREATE TABLE '||rfiltros.tabla||' AS SELECT * FROM temp_cargartablamotorbusqueda;';
     END IF;	

     PERFORM 'INSERT INTO '||rfiltros.tabla||' ( SELECT * FROM temp_cargartablamotorbusqueda );';


   /*  OPEN cvalorregistros FOR 	SELECT mnroregistro,count(*) FROM medicamentosys
				LEFT JOIN valormedicamento USING(mnroregistro,vmfechaini,vmimporte)
				WHERE nullvalue(idvalor) AND ikfechainformacion = '2015-11-30' --AND mnroregistro = 50959
				GROUP BY mnroregistro
				HAVING count(*) > 1
				--LIMIT 500
                                ;

     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP

	   
     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;*/
     return 'Listo';
END;
$function$
