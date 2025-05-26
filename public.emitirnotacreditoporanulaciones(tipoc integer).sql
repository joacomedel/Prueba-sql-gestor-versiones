CREATE OR REPLACE FUNCTION public.emitirnotacreditoporanulaciones(tipoc integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

elem RECORD;
formap RECORD;
datosper RECORD;
esbeneficiario RECORD;
tnotacred RECORD;
tnotacredaux RECORD;
notacred Cursor for select * from ttordenesanuladas NATURAL JOIN consumo order by nrodoc, tipodoc;
cursoraux Cursor for select * from ttnroorden; --Contiene las ordenes a gurdar en facturaorden
notacredaux Cursor for select * from ttitemsnotacred;
formapagocursor refcursor;
impamuc double precision = 0;
impefectivo double precision = 0;
impctacte double precision = 0;
impdebito double precision = 0;
imptarjcred double precision = 0;
impsosunc double precision = 0;
importeamucfac double precision = 0;
importeefectivofac double precision = 0;
importedebitofac double precision = 0;
importecreditofac double precision = 0;
importectactefac double precision = 0;
importesosuncfac double precision = 0;
sumaimp double precision;
tipoorden bigint;
nrodocumento VARCHAR;
tdoc INTEGER;
nrodocaux VARCHAR;
tipodocaux INTEGER;
aux INTEGER;
valorizada RECORD;
centroaux INTEGER;
tcursoraux RECORD;


BEGIN
--------- quitar
--create temp table ttordenesanuladas(nroorden bigint,centro integer) WITHOUT OIDS;
--INSERT INTO ttordenesanuladas (nroorden,centro) VALUES (328000,1);

--------
--Creo una tabla temporal para insertar las notas de crédito
CREATE TEMP TABLE ttitemsnotacred(tipocomprobante integer,nrosucursal integer,nrofactura bigint,
       idconcepto varchar,cantidad integer,importe double precision default 0,descripcion varchar,idiva integer) WITHOUT OIDS;

--Creo una tabla temporal para saber cuales son las notas de crédito generadas
CREATE TEMP TABLE ttnronotacred(tipocomprobante integer,nrosucursal integer,nrofactura bigint) WITHOUT OIDS;

CREATE TEMP TABLE ttnroorden(nroorden bigint) WITHOUT OIDS;--Uso para insertar los datos en facturaorden

open notacred;
fetch notacred into tnotacred;
SELECT into datosper nrodoc,tipodoc FROM consumo WHERE tnotacred.nroorden = consumo.nroorden AND tnotacred.centro = consumo.centro ORDER BY nrodoc, tipodoc;
nrodocaux = datosper.nrodoc;
tipodocaux = datosper.tipodoc;

--Recupero el nro de sucursal y factura
   SELECT into centroaux * FROM centro();
   SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(centroaux,tipoc,'NC');



WHILE FOUND LOOP
  --Recupero los datos de la persona
SELECT into datosper nrodoc,tipodoc FROM consumo WHERE tnotacred.nroorden = consumo.nroorden AND tnotacred.centro = consumo.centro ORDER BY nrodoc, tipodoc;

IF (datosper.nrodoc = nrodocaux) AND (datosper.tipodoc = tipodocaux) THEN

 --Recupero la forma de pago de la orden
  open formapagocursor for SELECT idformapagotipos, importe FROM importesorden where nroorden = tnotacred.nroorden and centro = tnotacred.centro;
  FETCH formapagocursor into formap;

  WHILE FOUND LOOP
      IF (formap.idformapagotipos = 1) THEN
              impamuc = impamuc + formap.importe;
              importeamucfac = importeamucfac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 2) THEN
              impefectivo = impefectivo + formap.importe;
              importeefectivofac = importeefectivofac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 3) THEN
              impctacte = impctacte + formap.importe;
              importectactefac = importectactefac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 4) THEN
              impdebito = impdebito + formap.importe;
              importedebitofac = importedebitofac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 5) THEN
              imptarjcred = imptarjcred + formap.importe;
              importecreditofac = importecreditofac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 6) THEN
              impsosunc = impsosunc + formap.importe;
              importesosuncfac = importesosuncfac + formap.importe;
      END IF;
   FETCH formapagocursor into formap;
   END LOOP;
   close formapagocursor;

   sumaimp = impefectivo + impctacte + impdebito + imptarjcred;
