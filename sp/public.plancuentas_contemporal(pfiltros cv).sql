CREATE OR REPLACE FUNCTION public.plancuentas_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_plancuentas_contemporal
AS (



 
select idcuenta,nrocuentac,descripcionsiges as descripcion,
saldohabitual,imputable,jerarquia,asignaccosto,activo,
 '1-idcuenta#idcuenta@2-nrocuentac#nrocuentac@3-descripcion#descripcion@4-saldohabitualn#saldohabitualn@5-imputable#imputable@6-jerarquia#jerarquia@7-asignaccosto#asignaccosto@8-activo#activo'::text as mapeocampocolumna 
 
from multivac.mapeocuentascontables 
where true and
 (descripcionsiges  ilike '%'||rfiltros.descripcion||'%'   or nullvalue(rfiltros.descripcion))
and (nrocuentac ilike  '%'||rfiltros.nrocuentac::varchar||'%' or nullvalue(rfiltros.nrocuentac))
order by jerarquia   
);
return true;
END;
$function$
