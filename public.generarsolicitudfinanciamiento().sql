CREATE OR REPLACE FUNCTION public.generarsolicitudfinanciamiento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* Se ingresa una nueva solicitud prestamo
 * recuperar los datos almacenados en las tablas temporales:
            tempsolicitudfinanciacion
            cada uno de los beneficiarios tempsolicitudfinanciacionbeneficiario
 * Los datos recuperados se insertan en las tablas fisicas: solicitudfinanciacion,solicitudfinanciacionbeneficiario
 * Se ingresa el estado pendiente a la solicitudfinanciacion

*/
DECLARE
	cursorsolbenef CURSOR FOR SELECT * FROM tempsolicitudfinanciacionbeneficiario;
	recordsolbenef RECORD;
	recordsolicitud RECORD;
	idsolfin INTEGER;

	
BEGIN

	SELECT INTO recordsolicitud *  FROM tempsolicitudfinanciacion ;
   	
    INSERT INTO solicitudfinanciacion (idcentrosolicitudfinanciacion,
fechaingresome,fechasolicitud,nrodoc,tipodoc,montosolicitado,sfdescripcion,nroingresome
           )
    VALUES(centro(),
           recordsolicitud.fechaingresome, recordsolicitud.fechasolicitud,
           recordsolicitud.nrodoc,recordsolicitud.tipodoc,
           recordsolicitud.montosolicitado,
           recordsolicitud.sfdescripcion,
           recordsolicitud.nroingresome);

    --(*) Recupero el id de solicitudfinanciacion
    idsolfin =  currval('solicitudfinanciacion_idsolicitudfinanciacion_seq');
	
	OPEN cursorsolbenef;
	FETCH cursorsolbenef into recordsolbenef;
	WHILE found LOOP
                INSERT INTO solicitudfinanciacionbeneficiario
                (nrodoc,tipodoc,idsolicitudfinanciacion,idcentrosolicitudfinanciacion)
                VALUES(recordsolbenef.nrodoc,recordsolbenef.tipodoc,
                   idsolfin, Centro());
    fetch cursorsolbenef into recordsolbenef;
	END LOOP;
close cursorsolbenef;

INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion,idcentrosolicitudfinanciacion,
fechaini,idusuario,idsolicitudfinanciacionestadotipo,sfedescripcion)
VALUES(idsolfin,centro(),
NOW(),recordsolicitud.idusuario,1,'Generado Automaticamente en generar solicitud financiamiento ');

return  concat(idsolfin,'-',centro());
END;
$function$
