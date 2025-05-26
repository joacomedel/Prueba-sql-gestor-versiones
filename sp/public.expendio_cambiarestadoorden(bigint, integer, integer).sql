CREATE OR REPLACE FUNCTION public.expendio_cambiarestadoorden(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 --RECORD
   rordenchek RECORD; 
   rlaorden RECORD;
   rusuario RECORD;
   rfichamedicaitem RECORD;
   rordenestados RECORD; 
   rexistemotivo RECORD;
   rordenanulada  RECORD;
   rtitular RECORD;
   rordeninfo RECORD;
 
BEGIN

     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN 
        rusuario.idusuario = 25;
     END IF;
     --MaLaPi 03-01-2022 Agrego para que si existe tome la ultima factura emitida, pues podria tener mas de una, y algunas anulada. Me tengo que asegurar de tomar la ultima emitida para esa orden
     SELECT INTO rlaorden tipo,orden.nroorden, orden.centro, orden.fechaemision, consumo.nrodoc , consumo.tipodoc, facturaventa.fechaemision as fechaemisionfactura, anulada FROM orden natural join consumo left join facturaorden using(nroorden, centro)  left join facturaventa using(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
     WHERE orden.nroorden = $1 AND orden.centro =$2
     ORDER BY nrofactura DESC LIMIT 1;

     UPDATE cambioestadosorden SET ceofechafin= now() WHERE nroorden=$1 AND centro=$2  AND nullvalue(ceofechafin);
     INSERT INTO cambioestadosorden (idordenventaestadotipo,nroorden,centro) VALUES($3,$1,$2);
     
 
     DELETE FROM ordenessinfacturas WHERE nroorden=$1 AND centro=$2;
     DELETE FROM itemordenessinfactura WHERE nroorden=$1 AND centro=$2;

--KR 26-07-19 inserto en ordenestados sino fue insertada y si el estado que manda por parametro es el 2 (cancelada)
--MaLaPi 28-08-2019 Verifico si ya existe un estado del mismo tipo que el que quiero
     SELECT INTO rordenestados * FROM ordenestados WHERE nroorden = $1 AND centro=$2 AND $3 = 2; --AND $3= 2 
     IF NOT FOUND AND $3 = 2 THEN 
        INSERT INTO ordenestados (nroorden,centro, fechacambio,idordenestadotipos)VALUES ($1,$2,(CASE WHEN rlaorden.tipo = 55 OR rlaorden.tipo = 56 THEN rlaorden.fechaemision ELSE now() END),$3);
     END IF;

--KR 16-04-18 modifico SP para contemplar casos en anulacion de OER


     
    IF (rlaorden.tipo = 48) THEN --KR 24-09-18 es una orden de odonto, anulo el item de la ficha

        SELECT INTO rfichamedicaitem * FROM fichamedicaitememisiones WHERE nroorden =$1 AND centro =$2 ;
        IF FOUND THEN 
              UPDATE fichamedicaitemestado SET fmiefechafin = now() WHERE idfichamedicaitem= rfichamedicaitem.idfichamedicaitem
                                                             AND idcentrofichamedicaitem = rfichamedicaitem.idcentrofichamedicaitem;
              INSERT INTO fichamedicaitemestado(idfichamedicaitem,idcentrofichamedicaitem,fmieusuario,idfichamedicaemisionestadotipo,fmiedescripcion)
                VALUES (rfichamedicaitem.idfichamedicaitem,rfichamedicaitem.idcentrofichamedicaitem,rusuario.idusuario,4,'Generado desde expendio_cambiarestadoorden');
        END IF; 
    
    END IF;  
--KR 30-01-20 controlo que el estado sea anulada
--KR 01-10-20 Dado el cambio en java controlo antes si la orden tiene ya un motivo de anulacion, sino lo tiene, guardo el motivo de locura MaLa
    SELECT INTO rexistemotivo * FROM ordenanuladamotivo WHERE nroorden = $1 AND centro=$2; 
    IF NOT FOUND THEN 
      IF iftableexists('temp_ordenanuladamotivo') THEN        
    
--KR 25-06-21 guardo en iierror el motivo de la anulacion
         SELECT INTO rordenanulada * from temp_ordenanuladamotivo  WHERE nroorden = $1 AND centro=$2; 
         update cambioestadosorden set observacion =rordenanulada.observacion   where nroorden=$1 and centro=$2; 


         INSERT INTO ordenanuladamotivo(nroorden,centro,idmotivoanulacionorden) VALUES     (rordenanulada.nroorden,rordenanulada.centro,rordenanulada.idmotivoanulacionorden);
          UPDATE iteminformacion SET iierror= concat(iierror,' ',rordenanulada.observacion) 
               FROM ( select  iditem, centro from itemvalorizada where nroorden= rordenanulada.nroorden and centro=rordenanulada.centro) AS T
               WHERE  iteminformacion.iditem = T.iditem AND iteminformacion.centro = T.centro;
      ELSE 
        IF (rlaorden.tipo = 56 and  $3 = 2 ) THEN --MALAPI 20-01-2020 Si es una Orden ONLINE al anularla siempre le pongo error de impresión (Es locura mia... no se que ponerle).
           INSERT INTO ordenanuladamotivo(nroorden,centro,idmotivoanulacionorden) VALUES ($1,$2,3);
    
        END IF; 
     END IF; 
    END IF;  
     IF (rlaorden.tipo = 55 AND $3=2) THEN --es una orden de reintegro 
           
         SELECT INTO rordenchek * 
         FROM reintegroorden AS ro  NATURAL JOIN reintegro NATURAL JOIN restados LEFT JOIN facturaorden USING(nroorden, centro) 
         LEFT JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
         LEFT JOIN cambioestadoordenpago USING(nroordenpago, idcentroordenpago)
          WHERE ro.nroorden =$1 AND ro.centro =$2 AND nullvalue(ceopfechafin) AND nullvalue(refechafin); 
         IF FOUND THEN 
--si se facturo y la OT y la MP estan anuladas o si no se facturo puedo anular la OR. Sino no se puede anular
       
            IF ((NOT nullvalue(rordenchek.nrofactura) AND NOT nullvalue(rordenchek.anulada) AND (rordenchek.idtipoestadoordenpago= 4 OR nullvalue(rordenchek.idtipoestadoordenpago))) 
                OR (nullvalue(rordenchek.nrofactura))) THEN  

            PERFORM  cambiarestadoinformefacturacion (T.nroinforme, T.idcentroinformefacturacion, 5,'Se anula el informe por haberse anulado la orden reintegro vinculada al mismo') 
           FROM ( SELECT  nroinforme, idcentroinformefacturacion 
                FROM informefacturacionexpendioreintegro  NATURAL JOIN reintegroorden AS ro 		 
                  WHERE nroorden = $1 AND centro=$2) as T;

             IF (rordenchek.tipoestadoreintegro<>1) THEN --dejo el reintegro en estado pendiente y elimino sus prestaciones
               INSERT INTO restados(fechacambio,nroreintegro,tipoestadoreintegro,anio,observacion,idcentroregional) 
          (SELECT now(), nroreintegro, 1, anio, 'Generado por anulación de orden vinculada al reintegro. ',idcentroregional FROM  informefacturacionexpendioreintegro  NATURAL JOIN reintegroorden AS ro WHERE nroorden = $1 AND centro=$2);

               UPDATE reintegroprestacion SET importe = 0.1 WHERE (anio, nroreintegro,idcentroregional) IN 
               (SELECT anio, nroreintegro,idcentroregional FROM reintegro WHERE nroreintegro = rordenchek.nroreintegro AND anio = rordenchek.anio AND idcentroregional = rordenchek.idcentroregional);
               UPDATE reintegro SET rimporte = 0.1 WHERE nroreintegro = rordenchek.nroreintegro AND anio = rordenchek.anio AND idcentroregional = rordenchek.idcentroregional;
               
             END IF;      
           --KR 27-09-18 Cuando anula la orden debe volver el comprobante a activo
              UPDATE catalogocomprobante SET ccactivo = true 
              FROM (SELECT idcatalogocomprobante, idcentrocatalogocomprobante FROM catalogoordencomprobante                                  
		       WHERE nroorden = $1 AND centro=$2 ) AS T 
              WHERE catalogocomprobante.idcatalogocomprobante = T.idcatalogocomprobante
		             AND catalogocomprobante.idcentrocatalogocomprobante = T.idcentrocatalogocomprobante;
      
           ELSE --no es posible anular la OR 
              RAISE EXCEPTION 'No es posible anular la orden. Si se facturo verifique que la OT o la MP estan anuladas. OR% % ',$1,$2;
	         
           END IF; 
        END IF; 
     END IF;  
-- KR 24-08-21 generamos pendiente NC si tiene factura y la FA no es del dia de hoy, current_date, si el estado es cancelada y la FA no esta anulada
     IF not nullvalue(rlaorden.fechaemisionfactura) and rlaorden.fechaemisionfactura::date<> current_date and  $3 = 2 and nullvalue(rlaorden.anulada) THEN 
        SELECT INTO rtitular * FROM (
          SELECT nrodoctitu as nrodoc,tipodoctitu as tipodoc from benefsosunc  
					where  benefsosunc.nrodoc =rlaorden.nrodoc and benefsosunc.tipodoc=rlaorden.tipodoc
          UNION 
          SELECT nrodoctitu as nrodoc,tipodoctitu as tipodoc  from benefreci  
				       where  benefreci.nrodoc = rlaorden.nrodoc and benefreci.tipodoc=rlaorden.tipodoc
        ) as t;
       IF NOT FOUND THEN 
          rtitular = rlaorden;
       END IF;
       INSERT INTO notascreditospendientes(nroorden,centro,nrodoc,tipodoc) VALUES(rlaorden.nroorden,rlaorden.centro,rtitular.nrodoc,rtitular.tipodoc );
        
     END IF;

--KR 27-06-22 SI anulo una orden de reci que tiene un informe pendiente lo anulo
  IF (rlaorden.tipo = 20) THEN  
        SELECT INTO rordeninfo * FROM informefacturacionreciprocidad WHERE nroorden =$1 AND centro =$2 ;
        IF FOUND THEN 
            select from cambiarestadoinformefacturacion(rordeninfo.nroinforme,rordeninfo.idcentroinformefacturacion,5,'Se anula el informe que se genero para facturacion en caja por anularse la orden');
        END IF; 
    
    END IF;  
return true;

END;
$function$
