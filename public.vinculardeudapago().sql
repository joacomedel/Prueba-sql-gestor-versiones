CREATE OR REPLACE FUNCTION public.vinculardeudapago()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES    

--REGISTROS
rvdeudapago RECORD;
relpago RECORD;

--CURSORES
cvincularDeudaPago CURSOR for SELECT * FROM temppagodeuda;



BEGIN


     OPEN cvincularDeudaPago;
     FETCH cvincularDeudaPago INTO rvdeudapago;

     WHILE FOUND LOOP

            IF (rvdeudapago.barra <100) THEN 

                   SELECT INTO relpago * FROM cuentacorrientepagos WHERE idcomprobante ilike (rvdeudapago.nrofactura*100)+rvdeudapago.nrosucursal 
                                           AND nrodoc = rvdeudapago.nrocliente AND tipodoc=rvdeudapago.barra;
                   IF FOUND THEN 
                            INSERT INTO cuentacorrientedeudapago (idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
                           VALUES (relpago.idpago,relpago.idcentropago,rvdeudapago.iddeuda,rvdeudapago.idcentrodeuda,CURRENT_TIMESTAMP, (-1*relpago.importe));

                            UPDATE cuentacorrientedeuda SET saldo =   round(CAST (saldo+relpago.importe AS numeric), 2)
                            WHERE iddeuda = rvdeudapago.iddeuda AND idcentrodeuda = rvdeudapago.idcentrodeuda;
           
                          
                   END IF; 
            ELSE 

                     SELECT INTO relpago * FROM ctactepagonoafil WHERE idcomprobante ilike (rvdeudapago.nrofactura*100)+rvdeudapago.nrosucursal 
                                           AND nrodoc = rvdeudapago.nrocliente AND tipodoc=rvdeudapago.barra;
IF FOUND THEN 
                             INSERT INTO ctactedeudapagonoafil(idpago,idcentropago,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
               VALUES (relpago.idpago,relpago.idcentropago,rvdeudapago.iddeuda,rvdeudapago.idcentrodeuda,CURRENT_TIMESTAMP, (-1*relpago.importe));

               UPDATE ctactedeudanoafil SET saldo =   round(CAST (saldo+relpago.importe AS numeric), 2)
                            WHERE iddeuda = rvdeudapago.iddeuda AND idcentrodeuda = rvdeudapago.idcentrodeuda;
           
                          
                   END IF; 
                 

           END IF; 
         

      FETCH cvincularDeudaPago into rvdeudapago;
      END LOOP;



 --   RETURN true;
END;
$function$
