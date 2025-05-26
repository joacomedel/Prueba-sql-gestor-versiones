CREATE OR REPLACE FUNCTION public.generardeudaordenesinstitucion(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se genera una nueva deuda vinculada al informe que se pasa por parametro
* Este SP es usado para los informes de AMUC y demas instituciones
* Tablas que se modifican: Informefacturacion,
*/

DECLARE
	--PARAMETROS
        idnroinforme alias for $1;
	
	--RECORDS
	elem RECORD;
        recdeuda RECORD;
        unconsumo RECORD;
        recdeudanoafil RECORD;
        relcliente RECORD;
        rctactecliente RECORD;

        --VARIABLES
	
        comprobantemovimiento BIGINT;
        movimientoconcepto VARCHAR;
        nrocuentacontable VARCHAR;      

        --CURSORES
        cursorconsumo refcursor;
         


		
BEGIN

SELECT INTO elem cliente.nrocliente,concat(cliente.cuitini,cliente.cuitmedio,cliente.cuitfin) as cuitcliente, if.nrocliente, cliente.barra as labarra
,sum(importe) AS importeinfo,idconcepto
-- CS 2018-07-23
-- el NroCuentaC depende del comprobante de venta, en lugar del cliente
/*KR 22-01-19 LAS cuentas contables quedaban nulas para aquellos casos donde la deuda se genera antes de que exista un comprobante de venta, para esos caso sigo poniendo la cta contable del cliente. Desde agosto habían deudas con cuentas contables nulas, ej de DASU hablado con maricel el 22-01*/
,CASE WHEN nullvalue(darctacontablecomprobanteventa($1,centro())) THEN darctacontablecliente(if.nrocliente,if.barra, if.idinformefacturaciontipo)  
ELSE darctacontablecomprobanteventa($1,centro()) END as nrocuentac
--,darctacontablecliente(if.nrocliente,if.barra, if.idinformefacturaciontipo) as nrocuentac
-----------------------------------------------------------------------
, cliente.denominacion as abreviatura
,concat('Suc ',nrosucursal,'-',nrofactura,' ',idtipofactura,' ' ,desccomprobanteventa) as comprobanteventa 
,clientectacte.idclientectacte,if.fechainforme	
 FROM cliente NATURAL JOIN clientectacte NATURAL JOIN informefacturacion AS if LEFT JOIN tipocomprobanteventa ON(if.tipocomprobante=tipocomprobanteventa.idtipo) 	
  NATURAL JOIN informefacturaciontipo AS ift
 JOIN informefacturacionitem USING(nroinforme,idcentroinformefacturacion)
WHERE informefacturacionitem.nroinforme = $1 AND informefacturacionitem.idcentroinformefacturacion= centro()
GROUP BY cliente.nrocliente, cuitcliente, if.nrocliente, cliente.barra,idconcepto,if.barra ,ift.nrocuentac,cliente.denominacion,if.idinformefacturaciontipo,if.idtipofactura , if.nrosucursal
                    ,if.nrofactura,desccomprobanteventa,clientectacte.idclientectacte,if.fechainforme;

IF FOUND THEN -- MaLaPi 15-12-2017 solo si es un cliente, y no un PRESTADOR tiene que ejecutar parte o algo de este SP.       
    
    --Si el informe es de una obra social x reciprocidad cancelo la deuda de las ordenes 

 --  IF elem.barra <> 999 and elem.nrocliente <>'24' THEN 

---Genero la deuda del informe 

     
     -- nrocuentacontable = '10325'; --Deudores x convenio RECIPROCIDAD

    OPEN cursorconsumo FOR SELECT * FROM informefacturacionreciprocidad NATURAL JOIN orden 
WHERE informefacturacionreciprocidad.nroinforme = $1 AND informefacturacionreciprocidad.idcentroinformefacturacion= centro();
 
  FETCH cursorconsumo into unconsumo;
 WHILE found LOOP

   movimientoconcepto = concat('Cancelación de deuda de orden ' ,to_char(unconsumo.nroorden,'00000000') , '-' , to_char(unconsumo.centro,'000') , ' por creacion de informe nro ' , idnroinforme) ;
 comprobantemovimiento = unconsumo.nroorden * 100 + unconsumo.centro;

--Busco la deuda de la orden

 SELECT INTO recdeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobantetipos = unconsumo.tipo
				AND cuentacorrientedeuda.idcomprobante = comprobantemovimiento;
   IF FOUND THEN 
 --      RAISE EXCEPTION 'nrocliente  % %',elem.nrocliente,comprobantemovimiento;
 
   INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
VALUES (21,elem.labarra,elem.abreviatura,CURRENT_TIMESTAMP,movimientoconcepto,'50350',recdeuda.importe * (- 1::double precision),comprobantemovimiento,0,999,elem.nrocliente);
			                
INSERT INTO cuentacorrientedeudapago(iddeuda,idcentrodeuda,idpago,idcentropago,fechamovimientoimputacion,importeimp)
VALUES (recdeuda.iddeuda,recdeuda.idcentrodeuda,currval('cuentacorrientepagos_idpago_seq'),centro(),CURRENT_TIMESTAMP,recdeuda.saldo);

UPDATE cuentacorrientedeuda SET saldo = 0 WHERE cuentacorrientedeuda.iddeuda = recdeuda.iddeuda
AND cuentacorrientedeuda.idcentrodeuda = recdeuda.idcentrodeuda;

  END IF;
  FETCH cursorconsumo into unconsumo;
  END LOOP;

close cursorconsumo;	

--ELSE      nrocuentacontable = '10323'; --Deudores x AMUC

--END IF;

 movimientoconcepto = concat('Informe: ' ,idnroinforme , ' - ' , centro(), '. Comprobante: ',elem.comprobanteventa);
  
 comprobantemovimiento = idnroinforme * 100 +centro();
    

  
--busco si ya existe una deuda para ese informe
 
  SELECT INTO recdeudanoafil * FROM ctactedeudanoafil WHERE ctactedeudanoafil.idcomprobante = comprobantemovimiento
                                   AND ctactedeudanoafil.idcomprobantetipos = 21;

  IF FOUND THEN
       
            UPDATE ctactedeudanoafil SET saldo =  round(CAST (elem.importeinfo AS numeric), 2), 
                            importe =  round(CAST (elem.importeinfo AS numeric), 2)
            WHERE iddeuda = recdeudanoafil.iddeuda AND idcentrodeuda = recdeudanoafil.idcentrodeuda;
	
  ELSE      
  

    INSERT INTO ctactedeudanoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,
                     importe,idcomprobante,saldo,idconcepto,nrodoc)
	  VALUES (21,elem.labarra,elem.cuitcliente,elem.fechainforme,movimientoconcepto,elem.nrocuentac,elem.importeinfo,comprobantemovimiento,
                    elem.importeinfo,elem.idconcepto,elem.nrocliente);



  END IF; --DE deuda para ese cliente

  SELECT INTO rctactecliente * FROM ctactedeudacliente WHERE ctactedeudacliente.idcomprobante = comprobantemovimiento
                                   AND ctactedeudacliente.idcomprobantetipos = 21;

 
        	
	        
  IF FOUND THEN
                UPDATE ctactedeudacliente SET saldo =  round(CAST (elem.importeinfo AS numeric), 2), 
                           importe =  round(CAST (elem.importeinfo AS numeric), 2)
               WHERE iddeuda = rctactecliente.iddeuda AND idcentrodeuda = rctactecliente.idcentrodeuda;
	
  ELSE      
 
           INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,fechamovimiento,movconcepto,nrocuentac,
                     importe,idcomprobante,saldo,fechavencimiento)
	  VALUES  (21,elem.idclientectacte,elem.fechainforme,movimientoconcepto,elem.nrocuentac,elem.importeinfo,comprobantemovimiento,
                    elem.importeinfo,current_date+30);
 END IF; --DEL IF FOUND

 END IF; -- Del IF FOUND de elem
                 



return true;
end;$function$
