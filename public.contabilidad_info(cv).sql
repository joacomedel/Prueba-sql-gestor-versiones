CREATE OR REPLACE FUNCTION public.contabilidad_info(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo_iva record;
       rinfo   record;
       observacion varchar;
       rinfocont record;
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rfiltros;
     observacion = '';

     -- Busco la funcion vinculada a la cuenta
     SELECT INTO rinfocont *
     FROM contabilidad_mayorinfo
     WHERE nrocuentac = rfiltros.nrocuentac;
 --    RAISE NOTICE 'En el sp info';
     IF (FOUND) THEN
           EXECUTE concat('SELECT ',rinfocont.cmifuncion,'(''',$1,''')')
           INTO observacion;
     
     END IF;
RETURN observacion;
END;
$function$
