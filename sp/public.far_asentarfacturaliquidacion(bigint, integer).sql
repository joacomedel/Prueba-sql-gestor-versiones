CREATE OR REPLACE FUNCTION public.far_asentarfacturaliquidacion(bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

elcomprobante varchar(100);
eliditemfactventa bigint;
resp boolean;
informeF integer;
movimientoconcepto VARCHAR;
nrocuentacontable VARCHAR;
comprobantemovimiento BIGINT;      
viddeuda BIGINT;
viddeudacliente BIGINT;
elidusuario INTEGER; 
--lacuenta VARCHAR;
--REGISTROS
elem record;
rfacvtacupon record;
rfactventa record;
rusuario RECORD;
--CURSORES

--cfactventa CURSOR FOR SELECT * FROM tempfacturaventa;
ccliquidacion CURSOR FOR  SELECT  SUM(round(CAST ((CASE WHEN fovifv.tipofactura='NC' THEN fovii.oviimonto *-1
ELSE fovii.oviimonto END) AS numeric),2)) AS monto ,cuentascontables.nrocuentac, desccuenta,nrocliente, c.barra, c.denominacion	,fos.oscuit	
                   ,fos.idobrasocial ,fos.nrocuentac as lacuenta,idclientectacte, far_liquidacion.nroliquidacionorigen
                 FROM far_liquidacion NATURAL JOIN far_liquidacionitems  NATURAL JOIN far_liquidacionitemovii
                 NATURAL JOIN far_ordenventaitemimportes 	fovii	
                 NATURAL JOIN far_obrasocial AS fos 
/*Dani agrego el 20072020*/
/*Dani comento el 2972021 porque para liq mutual policial obtenia tres tuplas en lugar de una por teneer en 3 configuraciones para el valor idvalorcajacoseguro=54. Hable con ML y dejamos pendiente  de si se vuelve a necesitar  haceer unaproyeccion y un dictinct por ese valor para obtener nuevamente una sola tupla*/
--JOIN far_configura_reporte cr ON cr.idobrasocial = fos.idobrasocial AND cr.idvalorcajacoseguro = fovii.idvalorescaja

 
                 JOIN far_ordenventaitem fovi USING(idordenventaitem, idcentroordenventaitem) 		
                JOIN far_ordenventaitemitemfacturaventa  as fovifv ON (fovi.idordenventaitem=fovifv.idordenventaitem and fovi.idcentroordenventaitem=fovifv.idcentroordenventaitem )
--JOIN far_liquidacionitemestado as flie USING(idliquidacionitem,idcentroliquidacionitem)   

JOIN far_liquidacionitemestado as flie ON(flie.idliquidacionitem=far_liquidacionitems.idliquidacionitem and flie.idcentroliquidacionitem=far_liquidacionitems.idcentroliquidacionitem and idestadotipo=1 and nullvalue(liefechafin)  ) 

               NATURAL JOIN facturaventa as fv
                NATURAL JOIN far_articulo 
                  JOIN cuentascontables ON (actacble=cuentascontables.nrocuentac) JOIN cliente as c 
                   JOIN clientectacte USING(nrocliente, barra)
                   ON (fos.oscuit ilike concat(c.cuitini ,c.cuitmedio,c.cuitfin) AND fos.oscuit<>'') 	
                WHERE  idliquidacion=$1	AND idcentroliquidacion=$2 AND 
 (idestadotipo=1 and nullvalue(liefechafin))  AND
 nullvalue(fv.anulada)
              GROUP BY cuentascontables.nrocuentac,desccuenta,nrocliente, c.barra,c.denominacion,fos.oscuit,fos.idobrasocial ,fos.nrocuentac,idclientectacte, far_liquidacion.nroliquidacionorigen	
          
                UNION		
                SELECT SUM(round(CAST ((montoitemsvalorcaja) AS numeric),2)) AS monto ,destctasctableimporte.nrocuentac, desccuenta,nrocliente, barra,c.denominacion,fos.oscuit	,fos.idobrasocial ,fos.nrocuentac as lacuenta	,idclientectacte, CASE WHEN nullvalue(far_liquidacion.nroliquidacionorigen) THEN '' ELSE far_liquidacion.nroliquidacionorigen END AS nroliquidacionorigen
              FROM far_liquidacion NATURAL JOIN far_obrasocial  AS fos JOIN 
              (SELECT cuentascontables.nrocuentac, desccuenta,idliquidacion, idcentroliquidacion,		
              round(cast(CASE WHEN tipofactura = 'NC' THEN monto*-1 ELSE monto END * ((abs((sum(importe)*100) /(itemfacturaventaimportetotal(nrosucursal, nrofactura, tipocomprobante, tipofactura)))) / 100) 
              as numeric),2) as montoitemsvalorcaja 		
              FROM itemfacturaventa natural join facturaventacupon NATURAL JOIN far_liquidacionitemfvc NATURAL JOIN far_liquidacionitems	
--dani agrego el 200922 porq en algunas liq traia items  que no correspondia(Ej liq 3433 Amuc)
NATURAL JOIN far_liquidacionitemestado
JOIN facturaventacuponestado as fvce USING(idfacturacupon, centro,nrofactura,tipocomprobante,nrosucursal,tipofactura)	JOIN cuentascontables ON(idconcepto=cuentascontables.nrocuentac) 			
             WHERE  idconcepto <> 50840 AND idliquidacion=$1 AND idcentroliquidacion=$2 AND nullvalue(fvce.fvcefechafin) AND idordenventaestadotipo=14
and (idestadotipo=1 and nullvalue(liefechafin)) 

                GROUP BY idliquidacion, idcentroliquidacion,nrosucursal, nrofactura, tipocomprobante, tipofactura,monto,
               nrocuentac, desccuenta) as destctasctableimporte	USING (idliquidacion, idcentroliquidacion)	
            JOIN cliente as c ON (fos.oscuit ilike concat(c.cuitini ,c.cuitmedio,c.cuitfin) AND fos.oscuit<>'') 		
            JOIN clientectacte USING(nrocliente, barra)
            WHERE idliquidacion=$1	AND idcentroliquidacion=$2
               GROUP BY destctasctableimporte.nrocuentac, desccuenta,nrocliente, barra ,c.denominacion ,fos.oscuit	,fos.idobrasocial ,fos.nrocuentac,idclientectacte , far_liquidacion.nroliquidacionorigen	;
 

BEGIN
    
     open ccliquidacion;
     FETCH ccliquidacion into rfactventa;
      /* Se guarda la cabecera de la factura */
    SELECT INTO elem * FROM devolvernrofactura(centro(),1,'LI',2);

     INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra)
            VALUES(elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero,
                 rfactventa.nrocliente,rfactventa.barra,1000,centro(),current_date,elem.tipofactura, rfactventa.barra);
    -- SELECT INTO lacuenta * FROM far_obrasocial  WHERE idobrasocial=rfactventa.idobrasocial; 
     elcomprobante = concat(elem.tipocomprobante,'|',elem.tipofactura,'|',elem.nrosucursal,'|',elem.sgtenumero);

     INSERT INTO ctactedeudanoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,nrocuentac,idconcepto,nrodoc)
			  VALUES (21,rfactventa.barra,rfactventa.oscuit,now(),rfactventa.lacuenta,998,rfactventa.nrocliente);

     viddeuda =currval('ctactedeudanoafil_iddeuda_seq');


    INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,nrocuentac,fechavencimiento)
			  VALUES (21,rfactventa.idclientectacte,rfactventa.lacuenta,current_date+30);

     viddeudacliente =currval('ctactedeudacliente_iddeuda_seq');
   
  ---CREO EL INFORME 
     SELECT INTO informeF * FROM crearinformefacturacion(rfactventa.nrocliente, rfactventa.barra, 12);

      WHILE FOUND LOOP
                       INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                                         idconcepto,cantidad,importe,descripcion,idiva)
			                             VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.sgtenumero,
                                         rfactventa.nrocuentac,1,rfactventa.monto,rfactventa.desccuenta,1 );
                                    
                  FETCH ccliquidacion into rfactventa;
                 END LOOP;
     
         SELECT INTO rfacvtacupon SUM(importe) as monto  FROM  itemfacturaventa  WHERE tipocomprobante=elem.tipocomprobante
                   AND nrosucursal= elem.nrosucursal
                   AND nrofactura=elem.sgtenumero
                   AND tipofactura=elem.tipofactura;
     

           INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
            tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
            cuotas, nrocupon)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                  2, 0, 0, round(CAST (rfacvtacupon.monto AS numeric),2),
                   1, 0);
   

   /* se devuelve el comprobante generado */


   /* Se actualiza la cabecera de la factura */
   UPDATE facturaventa SET
                   importeamuc=0  ,
                   importeefectivo=0,
                   importedebito=0,
                   importecredito=round(CAST (rfacvtacupon.monto AS numeric),2),
                   importectacte=0,
                   importesosunc=0
                  
    WHERE tipocomprobante=elem.tipocomprobante
                   AND nrosucursal= elem.nrosucursal
                   AND nrofactura=elem.sgtenumero
                   AND tipofactura=elem.tipofactura;


