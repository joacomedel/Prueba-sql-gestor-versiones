CREATE OR REPLACE FUNCTION public.configurarsolicitudfinanciamiento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
 * Datos entrada: TABLA tempconfiguracionprestamo
 *                tipodoc,nrodoc ,
 *                cantidadcuotas,
 *                idsolicitudfinanciacion,
 *				  idcentrosolicitudfinanciacion,
 *				  importetotal,
 *				  intereses,
 *				  idusuario,
 *				  importecuota
 * Llamar al Sp generarprestamocuotas que recibe como Parametro  el id del tipo de prestamo en este caso: 4 Plan pago Aistencial
 * Cambiar estado de la solicitud a Configurado estado = 6
 */

DECLARE

		cursorconfpres CURSOR FOR SELECT * FROM tempconfiguracionprestamo;
        rconfpres record;	
        valor integer;
BEGIN
            SELECT INTO valor * FROM generarprestamocuotas(4);
         
            IF valor <>0 THEN
            OPEN cursorconfpres;
            FETCH cursorconfpres INTO rconfpres;
                -- Se almacenan los datos especificos del prestamo originado a partir de solicitud de financiacion
                INSERT INTO prestamosolicitudfinanciacion (idprestamo,idcentroprestamo,idsolicitudfinanciacion,idcentrosolicitudfinanciacion)
                VALUES (valor, centro(),rconfpres.idsolicitudfinanciacion,rconfpres.idcentrosolicitudfinanciacion);
                -- Se actualiza el ultimo estado de la solicitud
                UPDATE solicitudfinanciacionestado SET fechafin = NOW()
                WHERE fechafin is NULL AND idsolicitudfinanciacion =rconfpres.idsolicitudfinanciacion AND idcentrosolicitudfinanciacion = rconfpres.idcentrosolicitudfinanciacion;
                -- Se ingresa el nuevo estado
                INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion, idcentrosolicitudfinanciacion,fechaini,idusuario,idsolicitudfinanciacionestadotipo,sfedescripcion)
                VALUES(rconfpres.idsolicitudfinanciacion,rconfpres.idcentrosolicitudfinanciacion,NOW(),rconfpres.idusuario,6, 'Generado Automaticamente en generar prestamo de una solicitud  ');

            CLOSE cursorconfpres;
            END IF;

RETURN 'true';
END;
$function$
