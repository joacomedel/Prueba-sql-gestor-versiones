CREATE OR REPLACE FUNCTION public.archivardocumento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES

    idpase INTEGER;

--REGISTROS

    regdcto RECORD;

    elem record;

--CURSORES

    cursordcto refcursor;

BEGIN

   OPEN cursordcto FOR SELECT * FROM temppasedocumento;

   FETCH cursordcto INTO regdcto;

   WHILE FOUND LOOP

---UPDATEO EL PASE DEL DOCUMENTO DESDE EL SECTOR DONDE SE ENVIA AL SECTOR DESTINO

	/*SELECT INTO idpase max(idpase) , iddocumento, idcentrodocumento, idsectordestino, pafecharecepcion 

	FROM pase

	WHERE pase.iddocumento= regdcto.iddoc AND pase.idcentrodocumento=regdcto.idcentro AND nullvalue(pase.pafecharecepcion) 

	GROUP BY iddocumento, idcentrodocumento, idsectordestino, pafecharecepcion;

	if found THEN

		UPDATE pase SET pafechaenvio= now(), idsectordestino= regdcto.sectordestino

		WHERE pase.idpase = elem.idpase AND pase.idcentropase= elem.idcentropase;

	end if;

*/

 --El estado del documento es archivado = 4

        UPDATE documentoestado SET defechafin = now() WHERE nullvalue(defechafin) AND iddocumento=regdcto.iddoc AND idcentrodocumento=centro();

        INSERT INTO documentoestado(iddocumentoestadotipo, iddocumento, dofecha,idcentrodocumento) VALUES (4, regdcto.iddoc, now(),centro());

--Inserto una nueva tupla en pase donde qde corroborado que el documento se archivo y el motivo

         INSERT INTO pase(pamotivo,  idsectororigen, idsectordestino, iddocumento, idcentrodocumento, pafechaenvio,pafecharecepcion) VALUES (regdcto.motivo,  regdcto.sectordestino, regdcto.sectordestino,regdcto.iddoc, regdcto.idcentro, now(), now());

        FETCH cursordcto INTO regdcto;

    END LOOP;

    CLOSE cursordcto;

return true;

END;

$function$