/* Se guarda la informacion del usuario que genero el comprobante */
                SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
                IF not found THEN
                   elidusuario = 25;
                ELSE
                    elidusuario = rusuario.idusuario;
                END IF;
                INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                VALUES   (elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero, elem.tipofactura,elidusuario,elem.sgtenumero);

 /* Dejo la LI en estado sincronizado */
  INSERT INTO multivac.facturaventa_migrada(nrofactura, tipocomprobante, nrosucursal,
            tipofactura,centro, iditem, fechamigracion, estaanulada)
            VALUES(elem.sgtenumero, elem.tipocomprobante, elem.nrosucursal, elem.tipofactura,
                 centro(), 0, now(),0 );

 /*Dejo el informe EN ESTADO FACTURADO. y lo vinculo con la factura */
 

  UPDATE informefacturacion set idformapagotipos = 2, nrofactura=elem.sgtenumero, tipocomprobante= elem.tipocomprobante, nrosucursal=elem.nrosucursal,
            tipofactura=elem.tipofactura WHERE nroinforme =informeF AND idcentroinformefacturacion = centro();
  INSERT INTO  informefacturacionliqfarmacia(nroinforme,idcentroinformefacturacion,idliquidacion,idcentroliquidacion)
             VALUES(informeF,centro(), $1, $2);
  PERFORM cambiarestadoinformefacturacion(informeF,centro(),4,
  concat('Se genero el comprobante LI para la liquidacion ' , $1 ,' - ' , $2));

