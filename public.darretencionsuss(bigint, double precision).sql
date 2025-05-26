CREATE OR REPLACE FUNCTION public.darretencionsuss(bigint, double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$-- El Parametro pmontopagar debe ser SIN IVA

DECLARE
       ctemordenpago refcursor;
       crearordenpagocontable integer;
       elidordenpagocontable bigint;

       xretencioncalculada double precision;
       xretencioncalculadaacumulada double precision;
       xsumapago double precision;
       xsumaret double precision;
       xmontobase double precision;
       xmontofijo double precision;
       xmontoprop double precision;
       xmontoretanteriores double precision;
       xmontototal double precision;
       rtiporetencion record;
       rescalaretencion record;
       unpago record;
       unaret record;

       cursortiporetencion CURSOR FOR
			select * from prestadortiporetencion
		       		natural join tiporetencion
				where idprestador=$1 and idregimenretencion=2;

       cursorretenciones CURSOR FOR
                         select *
                                from retencionprestador
                                natural join tiporetencion
                         where idregimenretencion=2 and idprestador=$1 and
                               rpfecha between current_date - EXTRACT(DAY FROM current_date)::integer +1 and current_date;
       cursorpagos CURSOR FOR
                   SELECT *,netoiva105+netoiva21+netoiva27+nogravado+exento as importesiniva
                          from ordenpagocontable
                          natural join ordenpagocontableordenpago
                          natural join ordenpago
                          join factura USING (nroordenpago)
                          join reclibrofact on (factura.nroregistro=reclibrofact.numeroregistro and factura.anio=reclibrofact.anio)
                   where ordenpagocontable.idprestador=$1
                         and ordenpagocontable.opcfechaingreso between current_date - EXTRACT(DAY FROM current_date)::integer +1 and current_date;
BEGIN

IF NOT  iftableexistsparasp('tretencionprestador') THEN
-- Creacion de la Tabla temporal
   CREATE TEMP TABLE "tretencionprestador" (
     "idtiporetencion" BIGINT,
     "rpfecha" TIMESTAMP WITHOUT TIME ZONE DEFAULT ('now'::text)::date,
     "idprestador" BIGINT,
     "rpmontofijo" DOUBLE PRECISION,
  "rpmontoporc" DOUBLE PRECISION,
  "rpmontototal" DOUBLE PRECISION,
  "rpmontobase" DOUBLE PRECISION,
  "rpmontoretanteriores" DOUBLE PRECISION
  ) WITHOUT OIDS;
end if;




OPEN cursortiporetencion;
FETCH cursortiporetencion INTO rtiporetencion;
xretencioncalculadaacumulada = 0;
while found loop

	-- Calculo la Retención
	-- Sumar los Pagos Anteriores del mes
	-- CS 2017-08-24 Los pagos acumulados no son necesarios para este tipo de Retencion SUSS
   	xsumapago=0; xsumaret=0;
	xmontobase = xsumapago + $2 - rtiporetencion.montonosujeto;
	xretencioncalculada = 0;

	xmontofijo = 0; --rescalaretencion.ermontofijo;
	xmontoprop = xmontobase * rtiporetencion.aretenerinscripto;
	xmontoretanteriores = xsumaret;
	xmontototal =  xmontofijo + xmontoprop - xsumaret;

	xretencioncalculada = xmontototal;

	if (xmontototal<rtiporetencion.minimoretencion) THEN
	      xretencioncalculada = 0;
	end if;

	if xretencioncalculada<>0 THEN
	   insert into tretencionprestador(idtiporetencion,idprestador,rpmontofijo,rpmontoporc,rpmontototal,rpmontobase,rpmontoretanteriores)
	   values (rtiporetencion.idtiporetencion,$1,xmontofijo,xmontoprop,xretencioncalculada,xmontobase,xmontoretanteriores);
	end if;

	xretencioncalculadaacumulada = xretencioncalculadaacumulada + xretencioncalculada;
	FETCH cursortiporetencion INTO rtiporetencion;
end loop;
CLOSE cursortiporetencion;


return xretencioncalculadaacumulada;
END;
$function$
