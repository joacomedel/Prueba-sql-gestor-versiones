CREATE OR REPLACE FUNCTION public.asentargtoadministrativo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
    comprobantemovimiento BIGINT;
    elimportetotal DOUBLE PRECISION;
--REGISTROS
    uninforme RECORD;
    ladeuda RECORD;
    lacuenta RECORD;
    ladeudacliente RECORD;

BEGIN

   SELECT INTO uninforme * FROM temp_informefacturacion;
   IF FOUND THEN 
   
	PERFORM cambiarestadoinformefacturacion(uninforme.nroinforme,uninforme.idcentroinformefacturacion,
	3,'Se cambia el estado en el momento de generar el gasto administrativo');

        comprobantemovimiento = uninforme.nroinforme * 100 +uninforme.idcentroinformefacturacion;
  
        SELECT INTO ladeuda * FROM ctactedeudanoafil WHERE ctactedeudanoafil.idcomprobante = comprobantemovimiento
	                                     AND ctactedeudanoafil.idcomprobantetipos = 21;
  
        IF FOUND THEN 

            elimportetotal = ladeuda.importe* uninforme.gtoadmi/100;
		
            IF uninforme.nrocliente ='24' AND uninforme.barra=999 THEN --es AMUC
                  SELECT INTO lacuenta * FROM cuentascontables WHERE nrocuentac='40713';
            ELSE 
                  SELECT INTO lacuenta * FROM cuentascontables WHERE nrocuentac='40358';
            END IF;

       

	        UPDATE ctactedeudanoafil SET importe = round(CAST ((ladeuda.importe +elimportetotal) AS numeric),2),
                       saldo =round(CAST ((ladeuda.importe +elimportetotal) AS numeric),2)
         	WHERE ctactedeudanoafil.idcomprobante = comprobantemovimiento
	        AND ctactedeudanoafil.idcomprobantetipos = 21;


       END IF;
       
--ME fijo si la deuda esta en la nueva estructura de tablas
       
   SELECT INTO ladeudacliente * FROM ctactedeudacliente WHERE ctactedeudacliente.idcomprobante = comprobantemovimiento
	                                     AND ctactedeudacliente.idcomprobantetipos = 21;
  
        IF FOUND THEN 

            elimportetotal = ladeudacliente.importe* uninforme.gtoadmi/100;
		
            IF uninforme.nrocliente ='24' AND uninforme.barra=999 THEN --es AMUC
                  SELECT INTO lacuenta * FROM cuentascontables WHERE nrocuentac='40713';
            ELSE 
                  SELECT INTO lacuenta * FROM cuentascontables WHERE nrocuentac='40358';
            END IF;

       
      UPDATE ctactedeudacliente SET importe = round(CAST ((ladeudacliente.importe +elimportetotal) AS numeric),2),
                       saldo =round(CAST ((ladeudacliente.importe +elimportetotal) AS numeric),2)
         	WHERE ctactedeudacliente.idcomprobante = comprobantemovimiento
	        AND ctactedeudacliente.idcomprobantetipos = 21;


       END IF;

       
 INSERT INTO informefacturacionitem (nroinforme ,idcentroinformefacturacion,idcentroinformefacturacionitem,nrocuentac ,cantidad ,importe ,descripcion) 
		VALUES(uninforme.nroinforme,uninforme.idcentroinformefacturacion,uninforme.idcentroinformefacturacion,lacuenta.nrocuentac,1,
round(CAST ((elimportetotal) AS numeric),2) ,lacuenta.desccuenta);

   	                                     
	  
   END IF;


return true;
END;
$function$
