CREATE OR REPLACE FUNCTION public.agregarliquidaciontarjetaitem()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rliq RECORD;
    elidliquidaciontarjeta bigint;   
    elidcentroliquidaciontarjeta integer;
    accion varchar;
    resp varchar;
    cliq CURSOR FOR
               select * from tliquidaciontarjetaitem;
    
BEGIN
     OPEN cliq;
     FETCH cliq INTO rliq;
     WHILE found LOOP
	begin
		accion = rliq.accion;
                 elidliquidaciontarjeta = rliq.idliquidacion;
                 elidcentroliquidaciontarjeta =rliq.idcentrolt ;
		
        
        if (accion='cargarCupon') then
           SELECT INTO resp liquidaciontarjeta_generarcuponfactura();
        END IF ;
        if (accion='I') then
			begin
			insert into liquidaciontarjetaitem(ltiusuariocargar,idliquidaciontarjeta,idcentroliquidaciontarjeta,idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura,idrecibocupon,idcentrorecibocupon) 
			values (sys_dar_usuarioactual(),
			rliq.idliquidacion,
			rliq.idcentrolt,
			rliq.idfacturacupon,
			rliq.centro,
			rliq.nrofactura,
			rliq.tipocomprobante,
			rliq.nrosucursal,
			rliq.tipofactura,

			rliq.idrecibocupon,
			rliq.idcentrorecibocupon);


                        if not nullvalue(rliq.idfacturacupon) then
			      insert into facturaventacuponestado(idordenventaestadotipo,idfacturacupon,centro,fvcedescripcion,nrofactura,tipocomprobante,nrosucursal,tipofactura)
			values (1,rliq.idfacturacupon,rliq.centro,concat ( 'Liquidacion Tarjeta ' , rliq.idliquidacion::text),rliq.nrofactura,rliq.tipocomprobante,rliq.nrosucursal,rliq.tipofactura);

                        else
			      insert into recibocuponestado(idordenventaestadotipo,idrecibocupon,idcentrorecibocupon,rcedescripcion)
			values (1,rliq.idrecibocupon,rliq.idcentrorecibocupon,concat ( 'Liquidacion Tarjeta ' , rliq.idliquidacion::text));

                        end if;




			end;
		else
		   if (accion='D') then
			begin
			delete from liquidaciontarjetaitem
				where idliquidaciontarjetaitem=rliq.idliquidaciontarjetaitem
                                       and idcentroliquidaciontarjetaitem=rliq.idcentroliquidaciontarjetaitem 	
;
                        if not nullvalue(rliq.idfacturacupon) then
                            begin
			    insert into facturaventacuponestado(idordenventaestadotipo,idfacturacupon,centro,fvcedescripcion,nrofactura,tipocomprobante,nrosucursal,tipofactura)
			values (2,rliq.idfacturacupon,rliq.centro,concat ( 'Eliminado de Liquidacion Tarjeta ' , rliq.idliquidacion::text),rliq.nrofactura,rliq.tipocomprobante,rliq.nrosucursal,rliq.tipofactura);
			
			    update facturaventacuponestado set fvcefechafin=now()
			where idfacturacupon=rliq.idfacturacupon and centro=rliq.centro 
				and nrofactura=rliq.nrofactura and tipocomprobante=rliq.tipocomprobante
				and nrosucursal=rliq.nrosucursal and tipofactura=rliq.tipofactura and idordenventaestadotipo=1;
                            end;
                        else
                            begin

                           insert into recibocuponestado(idordenventaestadotipo,idrecibocupon,idcentrorecibocupon,rcedescripcion)
			   values (2,rliq.idrecibocupon,rliq.idcentrorecibocupon,concat ( 'Eliminado de Liquidacion Tarjeta ' , rliq.idliquidacion::text));
			
			    update recibocuponestado set rcefechafin=now()
			where idrecibocupon=rliq.idrecibocupon and idcentrorecibocupon=rliq.idcentrorecibocupon
                              and idordenventaestadotipo=1;

                            end;

                        end if;

			end;
		   end if;
		end if;
	end;      
	FETCH cliq INTO rliq;
     END LOOP;
     CLOSE cliq;

     /*Actualizo la cabecera de la liquidacion */
    UPDATE liquidaciontarjeta SET  lttotalcupones = t.cantcupones , lttotalpagado = t.eltotal
     FROM (  SELECT  SUM(monto) as  eltotal , count(*)as cantcupones
             FROM liquidaciontarjetaitem 
             NATURAL JOIN facturaventacupon  
             WHERE  idliquidaciontarjeta = elidliquidaciontarjeta  
                    and  idcentroliquidaciontarjeta =  elidcentroliquidaciontarjeta 
             GROUP BY idliquidaciontarjeta ,idcentroliquidaciontarjeta
           ) as T
    WHERE  idliquidaciontarjeta = elidliquidaciontarjeta  and  idcentroliquidaciontarjeta = elidcentroliquidaciontarjeta   ;


     RETURN TRUE;
END;
$function$
