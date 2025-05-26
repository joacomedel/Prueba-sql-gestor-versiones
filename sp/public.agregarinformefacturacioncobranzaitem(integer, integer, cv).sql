CREATE OR REPLACE FUNCTION public.agregarinformefacturacioncobranzaitem(integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se guarda la informacion de los items del informe de facturacion cuyo numero se pasa por parametro
* Este SP es usado para insertar items de los informes de AMUC
* Tablas que se modifican: Informefacturacion,informefacturacionestado,informefacturacionitem
*/

DECLARE
	--PARAMETROS
        idnroinforme alias for $1;
        idcentro alias for $2;
	--RECORDS
         elem RECORD;

    --VARIABLES
	resultado boolean;
	cursoritem refcursor;
			
BEGIN

     resultado = true;
     IF ($3 ILIKE 'descuentounc' or $3 ILIKE 'institucion') THEN
            INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
              (SELECT idcentro,idnroinforme,d.nrocuentac, 1,sum(ccdp.importeimp) as importe , cuentascontables.desccuenta
                        FROM
                            (SELECT DISTINCT ON(idpago) idpago, idcentropago,nroinforme,idcentroinformefacturacion
                            FROM informefacturacioncobranza JOIN ctactepagonoafil as p USING(idpago,idcentropago)
                            WHERE nroinforme = idnroinforme AND idcentroinformefacturacion= idcentro
                            GROUP BY idpago, idcentropago,nroinforme, idcentroinformefacturacion ) AS tt
                        JOIN ctactedeudapagonoafil as ccdp ON(tt.idpago= ccdp.idpago AND tt.idcentropago=ccdp.idcentropago)
                        JOIN ctactedeudanoafil as d USING(iddeuda,idcentrodeuda)
                        JOIN cuentascontables ON(d.nrocuentac = cuentascontables.nrocuentac)
                        GROUP BY d.nrocuentac, cuentascontables.desccuenta);
     ELSE
          INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
        (  SELECT idcentro,idnroinforme,d.nrocuentac, 1,sum(ccdp.importeimp) as importe , cuentascontables.desccuenta
                        FROM
                            (SELECT DISTINCT ON(idpago) idpago, idcentropago,nroinforme,idcentroinformefacturacion
                            FROM informefacturacioncobranza JOIN cuentacorrientepagos as p USING(idpago,idcentropago)
                            WHERE nroinforme = idnroinforme AND idcentroinformefacturacion= idcentro
                            GROUP BY idpago, idcentropago,nroinforme, idcentroinformefacturacion ) AS tt
                        JOIN cuentacorrientedeudapago as ccdp ON(tt.idpago= ccdp.idpago AND tt.idcentropago=ccdp.idcentropago)
                        JOIN cuentacorrientedeuda as d USING(iddeuda,idcentrodeuda)
                        JOIN cuentascontables ON(d.nrocuentac = cuentascontables.nrocuentac)
                        GROUP BY d.nrocuentac, cuentascontables.desccuenta);


     
     END IF;
   
      return true;
end;
$function$
