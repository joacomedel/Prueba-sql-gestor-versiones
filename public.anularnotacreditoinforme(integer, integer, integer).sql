CREATE OR REPLACE FUNCTION public.anularnotacreditoinforme(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme
-- $2: idcentroinformefacturacion
-- $3: idinformefacturaciontipo

elem RECORD;
resp BOOLEAN;
informeF INTEGER;

--temporal que tiene los datos de la factura a anular
sitems CURSOR FOR SELECT * FROM informefacturacionitem WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitems RECORD;

BEGIN


   -- Cambio el estado del informe de facturacion
      SELECT INTO resp * FROM cambiarestadoinformefacturacion($1,$2,5,'Generado Automaticamente desde anularfacturaventainforme');

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
     INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
     VALUES (informeF,regsitems.nrocuentac,regsitems.cantidad,regsitems.importe,regsitems.descripcion);
    fetch sitems into regsitems;
END LOOP;
close sitems;

  SELECT INTO resp * FROM insertarinformefacturacionitem();


      IF ($3=1) THEN --si el informe de facturacion es de amuc

          --  SELECT INTO resp * FROM   anularfacturaventainformeamuc($1,$2,informeF,centro());

      END IF;

      IF ($3=2) THEN --si el informe de facturacion es de reciprocidad

           -- SELECT INTO resp * FROM   anularfacturaventainformereciprocidad($1,$2,informeF,centro());

         END IF;

       IF ($3=3) THEN --si el informe de facturacion es de consumo turismo

            SELECT INTO resp * FROM   anularnotacreditoinformeturismo($1,$2,informeF,centro());

         END IF;
      IF ($3=4) THEN --si el informe de facturacion es de solicitud financiacion

           -- SELECT INTO resp * FROM  anularfacturaventainformesolicitudfinanciacion($1,$2,informeF,centro());

         END IF;

     IF ($3=5) THEN --si el informe de facturacion es de nota de debito

         --   SELECT INTO resp * FROM  anularfacturaventainformenotadebito($1,$2,informeF,centro());

     END IF;
     IF ($3=6) THEN --si el informe de facturacion es de aportes

           -- SELECT INTO resp * FROM   anularfacturaventainformeaporte($1,$2,informeF,centro());

     END IF;

     IF ($3=14) THEN --si el informe es generico
-- KR 28-12-21 esto esta desde el 2019 pero segun tkt http://glpi.sosunc.org.ar/front/ticket.form.php?id=4755 quieren otra cosa, esta siendo tratado
       SELECT INTO resp * FROM  modificarctacte($1,$2);

     END IF;


 -- Cambio el estado del informe de facturacion 3=facturable
      FOR indiceestado IN 1..3 LOOP

          SELECT INTO resp * FROM cambiarestadoinformefacturacion(informeF,centro(),indiceestado,'Generado Automaticamente desde anularfacturaventainforme');

      END LOOP;


return true;
END;



$function$
