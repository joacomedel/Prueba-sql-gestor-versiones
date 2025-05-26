CREATE OR REPLACE FUNCTION public.asientogenerico_crear()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	xidasiento bigint;
	curasiento refcursor;	
	regasiento RECORD;
        curejercicio refcursor;
        rejerciciocontable RECORD;
        rasientodesbalanceado RECORD;
        rasientocondiferencia RECORD;
        ridsiges RECORD;
        rag_r RECORD;
        xfechaimputa DATE;
        xfechaimputa2 DATE;
        xidejercicio integer;
	rusuario RECORD;
	resp_info_ejercico varchar;
        adescripcion  varchar;
        rresp  RECORD;
        ritemasiento  RECORD;
        rexiste RECORD;
   
BEGIN

/*
Esta es la temporal con los datos de ingreso
TABLE tasientogenerico	(
            idoperacion bigint,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
	    centrocosto int
                        );

*/

OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

	-- ORDEN PAGO CONTABLE	------------------------------------------------------------
	if (regasiento.idasientogenericocomprobtipo=1) then 
		select into xidasiento asientogenerico_crear_1();  
	end if;-----------------------------------------------------------------------------

	-- LIQUIDACIONES DE TARJETA---------------------------------------------------------
	if (regasiento.idasientogenericocomprobtipo=2) then 
		select into xidasiento asientogenerico_crear_2();    
	end if;-----------------------------------------------------------------------------

	-- BONIFICACIONES EN APORTES JUB PEN------------------------------------------------
	if (regasiento.idasientogenericocomprobtipo=3) then 
		select into xidasiento asientogenerico_crear_3();    
	end if;-----------------------------------------------------------------------------

	-- MINUTAS DE PAGO  ----------------------------------------------------------------
	if (regasiento.idasientogenericocomprobtipo=4) then 
		select into xidasiento asientogenerico_crear_4();    
	end if;-----------------------------------------------------------------------------

        -- FACTURA VENTA
	if (regasiento.idasientogenericocomprobtipo=5) then 
                select into xidasiento asientogenerico_crear_5();  
	end if;-----------------------------------------------------------------------------
	
	-- ASIENTO MANUAL
	if (regasiento.idasientogenericocomprobtipo=6) then 
                select into xidasiento asientogenerico_crear_6();  
	end if;-----------------------------------------------------------------------------	

        -- COMPROBANTE DE COMPRA
	IF (regasiento.idasientogenericocomprobtipo=7) then 
--KR 16-09-20 SI reclibrofact.idrlfprecarga NO ES NULO es un comprobante que se cargo desde la PRecarga, caso contrario se cargo en reclibrofact. 

           
           SELECT INTO rexiste *  
                       FROM tasientogenerico JOIN reclibrofact 
                       ON (numeroregistro = tasientogenerico.idoperacion/10000 and anio = tasientogenerico.idoperacion%10000);  --AND  nullvalue(reclibrofact.idrlfprecarga));

           IF FOUND  THEN
               IF nullvalue(rexiste.idrlfprecarga)  THEN
                      select into xidasiento asientogenerico_crear_7();  
              
                ELSE 
                    RAISE NOTICE 'asientogenerico_crear idasientogenericocomprobtipo (%,%)',rexiste.idoperacion::bigint/10000,rexiste.idoperacion::bigint%10000;
                    select into xidasiento asientogenerico_precarga_crear_7(rexiste.numeroregistro,rexiste.anio); 
                END IF;
          END IF;
      
               
	end if;-----------------------------------------------------------------------------	

        -- RECIBO COBRANZA
	if (regasiento.idasientogenericocomprobtipo=8) then 
                select into xidasiento asientogenerico_crear_8();  
	end if;-----------------------------------------------------------------------------	

        -- IMPUTACION COBRANZA
	if (regasiento.idasientogenericocomprobtipo=9) then 
                select into xidasiento asientogenerico_crear_9();  
	end if;-----------------------------------------------------------------------------	
      -- Liquidacion sueldos
	if (regasiento.idasientogenericocomprobtipo=10) then
                select into xidasiento asientogenerico_crear_6();
	end if;-----------------------------------------------------------------------------	

   if not nullvalue(xidasiento) then
               --- VAS 13/09/19 se controla que no se generen asientos sobre cuentas configuradas como no imputables
               SELECT INTO ritemasiento * FROM asientogenericoitem
               WHERE idasientogenerico = xidasiento
                     and  idcentroasientogenerico = centro()
                     and nrocuentac IN(
                             SELECT nrocuentac
                             FROM multivac.mapeocuentascontables
                             WHERE not imputable 
                     );

                IF FOUND THEN
                         RAISE EXCEPTION 'No puede generar un asiento sobre una cuenta NO Imputable (%)',ritemasiento.nrocuentac;
                END IF;
                --- VAS 13/09/19 se controla que no se generen asientos sobre cuentas configuradas como no imputables

		-- MaLaPi 01-03-2019 Le agrego el usuario que genera el asiento
		SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
		IF NOT FOUND THEN
			rusuario.idusuario = 25;
		END IF;
		UPDATE asientogenerico SET agidusuario = rusuario.idusuario 
				WHERE idasientogenerico = xidasiento 
					AND idcentroasientogenerico = centro();
		
       
	    PERFORM	cambiarestadoasientogenerico(xidasiento,centro(),1);

