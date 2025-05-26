CREATE OR REPLACE FUNCTION public.asentarreciboenctactepagosfarmacia(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
 
PARAMETROS:
           $1: mes
           $2: anio 
           $3: origen pago 1 si es descuento concepto de sosunc, 2 si es UNCo
*/
DECLARE
    rusuario record;
    nrorecibo bigint;
    ridpago bigint;
    cursorauxi refcursor;
    cursorauxisos refcursor;
    elemcursor record;
    elemcursorsos record;
    regctactepago  record;
    existerecibo record;

BEGIN

/*Busco todos los descuentos en informedescuentoplanillav2*/
OPEN cursorauxisos FOR 

SELECT idpv2.idinforme,idpv2.nroliquidacion,idpv2.idcargo,idpv2.importe,idpv2.fechaingreso, idpv2.nrodoc, idpv2.tipodoc, idpv2.concepto
,CASE WHEN $3=2  THEN 8
          ELSE 13  END AS idformapago
,CASE WHEN $3=2 THEN 45
           ELSE 48  END AS idvalcaja
,CASE  WHEN $3=2 THEN '10311'
           ELSE '20661'  END AS nrocta  ---20661 Remuneraciones a Pagar	
,CASE WHEN $3=2 THEN '24917/1'
           ELSE '' END AS nroctab
,CASE WHEN $3=2 THEN 191
           ELSE 0 END AS nrobanco
,CASE WHEN $3=1 THEN 'SOSUNC'   WHEN $3=2 THEN 'UNC' END AS imputacionorigen
,CASE WHEN $3=1 THEN 'SOS'   WHEN $3=2 THEN '@' END AS ladepend
                    FROM informedescuentoplanillav2 as idpv2  LEFT JOIN
(SELECT clientectacte.nrocliente as nrodoc ,  tipodoc 
FROM ctactedeudacliente  AS ccd natural join clientectacte  JOIN enviodescontarctactev2 ON(ccd.iddeuda=enviodescontarctactev2.idmovimiento AND ccd.idcentrodeuda=enviodescontarctactev2.idcentromovimiento)
WHERE    
/*reemplazo 32 por 35*/
  -- CASE WHEN $3 = 1 THEN  concat('32',$2 ,trim(lpad($1,2,'0')))
 CASE WHEN $3 = 1 THEN  concat('35',$2 ,trim(lpad($1,2,'0')))
WHEN $3 =2 THEN concat($2,trim(lpad($1,2,'0')) )END ILIKE idenviodescontarctacte
GROUP BY  clientectacte.nrocliente, tipodoc) AS TT USING(nrodoc,tipodoc)  LEFT JOIN cargo USING (idcargo) 
                    WHERE 

                     
--04-10-2018 MALAPI: NO DEJAR PARAMETROS CABLEADOS.
                        idpv2.mes =$1 AND idpv2.anio=$2
                    /*AND CASE WHEN $3=1 THEN 'SOS'= iddepen
                        ELSE iddepen <> 'SOS' END */

      ORDER BY nrodoc; 

FETCH cursorauxisos INTO elemcursorsos;
WHILE found LOOP

SELECT INTO existerecibo * FROM informedescuentoplanillav2
                           LEFT JOIN ctactepagocliente as c using(idpago,idcentropago)   
                           WHERE idinforme = elemcursorsos.idinforme  AND NULLVALUE(c.idpago)    ;

IF FOUND THEN
			
 
--inserto en las tablas pagos, genero el recibo y updateo en cuentacorrientepagos
       SELECT INTO nrorecibo * FROM getidrecibocaja();
--10311
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro)
     VALUES (nrorecibo,elemcursorsos.importe,elemcursorsos.fechaingreso,
     concat('Descuento ', elemcursorsos.imputacionorigen,' liq ' , elemcursorsos.nroliquidacion , ' cargo ' ,   elemcursorsos.idcargo , ' ' , $1 , '/' , $2, ' concepto ', elemcursorsos.concepto)
,centro());
  INSERT INTO reciboautomatico(idrecibo,centro,idorigenrecibo)      VALUES (nrorecibo,centro(),$3);
  INSERT INTO mapeoinformedescuentoplanillav2recibo(idinforme,idrecibo,centro)      VALUES (elemcursorsos.idinforme ,nrorecibo,centro());

    --asienta en importesrecibo
     INSERT INTO importesrecibo(idrecibo,idformapagotipos,importe,centro)
     VALUES (nrorecibo,elemcursorsos.idformapago,elemcursorsos.importe,centro());
    --descomentado porque se debe insertar tbn en recibo cupon para que se migren correctamente a siges
      INSERT INTO recibocupon(idvalorescaja,  monto, cuotas, idrecibo,centro,nrotarjeta,nrocupon,autorizacion)

            VALUES(elemcursorsos.idvalcaja, elemcursorsos.importe, 1, nrorecibo,centro(),'','','');

     
      INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentac,nrocuentabanco)
    VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,elemcursorsos.idformapago,
        concat('Descuento' ,  elemcursorsos.imputacionorigen , ' liq ' , elemcursorsos.nroliquidacion , ' cargo ' , elemcursorsos.idcargo , ' ' , $1 , '/' , $2),elemcursorsos.fechaingreso,elemcursorsos.idformapago,elemcursorsos.nrobanco,6,2,elemcursorsos.nroctab,elemcursorsos.nrocta,elemcursorsos.nroctab);
   ridpago =currval('pagos_idpagos_seq');
    INSERT INTO pagosafiliado (idpagos,nrodoc,tipodoc) VALUES(ridpago,elemcursorsos.nrodoc,elemcursorsos.tipodoc);

    /* Recuperar el pago y modificar informedescuentoplanillav2*/
      SELECT INTO regctactepago * FROM ctactepagocliente
      WHERE idcomprobante = elemcursorsos.idinforme  AND idcomprobantetipos = 13;
      IF FOUND THEN
               UPDATE informedescuentoplanillav2 SET idcentropago=regctactepago.idcentropago , idpago=regctactepago.idpago
               WHERE idinforme = elemcursorsos.idinforme;

               UPDATE ctactepagocliente SET idcomprobante = nrorecibo  ,idcomprobantetipos = 0
               WHERE idcomprobante = elemcursorsos.idinforme
               AND idcomprobantetipos = 13;
      END IF;

--CS 2018-12-21----------------------------------------------------------------
/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),rusuario.idusuario) ;
--------------------------------------------------------------------------------

END IF;

FETCH cursorauxisos INTO elemcursorsos;
END LOOP;
CLOSE cursorauxisos;

 

return true;

END;$function$
