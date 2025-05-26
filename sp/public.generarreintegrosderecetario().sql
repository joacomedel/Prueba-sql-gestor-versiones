CREATE OR REPLACE FUNCTION public.generarreintegrosderecetario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que genera los reintegros y sus todos los estados hasta "facturado"
 * Entrada temporal tfacturas que contiene todas las facturas de las que se van a tener que generar los reintegros
 * tfacturas tiene los siguientes campos
 *       nroregistro
 *       anio
 *       NATURAL JOIN recetarioconvenio
 */
DECLARE
       cursorfactura CURSOR FOR SELECT * FROM tempfacturas;
       unafactura RECORD;
       numregistro integer;
       aniofac integer;
       idreintegro integer;
       cursorrecetario refcursor;
       unrecetario RECORD;
       unapersona RECORD;
       elrecetarioitem RECORD;
       unbenef RECORD;
       nrodoctitu INTEGER;
       tipodoctitu smallint;
       losdatosdelpago RECORD;
       unacuenta record;
       i integer;
       

BEGIN
     /*Recorro cada una de las facturas*/
     OPEN cursorfactura;
     FETCH cursorfactura into unafactura;
     WHILE  found LOOP
            numregistro = unafactura.nroregistro;
            aniofac = unafactura.anio;
            /* Recorro cada uno de los recetarios que corresponde a la factura (numregistro,aniofac)*/
            OPEN cursorrecetario FOR SELECT * FROM recetario NATURAL JOIN recetarioconvenio WHERE nroregistro=numregistro and anio=aniofac;
            FETCH cursorrecetario into unrecetario;
            WHILE  found LOOP

            /* Busco los datos del titular*/
           SELECT INTO unapersona * FROM persona WHERE tipodoc = unrecetario.tipodoc AND nrodoc = unrecetario.nrodoc;
           if(unapersona.barra >= 30) THEN-- se trata de un titular
                  nrodoctitu = unrecetario.nrodoc;
                  tipodoctitu = unrecetario.tipodoc;
           ELSE
               SELECT INTO unbenef * FROM benefsosunc WHERE tipodoc = unrecetario.tipodoc AND nrodoc = unrecetario.nrodoc;
               nrodoctitu = unbenef.nrodoctitu;
               tipodoctitu = unbenef.tipodoctitu;
           END IF;
           /* busco los datos de la cuenta del titular*/
           SELECT INTO unacuenta * FROM cuentas WHERE cuentas.nrodoc = nrodoctitu and cuentas.tipodoc = tipodoctitu;


           /* Obtengo la suma de los importes y la cantidad de item del recetario */
            SELECT INTO elrecetarioitem SUM(importeapagar) as elimporte ,nrorecetario,centro, COUNT(*)as cantidaditem
            FROM recetarioitem
            WHERE nrorecetario = unrecetario.nrorecetario and centro=unrecetario.centro
            GROUP BY nrorecetario,centro;

            SELECT INTO losdatosdelpago * FROM ordenpagodatospago WHERE ordenpagodatospago.nroordenpago=unafactura.nroordendepago;

             /*  Creo un reintegro correspondiente al recetario recuperado */
            INSERT INTO reintegro(anio,idcentroregional,tipodoc,nrodoc,tipocuenta,nrocuenta,tipoformapago,nroordenpago,rfechaingreso,rimporte,nrooperacion
            )VALUES(date_part('year', NOW()),centro(),tipodoctitu,nrodoctitu,unacuenta.tipocuenta,unacuenta.nrocuenta,3,unafactura.nroordendepago,unrecetario.fechauso,elrecetarioitem.elimporte,losdatosdelpago.nrooperacion);
            idreintegro = currval('reintegro_nroreintegro_seq');

            INSERT INTO reintegroprestacion(anio,nroreintegro, tipoprestacion, importe,  observacion,  cantidad, idcentroregional)
            VALUES(date_part('year', NOW()), idreintegro,1, elrecetarioitem.elimporte,'Generado automaticamente en generarreintegrosderecetario ', elrecetarioitem.cantidaditem,centro() );

            /* creo la relacion entre reintegro y el recetario*/
            INSERT INTO reintegrorecetario(nroreintegro,anio,idcentroregional,centro,nrorecetario)
            VALUES(idreintegro,date_part('year', NOW()),
            centro(),
            unrecetario.centro,
            unrecetario.nrorecetario);

            /*Creo los estados automaticos de los reintegros*/
            FOR i IN 1..3 LOOP -- Pendiente, Liquidable, Liquidado
                INSERT INTO restados(fechacambio, nroreintegro, anio,tipoestadoreintegro,observacion,idcentroregional)
                VALUES(NOW(),idreintegro,date_part('year', NOW()),i,'Generado automaticamente generarreintegrosderecetario',centro());
            END LOOP;
            FETCH cursorrecetario into unrecetario;
            END LOOP;
            close cursorrecetario;
     FETCH cursorfactura into unafactura;
     END LOOP;
     close cursorfactura;
RETURN FALSE;
END;
$function$
