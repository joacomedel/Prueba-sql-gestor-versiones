CREATE OR REPLACE FUNCTION public.auditoriaautomatica_guardarinformacionverificaprestador(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/*
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


UPDATE facturaprestadorverificar SET fpvmismoimporte = (rfiltros.fpvimporteingresado = fpvimportecalculado), fpvverificado = rfiltros.fpvverificado,fpvimporteingresado = rfiltros.fpvimporteingresado, fpvcomentario = rfiltros.fpvcomentario
, fpvnroprestador = rfiltros.fpvnroprestador
WHERE idprestador = rfiltros.idprestador AND nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio; 
	
--Modifico la categoria del prestador si es que se envia:

IF not nullvalue(rfiltros.pcategoria) AND trim(rfiltros.pcategoria) <> '' THEN
	update prestador set pcategoria=trim(rfiltros.pcategoria) where idprestador = rfiltros.idprestador AND pcategoria <> rfiltros.pcategoria; 
END IF;
   RETURN 'true';
  END;
$function$
