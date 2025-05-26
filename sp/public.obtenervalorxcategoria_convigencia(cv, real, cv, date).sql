CREATE OR REPLACE FUNCTION public.obtenervalorxcategoria_convigencia(character varying, real, character varying, date)
 RETURNS real
 LANGUAGE plpgsql
AS $function$/*Calcula los valores de la practica segun la configuracion establecida en la tabla practconvval*/

DECLARE
	ppcategoria alias for $1;
	punidad alias for $2;
	pidasocconv alias for $3;
	pfechainivigencia alias for $4;
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
                               AND (nullvalue(convenio.cfinvigencia) OR convenio.cfinvigencia > CURRENT_DATE)
                               AND (nullvalue(asocconvenio.acfechafin) OR asocconvenio.acfechafin > CURRENT_DATE)
                               AND (nullvalue(tablavalores.tvfinvigencia) OR tablavalores.tvfinvigencia > pfechainivigencia)
							   AND  (tablavalores.tvinivigencia >= pfechainivigencia );

         ELSE

           SELECT INTO valor CASE WHEN nullvalue(tablavaloresxcategoria.idtipovalor) THEN tablavalores.idtipovalor ELSE tablavaloresxcategoria.idtipovalor END
                         FROM tablavalores
                         JOIN tablavaloresxcategoria USING(idconvenio,idtablavalor,idtipounidad)
                         NATURAL JOIN convenio
                         NATURAL JOIN asocconvenio
                         WHERE tablavalores.idtipounidad = punidad
                               AND tablavaloresxcategoria.pcategoria = ppcategoria
                               AND asocconvenio.idasocconv = pidasocconv
                               AND (nullvalue(convenio.cfinvigencia) OR convenio.cfinvigencia > CURRENT_DATE)
                               AND (nullvalue(asocconvenio.acfechafin) OR asocconvenio.acfechafin > CURRENT_DATE)
                               AND (nullvalue(tablavalores.tvfinvigencia) OR tablavalores.tvfinvigencia > pfechainivigencia)
							   AND  (tablavalores.tvinivigencia >= pfechainivigencia );
       END IF;

       IF nullvalue(valor) THEN valor = 0;      END IF;

RETURN valor;
END;
$function$
