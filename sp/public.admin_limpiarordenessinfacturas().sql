CREATE OR REPLACE FUNCTION public.admin_limpiarordenessinfacturas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	
BEGIN

DELETE FROM itemordenessinfactura WHERE (nroorden,centro) IN (
SELECT nroorden,centro FROM itemordenessinfactura left join facturaorden using(nroorden,centro) where not nullvalue(facturaorden.nroorden) 
);

DELETE FROM ordenessinfacturas WHERE (nroorden,centro,tpoexpendio,nrodoc,tipodoc) IN (
select nroorden,centro,tpoexpendio,nrodoc,tipodoc from ordenessinfacturas left join facturaorden using(nroorden,centro) where not nullvalue(facturaorden.nroorden) 
);

return true;
END;
$function$
