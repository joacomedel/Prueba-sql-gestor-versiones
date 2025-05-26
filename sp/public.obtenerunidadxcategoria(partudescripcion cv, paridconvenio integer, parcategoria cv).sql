CREATE OR REPLACE FUNCTION public.obtenerunidadxcategoria(partudescripcion character varying, paridconvenio integer, parcategoria character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* */

DECLARE
	resultado character varying;
	ranexovalor RECORD;
	
BEGIN
 resultado = '';
   SELECT INTO ranexovalor tablavalores.idtablavalor,tablavalores.idconvenio,tablavalores.idtipounidad,tipounidad.tudescripcion
					 		,CASE WHEN nullvalue(tablavaloresxcategoria.idtipovalor) THEN tablavalores.idtipovalor ELSE tablavaloresxcategoria.idtipovalor END  as valor
					 		,tablavalores.tvinivigencia,tablavalores.tvfechaingreso,pcategoria        
					 		FROM tablavalores        
					 		LEFT JOIN tablavaloresxcategoria  USING (idconvenio,idtablavalor,idtipounidad)       
					 		NATURAL JOIN convenio        
					 		NATURAL JOIN tipounidad        
					 		WHERE convenio.idconvenio = paridconvenio AND (nullvalue(convenio.cfinvigencia) OR (convenio.cfinvigencia > CURRENT_DATE))             
					 		AND (nullvalue(tablavalores.tvfinvigencia)  OR (tablavalores.tvfinvigencia > CURRENT_DATE))
							AND tudescripcion ilike partudescripcion
							AND (nullvalue(tablavaloresxcategoria.pcategoria) OR tablavaloresxcategoria.pcategoria = parcategoria) LIMIT 1;
	  IF FOUND THEN
	    resultado = concat('{tudescripcion=',ranexovalor.tudescripcion,', pcategoria=',ranexovalor.pcategoria,', idconvenio=',ranexovalor.idconvenio,' , idtablavalor=',ranexovalor.idtablavalor,' , tvinivigencia=',ranexovalor.tvinivigencia,' , idtipounidad=',ranexovalor.idtipounidad,' }');
	  END IF;
	--  IF nullvalue(resultado) THEN resultado = '';      END IF;
RETURN resultado;
END;
$function$
