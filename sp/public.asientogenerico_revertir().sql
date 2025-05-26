CREATE OR REPLACE FUNCTION public.asientogenerico_revertir()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
    	rliq RECORD;

	xestado bigint;
	xidasiento bigint;
	xidasiento_new bigint;
	xidcentro integer;
	idas integer;

	curasiento refcursor;
	curitem refcursor;
	regasiento RECORD;
	regitem RECORD;
        rusuario RECORD;
        xdesc varchar;
xfechaimputa RECORD;
resp_info_ejercico varchar;
  rresp  RECORD;
rejerciciocontable record;
respuesta  character varying;
control  character varying;
   
BEGIN


OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

	if nullvalue(regasiento.idasientogenerico) then
		select into regitem * from asientogenerico
		where agdescripcion not like '%REVERSION%' and nullvalue(idasientogenericorevertido) and idasientogenericocomprobtipo=regasiento.idasientogenericocomprobtipo and idcomprobantesiges = regasiento.idcomprobantesiges;
		if found then
  		  xidasiento = regitem.idasientogenerico;	
		  xidcentro = regitem.idcentroasientogenerico;
                end if;
		
	else
		xidasiento = regasiento.idasientogenerico;	
		xidcentro = regasiento.idcentroasientogenerico;

                select into regitem * from asientogenerico
		where agdescripcion not like '%REVERSION%' 
                      and nullvalue(idasientogenericorevertido) and idasientogenerico=xidasiento and idcentroasientogenerico=xidcentro;

	end if;
      
        IF not nullvalue(xidasiento) THEN -- MaLaPi 30-01-2019 Solo si existe el asiento hay que revertirlo
                  --- VAS 2504222  Si el comprobante no se encuentra vinculado a NINGUNA conciliacion bancaria puede ser revertido caso contrario NO    
                  control='';
                  SELECT INTO control conciliacionbancaria_control(concat('{idasientogenerico=',xidasiento, ',idcentroasientogenerico=',xidcentro,'}'));
                  IF not (control='') THEN  
                       -- No se pasan los controles vinculados a la conciliacion bancaria, seguramente el comprobante que se desea modificar se encuentra conciliado
                          RAISE EXCEPTION ' %', control;
                  END IF;

 --VAS 23032022 solo si el asiento se encuentra en un ejercicio abierto puedo revertir, coso contrario se dispara una exepcion
                 
                  SELECT INTO respuesta  contabilidad_asiento_ejercicio_contable_cierre(concat('{idasientogenerico=',xidasiento ,', idcentroasientogenerico=',xidcentro ,'}' ) );

                  EXECUTE sys_dar_filtros(respuesta) INTO rejerciciocontable;

                  if ( not nullvalue (rejerciciocontable.eccerrado) ) THEN   --VAS 23032022 
                               RAISE EXCEPTION 'No puede ser revertido un asiento correspondiente a un ejercicio contable cerrado: ID Asiento: %|%', xidasiento,xidcentro;
                  END IF; 




--CS 2019-01-29 SIEMPRE hay que registrar la reversion.
--	if (regitem.idmultivac<>'' and not nullvalue(regitem.idmultivac)) then
	-- Si ya fue migrado, entonces hay que registrar la Reversion
                
                xdesc = concat('REVERSION asiento ',xidasiento,'|',xidcentro,' - ',regitem.agdescripcion);

		insert into asientogenerico(idasientogenericotipo,idagquienmigra,agtipoasiento,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges)

	        (select case when idasientogenericotipo=1 then 2 else case when idasientogenericotipo=2 then 1 else 6 end end,
                 idagquienmigra,case when agtipoasiento='OTI' then 'OTP' else case when agtipoasiento='OTP' then 'OTI' else 'AS' end end,
                 idasientogenericocomprobtipo,agfechacontable,
		 xdesc,idcomprobantesiges
			from asientogenerico
			where idasientogenerico=xidasiento and idcentroasientogenerico=xidcentro);

	        xidasiento_new=currval('asientogenerico_idasientocontable_seq');
   
		update asientogenerico set idasientogenericorevertido=xidasiento_new,idcentroasientogenericorevertido=centro()
		where idasientogenerico=xidasiento and idcentroasientogenerico=xidcentro;

		insert into asientogenericoitem(acidescripcion,idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acid_h)
		(select xdesc,xidasiento_new,centro(),acimonto,nrocuentac,case when acid_h='D' then 'H' else case when acid_h='H' then 'D' end end
			from asientogenericoitem 
			where idasientogenerico=xidasiento and idcentroasientogenerico=xidcentro); 

		perform	cambiarestadoasientogenerico(xidasiento_new,centro(),1);



---------------------------------------------------------------------------------------------------------------
       -- ESTO LO AGREGO 30/08/2019 este SP se deberia llamar desde asientogenerico_crear asi las restricciones de cualquier asiento que se implementan ahi tambien se aplican 
       -- VAS 06/05/2019 se calcula la fecha que corresponde al ejercicio contable abierto segun la fecha del comprobante
       SELECT INTO xfechaimputa agfechacontable FROM asientogenerico WHERE idasientogenerico=xidasiento and idcentroasientogenerico=xidcentro;

       SELECT INTO resp_info_ejercico  contabilidad_ejercicio_info(concat('{agfechacontable=',xfechaimputa,',idasientogenericocomprobtipo=',regitem.idasientogenericocomprobtipo,'}'));  --- VAS 2025-03-06
       EXECUTE sys_dar_filtros(resp_info_ejercico) INTO rresp;

       ------------ VAS 22/05/2018 controlo que la fecha no sea posterior a la fecha actual, no se puede crear un asiento con fecha posterior a la actual
       IF not ( rresp.fechaimputacion < to_char( date_trunc('day',now())+'30day' ::interval, 'YYYY-MM-DD' )
       )THEN             	              
	        RAISE EXCEPTION 'No puede generarse un asiento con fecha mayor a 30 dias';
       END IF;

       -- Actualizo el asiento con la fecha contable que le corresponda
       UPDATE asientogenerico
       SET idejerciciocontable = rresp.idejerciciocontable
            ,agfechacontable = rresp.fechaimputacion	
       WHERE idasientogenerico =  xidasiento_new
               and idcentroasientogenerico = centro() ;



-- --------------------------------------------------------------------------------------------------------------






        
   END IF;
   FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;

-- MaLaPi 08-08-2019 Le agrego el usuario que genera el asiento
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
    rusuario.idusuario = 25;
END IF;
UPDATE asientogenerico SET agidusuario = rusuario.idusuario WHERE idasientogenerico = xidasiento_new AND idcentroasientogenerico = centro();


RETURN xidasiento_new*100+centro()::numeric;
END;$function$
