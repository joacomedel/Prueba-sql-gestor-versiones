CREATE OR REPLACE FUNCTION public.tesoreria_vincular_controlcaja(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
rparam RECORD;
    respuesta character varying; 

    vidcontrolcaja integer;
    vidcentrocontrolcaja integer;
    --vnrofactura integer; 
    --vtipofactura character varying(2);
    --vnrosucursal bigint;
    --vtipocomprobante integer;

    rcontrolcajafacturaventa record; 
    rcontrolcajarecibo record; 
    rcontrolcaja record;

    vidcontrolcajanuevo integer;
    vidcentrocontrolcajanuevo integer;
    vaccion character varying; -- cerrar / editar / desvincular


    --Cursores 
    cfactventa CURSOR FOR SELECT  * FROM tempcontrolcajafacturaventa;
    crecibos CURSOR FOR SELECT * FROM tempcontrolcajarecibos;


BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;
    vidcontrolcaja =rparam.idcontrolcaja;
    vidcentrocontrolcaja =rparam.idcentrocontrolcaja;
    vaccion = rparam.accion;

    

   
    IF vaccion = 'vincular' THEN

        open cfactventa;
        FETCH cfactventa into rcontrolcajafacturaventa;
        WHILE FOUND LOOP
            UPDATE controlcajafacturaventa SET idcontrolcaja=vidcontrolcaja,idcentrocontrolcaja = vidcentrocontrolcaja 
            WHERE 
                idcontrolcajafacturaventa=rcontrolcajafacturaventa.idcontrolcajafacturaventa
                AND centro =rcontrolcajafacturaventa.centro
                AND idcontrolcaja=rcontrolcajafacturaventa.idcontrolcaja 
                AND idcentrocontrolcaja = rcontrolcajafacturaventa.idcentrocontrolcaja
                
                AND nrofactura = rcontrolcajafacturaventa.nrofactura 
                AND tipofactura = rcontrolcajafacturaventa.tipofactura 
                AND nrosucursal = rcontrolcajafacturaventa.nrosucursal
                AND tipocomprobante = rcontrolcajafacturaventa.tipocomprobante;
            FETCH cfactventa into rcontrolcajafacturaventa;
        END LOOP;
        CLOSE cfactventa;
     
        open crecibos;
        FETCH crecibos into rcontrolcajarecibo;
        WHILE FOUND LOOP
            UPDATE controlcajarecibo SET idcontrolcaja=vidcontrolcaja,idcentrocontrolcaja = vidcentrocontrolcaja 
            WHERE idcontrolcaja=rcontrolcajarecibo.idcontrolcaja 
                AND idcentrocontrolcaja = rcontrolcajarecibo.idcentrocontrolcaja
                AND idcontrolcajarecibo = rcontrolcajarecibo.idcontrolcajarecibo
                AND idcentrocontrolcajarecibo = rcontrolcajarecibo.idcentrocontrolcajarecibo;
            FETCH crecibos into rcontrolcajarecibo;
        END LOOP;
        CLOSE crecibos;
    ELSE
        IF vaccion = 'desvincular' THEN
            -- Busco la cja abierta de siges (25)
            SELECT INTO rcontrolcaja *
            FROM controlcaja
            NATURAL JOIN controlcajaestado
            WHERE ccidcajero=25
                AND  nullvalue(ccfechafin) AND idtipoestadoliquidaciontarjeta=0
                AND     idcentrocontrolcaja =centro();   

            open cfactventa;
                FETCH cfactventa into rcontrolcajafacturaventa;
                WHILE FOUND LOOP
                    UPDATE controlcajafacturaventa SET idcontrolcaja=rcontrolcaja.idcontrolcaja,idcentrocontrolcaja = rcontrolcaja.idcentrocontrolcaja 
                    WHERE 
                        idcontrolcajafacturaventa=rcontrolcajafacturaventa.idcontrolcajafacturaventa
                        AND centro =rcontrolcajafacturaventa.centro
                        AND idcontrolcaja=rcontrolcajafacturaventa.idcontrolcaja 
                        AND idcentrocontrolcaja = rcontrolcajafacturaventa.idcentrocontrolcaja
                        
                        AND nrofactura = rcontrolcajafacturaventa.nrofactura 
                        AND tipofactura = rcontrolcajafacturaventa.tipofactura 
                        AND nrosucursal = rcontrolcajafacturaventa.nrosucursal
                        AND tipocomprobante = rcontrolcajafacturaventa.tipocomprobante;
                    FETCH cfactventa into rcontrolcajafacturaventa;
                END LOOP;
                CLOSE cfactventa;
             
                open crecibos;
                FETCH crecibos into rcontrolcajarecibo;
                WHILE FOUND LOOP
                    UPDATE controlcajarecibo SET idcontrolcaja=rcontrolcaja.idcontrolcaja,idcentrocontrolcaja = rcontrolcaja.idcentrocontrolcaja 
                    WHERE idcontrolcaja=rcontrolcajarecibo.idcontrolcaja 
                        AND idcentrocontrolcaja = rcontrolcajarecibo.idcentrocontrolcaja
                        AND idcontrolcajarecibo = rcontrolcajarecibo.idcontrolcajarecibo
                        AND idcentrocontrolcajarecibo = rcontrolcajarecibo.idcentrocontrolcajarecibo;
                    FETCH crecibos into rcontrolcajarecibo;
                END LOOP;
                CLOSE crecibos;
        END IF; 
    END IF; 
    respuesta = 'todook';

return respuesta;
END;
$function$
