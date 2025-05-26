CREATE OR REPLACE FUNCTION public.asientogenericofacturaventa_update_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

DECLARE
	xidasiento bigint;
BEGIN
	select into xidasiento idasientogenerico*100+idcentroasientogenerico from asientogenerico where idasientogenericocomprobtipo = 5 and idcomprobantesiges = concat(OLD.tipofactura,'|',OLD.tipocomprobante,'|',OLD.nrosucursal,'|',OLD.nrofactura);
	if found then
		perform asientogenerico_revertir(xidasiento);
	end if;

        -- pidoperacion formato: 'FA|1|20|1894'	
	perform asientogenericofacturaventa_crear(concat(NEW.tipofactura,'|',NEW.tipocomprobante,'|',NEW.nrosucursal,'|',NEW.nrofactura));

	return NEW;
END;
$function$
