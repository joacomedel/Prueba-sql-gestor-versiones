CREATE OR REPLACE FUNCTION public.abmcargarcatalogocomprobante()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	ccatalogocomprobante CURSOR FOR SELECT * FROM temp_catalogocomprobante;
	rcatalogocomprobante RECORD;
 	relem RECORD;
        rexisteoc RECORD;
        rusuario RECORD;
BEGIN
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF NOT FOUND THEN 
        rusuario.idusuario = 25;
    END IF;
    OPEN ccatalogocomprobante;
    FETCH ccatalogocomprobante into rcatalogocomprobante;
    WHILE  found LOOP
      IF ((rcatalogocomprobante.accion = 'guardarCatalogoComprobante') AND rcatalogocomprobante.ccactivo) THEN
       SELECT INTO rexisteoc CONCAT('Comprobante ',cctipofactura,' ',ccletra,' ', ccpuntodeventa,'-', ccnrocomprobante,' ingresado el ',cocfechaingreso, ' por ',login, ' Nro.Orden: ', nroorden,'-', centro, ' Reintegro:', nroreintegro,'-',anio,'-',reintegroorden.idcentroregional, ' ',
tipofactura, ' ', to_char(facturaorden.nrosucursal, '0000'),'-', to_char(facturaorden.nrofactura, '00000000')) as existecomp,*
                FROM catalogocomprobante NATURAL JOIN usuario LEFT JOIN catalogoordencomprobante USING(idcatalogocomprobante, idcentrocatalogocomprobante) LEFT JOIN consumo USING(nroorden,centro) LEFT JOIN facturaorden USING(nroorden,centro) LEFT JOIN reintegroorden USING(nroorden,centro)
		WHERE  ccnrocomprobante = rcatalogocomprobante.ccnrocomprobante
		AND idtipocomprobante = rcatalogocomprobante.idtipocomprobante
		AND ccletra = rcatalogocomprobante.ccletra
		AND ccpuntodeventa = rcatalogocomprobante.ccpuntodeventa
		AND cctipofactura = rcatalogocomprobante.cctipofactura
		AND idprestador = rcatalogocomprobante.idprestador;
       IF FOUND THEN 
          IF nullvalue(rcatalogocomprobante.idcatalogocomprobante) THEN 
                RAISE EXCEPTION 'Ya se cargo el comprobante para ese prestador !! %', rexisteoc.existecomp;
-- concat(rcatalogocomprobante.cctipofactura,' ',rcatalogocomprobante.ccletra,' ', rcatalogocomprobante.ccpuntodeventa,'-', rcatalogocomprobante.ccnrocomprobante) ;
          ELSE --SOLO esta permitido modificar los campos siguientes:ccfechaemision, ccoriginal, ccactivo
               UPDATE catalogocomprobante SET ccfechaemision = rcatalogocomprobante.ccfechaemision  
                                             ,ccoriginal = rcatalogocomprobante.ccoriginal        
                                             ,ccactivo = rcatalogocomprobante.ccactivo                                     
			     WHERE  idcatalogocomprobante = rcatalogocomprobante.idcatalogocomprobante
		             AND idcentrocatalogocomprobante = rcatalogocomprobante.idcentrocatalogocomprobante;
          END IF; 
       ELSE 
           INSERT INTO catalogocomprobante(idusuario,idprestador,ccfechaemision,cctipofactura,idtipocomprobante,ccletra,ccpuntodeventa,ccactivo, 	ccoriginal,ccnrocomprobante, ccmonto) 
           VALUES
       (rusuario.idusuario ,rcatalogocomprobante.idprestador,rcatalogocomprobante.ccfechaemision, rcatalogocomprobante.cctipofactura,rcatalogocomprobante.idtipocomprobante,rcatalogocomprobante.ccletra,rcatalogocomprobante.ccpuntodeventa,rcatalogocomprobante.ccactivo,rcatalogocomprobante.ccoriginal,rcatalogocomprobante.ccnrocomprobante, rcatalogocomprobante.ccmonto);
       END IF;
     END IF;

      IF (rcatalogocomprobante.accion = 'vincularOrdenCatalago') THEN
        INSERT INTO catalogoordencomprobante(idusuario, nroorden, centro, idcatalogocomprobante,idcentrocatalogocomprobante) 
            VALUES
       (rusuario.idusuario ,rcatalogocomprobante.nroorden,rcatalogocomprobante.centro,rcatalogocomprobante.idcatalogocomprobante,rcatalogocomprobante.idcentrocatalogocomprobante);
      END IF;
        
      IF NOT rcatalogocomprobante.ccactivo THEN --desactivo el comprobante
            UPDATE catalogocomprobante SET ccactivo = rcatalogocomprobante.ccactivo                                       
			 WHERE  idcatalogocomprobante = rcatalogocomprobante.idcatalogocomprobante
		             AND idcentrocatalogocomprobante = rcatalogocomprobante.idcentrocatalogocomprobante;
      END IF; 

        
          
    FETCH ccatalogocomprobante into rcatalogocomprobante;
    END LOOP;
    CLOSE ccatalogocomprobante;

return 'true';
END;$function$
