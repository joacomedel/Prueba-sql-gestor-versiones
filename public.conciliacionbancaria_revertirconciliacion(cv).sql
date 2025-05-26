CREATE OR REPLACE FUNCTION public.conciliacionbancaria_revertirconciliacion(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;
    cmovconciliados CURSOR FOR SELECT * FROM  temp_movconciliados; -- temporal con los movimientos conciliados
    rmovconciliados record;
 
    resp boolean;
    cant integer;
    rfiltros RECORD;
    info varchar;

BEGIN
     EXECUTE sys_dar_filtros($1) INTO rfiltros;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;

     cant = 0;

     OPEN cmovconciliados;
     FETCH cmovconciliados INTO rmovconciliados;
     WHILE found LOOP

               UPDATE conciliacionbancariaitem SET cbiactivo = false
               WHERE idconciliacionbancariaitem = rmovconciliados.idconciliacionbancariaitem
                     and idcentroconciliacionbancariaitem = rmovconciliados.idcentroconciliacionbancariaitem;
              
               cant = cant + 1;
         FETCH cmovconciliados INTO rmovconciliados;
     END LOOP;
     CLOSE cmovconciliados;


return cant;
END;
$function$
