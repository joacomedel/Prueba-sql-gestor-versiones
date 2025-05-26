CREATE OR REPLACE FUNCTION public.agregaraportesjubpenmodificado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
aportes CURSOR FOR
              SELECT *
              FROM tempaportejubpen ORDER BY tempaportejubpen.anio,tempaportejubpen.mes ASC;
asientos CURSOR FOR
                SELECT *
                FROM tempasiento;

usuario varchar;
reci bigint;
imp real;
unatupla RECORD;
aux boolean;
idaportev bigint;
resp bigint;
rta boolean;
resul boolean;
nroorden integer;
concepto varchar;
informeF integer;


BEGIN

usuario = $1;
reci = asentarrecibopagoversion2();

     -- Creo la tabla temporal para insertar los items del informe de facturacion
             CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

open aportes;
FETCH aportes into unatupla;
    -- Creo el informe de facturacion
       SELECT INTO informeF * FROM crearinformefacturacion( unatupla.nrodoc, cast(unatupla.barra as integer), 6);
 
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

          INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
             VALUES (informeF,'50340',1,unatupla.importe,concat( 'Aporte mes: ', cast(unatupla.mes as integer),' Anio: ',cast(unatupla.anio as integer)));
           
            imp = imp + unatupla.importe; --almacena los importes de los aportes para luego generar un solo recibo
            if not rta then
               return resp;
            end if;
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



open asientos;

  

FETCH asientos into unatupla;
      while found loop
            select * into rta
            from agregarunasiento(cast(reci as integer),
                                  nroorden,
                                  unatupla.centro,
                                  unatupla.amuc,
                                  unatupla.cuentacorriente,
                                  unatupla.debito,
                                  unatupla.credito,
                                  unatupla.efectivo);
            if not rta then
               return resp;
            end if;
      fetch asientos into unatupla;
      end loop;

           
         
           


RETURN reci;
end;
$function$