--Recupero el tipo de orden
   SELECT INTO tipoorden tipo FROM orden where nroorden = tnotacred.nroorden and centro = tnotacred.centro;
   IF (tipoorden = 4) THEN
   /*Este es el caso de una orden de consulta*/
   select INTO aux cantidad from ttitemsnotacred where idconcepto='50340';
   IF FOUND THEN
      UPDATE ttitemsnotacred SET cantidad = cantidad +1, importe = importe + sumaimp
     WHERE idconcepto = '50340';
       INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
   ELSE
         INSERT INTO ttitemsnotacred(tipocomprobante,nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
   VALUES(tipoc,elem.nrosucursal,elem.nrofactura,'50340',1,sumaimp,'Consultas',1);
         INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
  END IF;
   ELSE
       /*Este es el caso de una orden valorizada*/
       select into valorizada nrocuentac, desccuenta FROM item NATURAL JOIN itemvalorizada NATURAL JOIN practica
       NATURAL JOIN cuentascontables WHERE itemvalorizada.nroorden = tnotacred.nroorden AND itemvalorizada.centro = tnotacred.centro;

       SELECT INTO aux cantidad from ttitemsnotacred where idconcepto= valorizada.nrocuentac;
       IF FOUND THEN
          UPDATE ttitemsnotacred SET cantidad = cantidad +1, importe = importe + sumaimp
          WHERE idconcepto = valorizada.nrocuentac;
          INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
       ELSE
         INSERT INTO ttitemsnotacred(tipocomprobante,nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
          VALUES(tipoc,elem.nrosucursal,elem.nrofactura,valorizada.nrocuentac,1,sumaimp,valorizada.desccuenta,1);
         INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
       END IF;

    END IF;
ELSE  --cambio la persona

  --Con esto recupero los datos del titular para emitir la factura
  select into esbeneficiario nrodoctitu,tipodoctitu from benefsosunc
  where (benefsosunc.nrodoc = nrodocaux and benefsosunc.tipodoc=tipodocaux);
  if found  then
       nrodocumento=esbeneficiario.nrodoctitu;
       tdoc=esbeneficiario.tipodoctitu;
  else
      nrodocumento=nrodocaux;
      tdoc= tipodocaux;
  end if;

  INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,
  importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura)
  VALUES(tipoc,elem.nrosucursal,elem.nrofactura,nrodocumento,tdoc,1000,centroaux,importeamucfac,importeefectivofac,
  importedebitofac,importecreditofac,importectactefac,importesosuncfac,current_date,2,'NC');


  INSERT INTO ttnronotacred(tipocomprobante,nrosucursal,nrofactura) VALUES(tipoc,elem.nrosucursal,elem.nrofactura);

  open cursoraux;
  FETCH cursoraux into tcursoraux;
  WHILE FOUND LOOP

  INSERT INTO facturaorden(tipocomprobante,nrosucursal,nrofactura,nroorden,centro,tipofactura)
  VALUES (tipoc,elem.nrosucursal,elem.nrofactura,tcursoraux.nroorden,centroaux,'NC');
  FETCH cursoraux into tcursoraux;

  END LOOP;
  close cursoraux;
  DELETE FROM ttnroorden;

  open notacredaux;
  FETCH notacredaux into tnotacredaux;
  WHILE FOUND LOOP

  INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,tipofactura)
  VALUES(tnotacredaux.tipocomprobante,tnotacredaux.nrosucursal,tnotacredaux.nrofactura,tnotacredaux.idconcepto,tnotacredaux.cantidad,
  tnotacredaux.importe,tnotacredaux.descripcion,tnotacredaux.idiva,'NC');

  FETCH notacredaux into tnotacredaux;

  END LOOP;
  close notacredaux;

   --Creo una tabla temporal para insertar las notas de crédito del afiliado
  DELETE from ttitemsnotacred;


 nrodocaux = datosper.nrodoc;
 tipodocaux = datosper.tipodoc;
 impamuc = 0;
 impefectivo = 0;
 impctacte = 0;
 impdebito = 0;
 imptarjcred = 0;
 impsosunc = 0;

 importeamucfac = 0;
 importeefectivofac = 0;
 importedebitofac = 0;
 importecreditofac = 0;
 importectactefac = 0;
 importesosuncfac = 0;


 open formapagocursor for SELECT idformapagotipos, importe FROM importesorden where nroorden = tnotacred.nroorden and centro = tnotacred.centro;
  FETCH formapagocursor into formap;
  WHILE FOUND LOOP
      IF (formap.idformapagotipos = 1) THEN
              impamuc = impamuc + formap.importe;
              importeamucfac = importeamucfac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 2) THEN
              impefectivo = impefectivo + formap.importe;
              importeefectivofac = importeefectivofac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 3) THEN
              impctacte = impctacte + formap.importe;
              importectactefac = importectactefac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 4) THEN
              impdebito = impdebito + formap.importe;
              importedebitofac = importedebitofac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 5) THEN
              imptarjcred = imptarjcred + formap.importe;
              importecreditofac = importecreditofac + formap.importe;
      END IF;
      IF (formap.idformapagotipos = 6) THEN
              impsosunc = impsosunc + formap.importe;
              importesosuncfac = importesosuncfac + formap.importe;
      END IF;
   FETCH formapagocursor into formap;
   END LOOP;
   close formapagocursor;