---------------------------------------------------------------------------------------------------------------
        -- VAS 06/05/2019 se calcula la fecha que corresponde al ejercicio contable abierto segun la fecha del comprobante
       SELECT INTO xfechaimputa agfechacontable FROM asientogenerico WHERE idasientogenerico=xidasiento and idcentroasientogenerico=centro();

       SELECT INTO resp_info_ejercico  contabilidad_ejercicio_info(concat('{agfechacontable=',xfechaimputa,',idasientogenericocomprobtipo=',regasiento.idasientogenericocomprobtipo,'}'));
       EXECUTE sys_dar_filtros(resp_info_ejercico) INTO rresp;

       ------------ VAS 22/05/2018 controlo que la fecha no sea posterior a la fecha actual, no se puede crear un asiento con fecha posterior a la actual
       IF not ( rresp.fechaimputacion < to_char( date_trunc('day',now())+'30day' ::interval, 'YYYY-MM-DD' )
       )THEN             	              
	        RAISE EXCEPTION 'No puede generarse un asiento con fecha mayor a 30 dias %', rresp.fechaimputacion;
       END IF;

       -- Actualizo el asiento con la fecha contable que le corresponda
       UPDATE asientogenerico
       SET idejerciciocontable = rresp.idejerciciocontable
            ,agfechacontable = rresp.fechaimputacion	
       WHERE idasientogenerico = xidasiento
               and idcentroasientogenerico = centro() ;

-- --------------------------------------------------------------------------------------------------------------

      end if; -- del Not nullvalue(xidasiento)

      FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
DELETE FROM tasientogenerico; --- AGREGO VAS 15/06

--CS 2019-01-31 Verifica si está DESBALANCEADO, y le cambia el estado. Además lo guarda en una tabla para volver a regenerarlos

select into ridsiges idcomprobantesiges,idasientogenericocomprobtipo 
			from asientogenerico 
			where idasientogenerico=xidasiento AND idcentroasientogenerico = centro();
if found then
   UPDATE asientogenerico_regenerar SET agrfecharesolucion = now() 
	WHERE idcomprobantesiges=ridsiges.idcomprobantesiges 
	and idasientogenericocomprobtipo=ridsiges.idasientogenericocomprobtipo
	AND nullvalue(agrfecharesolucion);
   --MaLaPi 20-02-2019 Ya no se puede borrar de esta tabla, pues es una tabla sincronizable
   --delete from asientogenerico_regenerar where idcomprobantesiges=ridsiges.idcomprobantesiges and idasientogenericocomprobtipo=ridsiges.idasientogenericocomprobtipo;
end if;

select into rasientodesbalanceado * 
from asientogenerico 
LEFT join  (select sum(acimonto) D,idasientogenerico,idcentroasientogenerico
               from asientogenericoitem
               where acid_h='D' AND idasientogenerico=xidasiento
                     AND idcentroasientogenerico = centro()
               group by idasientogenerico,idcentroasientogenerico
) debe using(idasientogenerico,idcentroasientogenerico)
LEFT join (select sum(acimonto) H,idasientogenerico,idcentroasientogenerico
                     from asientogenericoitem
                     Where acid_h='H'  AND  idasientogenerico=xidasiento AND idcentroasientogenerico = centro()
                     group by idasientogenerico,idcentroasientogenerico
) haber using(idasientogenerico,idcentroasientogenerico)
where idasientogenerico=xidasiento AND idcentroasientogenerico = centro()
      and ( abs(debe.D-haber.H)>1 or nullvalue(debe.idasientogenerico) or nullvalue(haber.idasientogenerico)    );

if found then

  IF (rasientodesbalanceado.idasientogenericocomprobtipo=7) THEN 
           RAISE EXCEPTION 'R-001, El comprobante de compro no fue aprobado. (SP asientogenerico_crear) Asientos Desbalanceados.(rasientodesbalanceado,%)',rasientodesbalanceado;
       
   --                 RAISE NOTICE 'El comprobante de compro no fue aprobado. Asientos Desbalanceados';
  ELSE 
           SELECT INTO adescripcion text_concatenar ( concat('[',nrocuentac,',',acid_h,',', acimonto,']')::character varying )
           FROM asientogenerico
           NATURAL JOIN asientogenericoitem 
           WHERE idasientogenerico= xidasiento and idcentroasientogenerico=centro();
RAISE NOTICE '>>>>>>>>>>>>>>> adescripcion(%)',adescripcion;
           -- Se inserta en una tabla para que pueda ser Regenerado, luego de verificar y corregir la causa que provoca el desbalance
           insert into asientogenerico_regenerar(idcomprobantesiges,idasientogenericocomprobtipo,agrdescripcion) 
           values (rasientodesbalanceado.idcomprobantesiges,rasientodesbalanceado.idasientogenericocomprobtipo,adescripcion);
    
           --Queda en estado Rechazado
           --perform cambiarestadoasientogenerico(xidasiento,centro(),5); 
           --MaLapi 20-02-2019 Ya no queda mas como rechazado, una asiento desbalanceado NO DEBE EXISTIR, se elimina de la contabilidad.
           DELETE FROM asientogenericoestado WHERE idasientogenerico=xidasiento AND idcentroasientogenerico = centro(); 
           DELETE FROM asientogenericoitem WHERE idasientogenerico=xidasiento AND idcentroasientogenerico = centro();
           DELETE FROM asientogenerico WHERE idasientogenerico=xidasiento AND idcentroasientogenerico = centro();
  END IF;         
end if;

----------------------------------------------------------------------------------------------------------------------------

RETURN xidasiento*100+centro()::numeric;
END;$function$
