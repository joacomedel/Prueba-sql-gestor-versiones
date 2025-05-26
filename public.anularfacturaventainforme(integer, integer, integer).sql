CREATE OR REPLACE FUNCTION public.anularfacturaventainforme(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme
-- $2: idcentroinformefacturacion
-- $3: idinformefacturaciontipo

elem RECORD;
rlaopc RECORD;
resp BOOLEAN;
informeF INTEGER;
valor boolean;
--temporal que tiene los datos de la factura a anular
sitems CURSOR FOR SELECT * FROM informefacturacionitem WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitems RECORD;

BEGIN
  IF iftableexistsparasp('tempfacturaaanular') THEN 
      select into valor nogenerapendiente from tempfacturaaanular;
  ELSE
     valor = TRUE;
  END IF;
      informeF=$1;
   -- Cambio el estado del informe de facturacion
      SELECT INTO resp * FROM cambiarestadoinformefacturacion($1,$2,5,'Generado Automaticamente desde anularfacturaventainforme');
 IF (not valor ) THEN 
   IF ($3<>11) THEN /* Si no es un informe de cliente vuelvo a generar el informe*/
   -- Busco el cliente y barra a nombre de quien salio la factura que se desea anular
  
  SELECT INTO elem nrocliente,barra,idtipofactura,idformapagotipos FROM informefacturacion WHERE nroinforme=$1 and idcentroinformefacturacion=$2;

   -- Creo el informe de facturacion segun el tipo de informe correspondiente
     SELECT INTO informeF * FROM crearinformefacturacion(elem.nrocliente,elem.barra,$3);
   --Updateo la forma de pago y el tipo de factura que corresponde al informe

      UPDATE informefacturacion set idformapagotipos = elem.idformapagotipos,idtipofactura=elem.idtipofactura
      WHERE nroinforme =informeF AND idcentroinformefacturacion = centro();

      open sitems;
      fetch sitems into regsitems;
      WHILE FOUND LOOP
         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
           VALUES (informeF,regsitems.nrocuentac,regsitems.cantidad,regsitems.importe,regsitems.descripcion,regsitems.idiva);
           fetch sitems into regsitems;
      END LOOP;
      close sitems;

      SELECT INTO resp * FROM insertarinformefacturacionitem();

   END IF;
 END IF;

      IF ($3=1) THEN --si el informe de facturacion es de amuc

            SELECT INTO resp * FROM   anularfacturaventainformeamuc($1,$2,informeF,centro());

      END IF;

      IF ($3=2) THEN --si el informe de facturacion es de reciprocidad

            SELECT INTO resp * FROM   anularfacturaventainformereciprocidad($1,$2,informeF,centro());

         END IF;

       IF ($3=3) THEN --si el informe de facturacion es de consumo turismo

            SELECT INTO resp * FROM   anularfacturaventainformeturismo($1,$2,informeF,centro());

         END IF;
      IF ($3=4) THEN --si el informe de facturacion es de solicitud financiacion

            SELECT INTO resp * FROM  anularfacturaventainformesolicitudfinanciacion($1,$2,informeF,centro());

         END IF;

     IF ($3=5) THEN --si el informe de facturacion es de nota de debito
       IF (valor) THEN --no debe generar pendiente luego de anular 
         UPDATE informefacturacionestado set descripcion = descripcion ||' por pedido de tesoreria no se debe Generar Pendiente ND '
         WHERE nroinforme =$1 AND idcentroinformefacturacion = $2 and  	idinformefacturacionestadotipo=5 and nullvalue(fechafin);
       end if;
            SELECT INTO resp * FROM  anularfacturaventainformenotadebito($1,$2,informeF,centro());

     END IF;
     IF ($3=6) THEN --si el informe de facturacion es de aportes

            SELECT INTO resp * FROM   anularfacturaventainformeaporte($1,$2,informeF,centro());

     END IF;
     IF ($3=8) THEN --si el informe de facturacion es de aportes y contribuciones de la UNC

            SELECT INTO resp * FROM   anularfacturaventainformefacturacionaportescontribuciones($1,$2,informeF,centro());

     END IF;
      IF ($3=9) THEN --si el informe de facturacion es de descuentos

            SELECT INTO resp * FROM   anularfacturaventainformefacturaciondescuento($1,$2,informeF,centro());

     END IF;
      IF ($3=10) THEN --si el informe de facturacion es de becarios

            SELECT INTO resp * FROM  anularfacturaventainformefacturacionbecariosaportescontribuciones ($1,$2,informeF,centro());

     END IF;
      
      IF ($3=11) THEN --si el informe de facturacion es de clientes

            SELECT INTO resp * FROM  configurarctactevinculadainformecliente ($1,$2);

     END IF;    
     
     IF ($3=13) THEN --si el informe de facturacion es de reintegros
 --KR 25-08-22 me fijo si la OT no tiene una OPC que este activa, si es asi aviso y no se puede anular la OT
      SELECT INTO rlaopc * FROM informefacturacion NATURAL JOIN informefacturacionexpendioreintegro  NATURAL JOIN  ordenpagocontablereintegro              NATURAL JOIN ordenpagocontableordenpago NATURAL JOIN ordenpagocontableestado
          WHERE  nroinforme =$1 AND idcentroinformefacturacion = $2 AND nullvalue(opcfechafin) and idordenpagocontableestadotipo<>6 ;
      IF FOUND THEN 
         RAISE EXCEPTION 'No es posible anular el comprobante, se encuentra vinculado a una OPC activa !!!  ' USING HINT = 'Informar al Sector de Tesoreria.'; 
      ELSE 
            SELECT INTO resp * FROM  anularfacturaventainformeexpendioreintegro ($1,$2,informeF,centro());
      END IF;
     END IF;
 
      IF ($3=14) THEN --si el informe de facturacion es un informe generico vas:21/12/2018 por los comprobantes de turismo

            SELECT INTO resp * FROM  anularinformefacturaciongenerico ($1,$2);

     END IF;
 
IF (not valor ) THEN 
 -- Cambio el estado del informe de facturacion 3=facturable
      FOR indiceestado IN 1..3 LOOP

          SELECT INTO resp * FROM cambiarestadoinformefacturacion(informeF,centro(),indiceestado,'Generado Automaticamente desde anularfacturaventainforme');

      END LOOP;

     END IF;
return true;
END;
$function$
