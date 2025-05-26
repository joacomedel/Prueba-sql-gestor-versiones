CREATE OR REPLACE FUNCTION public.asientogenerico_cerrar()
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
	regasientoinfo record;
	regopc  record;
	elidopc bigint;
	elidcopc integer;
	elidop bigint;
	elidcop integer;
	 resp boolean;
   
BEGIN


OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

        if (not regasiento.operacion='reversion') then
	      	update asientogenerico set idmultivac=regasiento.idmultivac,agerror=regasiento.agerror
 		where idasientogenerico=regasiento.idasientogenerico and idcentroasientogenerico=regasiento.idcentroasientogenerico;

		if (not regasiento.idmultivac='') then

			perform	cambiarestadoasientogenerico(regasiento.idasientogenerico,regasiento.idcentroasientogenerico,7);

                        -- CS 2017-10-18 llama a este sp que segun el tipo de comprobante, lo coloca en estado Sincronizado
                        perform asientogenerico_cambiarestadocomprobante(regasiento.idasientogenerico,regasiento.idcentroasientogenerico);

		end if;	
	else
		update asientogenerico set idasientogenericorevertido=regasiento.idmultivac,agerror=regasiento.agerror
 		where idasientogenerico=regasiento.idasientogenerico and idcentroasientogenerico=regasiento.idcentroasientogenerico;
	end if;

	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN TRUE;
END;$function$
