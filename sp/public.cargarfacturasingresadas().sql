CREATE OR REPLACE FUNCTION public.cargarfacturasingresadas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Ingresa todas las facturas ingresadas por mesa de entrada en las tablas de facturas para poder
ser auditadas por el modulo de mesa de entrada. */
DECLARE
    rfactura RECORD;
    alta refcursor;
    rresultado boolean;

BEGIN
OPEN alta FOR SELECT *
               FROM recepcion
               NATURAL JOIN reclibrofact WHERE numeroregistro >=816 AND numeroregistro <=834;
               
FETCH alta INTO rfactura;
WHILE  found LOOP
       SELECT INTO rresultado * FROM insertarfactura(cast(rfactura.idrecepcion as INTEGER));
FETCH alta INTO rfactura;
END LOOP;
CLOSE alta;
RETURN rresultado;
END;
$function$
