CREATE OR REPLACE FUNCTION public.auditoriaautomatica_genera_elimina_auditoria(pfiltros character varying)
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
        rverificacuil RECORD;
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


SELECT INTO rverificacuil * FROM suap_colegio_medico
			    JOIN ordenrecibo USING(idrecibo,centro)
			    JOIN orden USING(nroorden,centro)
			    JOIN ordvalorizada USING(nroorden,centro)
			    LEFT JOIN prestador as plana  ON idprestador = nromatricula
                            LEFT JOIN prestador as  planb ON replace(planb.pcuit,'-','') = cuit_efector
			    WHERE CASE WHEN not nullvalue(plana.idprestador) THEN plana.idprestador ELSE planb.idprestador END::bigint = rfiltros.idprestador::bigint 
			    AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio
                           
                            LIMIT 1;

IF FOUND THEN 

RAISE NOTICE ' Vamos a Auditar (%)',rfiltros;

IF rfiltros.accion = 'eliminarAuditoriaPrestador' THEN 


/*DELETE FROM facturadebitoimputacionpendiente WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND idprestador  
IN ( SELECT idprestador
FROM suap_colegio_medico
			LEFT JOIN ordenrecibo USING(idrecibo,centro)
			LEFT JOIN orden USING(nroorden,centro)
			LEFT JOIN ordvalorizada USING(nroorden,centro)
			LEFT JOIN prestador ON idprestador = nromatricula
			WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND nullvalue(scmprocesado)  AND cuit_efector = rverificacuil.cuit_efector
                        ORDER BY idprestador LIMIT 1
);*/
PERFORM sys_elimina_preauditoria_odonto(nroorden::integer,centro,tipo::integer,rfiltros.nroregistro,rfiltros.anio) 
			FROM suap_colegio_medico
			LEFT JOIN ordenrecibo USING(idrecibo,centro)
			LEFT JOIN orden USING(nroorden,centro)
			LEFT JOIN ordvalorizada USING(nroorden,centro)
			LEFT JOIN prestador ON idprestador = nromatricula
			WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND not nullvalue(scmprocesado) AND cuit_efector = rverificacuil.cuit_efector and not nullvalue(scmprocesado)
                        ORDER BY idprestador;



UPDATE suap_colegio_medico SET scmcoseguroaplicado=0,scmfacturadaantes = null, scmprocesado = null,scmrepartirdebito = FALSE,	scmdebitoconseguro = FALSE WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND cuit_efector = rverificacuil.cuit_efector; 
DELETE FROM facturadebitoimputacionpendiente WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND idprestador = rfiltros.idprestador ;

END IF;

IF rfiltros.accion = 'generarAuditoriaPrestador' THEN 
--MaLApi 17-12-2019 Le pongo por defecto que no puedo confiar en el valor del prestador, luego hay que pedirlo por interfaz
--MaLapi 04-02-2020 Ahora si lo tengo en la interfaz de java

--PERFORM sys_auditar_suap(concat('{ tipoenlinea = ',rfiltros.tipoenlinea,', nroregistro = ',rfiltros.nroregistro,', anio = ',rfiltros.anio,', restacoseguro = ',rfiltros.restacoseguro,',cuit_efector=',rverificacuil.cuit_efector,', confiarenvalorpractica= ',rfiltros.confiarenvalorpractica ,' , esbioquimico=',rfiltros.esbioquimico,'}'));

PERFORM sys_auditar_suap(concat('{  nroregistro = ',rfiltros.nroregistro,', anio = ',rfiltros.anio,', restacoseguro = ',rfiltros.restacoseguro,',cuit_efector=',rverificacuil.cuit_efector,', confiarenvalorpractica= ',rfiltros.confiarenvalorpractica ,' , esbioquimico=',rfiltros.esbioquimico,'}'));

END IF;

END IF;



   RETURN 'true';
  END;
$function$
