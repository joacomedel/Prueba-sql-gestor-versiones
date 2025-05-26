CREATE OR REPLACE FUNCTION public.contabilidad_mayor_xcuenta()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* SP que genera un archivo .csv por cada una de las cuentas */
DECLARE
	ccuentas CURSOR FOR SELECT Distinct idcuenta FROM multivac_temporal_mayor WHERE idcuenta= 10261 ;
	rcuenta RECORD;
	archivo varchar;
	
BEGIN
     
     OPEN ccuentas;
     FETCH ccuentas INTO rcuenta;
     WHILE  found LOOP
            archivo = concat('/tmp/vas_',rcuenta.idcuenta,'.csv');
            --COPY (SELECT * FROM multivac_temporal_mayor WHERE order by fechacontable) TO ''' || archivo || ''' WITH CSV HEADER;

            EXECUTE 'COPY (SELECT * FROM multivac_temporal_mayor WHERE idcuenta = ' || rcuenta.idcuenta::varchar || ' order by fechacontable,nroasiento) TO ''' || archivo || ''' WITH CSV HEADER';
            
           
            FETCH ccuentas INTO rcuenta;
            END LOOP;
     CLOSE ccuentas;
     return true;
END;
$function$
