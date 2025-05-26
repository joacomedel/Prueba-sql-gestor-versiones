CREATE OR REPLACE FUNCTION public.expendio_desanularorden(pnroorden bigint, pcentro integer)
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
--VARIABLES 
   vestadoorden INTEGER;
BEGIN
--select  * from expendio_desanularorden(nroorden,centro)
     
     SELECT INTO rlaorden tipo,orden.nroorden, orden.centro, orden.fechaemision, consumo.nrodoc , consumo.tipodoc, facturaventa.fechaemision as fechaemisionfactura, anulada ,anulado, anulada as facturaanulada
	 FROM orden 
	 natural join consumo 
	 left join facturaorden using(nroorden, centro)  
	 left join facturaventa using(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
     WHERE orden.nroorden = pnroorden AND orden.centro =pcentro;
	 
     IF FOUND AND rlaorden.anulado THEN 
        IF (nullvalue(rlaorden.fechaemisionfactura) OR (not nullvalue(rlaorden.fechaemisionfactura) and not nullvalue(rlaorden.facturaanulada)))  THEN 
--KR 21-04-22 si la orden no esta facturada o esta facturada pero la FA esta anulada entonces se pone pendiente
            vestadoorden = 1;
        ELSE 
--KR 21-04-22 SI la orden fue facturada y la fa no esta anulada entonces la dejo en estado facturada. Caso mail con asunto SOSUNC REPORTE ORDENES SOLICITADAS, desanule las ordenes pq se habian mandado a descontar
            vestadoorden =3;
        END IF;
           
        UPDATE cambioestadosorden SET ceofechafin= now(), observacion='Se desanula la orden desde SP expendio_desanularorden '
            WHERE nroorden=rlaorden.nroorden AND centro=rlaorden.centro  AND nullvalue(ceofechafin);
     	INSERT INTO cambioestadosorden (idordenventaestadotipo,nroorden,centro,observacion) VALUES(vestadoorden ,rlaorden.nroorden,rlaorden.centro, 'Se cambia el estado de la orden desde SP expendio_desanularorden ');

--KR 14-02-22 LA orden se deja pendiente sino es online, si es online se controla y luego el usuario la pone pendiente, sino se factura 2 veces, y ademas no va en las tablas ordenessinfacturas/itemordenessinfactura. Tkt 4872
         --KR 29-06-22 Si la orden no esta facturada (vestadoorden<>3)
           IF rlaorden.tipo<>56 and vestadoorden<>3 THEN 
            --La dejo pendiente de Facturacion
			INSERT INTO ordenessinfacturas(nroorden, centro, nrodoc, tipodoc) 
			VALUES(rlaorden.nroorden, rlaorden.centro, rlaorden.nrodoc, rlaorden.tipodoc);
			
			INSERT INTO itemordenessinfactura (nroorden, centro, idconcepto, cantidad, importe, descripcion) 
			(
			SELECT nroorden,centro, nrocuentac, cantidad,importesorden.importe, desccuenta
                         FROM importesorden LEFT JOIN
               (SELECT nrocuentac, cantidad,desccuenta,nroorden,centro
                FROM item JOIN itemvalorizada USING(iditem, centro)  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica)
                NATURAL JOIN cuentascontables  WHERE nroorden=rlaorden.nroorden and centro=rlaorden.centro
                UNION
                SELECT '40311' as nrocuentac, 1,'Consulta' as desccuenta, nroorden,centro FROM orden NATURAL JOIN ordconsulta  WHERE nroorden=rlaorden.nroorden and centro=rlaorden.centro
                UNION
                SELECT '40316' as nrocuentac, 1,'Recetario TP' as desccuenta,nrorecetario as nroorden,centro FROM recetariotp  WHERE nrorecetario=rlaorden.nroorden and centro=rlaorden.centro
              ) as TT USING (nroorden, centro)
               WHERE nroorden=rlaorden.nroorden and centro=rlaorden.centro and (idformapagotipos =2 or idformapagotipos=3)
			);
             END IF;

     		--Borro el anulado de ordenestados
			DELETE FROM ordenestados WHERE nroorden = rlaorden.nroorden AND centro= rlaorden.centro AND idordenestadotipos = 2;

               -- MaLaPi 01-02-2022 Cambio la marca en consumo
                  UPDATE consumo set anulado = false WHERE nroorden = rlaorden.nroorden AND centro= rlaorden.centro;
	
	IF (rlaorden.tipo = 48) THEN --Si es una orden de odonto, desanulo el item de la ficha
        SELECT INTO rfichamedicaitem * FROM fichamedicaitememisiones WHERE nroorden =rlaorden.nroorden AND centro =rlaorden.centro ;
        IF FOUND THEN 
              UPDATE fichamedicaitemestado SET fmiefechafin = now() WHERE idfichamedicaitem= rfichamedicaitem.idfichamedicaitem
                                                             AND idcentrofichamedicaitem = rfichamedicaitem.idcentrofichamedicaitem;
              INSERT INTO fichamedicaitemestado(idfichamedicaitem,idcentrofichamedicaitem,fmieusuario,idfichamedicaemisionestadotipo,fmiedescripcion)
                VALUES (rfichamedicaitem.idfichamedicaitem,rfichamedicaitem.idcentrofichamedicaitem,sys_dar_usuarioactual(),3,'Generado desde expendio_desanularorden');
        END IF; 
    
    END IF;  
	
	
	END IF;
     
    
	--Elimino el Motivo de Anulacion, si es que esta cargado
	DELETE FROM ordenanuladamotivo WHERE nroorden = rlaorden.nroorden AND centro=rlaorden.centro; 
    UPDATE iteminformacion SET iierror= concat(iierror,' ','Ahora esta Des-Anularon') 
    FROM ( select  iditem, centro 
		   from itemvalorizada 
		    where nroorden= rlaorden.nroorden AND centro=rlaorden.centro
		 ) AS T
    WHERE  iteminformacion.iditem = T.iditem AND iteminformacion.centro = T.centro;
    
	-- Debo eliminar el Pendiente de NC si es que aun no se emitio
	DELETE FROM notascreditospendientes WHERE nroorden= rlaorden.nroorden AND centro = rlaorden.centro;

	
	IF (rlaorden.tipo = 55 ) THEN --es una orden de reintegro 
	--MaLaPi No se que se puede recuperar al DesAnular un Reintegro... lo dejo comentado por si alguna vez es necesario
/*         SELECT INTO rordenchek * 
         FROM reintegroorden AS ro  NATURAL JOIN reintegro NATURAL JOIN restados LEFT JOIN facturaorden USING(nroorden, centro) 
         LEFT JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
         LEFT JOIN cambioestadoordenpago USING(nroordenpago, idcentroordenpago)
          WHERE ro.nroorden =rlaorden.nroorden AND ro.centro =rlaorden.centro AND nullvalue(ceopfechafin) AND nullvalue(refechafin); 
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
        END IF; */
     END IF;
 
	

return true;

END;$function$
