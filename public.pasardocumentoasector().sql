CREATE OR REPLACE FUNCTION public.pasardocumentoasector()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
   sectorOrigen INTEGER;
--REGISTROS
    regdcto RECORD;
    regOrigen RECORD;
    elem record;
    cantfolios integer;
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
                 AND nullvalue(idsectordestino);
           IF found THEN

           SELECT INTO regOrigen ca.empleado.idsector, concat(ca.persona.peapellido ,', ',ca.persona.penombre) as nombre
           FROM usuario JOIN ca.persona ON(usuario.dni=ca.persona.penrodoc AND usuario.tipodoc = ca.persona.idtipodocumento)
           JOIN ca.empleado USING(idpersona)
           WHERE ca.persona.idpersona=regdcto.idpersonadestino;
IF not existecolumtemp('temppasedocumento', 'pacantfolios') THEN 
       cantfolios=0;
     else cantfolios=regdcto.pacantfolios;
 END IF;

           if nullvalue(regdcto.sectordestino) THEN Begin
                UPDATE pase
                SET pafechaenvio= now(),
                       idpersonadestino= regdcto.idpersonadestino,
                       pamotivo = regdcto.motivo
                       ,pacantfolios = cantfolios
                       ,palibro = regdcto.palibro
                       ,pafolio = regdcto.pafolio
                WHERE pase.idpase = elem.idpase AND pase.idcentropase= elem.idcentropase;
                INSERT INTO pase(pamotivo,  idsectororigen, iddocumento, idcentrodocumento, pafechaenvio,idpersonaorigen) VALUES (concat('Documento enviado por ' , regOrigen.nombre),  regOrigen.idsector, regdcto.iddoc, regdcto.idcentro, now(),regdcto.idpersonadestino);
            end;
            else Begin
                 UPDATE pase
                 SET pafechaenvio= now(),
                        idsectordestino = regdcto.sectordestino,
                        personal=false,
                        pamotivo = regdcto.motivo
                       ,pacantfolios = cantfolios
			,palibro = regdcto.palibro
                       ,pafolio = regdcto.pafolio
                 WHERE pase.idpase = elem.idpase AND pase.idcentropase= elem.idcentropase;
                 INSERT INTO pase(pamotivo,  idsectororigen, iddocumento, idcentrodocumento, pafechaenvio,idpersonaorigen) VALUES (concat('Documento enviado por ' , regOrigen.nombre) ,  regdcto.sectordestino, regdcto.iddoc, regdcto.idcentro, now(),regdcto.idpersonadestino);

            end;
       end if;
end if;
 --No modifico el estado del documento que ya esta en estado enviado =3
       UPDATE documentoestado SET defechafin = now() WHERE nullvalue(defechafin) AND iddocumento=regdcto.iddoc AND idcentrodocumento=centro();
       INSERT INTO documentoestado(iddocumentoestadotipo, iddocumento, dofecha,idcentrodocumento) VALUES (3, regdcto.iddoc, now(),centro());
       FETCH cursordcto INTO regdcto;
       END LOOP;
       CLOSE cursordcto;
 PERFORM guardainfopasenota();
return true;
END;
$function$
