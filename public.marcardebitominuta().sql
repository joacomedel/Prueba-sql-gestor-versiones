CREATE OR REPLACE FUNCTION public.marcardebitominuta()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Llamo al sp que dados los debitos de la minuta correspondiente, llamara por cada debito al sp que migra*/
DECLARE
	cursordebitominuta CURSOR FOR SELECT * FROM comprobantedebitominuta;
	regdebitominuta RECORD;
        resultado BOOLEAN;

BEGIN

OPEN cursordebitominuta;
FETCH cursordebitominuta into regdebitominuta;
     WHILE  found LOOP

            SELECT INTO resultado * FROM multivac.marcarfacturaventamigrada(regdebitominuta.tipofactura, regdebitominuta.nrosucursal, regdebitominuta.nrofactura,
regdebitominuta.tipocomprobante);
	
     FETCH cursordebitominuta into regdebitominuta;
     END LOOP;
CLOSE cursordebitominuta;


return true;
end;
$function$
