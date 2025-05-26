CREATE OR REPLACE FUNCTION public.asentarreciboenctactepagos_hardcodeado(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Busca todos los informedescuentoplanillav2 para ese mes y anio, genero un recibo para el pago recibido desde la universidad
y updatea en la tabla cuentacorrientepagos para ese idcomprobante(que seria el nro de info)
e idcomprobantetipos(13 para descuentos UNC)
PARAMETROS:
           $1: mes
           $2: anio 
           $3: origen pago 1 si es descuento concepto de sosunc, 2 si es UNCo
*/

/*

CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe NUMERIC(10,2),	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
--INSERT INTO descuentososunc VALUES (12,2022,785,990190,990190,374,3495.07,1,'40099510');
 INSERT INTO descuentososunc VALUES (01,2023,789,990190,990190,374,3377.01,1,'40099510');

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
    relpago record;
    
BEGIN


/*Busco todos los descuentos en informedescuentoplanillav2*/
OPEN cursorauxisos FOR 


SELECT idpv2.idinforme,idpv2.nroliquidacion,idpv2.idcargo,idpv2.importe,idpv2.fechaingreso, idpv2.nrodoc, idpv2.tipodoc, idpv2.concepto
,CASE WHEN $3=2  THEN 8
ELSE 13  END AS idformapago
,CASE WHEN $3=2 THEN 45
ELSE 48  END AS idvalcaja
,CASE  WHEN $3=2 THEN '10311'
ELSE '20661'  END AS nrocta
,CASE WHEN $3=2 THEN '24917/1'
ELSE '' END AS nroctab
,CASE WHEN $3=2 THEN 191
ELSE 0 END AS nrobanco
,CASE WHEN $3=1 THEN 'SOSUNC'   WHEN $3=2 THEN 'UNC' END AS imputacionorigen
,CASE WHEN $3=1 THEN 'SOS'   WHEN $3=2 THEN '@' END AS ladepend
                    FROM informedescuentoplanillav2 as idpv2  LEFT JOIN
(SELECT ccd.nrodoc, ccd.tipodoc
FROM cuentacorrientedeuda AS ccd JOIN enviodescontarctactev2 ON(ccd.iddeuda=enviodescontarctactev2.idmovimiento AND ccd.idcentrodeuda=enviodescontarctactev2.idcentromovimiento)
WHERE    
   CASE WHEN $3 = 1 THEN  concat('32',$2 ,trim(lpad($1,2,'0')))
WHEN $3 =2 THEN concat($2,trim(lpad($1,2,'0')) )END ILIKE idenviodescontarctacte
GROUP BY  ccd.nrodoc, ccd.tipodoc) AS TT USING(nrodoc,tipodoc)  

--KR 22-08-22 agrego para que tome en cuenta a los empleados de la farma
LEFT JOIN (SELECT clientectacte.nrocliente as nrodoc ,  tipodoc 
FROM ctactedeudacliente  AS ccd natural join clientectacte  JOIN enviodescontarctactev2 ON(ccd.iddeuda=enviodescontarctactev2.idmovimiento AND ccd.idcentrodeuda=enviodescontarctactev2.idcentromovimiento)
WHERE    
/*reemplazo 32 por 35*/
  -- CASE WHEN $3 = 1 THEN  concat('32',$2 ,trim(lpad($1,2,'0')))
 CASE WHEN $3 = 1 THEN  concat('35',$2 ,trim(lpad($1,2,'0')))
WHEN $3 =2 THEN concat($2,trim(lpad($1,2,'0')) )END ILIKE idenviodescontarctacte
 
GROUP BY  clientectacte.nrocliente, tipodoc) AS tempfarma   USING(nrodoc,tipodoc)



LEFT JOIN cargo ON (idpv2.idcargo = cargo.idcargo AND CASE WHEN $3=1 THEN 'SOS'= iddepen ELSE iddepen <> 'SOS' END  ) 
              

WHERE 

                         idpv2.legajosiu in (23227) AND 
--04-10-2018 MALAPI: NO DEJAR PARAMETROS CABLEADOS.
                        idpv2.mes =$1 AND idpv2.anio=$2
--KR 22-02-22 Comento y lo agrego en el join con cargo
                 /*   AND CASE WHEN $3=1 THEN 'SOS'= iddepen
                        ELSE iddepen <> 'SOS' END 
*/
 and idpv2.nrodoc ='28010149' 
      ORDER BY idpv2.nrodoc; 




FETCH cursorauxisos INTO elemcursorsos;
WHILE found LOOP

  
  --KR 22-08-22 Modifico consulta ya que es un left join y si c.idpago es nulo es nulo en la tabla informedescuentoplanillav2 y bajo la consulta donde la uso
/*SELECT  INTO existerecibo  * FROM informedescuentoplanillav2
                           LEFT JOIN ctactepagocliente as c using(idpago,idcentropago)   
                           WHERE idinforme = elemcursorsos.idinforme  AND NULLVALUE(c.idpago)    ;*/
  --IF FOUND THEN
			
 
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

     --idbanco=9, localidad= 6 (NQN), provincia=2 (NQN)
      INSERT INTO pagos(idpagos,centro,idrecibo,idformapagotipos,pconcepto,pfechaingreso,idpagostipos,idbanco,idlocalidad,idprovincia,nrooperacion,nrocuentac,nrocuentabanco)
    VALUES(nextval('pagos_idpagos_seq'),centro(),nrorecibo,elemcursorsos.idformapago,
        concat('Descuento' ,  elemcursorsos.imputacionorigen , ' liq ' , elemcursorsos.nroliquidacion , ' cargo ' , elemcursorsos.idcargo , ' ' , $1 , '/' , $2),elemcursorsos.fechaingreso,elemcursorsos.idformapago,elemcursorsos.nrobanco,6,2,elemcursorsos.nroctab,elemcursorsos.nrocta,elemcursorsos.nroctab);
   ridpago =currval('pagos_idpagos_seq');
    INSERT INTO pagosafiliado (idpagos,nrodoc,tipodoc) VALUES(ridpago,elemcursorsos.nrodoc,elemcursorsos.tipodoc);

    /* Recuperar el pago y modificar informedescuentoplanillav2*/
     SELECT INTO existerecibo * FROM informedescuentoplanillav2  WHERE idinforme = elemcursorsos.idinforme AND nullvalue(idpago) ;
    /* IF FOUND THEN
      IF (nullvalue(existerecibo) nullvalue(existerecibo.tipoempleado) OR NOT (existerecibo.tipoempleado ILIKE 'Farmacia')) THEN
        INSERT INTO pagosafiliado (idpagos,nrodoc,tipodoc) VALUES(ridpago,elemcursorsos.nrodoc,elemcursorsos.tipodoc);
    */
    /* Recuperar el pago y modificar informedescuentoplanillav2*/
        SELECT INTO regctactepago * FROM cuentacorrientepagos WHERE idcomprobante = elemcursorsos.idinforme  AND idcomprobantetipos = 13;
        IF FOUND THEN
           UPDATE informedescuentoplanillav2 SET idcentropago=regctactepago.idcentropago , idpago=regctactepago.idpago
           WHERE idinforme = elemcursorsos.idinforme;

           UPDATE cuentacorrientepagos SET idcomprobante = nrorecibo  ,idcomprobantetipos = 0
           WHERE idcomprobante = elemcursorsos.idinforme
           AND idcomprobantetipos = 13;

        ELSE 
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
     
        END IF;
  --END IF;
     

--CS 2018-12-21----------------------------------------------------------------
/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),rusuario.idusuario) ;
--------------------------------------------------------------------------------


--END IF;

FETCH cursorauxisos INTO elemcursorsos;
END LOOP;
CLOSE cursorauxisos;



--CS 08-04-2016
--Esto debe ejecutarse en forma manual luego de hacer el proceso de Imputación Manual
--Hablado con Dani

--if($3=2) then
--   PERFORM  generarinformecobranzactacteunc($1,$2);
--end if;


return true;


END;

$function$
