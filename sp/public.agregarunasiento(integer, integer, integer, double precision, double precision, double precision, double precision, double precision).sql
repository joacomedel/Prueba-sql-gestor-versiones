CREATE OR REPLACE FUNCTION public.agregarunasiento(integer, integer, integer, double precision, double precision, double precision, double precision, double precision)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
agregarunasiento(nroRecibo,nroOrden,centro,amuc,ctacte,debito,credito,efectivo)

*/
DECLARE
       resp boolean;
       nroImput integer;
       --PARAMETROS
       nrorec alias for $1;
       nroord alias for $2;
       cen alias for $3;
       amuc alias for $4;
       cta alias for $5;
       deb alias for $6;
       cred alias for $7;
        efec alias for $8;
       cero double precision;
       nroasiento bigint;
       total double precision;
       centrov integer;

BEGIN
cero = 0.0;
total = amuc+cta+deb+cred+efec;

INSERT INTO asientocontable(fechaingreso)
       VALUES (current_date);

select * into nroasiento
from   currval('public.asientocontable_idasientocontable_seq');
/*
if not nullvalue(nroord) then
   INSERT INTO comprobantes(cfechacomprobante,idcomprobantetipos,idasientocontable,cimporte,cdescripcion,numerocomprobante,idcentroregional
                         )
        VALUES (current_date,2,nroasiento,total,'Orden Valorizada',nroord,1);
end if;
*/
SELECT  into centrov centro();

if not nullvalue(nrorec) THEN
   INSERT INTO comprobantes(cfechacomprobante,idcomprobantetipos,idasientocontable,cimporte,cdescripcion,numerocomprobante,idcentroregional
                         )
        VALUES (current_date,0,nroasiento,total,'Recibo',nrorec,centrov);
end if;

/*
   Genero la nueva imputacion para el COSEGURO -- cod. de cuenta 40350
   */
   SELECT max(idasientoimputacion) into nroImput
   FROM asientoimputacion
   WHERE asientoimputacion.idasientocontable=nroasiento;
   IF nullvalue(nroImput) then
      nroImput = 0;
   ELSE
       nroImput = nroImput +1;
   END IF;

   INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montohaber
                                 )
          VALUES (               nroImput,nroasiento,
                                 6,total);
/*
*/
IF NOT amuc = cero then
   /*
   Genero la nueva imputacion para AMUC -- cod. de cuenta 10323
   */
   SELECT max(idasientoimputacion) into nroImput
   FROM asientoimputacion
   WHERE asientoimputacion.idasientocontable=nroasiento;
   IF nullvalue(nroImput) then
      nroImput = 0;
   ELSE
       nroImput = nroImput +1;
   END IF;
   INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montodebe
                                 )
          VALUES (               nroImput,nroasiento,
                                 1,amuc);

END IF;
IF NOT cta = cero then
   /*
   Genero el nuevo asiento de Cuenta Corriente -- cod. de cuenta 10311
   */

   SELECT max(idasientoimputacion) into nroImput
   FROM asientoimputacion
   WHERE asientoimputacion.idasientocontable=nroasiento;
   IF nullvalue(nroImput) then
      nroImput = 0;
   ELSE
       nroImput = nroImput +1;
   END IF;
   INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montodebe
                                 )
          VALUES (               nroImput,nroasiento,
                                 3,cta);

END IF;
IF NOT deb = cero then
   /*
   Genero el nuevo asiento de Tarjeta de Debito -- cod. de cuenta AUN NO ESTA EN PLAN DE CUENTAS (99999)
   */

   SELECT max(idasientoimputacion) into nroImput
   FROM asientoimputacion
   WHERE asientoimputacion.idasientocontable=nroasiento;

   IF nullvalue(nroImput) then
      nroImput = 0;
   ELSE
       nroImput = nroImput +1;
   END IF;
   INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montodebe
                                 )
          VALUES (               nroImput,nroasiento,
                                 4,deb);

END IF;
IF NOT cred = cero then
   /*
   Genero el nuevo asiento de Tarjeta de Credito --- cod. de cuenta AUN NO ESTA PREVISTO EN PLAN DE CUENTAS (99999)
   */

   SELECT max(idasientoimputacion) into nroImput
   FROM asientoimputacion
   WHERE asientoimputacion.idasientocontable=nroasiento;
   IF nullvalue(nroImput) then
      nroImput = 0;
   ELSE
       nroImput = nroImput +1;
   END IF;
   INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montodebe
                                 )
          VALUES (               nroImput,nroasiento,
                                 5,cred);

END IF;
IF NOT efec = cero then
   /*
   Genero el nuevo asiento de dinero Efectivo -- cod. de cuenta 10223
   */

   SELECT max(idasientoimputacion) into nroImput
   FROM asientoimputacion
   WHERE asientoimputacion.idasientocontable=nroasiento;
   IF nullvalue(nroImput) then
      nroImput = 0;
   ELSE
       nroImput = nroImput +1;
   END IF;
   INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montodebe
                                 )
          VALUES (               nroImput,nroasiento,
                                 2,efec);

END IF;



RETURN true;
END;
$function$
