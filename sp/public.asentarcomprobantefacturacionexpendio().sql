CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturacionexpendio()
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$DECLARE
    
 
--VARIABLES   
tipoorden integer;
elidusuario integer;
vimportefv double precision;
todook VARCHAR;
--REGISTROS
rorden record;
elcomprobante RECORD;
rverificactacte RECORD;
rimporte  RECORD;
rusuario record;

--CURSORES
corden CURSOR FOR SELECT * FROM temporden;


BEGIN


    SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
    open corden;
    FETCH corden into rorden;
    WHILE FOUND LOOP
                 --KR 21-03-22 corroboro que la orden no este en otro comprobante
                 SELECT INTO todook * FROM cajadiaria_controlordenfactura(concat('{nroorden=' , rorden.nroorden, ',centro=',rorden.centro,' , idcomprobantetipos= ',rorden.idcomprobantetipos,',tipofactura =',elcomprobante.tipofactura, '}'));
    
                 tipoorden = rorden.idcomprobantetipos;
                 INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,  nrofactura, nroorden, centro, idcomprobantetipos)
                 VALUES(elcomprobante.tipocomprobante,elcomprobante.nrosucursal, elcomprobante.tipofactura,elcomprobante.nrofactura,
                 rorden.nroorden,rorden.centro,rorden.idcomprobantetipos);

                /* ELIMINO LOS PENDIENTES DE FACTURACION */
                 IF (elcomprobante.tipofactura ='FA') THEN 
                            DELETE from ordenessinfacturas WHERE nroorden=  rorden.nroorden AND centro=rorden.centro;
                            DELETE from itemordenessinfactura WHERE nroorden=  rorden.nroorden AND centro=rorden.centro;
                 ELSE
                            DELETE from notascreditospendientes WHERE nroorden=  rorden.nroorden AND centro=rorden.centro;

                 END IF; 

      FETCH corden into rorden;
      END LOOP;
      CLOSE corden;

      /* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF not found THEN
             elidusuario = 25;
    ELSE
        elidusuario = rusuario.idusuario;
    END IF;
    INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
     VALUES   (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.nrofactura, elcomprobante.tipofactura,elidusuario,elcomprobante.nrofactura);
   
/* KR 24-11-20 Si la orden es de SUAP no se genera movimiento en la cta cte ya que ahora se realiza desde el enviar a pagar la MP y anular la MP 
   MaLaPi 12/05/2021 Si la Orden se Factura, debe actualziar la Cta Cte. En el paso siguiente se verifica si la orden ya afecto la cta cte para que no la vuelva a afectar   

SELECT INTO rverificactacte * 
     FROM facturaorden NATURAL JOIN orden 
     WHERE nrosucursal = elcomprobante.nrosucursal AND nrofactura = elcomprobante.nrofactura 
        AND tipocomprobante= elcomprobante.tipocomprobante AND tipofactura = elcomprobante.tipofactura AND orden.tipo=56;
   IF NOT FOUND THEN 
       PERFORM generarconsumoctacte(concat('{','nrosucursal=',elcomprobante.nrosucursal, ',nrofactura=',elcomprobante.nrofactura, ',tipocomprobante=',elcomprobante.tipocomprobante, ',tipofactura=',elcomprobante.tipofactura,'}'));    
   END IF;
*/  

     --MaLaPi 20-07-2020 Solo genero deuda con la factura, si la orden no la genero antes.
     --MaLaPi 12-05-2021 Se pone de nuevo en marcha que si se factura una orden de suap, se debe enviar a la cta cte
/*  KR 22-06-21 AHORA el mvto en la cta cte se genera desde el comprobante! En el SP asentarcomprobantefacturacion

 SELECT INTO rverificactacte * 
     FROM facturaorden
     LEFT JOIN cuentacorrientedeuda ON facturaorden.idcomprobantetipos = cuentacorrientedeuda.idcomprobantetipos AND cuentacorrientedeuda.idcomprobantetipos= 56 AND idcomprobante = concat(facturaorden.nroorden,TRIM(LPAD(facturaorden.centro, 2, '0'))) 
     WHERE nrosucursal = elcomprobante.nrosucursal AND nrofactura = elcomprobante.nrofactura 
        AND tipocomprobante= elcomprobante.tipocomprobante AND tipofactura = elcomprobante.tipofactura
         AND nullvalue(cuentacorrientedeuda.iddeuda);
     IF FOUND THEN 
       --KR 16-09-19 se toca la cta cte al emitir una FA si la forma de pago es cta cte
     PERFORM generarconsumoctacte(concat('{','nrosucursal=',elcomprobante.nrosucursal, ',nrofactura=',elcomprobante.nrofactura, ',tipocomprobante=',elcomprobante.tipocomprobante, ',tipofactura=',elcomprobante.tipofactura,'}'));
     ELSE 
        IF (elcomprobante.tipofactura='NC') THEN 
           PERFORM generarconsumoctacte(concat('{','nrosucursal=',elcomprobante.nrosucursal, ',nrofactura=',elcomprobante.nrofactura, ',tipocomprobante=',elcomprobante.tipocomprobante, ',tipofactura=',elcomprobante.tipofactura,'}'));
        END IF;
     END IF;
*/   
     SELECT INTO vimportefv (importeefectivo+importedebito+importecredito+importectacte) 
     FROM facturaventa as fv 
     WHERE nrosucursal = elcomprobante.nrosucursal AND nrofactura = elcomprobante.nrofactura AND tipocomprobante= elcomprobante.tipocomprobante AND tipofactura = elcomprobante.tipofactura;

     IF vimportefv = 0.0 THEN 
           RAISE EXCEPTION ' El importe de un comprobante NO puede ser igual a 0.0 !! %', elcomprobante USING HINT = 'Verificar el comprobante de facturacion impreso.';
       
     END IF; 
      
   
    
    RETURN NEXT elcomprobante;
END;

$function$
