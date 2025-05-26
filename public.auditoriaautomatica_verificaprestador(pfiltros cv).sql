CREATE OR REPLACE FUNCTION public.auditoriaautomatica_verificaprestador(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$  DECLARE

       ccursor refcursor;
       ccursororden refcursor;
      
        
        rfiltros RECORD;
        rusuario RECORD;
        elem RECORD;
	elemorden  RECORD;
        rprestador RECORD;
	rvalores RECORD;
        rfacturado RECORD;

	vimporte double precision;

  BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF NOT iftableexists('temp_auditoriaautomatica') THEN

CREATE TEMP TABLE temp_auditoriaautomatica (nroregistro bigint, anio integer,idprestador bigint);
--INSERT INTO  temp_auditoriaautomatica (nroregistro,anio) VALUES(rfiltros.nroregistro,rfiltros.anio); 

END IF;


--Para Cada Orden
OPEN ccursororden FOR SELECT * 
			FROM temp_auditoriaautomatica
			LEFT JOIN facturaprestadorverificar USING(idprestador,nroregistro,anio)
			ORDER BY idprestador
			
;
FETCH ccursororden INTO elemorden;
WHILE  found LOOP 
	
		IF nullvalue(elemorden.fpvmismoimporte) THEN 
                        SELECT INTO rfacturado idprestador,sum(importeorden) as importefactura
                        FROM (SELECT  nroregistro,anio,idrecibo,centro,idprestador, valor_practica - valor_coseguro as importeorden 
			FROM (
			 SELECT nroregistro,anio,idrecibo,centro,idprestador,sum(valor_practica) as valor_practica,min(CASE WHEN nullvalue(valor_coseguro) THEN 0 ELSE valor_coseguro END) as valor_coseguro --as importefactura
                        FROM suap_colegio_medico JOIN prestador ON replace(pcuit,'-','') = cuit_efector
                        WHERE nroregistro =  elemorden.nroregistro AND  anio = elemorden.anio AND idprestador = elemorden.idprestador
                        GROUP BY nroregistro,anio,centro,idprestador,idrecibo
                        ) as pororden) as t 
                        JOIN prestador using(idprestador)
                        WHERE nroregistro =  elemorden.nroregistro AND  anio = elemorden.anio AND idprestador = elemorden.idprestador
                        GROUP BY idprestador;
                        
                        
       
                        --RAISE NOTICE ' No esta cargado (%)',elemorden.fpvmismoimporte;
			INSERT INTO facturaprestadorverificar(idprestador,nroregistro,anio,fpvimportecalculado,fpvimporteingresado,fpvmismoimporte) 
			VALUES(elemorden.idprestador,elemorden.nroregistro,elemorden.anio,elemorden.totalprestacion,CASE WHEN nullvalue(rfacturado.importefactura) THEN elemorden.totalprestacion ELSE rfacturado.importefactura END,CASE WHEN nullvalue(elemorden.totalprestacion) THEN false ELSE CASE WHEN nullvalue(rfacturado.importefactura) THEN elemorden.totalprestacion ELSE rfacturado.importefactura END = elemorden.totalprestacion END);
		ELSE 
			
			UPDATE facturaprestadorverificar 
					SET fpvimportecalculado = elemorden.totalprestacion,fpvmismoimporte = CASE WHEN nullvalue(elemorden.totalprestacion) THEN false ELSE elemorden.totalprestacion = elemorden.fpvimporteingresado END
					WHERE idprestador = elemorden.idprestador 
						AND nroregistro = elemorden.nroregistro AND anio = elemorden.anio;

			
				
		END IF;

		
fetch ccursororden into elemorden;
END LOOP;
CLOSE ccursororden;

UPDATE facturaprestadorverificar SET fpvnroprestador = t.fpvnroprestador 
FROM (
select fpvnroprestador,idprestador 
from facturaprestadorverificar where not nullvalue(fpvnroprestador)
) as t
WHERE nroregistro = rfiltros.nroregistro AND t.idprestador =  facturaprestadorverificar.idprestador
AND nullvalue(facturaprestadorverificar.fpvnroprestador);


UPDATE facturaprestadorverificar SET fpvprestadorinformado = t.efector, ftvcondicion_iva = t.tipoprestador,fpvnroprestador = t.nroprestadorinformado 
FROM (
SELECT idprestador,text_concatenarsinrepetir(nro_prestador_cm) as nroprestadorinformado,text_concatenarsinrepetir(concat(cuit_efector,' ',replace(ape_nom_efector,',',' '),'|')) as efector,text_concatenarsinrepetir(concat(condicion_iva,' ')) as tipoprestador
 FROM suap_colegio_medico
			 JOIN ordenrecibo USING(idrecibo,centro)
			 JOIN orden USING(nroorden,centro)
			 JOIN ordvalorizada USING(nroorden,centro)
			 JOIN prestador ON idprestador = nromatricula
WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio
GROUP BY nroregistro,anio,idprestador
) as t
WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND t.idprestador =  facturaprestadorverificar.idprestador
AND nullvalue(facturaprestadorverificar.fpvprestadorinformado) OR nullvalue(facturaprestadorverificar.ftvcondicion_iva)
;



   RETURN 'true';
  END;
$function$
