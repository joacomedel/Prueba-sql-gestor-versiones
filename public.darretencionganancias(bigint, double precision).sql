CREATE OR REPLACE FUNCTION public.darretencionganancias(bigint, double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$-- $1 idprestador
-- $2 montopagar SIN IVA

DECLARE
       ctemordenpago refcursor;
       crearordenpagocontable integer;
       elidordenpagocontable bigint;

       xretencioncalculada double precision;
       xsumapago double precision DEFAULT 0;
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
       agrupador integer;
--       cursorcomprobantes CURSOR FOR select * from tempcomprobante;

       cursorretenciones CURSOR FOR
                         select *
                                from retencionprestador
                                natural join tiporetencion
                                left join ordenpagocontableestado using (idordenpagocontable,idcentroordenpagocontable)
                         where idregimenretencion=1 and idprestador=$1 and
                               --rpfecha between current_date - EXTRACT(DAY FROM current_date)::integer +1 and current_date
                               rpfecha between current_date - EXTRACT(DAY FROM current_date)::integer +1 and (current_date + interval '1 month')::date - EXTRACT(DAY FROM (current_date + interval '1 month'))::integer
                               and nullvalue(opcfechafin) and idordenpagocontableestadotipo<>6 and idordenpagocontableestadotipo<>1;
       cursorpagos CURSOR FOR
                   SELECT ---netoiva105+netoiva21+netoiva27+nogravado+exento as importesiniva
				          reclibrofact.monto,reclibrofact.montosiniva ,
					 idordenpagocontable, idcentroordenpagocontable,
                                     ---(reclibrofact.monto/reclibrofact.montosiniva) as prom_iva ,
                          CASE WHEN(reclibrofact.montosiniva<>0) THEN opcmontototal/(reclibrofact.monto/reclibrofact.montosiniva)
                             ELSE  montopagado end as importesiniva
                          from ordenpagocontable
                          natural join ordenpagocontablereclibrofact
                          natural join reclibrofact
                          join (select * from ordenpagocontableestado where nullvalue(opcfechafin) and idordenpagocontableestadotipo<>1 and idordenpagocontableestadotipo<>6) as estado using (idordenpagocontable,idcentroordenpagocontable)
                          where ordenpagocontable.idprestador=$1
--                         and opcfechaingreso between current_date - EXTRACT(DAY FROM current_date)::integer +1 and current_date
                           and opcfechaingreso between current_date - EXTRACT(DAY FROM current_date)::integer +1 and (current_date + interval '1 month')::date - EXTRACT(DAY FROM (current_date + interval '1 month'))::integer
                         
					union

					SELECT -- VAS 260623 netoiva105+netoiva21+netoiva27+nogravado+exento as importesiniva
					          reclibrofact.monto,reclibrofact.montosiniva ,
							 idordenpagocontable, idcentroordenpagocontable,
					-----		 (reclibrofact.monto/reclibrofact.montosiniva) as prom_iva ,
                             CASE WHEN(reclibrofact.montosiniva<>0) THEN  opcmontototal/(reclibrofact.monto/reclibrofact.montosiniva)
                             ELSE  opcmontototal end as importesiniva
                            ---- ( opcmontototal/(reclibrofact.monto/reclibrofact.montosiniva) ) as importesiniva
                    from ordenpagocontable
                    natural join ordenpagocontableordenpago
                    natural join factura
                    join reclibrofact on(factura.nroregistro=reclibrofact.numeroregistro) and (factura.anio=reclibrofact.anio)
                    join (select * from ordenpagocontableestado where nullvalue(opcfechafin) and idordenpagocontableestadotipo<>1 and idordenpagocontableestadotipo<>6) as estado using (idordenpagocontable,idcentroordenpagocontable)
                    where ordenpagocontable.idprestador=$1
                         --and opcfechaingreso between current_date - EXTRACT(DAY FROM current_date)::integer +1 and current_date
                         and opcfechaingreso between current_date - EXTRACT(DAY FROM current_date)::integer +1 and (current_date + interval '1 month')::date - EXTRACT(DAY FROM (current_date + interval '1 month'))::integer
                         ;

       cursortiporetencion CURSOR FOR
                select tiporetencion.*
 		        from prestadortiporetencion
       			natural join tiporetencion
       			where idprestador=$1 and idregimenretencion=1;
BEGIN
/*
select into rtiporetencion tiporetencion.*
       from prestadortiporetencion
       natural join tiporetencion
       where idprestador=$1 and idregimenretencion=1;
*/
-- Sumar los Pagos Anteriores del mes
 	raise notice 'calculo retenciones para  %  ', $1;

   OPEN cursorpagos;
   FETCH cursorpagos INTO unpago;
   xsumapago=0;
   while found loop
   		 raise notice '                    Importe de un pago <  %  >', unpago.montosiniva;
         	---VAS 100724 xsumapago = xsumapago + unpago.importesiniva;
                  xsumapago = xsumapago + unpago.montosiniva;		
         	 FETCH cursorpagos INTO unpago;
   end loop;

   raise notice 'PAGOS total   %  ', xsumapago;
-- Sumar las Retenciones anteriores del mes
   OPEN cursorretenciones;
   FETCH cursorretenciones INTO unaret;
   xsumaret=0;
   while found loop
         	 raise notice 'Una ret  retenciones  < % > ', unaret.rpmontototal;
         	 xsumaret = xsumaret + unaret.rpmontototal;
                 agrupador= unaret.eragrupador;  -- me quedo con un agrupador, ojo si el prestador puede tener mas de una retencion diferente 
         	 FETCH cursorretenciones INTO unaret;
   end loop;
   raise notice 'TOTAL retenciones   %  ', xsumaret;
-- Calculo la Retención
   OPEN cursortiporetencion;
   FETCH cursortiporetencion INTO rtiporetencion; --- por cada retencion que tenga configurada el prestador
   xretencioncalculada = 0;
   while found loop
   	       xmontobase = xsumapago + $2 - rtiporetencion.montonosujeto;
               xmontofijo=0;
	       xmontoretanteriores = xsumaret;
	       raise notice 'Monto BASE (%)= totalpagado(%) + importePagarSinIVA (%) - monto sujeto retencion x tabla (%)  ', xmontobase,xsumapago,$2,rtiporetencion.montonosujeto;
               if xmontobase>0 then

            	 	 if rtiporetencion.aretenerinscripto=0 then
		      	 	 raise notice 'ENTRO IF';
              	 	 	 select into rescalaretencion * 
              	 	 	 from escalaretencion
              	 	 	 where erdesdemonto < xmontobase  
                    	 	 	 and erhastamonto >= xmontobase 
                    	 	 	 and idregimenretencion=1  
                   	 	 	 and eragrupador = rtiporetencion.eragrupador
                  	 	 	 AND nullvalue(erborrado); ---es una retencion vigente

              	 	 	 xmontofijo = rescalaretencion.ermontofijo;
              	 	 	 xmontoprop = (xmontobase - rescalaretencion.ermontosobreexed)* rescalaretencion.erporcmonto;
 raise notice 'montoprop(%) =() xmontobase (%) -  monto sobre exed agrupador tabla<%> (%) ) * porcentaje aplicar tabla (%)  ',xmontoprop,xmontobase,rtiporetencion.eragrupador, rescalaretencion.ermontosobreexed,rescalaretencion.erporcmonto;
   
           	 	 else
		      	 	 raise notice 'ENTRO ELSE ';
              	 	 	 xmontoprop = xmontobase*rtiporetencion.aretenerinscripto;
                                 raise notice 'xmontoprop(%) = xmontobase (%) * rtiporetencion (%)',xmontoprop,xmontobase,rtiporetencion.aretenerinscripto;
           	 	 end if;

           	 	 xmontototal =  xmontofijo + xmontoprop - xsumaret;
           	 	 raise notice 'Monto TOTAL(%) = montofijo (%) + montoprop (%) - sumaretenida (%)  ',xmontototal, xmontofijo,xmontoprop,xsumaret;
      
           	 	 if not (xmontototal > rtiporetencion.minimoretencion) then
                	 	 xmontototal = 0;
           	 	 end if;
            	 	 raise notice 'Monto TOTAL = %',xmontototal;
         	 end if;
	 	 /*KR 28-01-20 no se estaban generando retenciones para pago a cuentas ya que no tenemos la documentación respaldatoria*/
 
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

	 	 if (xmontototal>0) THEN
  	 	 	  insert into tretencionprestador(idtiporetencion,idprestador,rpmontofijo,rpmontoporc,rpmontototal,rpmontobase,rpmontoretanteriores)
   	 	 	 values (rtiporetencion.idtiporetencion,$1,xmontofijo,xmontoprop,xmontototal,xmontobase,xmontoretanteriores);

    	 	 	 xretencioncalculada = xretencioncalculada + xmontototal;
	 	 end if;
         
         

         FETCH cursortiporetencion INTO rtiporetencion;
     end loop;
  close cursortiporetencion;

return xretencioncalculada;
END;$function$
