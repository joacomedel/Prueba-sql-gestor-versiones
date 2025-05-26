CREATE OR REPLACE FUNCTION public.afiliaciones_subsidiofalle_procesarcambiosdesdeweb(pfiltros character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/* Procesa las declaraciones de Subsidio por fallecimiento enviadas en la tabla temporal temp_w_procesarcambios 
CREATE TEMP TABLE temp_w_procesarcambios (  cambio VARCHAR,  adtelfijo VARCHAR,  nrodoc VARCHAR,  nombresyapellido VARCHAR,  nrosiges VARCHAR,  tipodoc BIGINT,  ademail VARCHAR,  final INTEGER  ); 

*/

DECLARE
	cprocesarcambios refcursor;
	rfiltros record;
	
	resultado TEXT;
	vprocesados INTEGER;
	vnoprocesados INTEGER;
	rbenefborrado RECORD;
	rdireccion RECORD;
	rweb RECORD;
	marcarprocesada boolean;
        vtieneamuc boolean;
        vtextoauxiliar text;
	
	

BEGIN

--RAISE NOTICE 'Lala (%),(%),(%)',rfiltros.nrodoc,rfiltros.tipodoc,rweb;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vprocesados = 0;
vnoprocesados = 0;
vtextoauxiliar = '';
 OPEN cprocesarcambios FOR  SELECT nrodoctitu,tipodoctitu,  cambio 
                 FROM temp_w_procesarcambios as t
				 JOIN w_afiliacion_declara_subsidio as ad ON (t.nrodoc = ad.nrodoctitu AND t.tipodoc = ad.tipodoctitu) 
				 LEFT JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio) 
				 WHERE nullvalue(adsfechafinvigencia) AND nullvalue(adspfechaproceso)  
				 GROUP BY nrodoctitu,tipodoctitu,cambio
				 ORDER BY nrodoctitu;
				 
     FETCH cprocesarcambios into rweb;
     WHILE FOUND LOOP
     IF rweb.cambio = 'SI' OR TRUE THEN  
	 marcarprocesada = true;
	 
	 -- Guardo BK con lo que esta Ahora
	 INSERT INTO declarasubsborradas(nrodoctitu, nro, apellido, nrodoc, vinculo, tipodoctitu, tipodoc, nombres, porcent, declarasubscc) (
		 SELECT nrodoctitu, nro, apellido, nrodoc, vinculo, tipodoctitu, tipodoc, nombres, porcent, declarasubscc
		 FROM declarasubs
		 WHERE nrodoctitu =rweb.nrodoctitu AND tipodoctitu = rweb.tipodoctitu
	 );
	 
	 --Elimino lo que esta ahora
	 DELETE FROM declarasubs WHERE nrodoctitu =rweb.nrodoctitu AND tipodoctitu = rweb.tipodoctitu;
	 --Inserto lo Nuevo
	 INSERT INTO declarasubs (nrodoctitu, nro, apellido, nrodoc, vinculo, tipodoctitu, tipodoc, nombres, porcent)
	 (SELECT nrodoctitu, adsorden, adsapellido, adsnrodoc, adsvinculo, tipodoctitu, adstipodoc, adsnombres, adsporciento
	  FROM w_afiliacion_declara_subsidio as ad 
	  LEFT JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio) 
	  WHERE nullvalue(adsfechafinvigencia) AND nullvalue(adspfechaproceso)  
	   AND nrodoctitu =rweb.nrodoctitu AND tipodoctitu = rweb.tipodoctitu
	 );
	 
	END IF;
	
	IF marcarprocesada THEN
		INSERT INTO w_afiliacion_declara_subsidio_procesado( idafiliaciondeclarasubsidio, adspfechaproceso, adspusuarioproceso, adspfechacarga)
		(SELECT idafiliaciondeclarasubsidio, now() as adspfechaproceso,sys_dar_usuarioactual() as adspusuarioproceso,adsfechaingreso as adspfechacarga
		 FROM w_afiliacion_declara_subsidio as ad 
		 LEFT JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio) 
		 WHERE nullvalue(adsfechafinvigencia) AND nullvalue(adspfechaproceso)  
		   AND nrodoctitu =rweb.nrodoctitu AND tipodoctitu = rweb.tipodoctitu
		);
		vprocesados = vprocesados + 1;
	ELSE 
		vnoprocesados = vnoprocesados + 1;
	END IF;
    
FETCH cprocesarcambios into rweb;
     END LOOP;
     CLOSE cprocesarcambios;

resultado = concat('<span>','Se procesaron correctamente ',vprocesados,'. <br> No se pudieron procesar ',vnoprocesados,'</span><p>'::text,vtextoauxiliar,'</p>');

return resultado;
END;
$function$
