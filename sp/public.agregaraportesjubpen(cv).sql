CREATE OR REPLACE FUNCTION public.agregaraportesjubpen(character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$/*
agregaraportesjubpen(usuario)
*/

DECLARE
aportes CURSOR FOR
              SELECT tempaportejubpen.nrodoc,tempaportejubpen.importe,tempaportejubpen.mes,tempaportejubpen.anio, descripaporte
                  ,tempaportejubpen.idformapagotipos, persona.tipodoc, persona.barra

              FROM tempaportejubpen JOIN persona ON (tempaportejubpen.nrodoc=persona.nrodoc AND 
                                                     tempaportejubpen.tipodoc=persona.tipodoc) 
              ORDER BY tempaportejubpen.anio,tempaportejubpen.mes ASC;


usuario varchar;
reci bigint;
imp real;
unatupla RECORD;
undato RECORD;
aux boolean;
idaportev bigint;
resp bigint;
rta boolean;
resul boolean;
nroorden integer;
concepto varchar;
informeF integer;
nrocuentactacble VARCHAR;
iva double precision;

raportejb RECORD;
BEGIN


iva=0;
usuario = $1;


IF iftableexistsparasp('temp_aportejubpen') THEN
       SELECT INTO raportejb * FROM temp_aportejubpen;
       IF (raportejb.generarecibo) THEN
--KR 29-04-20 solo creo el recibo si se debe crear
          reci = asentarrecibopagoversion2();
       END IF;
ELSE 
   reci = asentarrecibopagoversion2();
END IF;

  -- Creo la tabla temporal para insertar los items del informe de facturacion
   
IF NOT iftableexists('ttinformefacturacionitem') THEN
   CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion 
VARCHAR, idiva INTEGER);
ELSE 
   DELETE FROM ttinformefacturacionitem;
END IF;

            


open aportes;
FETCH aportes into unatupla;
    -- Creo el informe de facturacion
       SELECT INTO informeF * FROM crearinformefacturacion( unatupla.nrodoc, cast(unatupla.tipodoc as integer), 6);
       UPDATE informefacturacion set idformapagotipos = 2 WHERE nroinforme =informeF AND idcentroinformefacturacion = centro();
       while found loop
            select * INTO rta
            from agregarunaporte(usuario,
                                 unatupla.nrodoc,
                                 cast(unatupla.barra as integer),
                                 cast(unatupla.mes as integer),
                                 cast(unatupla.anio as integer),
                                 unatupla.importe,
                                 cast(reci as integer),
                                 unatupla.idformapagotipos);

          SELECT currval('aporte_idaporte_seq') INTO idaportev;
          --Por cada aporte
          INSERT INTO  informefacturacionaporte(nroinforme,idcentroinformefacturacion,idaporte,idcentroregionaluso)
             VALUES(informeF,centro(), idaportev, centro());

          IF (cast(unatupla.barra as integer)>=35) THEN
               nrocuentactacble= '40245';
               iva = 0.105;	
          ELSE
            IF (cast(unatupla.barra as integer)=34) THEN
               nrocuentactacble = '40230';
            ELSE
               nrocuentactacble= '40225';

            END IF;
          END IF;

          INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
             VALUES (informeF,nrocuentactacble,1,unatupla.importe * (1+iva),unatupla.descripaporte ,3);


      FETCH aportes into unatupla;
      END loop;
close aportes;
SELECT INTO resul * FROM insertarinformefacturacionitem();

             -- Cambio el estado del informe de facturacion 3=facturable
             UPDATE informefacturacionestado
             SET fechafin=NOW()
             WHERE nroinforme=informeF and idcentroinformefacturacion=centro() and fechafin is null;

             INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini)
             VALUES(informeF,centro(),3,NOW());


RETURN informeF;
END;$function$
