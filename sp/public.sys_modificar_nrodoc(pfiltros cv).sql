CREATE OR REPLACE FUNCTION public.sys_modificar_nrodoc(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
 
SELECT sys_modificar_nrodoc('{nrodoccargado =93698423,nrodocnuevo=19085276}');

*/
DECLARE
	
	elem RECORD;
	rfiltros RECORD;
    resultado boolean;
    
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

UPDATE persona SET nrodoc = rfiltros.nrodocnuevo WHERE nrodoc = rfiltros.nrodoccargado;
UPDATE far_afiliado SET aidafiliadoobrasocial=rfiltros.nrodocnuevo , nrodoc =rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE cuentacorrientedeuda SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE cuentacorrientepagos SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE cuentas SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE declarasubs SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE derivacionacompaniante SET danrodoc=rfiltros.nrodocnuevo  WHERE danrodoc =  rfiltros.nrodoccargado; 
UPDATE histobarras SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE grupoacompaniante SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE informedescuentoplanilla SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE infoafiliado SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE informedescuentoplanillav2 SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE reintegro SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE ctasctesmontosdescuento SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc = rfiltros.nrodoccargado; 
UPDATE solicitudauditoria SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE tbarras SET nrodoctitu=rfiltros.nrodocnuevo  WHERE nrodoctitu =  rfiltros.nrodoccargado; 
UPDATE tarjeta SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE taporterecibido SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc =  rfiltros.nrodoccargado; 
UPDATE tafiliado SET nrodoc=rfiltros.nrodocnuevo  WHERE nrodoc = rfiltros.nrodoccargado; 
update cliente set nrocliente=rfiltros.nrodocnuevo  where nrocliente=rfiltros.nrodoccargado; 



RETURN true;

END;
$function$