---GENERO LA DEUDA POR LA LI

 movimientoconcepto = concat('Farmacia. Deuda por generacion de informe numero: ' , informeF , ' - ' , centro()
                              , '. Liquidacion: ' , $1 ,' - ' , $2  );
  
 comprobantemovimiento = informeF * 100 +centro();
    
 UPDATE ctactedeudanoafil SET importe= round(CAST (rfacvtacupon.monto AS numeric),2) , saldo=round(CAST (rfacvtacupon.monto AS numeric),2),
                           movconcepto=movimientoconcepto, idcomprobante=comprobantemovimiento
           WHERE iddeuda= viddeuda and idcentrodeuda=centro();


  UPDATE ctactedeudacliente SET importe= round(CAST (rfacvtacupon.monto AS numeric),2) , saldo=round(CAST (rfacvtacupon.monto AS numeric),2),
                           movconcepto=movimientoconcepto, idcomprobante=comprobantemovimiento
           WHERE iddeuda= viddeudacliente and idcentrodeuda=centro();

--KR 27-06-18 Se guarda el importe total en la cabecera de la liquidacion 
  UPDATE far_liquidacion SET limporte= round(CAST (rfacvtacupon.monto AS numeric),2)   
           WHERE idliquidacion=$1 AND idcentroliquidacion=$2;
return elcomprobante;
END;$function$
