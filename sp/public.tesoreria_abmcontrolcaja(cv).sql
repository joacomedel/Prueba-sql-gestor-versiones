CREATE OR REPLACE FUNCTION public.tesoreria_abmcontrolcaja(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/

/****/
DECLARE

    rparam RECORD;
    respuesta character varying; 
--x convencion los nombres de record comienzan con r. Ademas de que es peligroso que se llame igual que la tabla
    rcontrolcaja record; 
    rcontrolcajadineroNueva record; 
    rcontrolcajadineroVieja record; 

    rc_controlcajadineroVieja refcursor;
    rc_rcontrolcajadineroNueva refcursor;
--x convencion los nombres de cursor comienzan con c 
    unaCaja record;
    vidcontrolcaja integer;
    vidcentrocontrolcaja integer;
    vaccion character varying; -- cerrar / editar
    aux character varying;


BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;
    vidcontrolcaja =rparam.idcontrolcaja;
    vidcentrocontrolcaja =rparam.idcentrocontrolcaja;
    vaccion = rparam.accion;
    SELECT INTO rcontrolcaja  * FROM tempcontrolcaja ;

    --ESTADOS
    -- 0 Abierta
    -- 1 Modificar 
    -- 2 Cerrada


   
    IF vaccion = 'abrir' THEN
        --Si accion cerrar 

        IF FOUND THEN
            UPDATE controlcajaestado SET ccidusuario=sys_dar_usuarioactual(),ccfechafin=now() 
            WHERE idcontrolcaja=vidcontrolcaja 
                AND idcentrocontrolcaja = vidcentrocontrolcaja
                AND idtipoestadoliquidaciontarjeta=2
                AND ccfechafin IS NULL;

            INSERT INTO controlcajaestado (idcontrolcaja, idcentrocontrolcaja,ccidusuario,idtipoestadoliquidaciontarjeta,ccfechafin,ccedescripcion)
            VALUES(vidcontrolcaja ,vidcentrocontrolcaja,sys_dar_usuarioactual(),0,NULL,'SP tesoreria_controlcaja_vincularcomprobante');     
        END IF;
    ELSE
       IF vaccion = 'cerrar' THEN 
            IF FOUND THEN
                -- Estado CERRADA 2
                UPDATE controlcajaestado SET ccidusuario=sys_dar_usuarioactual(),ccfechafin=now() 
                WHERE idcontrolcaja=vidcontrolcaja 
                    AND idcentrocontrolcaja = vidcentrocontrolcaja
                    AND idtipoestadoliquidaciontarjeta=0
                    AND ccfechafin IS NULL;

                INSERT INTO controlcajaestado (idcontrolcaja, idcentrocontrolcaja,ccidusuario,idtipoestadoliquidaciontarjeta,ccfechafin,ccedescripcion)
                    VALUES(vidcontrolcaja ,vidcentrocontrolcaja,sys_dar_usuarioactual(),2,null,'SP tesoreria_controlcaja_vincularcomprobante');   
            END IF;

           
        END IF;
             --FIJATE DE UPDATEAR SOLO SI el ccidcajero=25 sino no hace falta el update 
        UPDATE controlcaja SET ccidcajero = rcontrolcaja.ccidcajero
        WHERE idcontrolcaja=vidcontrolcaja AND idcentrocontrolcaja = vidcentrocontrolcaja;            


        --DROP para todas la tuplas existentes dentro de controlcajadinero de la caja en edicion 
        DELETE FROM controlcajadinero WHERE idcontrolcaja=vidcontrolcaja AND idcentrocontrolcaja = vidcentrocontrolcaja;

        -- inserto todos las tuplas que no tengan cero en cantidadapertura
        INSERT INTO controlcajadinero (denominacion,ccdcantidadapertura,ccdcantidadcierre,ccdtotal,idcontrolcaja,idcentrocontrolcaja) 
                SELECT moneda,cantidadapertura,cantidadcierre,total,vidcontrolcaja,vidcentrocontrolcaja
                FROM tempcontrolcajadinero 
                WHERE (cantidadapertura>0 OR cantidadcierre>0) AND idcontrolcaja=vidcontrolcaja AND idcentrocontrolcaja = vidcentrocontrolcaja;
    END IF; 
--
 

    respuesta = 'todook';
     
return respuesta;
END;

$function$
