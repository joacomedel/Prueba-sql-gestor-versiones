CREATE OR REPLACE FUNCTION public.recibirdocumento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTROS
    regdcto RECORD;
    regOrigen RECORD;
     elem record;
--CURSORES
    cursordcto refcursor;

	
BEGIN


   OPEN cursordcto FOR SELECT * FROM temppasedocumento;
   FETCH cursordcto INTO regdcto;
   WHILE FOUND LOOP


   
---UPDATEO EL PASE DEL DOCUMENTO DESDE EL SECTOR DONDE SE ENVIA AL SECTOR DESTINO
   SELECT INTO elem *
   FROM pase
   WHERE iddocumento = regdcto.iddoc
         AND idcentrodocumento = regdcto.idcentro
         AND idsectororigen= regdcto.sectororigen
         AND nullvalue(pafecharecepcion)
         AND not nullvalue(pafechaenvio);
         
   IF  found THEN
             SELECT INTO regOrigen ca.empleado.idpersona, concat(ca.persona.peapellido ,', ',ca.persona.penombre) as nombre
             FROM usuario
             JOIN ca.persona ON(usuario.dni=ca.persona.penrodoc AND usuario.tipodoc = ca.persona.idtipodocumento)
             JOIN ca.empleado USING(idpersona)
             WHERE usuario.idusuario=regdcto.idpersonaorigen;

             IF nullvalue(elem.idpersonaorigen) THEN
                   UPDATE pase
                   SET pafecharecepcion= now(),
                       idpersonaorigen= regOrigen.idpersona,
                       pamotivo = concat('Documento recibido por: ' ,regOrigen.nombre)
                   WHERE pase.idpase=elem.idpase AND pase.idcentropase= elem.idcentropase;

             ELSE
                  UPDATE pase
                  SET pafecharecepcion= now(),
                      pamotivo = concat('Documento recibido por: ' ,regOrigen.nombre)
                  WHERE pase.idpase=elem.idpase AND pase.idcentropase= elem.idcentropase;
             END IF;
    END IF;
 --El estado del documento es recibido = 2
   UPDATE documentoestado SET defechafin = now() WHERE nullvalue(defechafin) AND iddocumento=regdcto.iddoc AND idcentrodocumento=regdcto.idcentro;
   INSERT INTO documentoestado(iddocumentoestadotipo, iddocumento, dofecha,idcentrodocumento) VALUES (2, regdcto.iddoc, now(),regdcto.idcentro);
   FETCH cursordcto INTO regdcto;

   END LOOP;
   CLOSE cursordcto;
return true;
END;$function$
