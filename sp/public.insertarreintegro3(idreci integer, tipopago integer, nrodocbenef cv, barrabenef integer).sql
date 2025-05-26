CREATE OR REPLACE FUNCTION public.insertarreintegro3(idreci integer, tipopago integer, nrodocbenef character varying, barrabenef integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Es llamado desde mesa de entrada cuando se da
entrada a un reintegro, se le pasa como parametro
el idrecepcion.
Llena la tabla reintegro, setea el idcentroregional en 1
(Neuquen). Llena el resto de los campos con excepcion de
los campos tipoformapago,nroordenpago y rimporte.
Inserta el reintegro en la tabla restados como pendiente
Carga las prestaciones del reintegro en la tabla reintegroprestacion
LLena la tabla reintegrobenef con el nrosiges del beneficiario del
reintegro y el nro de reintegro
*/
DECLARE
          eltipoauditoria integer;
          elidficha integer;
          elidcentroficha integer;
         
        idreci alias for $1;
         tipopago alias for $2;
        nrodocbenef alias for $3;
         barrabenef alias for $4;
        tipoformapagodef reintegro.tipoformapago%TYPE;
    rrec RECORD;
    rcuentas RECORD;
    aux RECORD;
    nroreint RECORD;
    laficha RECORD;
   
    rrecreintegro CURSOR FOR
                   SELECT persona.nrodoc as nrodoc
                             ,persona.tipodoc as tipodoc
                             ,extract('year' from fecha) as anio
                             ,persona.barra
                             ,localidad
                             ,nombreaf
                             ,apellidoaf
                             ,fecha
                             ,idestudio
                             ,cantidad
                             ,centroregional.idcentroregional
                             FROM recepcion NATURAL JOIN recreintegro
                             NATURAL JOIN reintegroestudio
                             JOIN centroregional on centroregional.idcentroregional = recepcion.idcentroregional 
                             JOIN persona USING(nrodoc,barra)
    WHERE idrecepcion =$1 and recepcion.idcentroregional = centro();

BEGIN
        IF (tipopago = 0) THEN
        tipoformapagodef:=NULL;
        ELSE
                tipoformapagodef:=tipopago;
        END IF;

    OPEN rrecreintegro;   
    FETCH rrecreintegro INTO rrec;
    WHILE  found LOOP
   
       SELECT INTO aux * FROM reintegro where idrecepcion = idreci and reintegro.idcentrorecepcion = centro();
       IF NOT FOUND THEN
          SELECT INTO rcuentas * FROM cuentas  
                                 WHERE (rrec.nrodoc = cuentas.nrodoc AND rrec.tipodoc = cuentas.tipodoc);
           INSERT INTO reintegro (anio,idcentroregional,tipodoc,nrodoc,tipocuenta,nrocuenta,tipoformapago,nroordenpago,rimporte,rfechaingreso,idrecepcion,nrooperacion,idcentrorecepcion )
             VALUES (rrec.anio,rrec.idcentroregional,rrec.tipodoc,rrec.nrodoc,rcuentas.tipocuenta,rcuentas.nrocuenta,tipoformapagodef,null,null,rrec.fecha,idreci,null,centro());

          SELECT INTO nroreint currval(('reintegro_nroreintegro_seq'::text)) as nroreintegro;
          --MaLaPi 20-08-2013 Si se trata de una nrodoc con 7 digitos, le agrego el cero clasico.
          INSERT INTO reintegrobenef(nrodoc,barra,nroreintegro,anio,idcentroregional)
          VALUES(CASE WHEN char_length(nrodocbenef) < 8 THEN concat('0', nrodocbenef) ELSE nrodocbenef END,barrabenef,nroreint.nroreintegro,rrec.anio,rrec.idcentroregional);

                 INSERT INTO restados
                 (fechacambio,nroreintegro,tipoestadoreintegro,anio,observacion,idcentroregional)
                 VALUES(rrec.fecha,nroreint.nroreintegro,1,rrec.anio,'Desde mesa de entrada',rrec.idcentroregional);

                 INSERT INTO reintegroprestacion
                 (nroreintegro,anio,tipoprestacion,importe,observacion,
                 prestacion,cantidad,idcentroregional)
                 VALUES(nroreint.nroreintegro,rrec.anio,rrec.idestudio,0,'Desde mesa de entrada',null,rrec.cantidad,rrec.idcentroregional);

       ELSE
           INSERT INTO reintegroprestacion
              (nroreintegro,anio,tipoprestacion,importe,observacion,prestacion,cantidad,idcentroregional)
/*             VALUES(nroreint.nroreintegro,rrec.anio,rrec.idestudio,0,'Desde mesa de entrada',null,rrec.cantidad,rrec.idcentroregional);*/
VALUES(aux.nroreintegro,rrec.anio,rrec.idestudio,0,'Desde mesa de entrada',null,rrec.cantidad,rrec.idcentroregional);



       END IF;

       /*Generear pendientes en caso de tratarse de psicoterapia o odontología*/
      
      
       -- verificar si existe la ficha medica en caso de ser una practica de odonto o psicoterapia
       --(2 = odonto 4 = psico)
       if (rrec.idestudio= 6 or rrec.idestudio=7 ) THEN
          if (rrec.idestudio=6 ) THEN eltipoauditoria=1; END IF;
          if (rrec.idestudio=7 ) THEN eltipoauditoria=3; END IF;
        
           SELECT INTO laficha * FROM fichamedica
                  WHERE fichamedica.nrodoc=rrec.nrodoc
                        AND  fichamedica.tipodoc=rrec.tipodoc
                        AND fichamedica.idauditoriatipo =eltipoauditoria;

          IF NOT FOUND THEN
              INSERT INTO fichamedica (tipodoc,nrodoc,fmfechacreacion,fmdescripcion,idauditoriatipo)
              VALUES(rrec.tipodoc,rrec.nrodoc,now(),'Generada desde mesa de entrada ingreso reintegro',eltipoauditoria);
              elidficha =  currval('public.fichamedica_idfichamedica_seq');
              SELECT INTO elidcentroficha * FROM centro();
          ELSE
              elidficha = laficha.idfichamedica ;
              elidcentroficha = laficha.idcentrofichamedica;
          END IF;

          INSERT INTO fichamedicaitempendiente(tipodoc,nrodoc,idfichamedica,idcentrofichamedica,idauditoriatipo, nroreintegro, idcentroregional , anio )
             VALUES(rrec.tipodoc,rrec.nrodoc,elidficha,elidcentroficha,eltipoauditoria, nroreint.nroreintegro, rrec.idcentroregional, rrec.anio );
       END IF; -- cierra el if del caso de prestacion para psicoterapia o odontología

      
      
      
      
      
    FETCH rrecreintegro INTO rrec;
    END LOOP;
    CLOSE rrecreintegro ;
    RETURN 'true';
END;
$function$
