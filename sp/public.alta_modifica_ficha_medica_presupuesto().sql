CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica_presupuesto()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES

    idfichamedicaaux INTEGER; 


--REGISTROS

    raux RECORD;
    rauxfmt RECORD;
    elem RECORD;
   

--CURSORES


cursorficha refcursor;
    
BEGIN
/*
CREATE TEMP TABLE tempfichamedicainfo ( idfichamedica INTEGER,fmtfechainicio DATE, idcentrofichamedica INTEGER, idcentrofichamedicainfo INTEGER, idfichamedicainfo INTEGER,fmifecha DATE, fmiauditor INTEGER, fmidescripcion character varying, nrodoc character varying, tipodoc INTEGER, fmfechacreacion DATE, fmdescripcion  character varying,idauditoriatipo INTEGER, idcentrofichamedicatratamiento INTEGER, idfichamedicatratamiento INTEGER,idfichamedicatratamientotipo INTEGER,idfichamedicainfotipos INTEGER ) WITHOUT OIDS;

 INSERT INTO tempfichamedicainfo(	 idfichamedica,  fmtfechainicio, idcentrofichamedica, idcentrofichamedicainfo, idfichamedicainfo, fmiauditor, fmifecha, fmidescripcion, nrodoc, tipodoc,  fmfechacreacion, fmdescripcion, idauditoriatipo, idcentrofichamedicatratamiento, idfichamedicatratamiento, idfichamedicatratamientotipo, idfichamedicainfotipos ) VALUES(1289,'2013-03-22',1,NULL,NULL,21,'2013-03-22',NULL,'05128383',1,'2012-04-20','Generada Automaticamente',5,NULL,NULL,1,NULL);
*/


OPEN cursorficha  FOR SELECT * FROM  tempfichamedicainfo;

--open cursorficha;

FETCH cursorficha INTO elem;
WHILE FOUND LOOP

    SELECT INTO raux *  FROM fichamedica
                        WHERE  nrodoc= elem.nrodoc
                        AND tipodoc=elem.tipodoc
                        AND idauditoriatipo = 5;
    IF NOT FOUND THEN
               INSERT INTO fichamedica(tipodoc,nrodoc,fmdescripcion,idauditoriatipo) 
               VALUES(elem.tipodoc,elem.nrodoc,'Generada Automaticamente desde SP alta_modifica_ficha_medica_presupuesto',5);
               elem.idfichamedica = currval('public.fichamedica_idfichamedica_seq');
               elem.idcentrofichamedica = centro();
    ELSE 
               elem.idfichamedica = raux.idfichamedica;
               elem.idcentrofichamedica = raux.idcentrofichamedica;
    
    END IF;	
    idfichamedicaaux =  elem.idfichamedica;


     SELECT INTO rauxfmt *  FROM fichamedicatratamiento
                        WHERE  idfichamedicatratamientotipo= elem.idfichamedicatratamientotipo
                        AND idfichamedica=elem.idfichamedica
                        AND idcentrofichamedica = elem.idcentrofichamedica;
      IF NOT FOUND THEN

      INSERT INTO fichamedicatratamiento (idfichamedica,
 idcentrofichamedica,
idfichamedicatratamientotipo,
fmtfechainicio) 
                            VALUES(elem.idfichamedica,
elem.idcentrofichamedica,
elem.idfichamedicatratamientotipo,
elem.fmtfechainicio);

     elem.idfichamedicatratamiento = currval('public.fichamedicatratamiento_idfichamedicatratamiento_seq');
                elem.idcentrofichamedicatratamiento=currval('public.fichamedicatratamiento_idcentrofichamedicatratamiento_seq');

  --         elem.idcentrofichamedicatratamiento = centro();


      ELSE
          elem.idfichamedicatratamiento = rauxfmt.idfichamedicatratamiento;
          elem.idcentrofichamedicatratamiento = rauxfmt.idcentrofichamedicatratamiento;
      end if;		

--idfichamedicainfotipos ES siempre 8 (presupuesto)
       INSERT INTO fichamedicainfo 
      (fmifecha,
       fmiauditor,
      fmidescripcion,
       idfichamedicatratamiento,
      idcentrofichamedicatratamiento,
       idfichamedicainfotipos) 
VALUES(elem.fmifecha,
       elem.fmiauditor
        ,elem.fmidescripcion,
        elem.idfichamedicatratamiento,
      elem.idcentrofichamedicatratamiento,
      8);

     

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;

return idfichamedicaaux;   

END;$function$
