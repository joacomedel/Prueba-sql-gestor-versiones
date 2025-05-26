CREATE OR REPLACE FUNCTION public.darretencionivam(bigint, double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$-- $1 idprestador
-- $2 montopagar SIN IVA
-- comprobantes cargados en Tabla tempcomprobante


DECLARE
      
       xretencioncalculada double precision;       
       rtiporetencion record;
	rcomp record;
	xreglibrofact record;
	xivacomp double precision;	
	xreg bigint;
	xanio integer;

	cursorcomprobantes CURSOR FOR
		select * from tempcomprobante;
BEGIN

	xretencioncalculada = 0;
-- Calculo la Retención
	select into rtiporetencion 
		tiporetencion.*       from prestadortiporetencion       natural join tiporetencion       
	where idprestador=$1 and idregimenretencion=3;
	if found then
		if ($2 >= rtiporetencion.montonosujeto) then
			OPEN cursorcomprobantes;			
			FETCH cursorcomprobantes INTO rcomp;
			while found loop
				xreg = rcomp.idcomprobante/10000;
				xanio = rcomp.idcomprobante%10000;
				select into xreglibrofact * from reclibrofact where numeroregistro=xreg and anio=xanio;
				xivacomp = xreglibrofact.iva21+xreglibrofact.iva105+xreglibrofact.iva27;
				xretencioncalculada = xretencioncalculada + xivacomp;
				FETCH cursorcomprobantes INTO rcomp;
			end loop;
		end if;
	end if;

	if (xretencioncalculada>0) THEN
		insert into tretencionprestador(idtiporetencion,idprestador,rpmontofijo,rpmontoporc,rpmontototal,rpmontobase,rpmontoretanteriores)
		values (rtiporetencion.idtiporetencion,$1,0,0,xretencioncalculada,0,0);
	end if;

	return xretencioncalculada;
END;
$function$
