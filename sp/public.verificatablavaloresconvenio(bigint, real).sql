CREATE OR REPLACE FUNCTION public.verificatablavaloresconvenio(bigint, real)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$/* Verifica que sean valida la tabla de valores y que dicha tabla contenga el Id de unidad, por ultimo
retorna el Id de Convenio
Modificado 11-09-2006 Para que Verifique la Unidad dada un IdAsociacion.
verificatablavaloresconvenio(IdAsociacion,IdTipoUnidad)
$1 = IdTablaValores
$2 = IdTipoUnidad */
DECLARE
	idasociacion alias for $1;
	idunidad alias for $2;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado bigint;
BEGIN
resultado = 0;
  SELECT INTO aux * FROM tablavalores
                         NATURAL JOIN convenio
                         NATURAL JOIN asocconvenio
                         WHERE tablavalores.idtipounidad = idunidad
                               AND asocconvenio.idasocconv = idasociacion
                               AND (nullvalue(convenio.cfinvigencia) OR convenio.cfinvigencia >= CURRENT_DATE)
                               AND (nullvalue(asocconvenio.acfechafin) OR asocconvenio.acfechafin >= CURRENT_DATE)
                               AND (nullvalue(tablavalores.tvfinvigencia) OR tablavalores.tvfinvigencia >= CURRENT_DATE);
  IF NOT FOUND THEN
        UPDATE temppractconvval SET error = 'NOUNIDAD'  WHERE temppractconvval.idasocconv = idasociacion;
  ELSE /*Si existe la unidad en alguna tabla de valor de los convenios de la asociacion*/
       resultado = aux.idconvenio;
  END IF; /*Si existe la tabla de valores*/
RETURN resultado;
END;
$function$
