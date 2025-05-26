CREATE OR REPLACE FUNCTION public.asientogenerico_arreglo40716(pnroordenpago character varying, pimporte double precision, pdesc character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

xidasiento bigint;
xid bigint;
xcen integer;
xnroop varchar;

BEGIN

xid = pnroordenpago::bigint/100;
xcen = pnroordenpago::bigint%100;
xnroop = concat(xid,'|',xcen);

	insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
			values(1,4,'2018-12-31',concat('RECLA ',pdesc),xnroop,'OTP',3);
    xidasiento=currval('asientogenerico_idasientocontable_seq');

    insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
					values(xidasiento,centro(),pimporte,'20200',concat('RECLA ',pdesc),'D');

    insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
					values(xidasiento,centro(),pimporte,'40716',concat('RECLA ',pdesc),'H');

    perform	cambiarestadoasientogenerico(xidasiento,centro(),1);

return true;
END;

$function$
