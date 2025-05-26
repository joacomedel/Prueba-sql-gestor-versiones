CREATE OR REPLACE FUNCTION public.modificarpasedocumentoasector()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES
   -- sectorOrigen INTEGER;
--REGISTROS
    regdcto RECORD;
    regdctorecibir RECORD;
   regOrigen RECORD;
     elem record;
--CURSORES
    cursordcto refcursor;
    cursordctorecibir refcursor;

	
BEGIN
--CREATE TEMP TABLE temppasedocumento (fechaenvio DATE, motivo VARCHAR,	sectordestino INTEGER,	sectororigen INTEGER,	iddoc INTEGER,	idcentro INTEGER,	idpersonaorigen INTEGER,	idpersonadestino INTEGER);
-- INSERT INTO temppasedocumento(fechaenvio,motivo,sectordestino, sectororigen,iddoc,idcentro, idpersonaorigen,idpersonadestino)   VALUES ('2010/08/06', 'se modifica el pase del documento con id 73 y se envia al sector dpto turismo',16,2,73,1,36,null);


 OPEN cursordctorecibir FOR SELECT * FROM temppasedocumento;
   FETCH cursordctorecibir INTO regdctorecibir;
   WHILE FOUND LOOP



---UPDATEO EL PASE DEL DOCUMENTO DESDE EL SECTOR DONDE SE ENVIA AL SECTOR DESTINO
   select into elem max(idpase) as idpase, iddocumento, idcentrodocumento,idpersonaorigen
   from pase
   WHERE pase.iddocumento = regdctorecibir.iddoc AND pase.idcentrodocumento = regdctorecibir.idcentro
   and nullvalue(pafecharecepcion) and not nullvalue(pafechaenvio)
   GROUP BY iddocumento, idcentrodocumento,idpersonaorigen;

if found THEN
       SELECT INTO regOrigen ca.empleado.idpersona, concat(ca.persona.peapellido ,', ',ca.persona.penombre) as nombre
       FROM usuario JOIN ca.persona ON(usuario.dni=ca.persona.penrodoc AND usuario.tipodoc = ca.persona.idtipodocumento) JOIN ca.empleado USING(idpersona)
       WHERE usuario.idusuario=regdctorecibir.idpersonaorigen;

       if nullvalue(elem.idpersonaorigen) then
         UPDATE pase SET pafecharecepcion= now(), idpersonaorigen= regOrigen.idpersona,
         pamotivo = concat('Documento redirigido  por: ' ,regOrigen.nombre)
         WHERE pase.idpase=elem.idpase AND pase.idcentropase= elem.idcentrodocumento;

    else

        UPDATE pase SET pafecharecepcion= now(), pamotivo = concat('Documento redirigido por: ' ,regOrigen.nombre)
        WHERE pase.idpase=elem.idpase AND pase.idcentropase= elem.idcentrodocumento;
    end if;
end if;

     FETCH cursordctorecibir INTO regdctorecibir;

    END LOOP;

    CLOSE cursordctorecibir;




 OPEN cursordcto FOR SELECT * FROM temppasedocumento;
   FETCH cursordcto INTO regdcto;
   WHILE FOUND LOOP


      SELECT INTO regOrigen ca.empleado.idsector, concat(ca.persona.peapellido ,', ',ca.persona.penombre) as nombre
         FROM usuario JOIN ca.persona ON(usuario.dni=ca.persona.penrodoc AND usuario.tipodoc = ca.persona.idtipodocumento)
         JOIN ca.empleado USING(idpersona)
         WHERE usuario.idusuario=regdcto.idpersonaorigen;

 if nullvalue(regdcto.sectordestino) THEN

         INSERT INTO pase(pamotivo,  idsectororigen, iddocumento, idcentrodocumento, pafechaenvio,idpersonaorigen) VALUES (concat('Documento enviado por ' , regOrigen.nombre),  regOrigen.idsector, regdcto.iddoc, regdcto.idcentro, now(),regdcto.idpersonadestino);

   
 else
    
         INSERT INTO pase(pamotivo,  idsectororigen, iddocumento, idcentrodocumento, pafechaenvio,idpersonaorigen) VALUES (concat('Documento enviado por ' , regOrigen.nombre ),  regdcto.sectordestino, regdcto.iddoc, regdcto.idcentro, now(),regdcto.idpersonadestino);
end if;

 

        FETCH cursordcto INTO regdcto;

    END LOOP;

    CLOSE cursordcto;

return true;
END;
$function$
