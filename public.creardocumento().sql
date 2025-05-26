CREATE OR REPLACE FUNCTION public.creardocumento()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES

    iddoc INTEGER;
    personaOrigen integer;
    esminuta BOOLEAN;
    tipodocumento varchar;
    cantfolios integer;
  

--REGISTROS

    regdcto RECORD;
    regdctoitem RECORD;
    regitem RECORD;
    regarchivo RECORD;
    rpasedocinfo RECORD;
    rsectororigen RECORD;
--CURSORES

    cursordcto refcursor;
    cursordctoitem refcursor;
    cursorarchivos refcursor;

BEGIN

   OPEN cursordcto FOR SELECT * FROM tempdocumento;
   
   FETCH cursordcto INTO regdcto;

   WHILE FOUND LOOP

         INSERT INTO documento(dofechacreacion, dotitulo, docontenido,iddocumentopadre,idcentrodocumentopadre) VALUES (regdcto.fechacreacion, regdcto.titulo, regdcto.contenido,regdcto.iddocumentopadre,regdcto.idcentropadre);

 --(*) Recupero el id del documento

         iddoc =  currval('documento_iddocumento_seq');

 --El estado del documento es CREADO = 1

        INSERT INTO documentoestado(iddocumentoestadotipo, iddocumento, dofecha,idcentrodocumento) VALUES (1, iddoc, now(),centro());

        SELECT INTO personaOrigen ca.persona.idpersona
         FROM usuario JOIN ca.persona ON(usuario.dni=ca.persona.penrodoc AND usuario.tipodoc =    ca.persona.idtipodocumento) JOIN ca.empleado USING(idpersona) 
         WHERE usuario.idusuario=regdcto.idpersonaorigen;

 IF not existecolumtemp('tempdocumento', 'pacantfolios') THEN 
       cantfolios=0;
     else cantfolios=regdcto.pacantfolios;
 END IF;
        
          SELECT INTO rsectororigen *
         FROM usuario JOIN ca.persona ON(usuario.dni=ca.persona.penrodoc AND usuario.tipodoc =    ca.persona.idtipodocumento) JOIN ca.empleado USING(idpersona) 
         WHERE usuario.idusuario=regdcto.idpersonaorigen;

         INSERT INTO pase(pacantfolios,pamotivo, pafecharecepcion, idsectororigen,iddocumento, idcentrodocumento,idpersonaorigen) 
         VALUES (cantfolios,'CREACION DEL DOCUMENTO ', regdcto.fechacreacion, case when nullvalue(regdcto.sectorcreacion) then rsectororigen.idsector else regdcto.sectorcreacion end , iddoc, centro(),personaOrigen);

        IF iftableexistsparasp('tempdocumentoitemarchivos') THEN 

         UPDATE tempdocumentoitemarchivos SET idpase = currval('pase_idpase_seq'::regclass), idcentropase = centro();
        END IF;
       
       
      --me fijo si el doc es de de minutas 
        OPEN cursordctoitem FOR SELECT * FROM tempdocumentoitem;
        FETCH cursordctoitem INTO regdctoitem;
               WHILE FOUND LOOP
                  IF (not nullvalue(regdctoitem.nroordenpago)) THEN 
--es decir, es un documento que contiene minutas de pago
                     esminuta = true;
                     UPDATE tempdocumentoitem 
                     SET iddocumento= iddoc, centrodoc=centro()
                     WHERE nroordenpago=regdctoitem.nroordenpago AND idcentroordenpago = regdctoitem.idcentroordenpago;
                  ELSE
                     UPDATE tempdocumentoitem 
                     SET iddocumento= iddoc, centrodoc=centro()
                     WHERE idclave=regdctoitem.idclave AND idcentroclave=regdctoitem.idcentroclave; 
                  END IF; 

                --KR 01-02-19 guardo el pase de ingreso de la nota, luego este mismo pase lo voy updateando con la info que se va generando.  
          SELECT INTO rpasedocinfo * FROM recrecetario WHERE idrecepcion=regdctoitem.idclave AND idcentroregional = regdctoitem.idcentroclave;
         RAISE NOTICE 'regdctoitem (%)',regdctoitem.idclave;

          IF FOUND THEN  
            INSERT INTO paseinfodocumento(idpase, idcentropase,pidmotivo,idrecepcion,idcentroregional,pidultimo	)
             VALUES (currval('pase_idpase_seq'::regclass), centro(),'CREACION DEL DOCUMENTO ',rpasedocinfo.idrecepcion,rpasedocinfo.idcentroregional, TRUE);
         END IF;  
      
                FETCH cursordctoitem INTO regdctoitem;
               END LOOP;
        IF esminuta THEN
               PERFORM guardardocumentoitem();
        ELSE 
               PERFORM guardardocumentoitemfactura();
          
       
        END IF;
        CLOSE cursordctoitem;

        -- Malapi 03/08/2017 Guardo los documentos del pase
        IF iftableexistsparasp('tempdocumentoitemarchivos') THEN 

        OPEN cursorarchivos FOR SELECT * FROM tempdocumentoitemarchivos;
        FETCH cursorarchivos INTO regarchivo;
               WHILE FOUND LOOP
                 UPDATE circuitodocumento_archivos SET idpase = regarchivo.idpase, idcentropase = regarchivo.idcentropase WHERE idarchivo = regarchivo.idarchivo AND idcentroarchivo = regarchivo.idcentroarchivo;
                FETCH cursorarchivos INTO regarchivo;
               END LOOP;
       
        CLOSE cursorarchivos;

        END IF;
        IF existecolumtemp('tempdocumento', 'tipodocumento') THEN  
               tipodocumento = regdcto.tipodocumento;
        END IF;
        FETCH cursordcto INTO regdcto;




    END LOOP;


    --- VAS 25/04/2018
    IF existecolumtemp('tempdocumento', 'tipodocumento') THEN 
        IF (tipodocumento='expediente') THEN
             PERFORM expediente_crear(iddoc,centro());
        END IF;
    END IF;
    CLOSE cursordcto;
   
   

return iddoc;

END;
$function$
