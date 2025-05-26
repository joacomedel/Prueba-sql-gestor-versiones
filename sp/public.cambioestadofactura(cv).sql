CREATE OR REPLACE FUNCTION public.cambioestadofactura(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

    rdata RECORD;
  

BEGIN
      EXECUTE sys_dar_filtros($1) INTO rdata;
      INSERT INTO festados (nroregistro,anio,tipoestadofactura,fechacambio,observacion,idusuario)
      VALUES (rdata.nroregistro,rdata.anio,rdata.tipoestadofactura,current_date,rdata.observacion,sys_dar_usuarioactual());

RETURN true;
END;
$function$
