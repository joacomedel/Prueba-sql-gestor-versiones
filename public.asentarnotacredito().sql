CREATE OR REPLACE FUNCTION public.asentarnotacredito()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE

datos CURSOR for
             SELECT *
             FROM temp_notascredito;

unDato RECORD;
aux RECORD;

respuesta integer;
numD varchar;
barraD integer;
numNotaCredito integer;
nroImput integer;
nroasiento integer;
cen integer;
totalAux Double precision;
numOrden integer;

BEGIN
totalAux = 0;
respuesta = 0;
open datos;
FETCH datos INTO unDato;
      numD = unDato.nroDoc;
      barraD = unDato.barra;
      cen = unDato.centro;
      numOrden = unDato.nroorden;
      SELECT
              public.benefsosunc.barratitu,
              public.benefsosunc.nrodoctitu INTO aux
      FROM public.persona
                 INNER JOIN public.benefsosunc ON (public.persona.tipodoc=public.benefsosunc.tipodoc)
                       AND (public.persona.nrodoc=public.benefsosunc.nrodoc)
      WHERE  (public.persona.nrodoc = numD) AND
                   (public.persona.barra = barraD);
      IF found THEN
               numD = aux.nrodoctitu;
               barraD = aux.barratitu;
      END if;
      INSERT INTO notacredito(nrodoc,barra,fechaemision,centro,nroorden,centroorden)
       VALUES(numD,barraD,current_date,cen,numOrden,cen);
       numNotaCredito = currval('"public"."notacredito_nronotacredito_seq"');
       INSERT INTO asientocontable(fechaingreso)
             VALUES (current_date);
      nroasiento = currval('"public"."asientocontable_idasientocontable_seq"');
CLOSE datos;
OPEN datos;
FETCH datos INTO unDato;
WHILE found LOOP
      INSERT INTO tnotascredito(importe,centro,nronotacredito,iditem)
             VALUES(unDato.importe,unDato.centro,numNotaCredito,unDato.iditem);

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
          VALUES (               nroImput+1,nroasiento,
                                 3,unDato.importe);
      totalAux = totalAux+unDato.importe;
      FETCH datos INTO unDato;
      END LOOP;
CLOSE datos;
      UPDATE notacredito
             SET importe=totalAux
             WHERE (notacredito.nronotacredito= numNotaCredito)
                   AND (notacredito.centro = cen);
      INSERT INTO asientoimputacion(idasientoimputacion,idasientocontable,
                                 idformapagotipos,montodebe
                                 )
              VALUES (               nroImput,nroasiento,
                                 6,totalAux);
      INSERT INTO comprobantes(cfechacomprobante,idcomprobantetipos,idasientocontable,cimporte,cdescripcion,numerocomprobante,idcentroregional
                         )
        VALUES (current_date,1,nroasiento,totalAux,'Nota de Credito',numNotaCredito,1);
respuesta = numNotaCredito;
return respuesta;
END;
$function$
