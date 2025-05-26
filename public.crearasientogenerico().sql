CREATE OR REPLACE FUNCTION public.crearasientogenerico()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    	rliq RECORD;
	xestado bigint;
	xidasiento bigint;
	idas integer;

	curasiento refcursor;
	curitem refcursor;
	regasiento RECORD;
	regitem RECORD;
   
BEGIN


OPEN curasiento FOR SELECT * FROM tasientogenerico;

OPEN curitem for select * from tasientogenericoitem;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP
	
	idas = regasiento.idasientogenerico; --se usa para discriminar los asientos

	insert into asientogenerico(agtipoasiento,agfechacontable,agdescripcion)
	values(regasiento.agtipoasiento,regasiento.agfechacontable,regasiento.agdescripcion);
	xidasiento=currval('asientogenerico_idasientocontable_seq');
	
	if (not nullvalue(regasiento.idasientosueldo)) then
		insert into asientogenerico_as(idasientogenerico,idcentroasientogenerico,idasientosueldo,idcentroasientosueldo)
		values(xidasiento,centro(),regasiento.idasientosueldo,centro());
	end if;

	if (not nullvalue(regasiento.nroordenpago)) then
		insert into asientogenerico_ordenpago(idasientogenerico,idcentroasientogenerico,nroordenpago,idcentroordenpago)
		values(xidasiento,centro(),regasiento.nroordenpago,centro());
	end if;

	if (not nullvalue(regasiento.idsigesoti)) then
		insert into asientogenerico_oti(idasientogenerico,idcentroasientogenerico,idsigesoti,idcentrosigesoti)
		values(xidasiento,centro(),regasiento.idsigesoti,centro());
	end if;

	FETCH curitem INTO regitem;
	while found LOOP
		if (idas = regitem.idasientogenerico) then
			insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
			values(xidasiento,centro(),regitem.acimonto,regitem.acinrocuentac,regitem.acidescripcion,regitem.acid_h);
		end if;
		FETCH curitem INTO regitem;
	END LOOP;
	CLOSE curitem;

	perform cambiarestadoasientogenerico(xidasiento,centro(),1);

	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN TRUE;
END;$function$
