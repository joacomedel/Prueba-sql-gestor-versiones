CREATE OR REPLACE FUNCTION public.darretenciongananciasm(pidprestador bigint, pmontopagar double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$-- $1 idprestador
-- $2 montopagar SIN IVA

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


-- Calculo la Retención
     xretencioncalculada = 0;
	select into rtiporetencion 
		tiporetencion.*       from prestadortiporetencion       natural join tiporetencion       
	where idprestador=$1 and idregimenretencion=1;
	if found then

		if ($2 >= rtiporetencion.montonosujeto) then
			OPEN cursorcomprobantes;			
			FETCH cursorcomprobantes INTO rcomp;
			while found loop
				xreg = rcomp.idcomprobante/10000;
				xanio = rcomp.idcomprobante%10000;
				select into xreglibrofact * from reclibrofact where numeroregistro=xreg and anio=xanio;
				xivacomp = xreglibrofact.netoiva21+xreglibrofact.netoiva105+xreglibrofact.netoiva27;
				xretencioncalculada = xretencioncalculada + (xivacomp* rtiporetencion.aretenerinscripto);
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
