CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica_presupuesto2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES

    idfichamedicaaux INTEGER; 
    idfichamedicainfoaux INTEGER;
    idcentrofichamedicainfoaux INTEGER;



--REGISTROS

    raux RECORD;
    rauxfmt RECORD;
    rauxinfo RECORD;
    rauxinfotratamiento RECORD;
    elem RECORD;
   

--CURSORES


cursorficha refcursor;
    
BEGIN
/*
CREATE TEMP TABLE tempsolicitudpresupuesto (	idsol INTEGER, 	idcentrosol INTEGER, 	idfichamedicainfo INTEGER,    idcentrofichamedicainfo INTEGER, 	idcentrofichamedica INTEGER, 	spfechavencimiento DATE ,   spdescripcion VARCHAR , spdescripciondiagnostico VARCHAR );
INSERT INTO tempsolicitudpresupuesto (	idsol,	idcentrosol,   idfichamedicainfo ,    idcentrofichamedicainfo , 	idcentrofichamedica,	spfechavencimiento,   spdescripcion ,    spdescripciondiagnostico) 	VALUES(188,1,21949,1,1,'2014-06-06','observacion celiaco','diagnostico celiaco  wwwwwwwwww') ;
CREATE TEMP TABLE tempsolpresitem (          spcoditem VARCHAR NOT NULL,          spcoddescripcion VARCHAR NOT NULL,          spdiscriminante VARCHAR NOT NULL,          idsolicitudpresupuestoitem INTEGER,          idcentrosolpreitem INTEGER,          idsolicitudpresupuestoitemestadotipo INTEGER,          spcantidad INTEGER NOT NULL);
INSERT INTO tempsolpresitem (	spcoditem,	spcoddescripcion,	spdiscriminante,	idsolicitudpresupuestoitemestadotipo,	idcentrosolpreitem,	idsolicitudpresupuestoitem,   spcantidad) 	VALUES('50','ancla para hombro 5.0','Articulo',1,1,364,2);INSERT INTO tempsolpresitem (	spcoditem,	spcoddescripcion,	spdiscriminante,	idsolicitudpresupuestoitemestadotipo,	idcentrosolpreitem,	idsolicitudpresupuestoitem,   spcantidad) 	VALUES('180','ansa de polipectomía','Articulo',1,1,365,3);


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
            elem.idcentrofichamedicatratamiento = centro();
 

      ELSE
          
         elem.idfichamedicatratamiento = rauxfmt.idfichamedicatratamiento;
          elem.idcentrofichamedicatratamiento = rauxfmt.idcentrofichamedicatratamiento;
          
      end if;		

--idfichamedicainfotipos ES siempre 8 (presupuesto)


  SELECT INTO rauxinfo *  FROM fichamedicainfo
                        WHERE  idfichamedicainfo= elem.idfichamedicainfo                       
                        AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;
 
      IF NOT FOUND THEN

                          SELECT INTO rauxinfotratamiento *  FROM fichamedicatratamiento
                        WHERE  idfichamedicatratamiento= elem.idfichamedicatratamiento                       
                        AND idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento;
                
              IF NOT FOUND THEN
                       INSERT INTO fichamedicatratamiento 
                  (idfichamedica,
                   idcentrofichamedica,
              idfichamedicatratamientotipo,
                 fmtfechainicio) 
                 VALUES(elem.idfichamedica,
                 elem.idcentrofichamedica      
                ,elem.idfichamedicatratamientotipo,
                    elem.fmtfechainicio);

              end if;

          

       INSERT INTO fichamedicainfo 
      (fmifecha,
       fmiauditor,
      fmidescripcion,
       idfichamedicatratamiento,
      idcentrofichamedicatratamiento,
       idfichamedicainfotipos) 
VALUES(elem.fmifecha,
       elem.fmiauditor
      -- ,elem.fmidescripcionnva,
       ,elem.fmidescripciontotal,
        elem.idfichamedicatratamiento,
      elem.idcentrofichamedicatratamiento,
      8);

idfichamedicainfoaux=currval('public.fichamedicainfo_idfichamedicainfo_seq');
idcentrofichamedicainfoaux = centro() ;

     ELSE
          
        --  UPDATE fichamedicainfo SET fmidescripcion=elem.fmidescripcionnva
              UPDATE fichamedicainfo SET fmidescripcion=elem.fmidescripciontotal
                WHERE  idfichamedicainfo= elem.idfichamedicainfo                       
                        AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;
          idfichamedicainfoaux=elem.idfichamedicainfo;
          idcentrofichamedicainfoaux = centro() ;
      end if;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;

return concat( idfichamedicaaux ,'-', idfichamedicainfoaux ,'-', idcentrofichamedicainfoaux);

END;
$function$
