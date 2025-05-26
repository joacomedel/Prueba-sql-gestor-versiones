CREATE OR REPLACE FUNCTION public.sys_auditar_suap_eliminar(pparametros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE 
 rfiltros RECORD;
 ccursor refcursor;
       ccursororden refcursor;
        rusuario RECORD;
        elem RECORD;
        elemorden  RECORD;
        indice integer;
        total integer;
   BEGIN
     EXECUTE sys_dar_filtros(pparametros) INTO rfiltros;

indice = 0;
total = -1;
OPEN ccursororden FOR SELECT t.nroregistro,idprestador,concat('{anio=',t.anio,', nroregistro= ',t.nroregistro,' , restacoseguro=no, esbioquimico=no, confiarenvalorpractica=si, accion=eliminarAuditoriaPrestador, idprestador = ',idprestador,' }') as param,ROW_NUMBER() OVER () AS row_num
FROM (
SELECT CASE WHEN not nullvalue(plana.idprestador) THEN plana.idprestador ELSE planb.idprestador END::bigint as idprestador
,replace(CASE WHEN not nullvalue(plana.pcuit) THEN plana.pcuit ELSE planb.pcuit END,'-','') as pcuit
,CASE WHEN not nullvalue(plana.pcategoria) THEN plana.pcategoria ELSE planb.pcategoria END::varchar as pcategoria
,nroorden,centro,idasocconv,suap_colegio_medico.*,categoriaefector::varchar,coseguro.*
,CASE WHEN NOT nullvalue(categoria_efector) AND trim(categoria_efector) <> '' THEN categoria_efector  
 WHEN NOT nullvalue(plana.pcategoria) THEN plana.pcategoria END as categoriaseleccionada

			FROM suap_colegio_medico
			LEFT JOIN ordenrecibo USING(idrecibo,centro)
                        LEFT JOIN (SELECT importe as importecoseguro, idrecibo,centro FROM importesrecibo WHERE idformapagotipos = 2 ) as coseguro USING(idrecibo,centro)
			LEFT JOIN orden USING(nroorden,centro)
                        LEFT JOIN ordenonlineinfoextra USING(nroorden,centro)
			LEFT JOIN ordvalorizada USING(nroorden,centro)
			LEFT JOIN prestador as plana  ON idprestador = nromatricula
                        LEFT JOIN prestador as  planb ON replace(planb.pcuit,'-','') = cuit_efector
                        WHERE nroregistro = rfiltros.nroregistro  AND not nullvalue(scmprocesado)
 ) as t 
WHERE idprestador >= 11712                     
GROUP BY nroregistro,anio,idprestador
ORDER BY row_num DESC
            --Limit 10
;
FETCH ccursororden INTO elemorden;
WHILE  found LOOP 
indice = indice +1;
if total = -1 then 
   total = elemorden.row_num;
end if;

PERFORM auditoriaautomatica_genera_elimina_auditoria(elemorden.param) ;
RAISE NOTICE 'Listo % de %',indice,total;
RAISE NOTICE '%',elemorden.param;


fetch ccursororden into elemorden;
END LOOP;
CLOSE ccursororden;

IF indice = 0 THEN 

OPEN ccursororden FOR SELECT t.nroregistro,idprestador,concat('{anio=',t.anio,', nroregistro= ',t.nroregistro,' , restacoseguro=no, esbioquimico=no, confiarenvalorpractica=si, accion=eliminarAuditoriaPrestador, idprestador = ',idprestador,' }') as param,ROW_NUMBER() OVER () AS row_num
FROM (
SELECT CASE WHEN not nullvalue(plana.idprestador) THEN plana.idprestador ELSE planb.idprestador END::bigint as idprestador
,replace(CASE WHEN not nullvalue(plana.pcuit) THEN plana.pcuit ELSE planb.pcuit END,'-','') as pcuit
,CASE WHEN not nullvalue(plana.pcategoria) THEN plana.pcategoria ELSE planb.pcategoria END::varchar as pcategoria
,nroorden,centro,idasocconv,suap_colegio_medico.*,categoriaefector::varchar,coseguro.*
,CASE WHEN NOT nullvalue(categoria_efector) AND trim(categoria_efector) <> '' THEN categoria_efector  
 WHEN NOT nullvalue(plana.pcategoria) THEN plana.pcategoria END as categoriaseleccionada

			FROM suap_colegio_medico
			LEFT JOIN ordenrecibo USING(idrecibo,centro)
                        LEFT JOIN (SELECT importe as importecoseguro, idrecibo,centro FROM importesrecibo WHERE idformapagotipos = 2 ) as coseguro USING(idrecibo,centro)
			LEFT JOIN orden USING(nroorden,centro)
                        LEFT JOIN ordenonlineinfoextra USING(nroorden,centro)
			LEFT JOIN ordvalorizada USING(nroorden,centro)
			LEFT JOIN prestador as plana  ON idprestador = nromatricula
                        LEFT JOIN prestador as  planb ON replace(planb.pcuit,'-','') = cuit_efector
                        WHERE nroregistro = rfiltros.nroregistro  AND not nullvalue(scmprocesado)
 ) as t 
WHERE idprestador < 11712                     
GROUP BY nroregistro,anio,idprestador
ORDER BY row_num DESC
        --    Limit 10
;
FETCH ccursororden INTO elemorden;
WHILE  found LOOP 
indice = indice +1;
if total = -1 then 
   total = elemorden.row_num;
end if;

PERFORM auditoriaautomatica_genera_elimina_auditoria(elemorden.param) ;
RAISE NOTICE 'Listo % de %',indice,total;
RAISE NOTICE '%',elemorden.param;

fetch ccursororden into elemorden;
END LOOP;
CLOSE ccursororden;

END IF;

IF rfiltros.limpiartabla = 'si' and indice = 0 then
select into total count(*) as total from suap_colegio_medico WHERE nroregistro = rfiltros.nroregistro ;
select into indice count(*) as indice from suap_colegio_medico WHERE nroregistro = rfiltros.nroregistro  AND nullvalue(scmprocesado);
RAISE NOTICE 'Se eliminan % filas de un total de %',indice,total;
delete from suap_colegio_medico WHERE nroregistro = rfiltros.nroregistro  AND nullvalue(scmprocesado);

end if; 

RETURN 'true';
END;$function$
