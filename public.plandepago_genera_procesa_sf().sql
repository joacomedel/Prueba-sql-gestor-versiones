CREATE OR REPLACE FUNCTION public.plandepago_genera_procesa_sf()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se ingresa una nueva solicitud prestamo
 * recuperar los datos almacenados en las tablas temporales:
            tempsolicitudfinanciacion
            cada uno de los beneficiarios tempsolicitudfinanciacionbeneficiario
 * Los datos recuperados se insertan en las tablas fisicas: solicitudfinanciacion,solicitudfinanciacionbeneficiario
 * Se ingresa el estado pendiente a la solicitudfinanciacion

*/
DECLARE
--RECORD	
	recordsolicitud RECORD;
        rcliente RECORD;
rconfig  record;

--VARIABLES
        idsolfin INTEGER;
        informeF INTEGER;
        nrocuentacontableintereses VARCHAR;
        cursor_prestamocuotas refcursor;
         r_prestamocuotas record; 
	
BEGIN

/*genera la solicitud*/
	SELECT INTO recordsolicitud *  FROM tempconfiguracionprestamo ;
   	
	INSERT INTO solicitudfinanciacion (idcentrosolicitudfinanciacion,
fechaingresome,fechasolicitud,nrodoc,tipodoc,montosolicitado,sfdescripcion, idprestamo, idcentroprestamo
           )
	VALUES(centro(),
           CURRENT_DATE, CURRENT_DATE,
           recordsolicitud.nrodoc,recordsolicitud.tipodoc,
           recordsolicitud.importetotal,
           'Generado a partir de un plan de pago en plandepago_genera_procesa_sf',recordsolicitud.idprestamo,recordsolicitud.idcentroprestamo);

    --(*) Recupero el id de solicitudfinanciacion
	idsolfin =  currval('solicitudfinanciacion_idsolicitudfinanciacion_seq');
	
	 INSERT INTO solicitudfinanciacionbeneficiario
                (nrodoc,tipodoc,idsolicitudfinanciacion,idcentrosolicitudfinanciacion)
                VALUES(recordsolicitud.nrodoc,recordsolicitud.tipodoc,
                   idsolfin, centro());

	INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion,idcentrosolicitudfinanciacion,
	fechaini,idusuario,idsolicitudfinanciacionestadotipo,sfedescripcion)
	VALUES(idsolfin,centro(),
	NOW(),recordsolicitud.idusuario,1,'Generado Automaticamente en plandepago_genera_procesa_sf');


/*se aprueba */
	INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion,idcentrosolicitudfinanciacion,idsolicitudfinanciacionestadotipo,fechaini,sfedescripcion,idusuario) 
	VALUES(idsolfin,centro(),2,CURRENT_DATE,'Generado Automaticamente en plandepago_genera_procesa_sf ',recordsolicitud.idusuario);
	
	UPDATE solicitudfinanciacionestado SET fechafin = CURRENT_DATE 
		 WHERE idsolicitudfinanciacion = idsolfin  AND  idcentrosolicitudfinanciacion= centro() AND nullvalue(fechafin);
		
	UPDATE solicitudfinanciacion SET montoaprobado =recordsolicitud.importetotal
				WHERE idsolicitudfinanciacion = idsolfin AND  idcentrosolicitudfinanciacion= centro();
		
		
/*se configura*/
	
        UPDATE tempconfiguracionprestamo SET idsolicitudfinanciacion=idsolfin,
                                             idcentrosolicitudfinanciacion=centro();
	

    -- Creo el informe de facturacion
        if (recordsolicitud.intereses*recordsolicitud.importetotal <>0)then
              SELECT INTO rcliente * FROM persona WHERE persona.nrodoc=recordsolicitud.nrodoc 
                 AND persona.tipodoc=recordsolicitud.tipodoc;
--KR 18-12-19 la cuenta contable que corresponde a interes x prestamos es la 40605.
--VAS 19-12-19 la cuenta contable que corresponde a interes x prestamos es la 10349.
         nrocuentacontableintereses = '10349';

            -- VAS 21/03/2022 todos los prestamos deberian estar configurados en la tabla cuentacorrienteconceptotipo 
            -- Solo esta chekado hasta el momento con PP cuando se cheke con todos los tipo de prestamos la cuenta se tomaría de la base de datos como se hace actualmente con los PP 
            SELECT INTO rconfig *
            FROM prestamo 
            JOIN cuentacorrienteconceptotipo USING(idprestamotipos)
            WHERE idprestamo = recordsolicitud.idprestamo 
                  AND idcentroprestamo =recordsolicitud.idcentroprestamo
                  AND not nullvalue( nrocuentacontable_debe )	
                  ;
            
            IF FOUND THEN
                     nrocuentacontableintereses = rconfig.nrocuentacontable_debe; 
            END IF;


            SELECT INTO informeF * FROM crearinformefacturacion(recordsolicitud.nrodoc,rcliente.barra, 4 );
            INSERT INTO  informefacturacionsolicitudfinanciacion(nroinforme,idcentroinformefacturacion,idsolicitudfinanciacion,idcentrosolicitudfinanciacion )
             VALUES(informeF,centro(),idsolfin,centro());

             -- Creo los item del informe de facturacion
              -- Modificado 23/04/2010 el importe total del prestamo no se factura , SOLO SE FACTURA LOS INTERESES

              -- VAS 21/03/2022 no se va a dar el caso que tengamos diferentes IVAS ... pero como necesito agrupar por idiva defino un cursor
             
             OPEN cursor_prestamocuotas  FOR SELECT  sum(importeinteres) as sum_importeinteres, pcidiva
             FROM prestamocuotas 
             WHERE idprestamo = recordsolicitud.idprestamo AND idcentroprestamo =recordsolicitud.idcentroprestamo
             GROUP BY pcidiva;

             FETCH cursor_prestamocuotas INTO r_prestamocuotas ;
             WHILE FOUND LOOP

                      IF nullvalue(r_prestamocuotas.pcidiva) THEN
                             --- 04-04-2022 esto debería cambiar cuando esten configurados todos los prestamos 
                             --- 04-04-2022 este dato se debe de obtener de la configuracion   
                             r_prestamocuotas.pcidiva  = 2;  -- 21
                      END IF; 
                      INSERT INTO informefacturacionitem (nroinforme ,idcentroinformefacturacion,nrocuentac ,cantidad ,idiva,importe ,descripcion)
                      VALUES (informeF,centro(),nrocuentacontableintereses,1,r_prestamocuotas.pcidiva,r_prestamocuotas.sum_importeinteres ,'Interés p/Préstamos');
                      FETCH cursor_prestamocuotas INTO r_prestamocuotas ;
             END LOOP;
          
             -- Cambio el estado del informe de facturacion 3=facturable
             UPDATE informefacturacionestado
             SET fechafin=NOW()
             WHERE nroinforme=informeF and idcentroinformefacturacion=centro() and 
                    nullvalue(fechafin);

             INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini)
             VALUES(informeF,centro(),3,NOW());
          END IF;

return 'true';
END;
$function$
