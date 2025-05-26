CREATE OR REPLACE FUNCTION public.guardardatospagoordenpagomultivac()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES

    iddoc INTEGER;
    personaOrigen integer;


--REGISTROS

    regmp RECORD;
    regfact RECORD;
    rfactura RECORD;
    rreclibrofact RECORD;
    rcambioestado RECORD;
    rordenpagomultivacdatospago RECORD;

--CURSORES

    cursormp refcursor;
    cursorfact refcursor;

BEGIN

   OPEN cursormp FOR SELECT * FROM tempordenpagomultivacdatospago;

   FETCH cursormp INTO regmp;

   WHILE FOUND LOOP

         IF (not nullvalue(regmp.idbancatransferencia)) THEN
                  UPDATE bancatransferencia SET btprocesado = now()
                   WHERE idbancatransferencia = regmp.idbancatransferencia;
         END IF;
         
         
        SELECT INTO rcambioestado * FROM cambioestadoordenpagomultivac
               WHERE nroordenpago = regmp.nroordenpago AND idtipoestadoordenpago = 3;
        IF NOT FOUND THEN
                 INSERT INTO cambioestadoordenpagomultivac (fechacambio,nroordenpago,idtipoestadoordenpago,motivo)
                 VALUES(CURRENT_DATE,regmp.nroordenpago,3,regmp.motivo);
        END IF;

        SELECT INTO rreclibrofact * FROM reclibrofact as r JOIN mapeocompcompras as m on r.idrecepcion=m.idrecepcion

                                    WHERE m.idcomprobantemultivac =regmp.idcomprobantemultivac;
        IF FOUND THEN
        -- Inserto datos del pago
        SELECT INTO rordenpagomultivacdatospago *
               FROM ordenpagomultivacdatospago
               WHERE nroordenpago =regmp.nroordenpago
               AND nrooperacion = regmp.nrooperacion
               AND nroopsiges = regmp.nroopsiges
               AND nroregistro = rreclibrofact.numeroregistro
               AND anio = rreclibrofact.anio;
        IF NOT FOUND THEN
         INSERT INTO ordenpagomultivacdatospago(fechaoperacion,nroordenpago,nrooperacion,cuentasosunc,tipoformapago,importe,observaciones,nroopsiges,nroregistro,anio,importepagadocomp)
         VALUES (regmp.fechaoperacion, regmp.nroordenpago, regmp.nrooperacion,regmp.cuentasosunc,regmp.tipoformapago,regmp.importe,regmp.observaciones,regmp.nroopsiges,rreclibrofact.numeroregistro,rreclibrofact.anio,regmp.importepagadocomp);

                SELECT INTO rfactura * FROM factura WHERE factura.nroregistro = rreclibrofact.numeroregistro
                                                          AND factura.anio = rreclibrofact.anio;
                IF FOUND THEN
                -- Si es un comprobante auditabble, lo cambio de estado a historico
                          INSERT INTO festados(fechacambio,nroregistro,anio,tipoestadofactura,observacion)
                          VALUES(CURRENT_DATE,rfactura.nroregistro,rfactura.anio,8,'Modificado desde el SP guardardatospagoordenpagomultivac');
                END IF;
        END IF;
        END IF;
        FETCH cursormp INTO regmp;

    END LOOP;

    CLOSE cursormp;

return iddoc;

END;
$function$
