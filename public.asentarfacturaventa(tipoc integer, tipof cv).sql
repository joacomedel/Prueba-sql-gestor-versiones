CREATE OR REPLACE FUNCTION public.asentarfacturaventa(tipoc integer, tipof character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
elem RECORD;
esbeneficiario RECORD;
ordenesgeneradas Cursor for select * from ttorden;
torden record;
itemv RECORD;
tdoc INTEGER;
sumaimporte double precision;
items CURSOR FOR SELECT * FROM ttitems NATURAL JOIN practica NATURAL JOIN cuentascontables ORDER BY nrocuentac;
--importevalorizada double precision;
importevalorizada numeric(10,2);
nrocuenta VARCHAR;
cantidad1 INTEGER;
nrodocumento VARCHAR;
descripcionactual text;
tieneamuc boolean;
porcentajereal double precision;
formadepagocalculada integer;

BEGIN

open ordenesgeneradas;
fetch ordenesgeneradas into torden;
sumaimporte = torden.efectivo+torden.debito+torden.credito+torden.cuentacorriente; ---torden.amuc-torden.sosunc;
CREATE TEMP TABLE ttfacturasgeneradas(
           tipocomprobante integer,
           nrosucursal integer,
           tipofactura varchar(2),
           nrofactura bigint
    ) WITHOUT OIDS;




SELECT into tdoc tipodoc FROM persona WHERE nrodoc = torden.nrodoc;

select into esbeneficiario nrodoctitu,tipodoctitu from benefsosunc
where (benefsosunc.nrodoc = torden.nrodoc and benefsosunc.tipodoc=tdoc);
if found  then
       nrodocumento=esbeneficiario.nrodoctitu;
       tdoc=esbeneficiario.tipodoctitu;
  else
      nrodocumento=torden.nrodoc;
end if;


/*Tendriamos que tomar el omprobante de ttorden*/
/*devolvernrofactura() nos devolveria 2 campos: nrosucursal, nrofactura*/

SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(torden.centro,tipoc,tipof);

/*Calcula la forma de pago. Si es una forma de pago mixta efectivo/cta cte, saldra como cta cte.
AUN NO SOPORTA PAGO POR DEBITO o CREDITO o CHEQUE. FIGURARA EFECTIVO.*/
if(torden.cuentacorriente <> 0.00) then
       formadepagocalculada=3;
else
       formadepagocalculada=2;
end if;

INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura)
VALUES(tipoc,elem.nrosucursal,elem.nrofactura,nrodocumento,tdoc,1000,torden.centro,torden.amuc,torden.efectivo,torden.debito,torden.credito,torden.cuentacorriente,torden.sosunc,current_date,formadepagocalculada,tipof);


tieneamuc = (torden.amuc <> 0.00);

IF (torden.tipo = 4) THEN
   /*Este es el caso de una orden de consulta*/
   INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
   VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,'50340',torden.cantordenes,sumaimporte,'Consultas',1);
ELSE
    IF (torden.tipo = 3) THEN
       /*Este es el caso de una orden de internacion*/
       INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
       VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,'50310',torden.cantordenes,sumaimporte,'Internación',1);
    ELSE
        /*Este es el caso de una orden valorizada*/
        open items;
        FETCH items into itemv;
        IF FOUND THEN
           porcentajereal = itemv.porcentaje;
           cantidad1 = itemv.cantidad;
           IF (tieneamuc) THEN
              IF (itemv.porcentaje + 10 > 100) THEN
                 porcentajereal = itemv.porcentaje - (itemv.porcentaje + 10 -100);
              END IF;
              importevalorizada = itemv.cantidad*(itemv.importe*(100-porcentajereal)/100) - itemv.cantidad*itemv.importe*0.1;
           ELSE
              importevalorizada = itemv.cantidad*(itemv.importe*(100-porcentajereal)/100);
           END IF;
           nrocuenta = itemv.nrocuentac;
           descripcionactual = itemv.desccuenta;
        END IF;
        FETCH items into itemv;
        WHILE FOUND LOOP
            porcentajereal = itemv.porcentaje;
            IF itemv.nrocuentac = nrocuenta  THEN
                 cantidad1 = cantidad1+itemv.cantidad;
                 IF (tieneamuc) THEN
                    IF (itemv.porcentaje + 10 > 100) THEN
                       porcentajereal = itemv.porcentaje - (itemv.porcentaje + 10 -100);
                    END IF;
                    importevalorizada = importevalorizada+itemv.cantidad*(itemv.importe*(100-porcentajereal)/100)- itemv.cantidad*itemv.importe*0.1;
                 ELSE
                     importevalorizada = importevalorizada+itemv.cantidad*(itemv.importe*(100-porcentajereal)/100);
                 END IF;
            ELSE
                INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
                VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,nrocuenta,cantidad1,importevalorizada,itemv.desccuenta,1);
                cantidad1 = itemv.cantidad;
                IF (tieneamuc) THEN
                   IF (itemv.porcentaje + 10 > 100) THEN
                      porcentajereal = itemv.porcentaje - (itemv.porcentaje + 10 -100);
                   END IF;
                   importevalorizada = itemv.cantidad*(itemv.importe*(100-porcentajereal)/100)- itemv.cantidad*itemv.importe*0.1;
                ELSE
                    importevalorizada = itemv.cantidad*(itemv.importe*(100-porcentajereal)/100);
                END IF;
                nrocuenta = itemv.nrocuentac;
                descripcionactual = itemv.desccuenta;
            END IF;
         FETCH items into itemv;
        END LOOP;
        INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
        VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,nrocuenta,cantidad1,importevalorizada,descripcionactual,1);
        close items;
    END IF;
END IF;



 --  inserta las facturas en ttfacturasgeneradas
            INSERT INTO ttfacturasgeneradas (tipocomprobante, nrosucursal,tipofactura,nrofactura)
                VALUES (tipoc,elem.nrosucursal,tipof,elem.nrofactura);


INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,nrofactura,nroorden,centro)
select tipoc, elem.nrosucursal,tipof, elem.nrofactura, ttordenesgeneradas.nroorden, ttordenesgeneradas.centro FROM ttordenesgeneradas;

close ordenesgeneradas;
--VALUES(1,elem.nrosucursal,elem.nrofactura,ttordenesgeneradas.nroorden,ttordenesgeneradas.centro);
return true;
END;
$function$
