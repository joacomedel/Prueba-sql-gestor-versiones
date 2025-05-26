CREATE OR REPLACE FUNCTION public.ingresarconsumoturismososunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que ingresa la deuda de sosunc con la unidad de un consumo turismoen particular */
DECLARE
   rinfoconsumo RECORD;
   elconsumoprestamo RECORD;
   elconsumo RECORD;
   laspersonas RECORD;
   rvalores RECORD;
   elidconsumo integer;
   elidcentroconsumo integer;
   cuentacontable integer;
   imptotaldelconsumososunc DOUBLE PRECISION;
   importeconsumoafiliado DOUBLE PRECISION;
   impdescuentoafil  DOUBLE PRECISION;
   descuentososunc  DOUBLE PRECISION;
BEGIN
     cuentacontable = 4450;
     SELECT INTO rinfoconsumo * 
     FROM infoconsumo;
     elidconsumo = rinfoconsumo.idconsumoturismo;
     elidcentroconsumo =   rinfoconsumo.idcentroconsumoturismo;      

     /* REcupero los datos del prestamos y del consumo */ 
     -- ctdescuento , importeprestamo
     SELECT INTO  elconsumoprestamo  *
     FROM consumoturismo
     NATURAL JOIN prestamo
     WHERE idconsumoturismo = elidconsumo
                and idcentroconsumoturismo = elidcentroconsumo;  
     impdescuentoafil = elconsumoprestamo.ctdescuento ;
     importeconsumoafiliado = impdescuentoafil + elconsumoprestamo.importeprestamo;
 
     /* Recupero la cantidad de invitados y de personas del consumo*/
     SELECT INTO laspersonas SUM(cantperinvitado)as cantperinvitado,SUM(cantper)as cantperso         
     FROM (         
           SELECT idconsumoturismo ,idcentroconsumoturismo, count(*) as cantperinvitado,0 as cantper
           FROM grupoacompaniante         
           WHERE invitado   
                and idconsumoturismo = elidconsumo
                and idcentroconsumoturismo = elidcentroconsumo                           
           GROUP by idconsumoturismo ,idcentroconsumoturismo         
           UNION         
           SELECT idconsumoturismo ,idcentroconsumoturismo, 0 as cantperinvitado, count(*) as cantper         
           FROM grupoacompaniante         
           WHERE not invitado 
                 and idconsumoturismo = elidconsumo
                and idcentroconsumoturismo = elidcentroconsumo                         
           GROUP by idconsumoturismo ,idcentroconsumoturismo         
          ) as CP         
     GROUP by idconsumoturismo ,idcentroconsumoturismo;        

     /* Recupero los valores del consumo */

     SELECT INTO rvalores * 
     FROM turismounidad 
     NATURAL JOIN consumoturismovalores         
     NATURAL JOIN turismounidadvalor 
     WHERE idconsumoturismo = elidconsumo
           and idcentroconsumoturismo = elidcentroconsumo;
    
     IF(rvalores.tuvporpersona)THEN
          imptotaldelconsumososunc = (rvalores.tuvimportesosunc * rvalores.ctvcantdias * rvalores.cantperso)+ (rvalores.tuvimporteinvitadososunc * rvalores.ctvcantdias * rvalores.cantperinvitado);

     ELSE
            imptotaldelconsumososunc =  (rvalores.tuvimportesosunc * rvalores.ctvcantdias);
     END IF;

     /* Calculo la proporcion de descuento aplicado sobre el importe del consumo  pagado por afiliado para aplicarlo al importe que debe pagar sosunc   importeafiliado/descuento = importesosunc / x       */
     descuentososunc =  (imptotaldelconsumososunc * impdescuentoafil) /importeconsumoafiliado;
     imptotaldelconsumososunc = imptotaldelconsumososunc - descuentososunc;  

    /*??????  Generar dos deudas en la cuenta corriente del administrador una correspondiente al 30 % o seña y la otra = resto */
     INSERT INTO cuentacorrientedeuda (idcomprobantetipos ,tipodoc , idctacte ,
          fechamovimiento ,movconcepto, nrocuentac ,importe ,
          idcomprobante ,fechaenvio ,saldo,idconcepto , nrodoc , idcentrodeuda
     )VALUES(7 , 333 , (rvalores.idturismoadmin * 1000)+333 ,
          now() ,concat('Deuda consumo con administrador consumo turismo ',elidconsumo ,'-',elidcentroconsumo) ,
          cuentacontable ,imptotaldelconsumososunc ,       (elidconsumo*10)+elidcentroconsumo,elconsumoprestamo.ctfechasalida ,
          imptotaldelconsumososunc, 330 , rvalores.idturismoadmin , centro()
     );



     SELECT INTO elconsumo * FROM consumoturismo 
     WHERE idconsumoturismo = elidconsumo
           and idcentroconsumoturismo = elidcentroconsumo;

RETURN TRUE;
END;
$function$
