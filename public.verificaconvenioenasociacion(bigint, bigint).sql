CREATE OR REPLACE FUNCTION public.verificaconvenioenasociacion(bigint, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* verificaconvenioenasociacion(idasociacion,idconvenio)
$1 = IdAsociacion de Convenios
$2 = Id de Convenio */
DECLARE
       idasoc alias for $1;
       idconv alias for $2;
       elem RECORD;
       resultado boolean;
BEGIN
SELECT INTO elem * FROM asocconvenio WHERE asocconvenio.idasocconv = idasoc
                                           AND asocconvenio.idconvenio = idconv;
IF NOT FOUND THEN
resultado = 'false';
ELSE
resultado = 'true';
END IF;
RETURN resultado;
END;
$function$
