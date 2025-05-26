CREATE OR REPLACE FUNCTION public.far_abmliquidacionctacteinstitucion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
cursorov CURSOR FOR SELECT * FROM tfar_liqitem;

	rliquidacion RECORD;
        r_liquidacionitemfvc RECORD;
	
ridliquidacionitems integer;

BEGIN


 OPEN cursorov;
    FETCH cursorov into rliquidacion;
    WHILE  found LOOP

        IF nullvalue(rliquidacion.idliquidacion) THEN --no existe la liquidacion

         INSERT INTO  far_liquidacion (lidescripcion,idobrasocial,lfechadesde,lfechahasta,pcporcentaje,coseguro)
                        ( SELECT concat(' Fechas ' ,rliquidacion.lfechadesde , ' - '  ,  rliquidacion.lfechahasta , '. Liquidacion de '
                          , osdescripcion ) ,
                          idobrasocial,rliquidacion.lfechadesde,
                          rliquidacion.lfechahasta,null, false
                          FROM tfar_liqitem   NATURAL JOIN far_obrasocial
                         );
         rliquidacion.idliquidacion = currval('far_liquidacion_idliquidacion_seq'::regclass);
         rliquidacion.idcentroliquidacion = centro();
         INSERT INTO far_liquidacionestado(idestadotipo,idliquidacion)   VALUES(1,rliquidacion.idliquidacion);
             
 
         PERFORM  far_cambiarestadofacturaventacupon (idfacturacupon, centro,nrofactura,tipocomprobante
     ,nrosucursal,tipofactura,15,concat('Al generar liquidacion ',rliquidacion.idliquidacion ,'-' ,centro()))  as x,
            idfacturacupon,	centro,	nrofactura,	tipocomprobante,nrosucursal,	tipofactura 
                 FROM (SELECT  idfacturacupon,	centro,	nrofactura,	tipocomprobante,nrosucursal,	tipofactura 
                        FROM facturaventa as fv NATURAL JOIN itemfacturaventa 
                        NATURAL JOIN facturaventacupon JOIN far_configura_reporte as cr ON idvalorescaja = idvalorcajactacte
                        LEFT JOIN cliente on cliente.nrocliente = fv.nrodoc AND cliente.barra=fv.barra                                
                        LEFT JOIN facturaventacuponestado as fvce USING(idfacturacupon, centro,nrofactura,tipocomprobante,nrosucursal,tipofactura)
                                               
WHERE  (NULLVALUE(fvce.idordenventaestadotipo) OR  (fvce.idordenventaestadotipo=13 and nullvalue(fvce.fvcefechafin)))
AND cr.idobrasocial= rliquidacion.idobrasocial  and nullvalue(anulada) AND fechaemision >= rliquidacion.lfechadesde AND fechaemision <= rliquidacion.lfechahasta
                        AND fv.tipofactura<>'NC') as t
                where true;


                        
              
        ELSE --la liquidacion ya existe
           
           
              PERFORM  far_cambiarestadofacturaventacupon (idfacturacupon, centro,nrofactura,tipocomprobante
              ,nrosucursal,tipofactura,14,concat('Al ingresar el cupon a liquidacion ',rliquidacion.idliquidacion ,'-',centro())) FROM tfar_liqitem;
              INSERT INTO far_liquidacionitems(idliquidacion ,idcentroliquidacion)VALUES(rliquidacion.idliquidacion ,rliquidacion.idcentroliquidacion);
           
     /* busco q no este far_liquidacionitemfvc*/  

      /*   SELECT INTO  r_liquidacionitemfvc *  FROM far_liquidacionitemfvc
               WHERE  idfacturacupon=rliquidacion.idfacturacupon and centro=rliquidacion.centro and nrofactura= rliquidacion.nrofactura and 
               tipocomprobante= rliquidacion.tipocomprobante and nrosucursal=rliquidacion.nrosucursal and tipofactura=rliquidacion.tipofactura ;

IF NOT FOUND THEN
*/

             INSERT INTO far_liquidacionitemfvc(idliquidacionitem,idcentroliquidacionitem,idfacturacupon, centro,nrofactura,tipocomprobante,nrosucursal,tipofactura)   
              VALUES(currval('far_liquidacionitems_idliquidacionitem_seq'::regclass), centro(),rliquidacion.idfacturacupon,rliquidacion.centro,rliquidacion.nrofactura,rliquidacion.tipocomprobante,rliquidacion.nrosucursal,rliquidacion.tipofactura);
          
--END IF;
                 
                  /* recuperar ultimo movimiento*/
                  ridliquidacionitems =currval('far_liquidacionitems_idliquidacionitem_seq');
                        

                  /*inserta el estado de el item de la liquidacion*/

            /*      INSERT INTO far_liquidacionitemestado(idcentroliquidacionitem,idliquidacionitem,liefechaini,liefechafin,idestadotipo,liedescripcion)   
              VALUES(centro(),ridliquidacionitems,now(),null,rliquidacion.idestadotipo,concat(rliquidacion.liedescripcion,' ',rliquidacion.idliquidacion ,'-',centro()));
          
*/
--KR 02-08-18 modifique para que guarde el estado actual y modifique el anterior.
         PERFORM  far_cambiarestadoliquidacionitem(ridliquidacionitems, centro(), rliquidacion.idestadotipo, concat(rliquidacion.liedescripcion, 'Desde SP far_abmliquidacionctacteinstitucion'));





        END IF;
     fetch cursorov into rliquidacion;
        
  END LOOP;
  CLOSE cursorov;

   


return true;
END;
$function$
