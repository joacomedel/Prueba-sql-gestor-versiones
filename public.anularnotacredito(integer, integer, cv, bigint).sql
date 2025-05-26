CREATE OR REPLACE FUNCTION public.anularnotacredito(integer, integer, character varying, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE
    elem RECORD;
    resp BOOLEAN;
    desimputar boolean; --BelenA 10-04-24 agrego
    todook VARCHAR;
    --BelenA 10-04-24 agrego
    xctacte varchar;
    rdatosfact RECORD;  
    xpago RECORD;
    rdeuda RECORD;  
    cursordeudas REFCURSOR;

    --temporal que tiene los datos de la factura a anular
    anularcred CURSOR FOR SELECT * FROM facturaorden JOIN orden USING (nroorden,centro)
                JOIN facturaventa USING (nrosucursal,nrofactura,tipofactura,tipocomprobante)
                WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2;
    reganularcred RECORD;

    --cursor que tiene los datos si la nota de credito a anular corresponde a un informe
    anularnotacreditoinfo CURSOR FOR SELECT * FROM facturaventa
               JOIN informefacturacion USING (nrosucursal,nrofactura,tipofactura,tipocomprobante)
                WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2;
    reganularnotacreditoinfo RECORD;

BEGIN

    -- BelenA 10-04-24 modifico toda la forma de desimputar si tiene deuda y ya no crea el movimiento nuevo en la ctacte del
    -- "Genera deuda por anulacion de NC..."
    -- Agrego para llamar al desimputar 
    CREATE TEMP TABLE cuentacorrientedeudapagodesimputar (ccdpdobservacion varchar , iddeuda    bigint ,idcentrodeuda   integer, idpago bigint,idcentropago integer,                origenctacte varchar);

    -- Busco los datos de la factura
    SELECT INTO rdatosfact * FROM facturaventa WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2;
    open anularcred;
    fetch anularcred into reganularcred;
     WHILE FOUND LOOP
           INSERT INTO notascreditospendientes(nroorden,centro,tpoexpendio,nrodoc,tipodoc)     VALUES

        (reganularcred.nroorden,reganularcred.centro,CURRENT_TIMESTAMP,reganularcred.nrodoc,reganularcred.tipodoc);
           fetch anularcred into reganularcred;
     END LOOP;
    close anularcred; 



    desimputar = false;

    -- Obtengo los datos del pago asociados a la NC para un afiliado
    xctacte = 'afiliadoctacte';
    SELECT INTO xpago 1 as ctacte, *
    FROM informefacturacion  
    JOIN cuentacorrientepagos ON (idcomprobante=concat(nroinforme*100+idcentroinformefacturacion)::varchar )
    WHERE nrofactura=rdatosfact.nrofactura AND tipofactura= 'NC' AND nrosucursal = rdatosfact.nrosucursal ;
    /*movconcepto ilike 
    concat ('',concat('%NC ',rdatosfact.centro, ' ', rdatosfact.nrofactura, ' %'),'' ) ;*/

    IF FOUND THEN
        -- Busco si esta imputado a una deuda en la cuenta del afiliado
        -- Uso un cursor porque puede tener más de una deuda
        open cursordeudas FOR 
            SELECT   iddeuda, idcentrodeuda, SUM(importeimp) AS importeimp
            FROM cuentacorrientepagos 
            NATURAL JOIN cuentacorrientedeudapago 
            WHERE idpago=xpago.idpago and idcentropago=xpago.idcentropago
            GROUP BY iddeuda, idcentrodeuda ;
        
            fetch cursordeudas into rdeuda;
            WHILE FOUND LOOP
                   INSERT INTO cuentacorrientedeudapagodesimputar(ccdpdobservacion, iddeuda ,idcentrodeuda, origenctacte, idpago, idcentropago ) 
                   VALUES ( concat('Anulacion de NC - ', xpago.movconcepto) ,rdeuda.iddeuda,rdeuda.idcentrodeuda,xctacte, xpago.idpago ,xpago.idcentropago);
                desimputar = true;
            fetch cursordeudas into rdeuda;
            END LOOP;
            close cursordeudas; 

    ELSE
        -- Si no es pago de afiliado, es de cliente/adherente
        xctacte = 'clientectacte';
        SELECT INTO xpago 2 as ctacte, *
        FROM informefacturacion  
        JOIN ctactepagocliente ON (idcomprobante=concat(nroinforme*100+idcentroinformefacturacion)::varchar )
        WHERE nrofactura=rdatosfact.nrofactura AND tipofactura= 'NC' AND nrosucursal = rdatosfact.nrosucursal;

        -- Busco si esta imputado a una deuda en la cuenta del cliente
        -- Uso un cursor porque puede tener más de una deuda
        open cursordeudas FOR  
            SELECT   iddeuda, idcentrodeuda, SUM(importeimp) AS importeimp
            FROM ctactepagocliente 
            NATURAL JOIN ctactedeudapagocliente 
            WHERE idpago=xpago.idpago and idcentropago=xpago.idcentropago 
            GROUP BY iddeuda, idcentrodeuda ;

            fetch cursordeudas into rdeuda;
            WHILE FOUND LOOP
                   INSERT INTO cuentacorrientedeudapagodesimputar(ccdpdobservacion, iddeuda ,idcentrodeuda, origenctacte, idpago, idcentropago ) 
                   VALUES ( concat('Anulacion de NC - ', xpago.movconcepto) ,rdeuda.iddeuda,rdeuda.idcentrodeuda,xctacte, xpago.idpago ,xpago.idcentropago);
                desimputar = true;
            fetch cursordeudas into rdeuda;
            END LOOP;
            close cursordeudas; 
    END IF;

    IF (desimputar) THEN
        -- Llamo al SP que va a desimputar los movimientos
        PERFORM tesoreria_desimputar_cuentascorrientes();
    END IF;
        -- Pongo el pago en 0 tanto importe como saldo y le concateno la anulacion
    IF ( xpago.ctacte = 1) THEN
    -- 1  xctacte = 'afiliadoctacte';
        UPDATE cuentacorrientepagos
        SET importe=0 , saldo=0, movconcepto=concat('Anulacion de NC - ', xpago.movconcepto)
        WHERE idpago=xpago.idpago AND idcentropago=xpago.idcentropago;

    ELSE
    -- 2  xctacte = 'clientectacte';
        UPDATE ctactepagocliente
        SET importe=0 , saldo=0, movconcepto=concat('Anulacion de NC - ', xpago.movconcepto)
        WHERE idpago=xpago.idpago AND idcentropago=xpago.idcentropago;

    END IF;




    open anularnotacreditoinfo;
    fetch anularnotacreditoinfo into reganularnotacreditoinfo;
    -- Creo la tabla para guardar los items del informe de facturacion
         CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

     WHILE FOUND LOOP

               SELECT INTO resp * FROM   anularnotacreditoinforme(reganularnotacreditoinfo.nroinforme,reganularnotacreditoinfo.idcentroinformefacturacion,reganularnotacreditoinfo.idinformefacturaciontipo);

         DELETE FROM  ttinformefacturacionitem;
     fetch anularnotacreditoinfo into reganularnotacreditoinfo;
     END LOOP;
    close anularnotacreditoinfo;

    return true;
END;
$function$