--Recupero el nro de sucursal y factura
   SELECT into centroaux * FROM centro();
   SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(centroaux,tipoc,'NC');
   sumaimp = impefectivo + impctacte + impdebito + imptarjcred;
--Recupero el tipo de orden
   SELECT INTO tipoorden tipo FROM orden where nroorden = tnotacred.nroorden and centro = tnotacred.centro;
   IF (tipoorden = 4) THEN
   /*Este es el caso de una orden de consulta*/
   select into aux cantidad from ttitemsnotacred where idconcepto='50340';
   IF FOUND THEN
      UPDATE ttitemsnotacred SET cantidad = cantidad +1, importe = importe + sumaimp
      WHERE idconcepto = '50340';
      INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
   ELSE
         INSERT INTO ttitemsnotacred(tipocomprobante,nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
   VALUES(tipoc,elem.nrosucursal,elem.nrofactura,'50340',1,sumaimp,'Consultas',1);
         INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);

  END IF;
   ELSE
       /*Este es el caso de una orden valorizada*/
       select into valorizada nrocuentac, desccuenta FROM item NATURAL JOIN itemvalorizada NATURAL JOIN practica
       NATURAL JOIN cuentascontables WHERE itemvalorizada.nroorden = tnotacred.nroorden AND itemvalorizada.centro = tnotacred.centro;

       SELECT INTO aux cantidad from ttitemsnotacred where idconcepto= valorizada.nrocuentac;
       IF FOUND THEN
          UPDATE ttitemsnotacred SET cantidad = cantidad +1, importe = importe + sumaimp
          WHERE idconcepto = valorizada.nrocuentac;
          INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
       ELSE
         INSERT INTO ttitemsnotacred(tipocomprobante,nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
          VALUES(tipoc,elem.nrosucursal,elem.nrofactura,valorizada.nrocuentac,1,sumaimp,valorizada.desccuenta,1);
         INSERT INTO ttnroorden (nroorden) VALUES (tnotacred.nroorden);
       END IF;


 END IF;

END IF;

     impamuc = 0;
     impefectivo = 0;
     impctacte = 0;
     impdebito = 0;
     imptarjcred = 0;
     impsosunc = 0;
   fetch notacred into tnotacred;
END LOOP;

 --Con esto recupero los datos del titular para emitir la factura
  select into esbeneficiario nrodoctitu,tipodoctitu from benefsosunc
  where (benefsosunc.nrodoc = nrodocaux and benefsosunc.tipodoc=tipodocaux);
  if found  then
       nrodocumento=esbeneficiario.nrodoctitu;
       tdoc=esbeneficiario.tipodoctitu;
  else
      nrodocumento=datosper.nrodoc;
      tdoc= datosper.tipodoc;
  end if;

  INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,
  importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura)
  VALUES(tipoc,elem.nrosucursal,elem.nrofactura,nrodocumento,tdoc,1000,centroaux,importeamucfac,importeefectivofac,
  importedebitofac,importecreditofac,importectactefac,importesosuncfac,current_date,2,'NC');

 INSERT INTO ttnronotacred(tipocomprobante,nrosucursal,nrofactura) VALUES(tipoc,elem.nrosucursal,elem.nrofactura);

 open cursoraux;
  FETCH cursoraux into tcursoraux;
  WHILE FOUND LOOP

  INSERT INTO facturaorden(tipocomprobante,nrosucursal,nrofactura,nroorden,centro,tipofactura)
  VALUES (tipoc,elem.nrosucursal,elem.nrofactura,tcursoraux.nroorden,centroaux,'NC');
  FETCH cursoraux into tcursoraux;

  END LOOP;
  close cursoraux;

  open notacredaux;
  FETCH notacredaux into tnotacredaux;
  WHILE FOUND LOOP

   INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,tipofactura)
  VALUES(tnotacredaux.tipocomprobante,tnotacredaux.nrosucursal,tnotacredaux.nrofactura,tnotacredaux.idconcepto,tnotacredaux.cantidad,
  tnotacredaux.importe,tnotacredaux.descripcion,tnotacredaux.idiva,'NC');

    FETCH notacredaux into tnotacredaux;
  END LOOP;
  close notacredaux;

close notacred;




return true;

END;
$function$
