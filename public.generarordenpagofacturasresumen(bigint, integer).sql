CREATE OR REPLACE FUNCTION public.generarordenpagofacturasresumen(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Actualiza la minuta de pago asoiciada a las facturas incluidas en un resumen, realizando el cambio de estados para los
mismos.*/

DECLARE

nrofac bigint=$1;
nroanio integer =$2;
	
	unafactura RECORD;
	resultado boolean;
        cursorfacturas CURSOR FOR SELECT * FROM factura WHERE factura.idresumen=nrofac and factura.anioresumen=nroanio;
      nroorden bigint;
BEGIN


   select into nroorden nroordenpago from factura  WHERE factura.nroregistro =nrofac and factura.anio=nroanio;
  OPEN cursorfacturas;
  FETCH cursorfacturas INTO unafactura;

                     
  WHILE  found LOOP
      --- VAS 06/08   agrego: , idcentroordenpago = centro()
     UPDATE factura  SET nroordenpago = nroorden , idcentroordenpago = centro()
                      WHERE factura.nroregistro = unafactura.nroregistro AND factura.anio =  unafactura.anio;
     INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion)
    VALUES (CURRENT_DATE,unafactura.nroregistro,unafactura.anio,3,concat('Al ser generada la orden',unafactura.nroregistro));

      FETCH cursorfacturas INTO unafactura;  
    
  END LOOP;


   CLOSE cursorfacturas;
   resultado = 'true';

RETURN resultado;
END;
$function$
