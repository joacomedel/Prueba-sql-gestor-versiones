CREATE OR REPLACE FUNCTION public.asientogenericofacturaventa_anular_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
	xidasiento bigint;
BEGIN
	-- SI fue ANULADA
        if (not nullvalue(NEW.anulada)) then
		-- Busco el asiento generado
  		--MaLaPi 27-02-2019 Ahora se llama al mismo sp que genera el asiento, en ese se creo o modifica un asiento
               /*  select into xidasiento idasientogenerico*100+idcentroasientogenerico from asientogenerico where idasientogenericocomprobtipo = 5 and idcomprobantesiges = concat(OLD.tipofactura,'|',OLD.tipocomprobante,'|',OLD.nrosucursal,'|',OLD.nrofactura);
		if found then               
			--Genero la reversion del asiento 
			perform asientogenerico_revertir(xidasiento);
                end if;
                */
                 perform asientogenericofacturaventa_crear(concat(NEW.tipofactura,'|',NEW.tipocomprobante,'|',NEW.nrosucursal,'|',NEW.nrofactura));
	end if;

	return NEW;
END;
$function$
