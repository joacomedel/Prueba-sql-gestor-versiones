CREATE OR REPLACE FUNCTION public.auditoriaautomatica_desvincular(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
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

PERFORM sys_elimina_preauditoria_odonto(nroorden::integer,centro,tipo::integer,nroregistro,anio) 			
			FROM suap_colegio_medico
			LEFT JOIN ordenrecibo USING(idrecibo,centro)
			LEFT JOIN orden USING(nroorden,centro)
			LEFT JOIN ordvalorizada USING(nroorden,centro)
			LEFT JOIN prestador ON idprestador = nromatricula
			WHERE idprestador = rfiltros.idprestador 
			AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio
                        ORDER BY idprestador;

UPDATE facturaprestadorverificar SET fpvdesvincular = true 
		WHERE idprestador = rfiltros.idprestador 
		AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio;

   RETURN 'true';
  END;
$function$
