CREATE OR REPLACE FUNCTION public.obtenervalorxcategoria(character varying, real, character varying)
 RETURNS real
 LANGUAGE plpgsql
AS $function$/*Calcula los valores de la practica segun la configuracion establecida
en la tabla practconvval*/

DECLARE
	ppcategoria alias for $1;
	punidad alias for $2;
	pidasocconv alias for $3;
	valor float4;
	
BEGIN
valor = 0;

         IF ppcategoria = '*' THEN 
            SELECT INTO valor tablavalores.idtipovalor 
                         FROM tablavalores
                         NATURAL JOIN convenio
                         NATURAL JOIN asocconvenio
                         WHERE tablavalores.idtipounidad = punidad
                               AND asocconvenio.idasocconv = pidasocconv
                               AND (/*nullvalue*/(convenio.cfinvigencia)is null  OR convenio.cfinvigencia > CURRENT_DATE)
                               AND (/*nullvalue*/(asocconvenio.acfechafin)is null OR asocconvenio.acfechafin > CURRENT_DATE)
                               AND (/*nullvalue*/(tablavalores.tvfinvigencia)is null OR tablavalores.tvfinvigencia > CURRENT_DATE);

         ELSE

           SELECT INTO valor CASE WHEN nullvalue(tablavaloresxcategoria.idtipovalor) THEN tablavalores.idtipovalor ELSE tablavaloresxcategoria.idtipovalor END
                         FROM tablavalores
                         JOIN tablavaloresxcategoria USING(idconvenio,idtablavalor,idtipounidad)
                         NATURAL JOIN convenio
                         NATURAL JOIN asocconvenio
                         WHERE tablavalores.idtipounidad = punidad
                               AND tablavaloresxcategoria.pcategoria = ppcategoria
                               AND asocconvenio.idasocconv = pidasocconv
                               AND (/*nullvalue*/(convenio.cfinvigencia)is null OR convenio.cfinvigencia > CURRENT_DATE)
                               AND (/*nullvalue*/(asocconvenio.acfechafin)is null OR asocconvenio.acfechafin > CURRENT_DATE)
                               AND (/*nullvalue*/(tablavalores.tvfinvigencia)is null OR tablavalores.tvfinvigencia > CURRENT_DATE);
       END IF;

       IF /*nullvalue*/(valor)is null THEN valor = 0;      END IF;

RETURN valor;
END;
$function$
