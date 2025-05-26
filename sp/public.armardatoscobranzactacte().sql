CREATE OR REPLACE FUNCTION public.armardatoscobranzactacte()
 RETURNS SETOF datosmigracioncobranza
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
    idinforme  integer default 0;
    nroinfo INTEGER;
    losnroinfo VARCHAR;
    lala VARCHAR;
    elorigenpago INTEGER; 
    latablapago VARCHAR;
-- REGISTROS
   regpago RECORD;
   uninforme public.datosmigracioncobranza;
   --relinforme public.informefacturacioncobranza%rowtype;
   unitemifc RECORD;
   rexisteninfo RECORD;

--CURSORES
    cursorpago refcursor;
    informes refcursor;
BEGIN
IF NOT  iftableexistsparasp('ttnroinforme') THEN
   CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER,idcentroinformefacturacion INTEGER,ifcorigenpago INTEGER);
END IF;

 IF NOT  iftableexistsparasp('temp_formapago') THEN

  CREATE TEMP TABLE temp_formapago
  ("idTipoValor" VARCHAR,
  "idValor" VARCHAR,
   nroinforme INTEGER,
   monto VARCHAR
  );


 END IF;
 IF NOT  iftableexistsparasp('temp_informefacturacioitem') THEN

  CREATE TEMP TABLE temp_informefacturacioitem
  ("cuentaImputacion" VARCHAR,
       nroinforme INTEGER,
   "montoImputacion" VARCHAR --DOUBLE PRECISION

  );

 END IF;

IF NOT  iftableexistsparasp('temp_formapagocheque') THEN

   CREATE TEMP TABLE temp_formapagocheque
  (barra VARCHAR,
  "nroDocumento" VARCHAR,
  "nombreCliente" VARCHAR,
  "cuit" VARCHAR,
  "idTipoIva" VARCHAR,
  "ciudad" VARCHAR,
  "provincia" VARCHAR,
  "idValor" VARCHAR,
  "idTipoValor" VARCHAR,
  "fechaCobro" DATE,
  "fechaEmision" DATE,
  "idBanco" VARCHAR,
  importe DOUBLE PRECISION,
     nroinforme INTEGER,
  "nroCheque" VARCHAR);
END IF;
IF NOT  iftableexistsparasp('temp_formapagotarjeta') THEN

   CREATE TEMP TABLE temp_formapagotarjeta
  (barra VARCHAR,
  "nroDocumento" VARCHAR,
  "nroAutorizacion" VARCHAR,
  "nombreCliente" VARCHAR,
  "idTarjeta" VARCHAR,
  "nroCupon" VARCHAR,
  "nroTarjeta" VARCHAR,
  "fechaEmision" VARCHAR,
   nroinforme INTEGER,
  cuotas VARCHAR,
  importe VARCHAR);
END IF;
IF NOT  iftableexistsparasp('temp_cuentasmalimputadas') THEN

   CREATE TEMP TABLE temp_cuentasmalimputadas
  ( monto DOUBLE PRECISION,
    "idCuenta" VARCHAR,
     idcentropago INTEGER,
    idcuentadeuda VARCHAR );
END IF;

IF NOT iftableexistsparasp('temp_cobranzassinmigrar') THEN

 
      INSERT INTO ttnroinforme(nroinforme,idcentroinformefacturacion,ifcorigenpago)
            ( SELECT DISTINCT informefacturacioncobranza.nroinforme,idcentroinformefacturacion,ifcorigenpago
                          FROM   informefacturacioncobranza	NATURAL JOIN informefacturacioncobranzaunc 
			NATURAL JOIN  informefacturacionestado 
			WHERE nullvalue(fechafin) and idinformefacturacionestadotipo <>8
               ) ;
END IF;
    SELECT INTO rexisteninfo * FROM ttnroinforme; 
    IF FOUND THEN
 
         SELECT INTO losnroinfo  trim(trailing ' or ' from text_concatenar(concat('nroinforme = ', T.nroinforme  , ' or ' )))
                 FROM
               ( /*SELECT DISTINCT informefacturacioncobranza.nroinforme
                          FROM   informefacturacioncobranza	NATURAL JOIN informefacturacioncobranzaunc 
			NATURAL JOIN  informefacturacionestado 
			WHERE nullvalue(fechafin) and idinformefacturacionestadotipo <>8
                UNION */
                SELECT DISTINCT informefacturacioncobranza.nroinforme FROM informefacturacioncobranza NATURAL JOIN ttnroinforme) AS T;
       
         /*Defino con que tabla debo joinear*/
         IF (rexisteninfo.ifcorigenpago=2 ) THEN 
-- CS 2015-09-30
--         latablapago = 'ctactepagonoafil';
          latablapago = 'ctactepagocliente';
         ELSE 
          latablapago = 'cuentacorrientepagos';
   
         END IF; 



/*busco las formas de pago, tengo en cuenta ambas tablas: cuentacorrientepagos y ctactepagonoafil ya que el pago puede ser de un afiliado como de una institucion o que cliente que no es afiliado de la obra social. Como a veces el importe guardado en las tablas de pago no es negativo, pregunto por eso y lo vuelvo positivo. El case tambien es para encontrar el importe del pago.  */
--KR 03-02-15 COMente que se le sume al monto del pago el saldo, ya que el valor del pago esta dado por lo que está en recibocupon

-- CS 2017-01-25 comento esto y lo reemplazo por la consulta de abajo.
-- No coincidia la suma de las cuentas con la suma de los pagos

--Consulta anterior
/*
         EXECUTE concat('  INSERT INTO temp_formapago(monto, "idTipoValor", "idValor",   nroinforme)
       (SELECT sum(r.monto + CASE WHEN nullvalue(ifcu.nroinforme) AND nullvalue(rca.idrecibo) THEN ccp.saldo
                                  ELSE 0 END)::VARCHAR as montopago, 
                              idformapagotipos::VARCHAR ,idvalorescaja::VARCHAR, T.nroinforme
	     FROM  ttnroinforme as T NATURAL JOIN informefacturacioncobranza AS ifc
               LEFT JOIN informefacturacioncobranzaunc AS ifcu USING(nroinforme, idcentroinformefacturacion)
               JOIN ', latablapago  , ' as ccp USING(idpago,idcentropago) 			
               JOIN recibocupon as r ON (ifc.idcentropago = r.centro AND 
                                ccp.idcomprobante = r.idrecibo  AND ifc.idformapagocobranza=r.idvalorescaja)
               LEFT JOIN recibocobroacuenta AS rca USING(idrecibo, centro)	
                NATURAL JOIN valorescaja
               GROUP BY  idcentropago, idvalorescaja,idformapagotipos,T.nroinforme)');
*/

-- Consulta vigente
EXECUTE concat('  INSERT INTO temp_formapago(monto, "idTipoValor", "idValor",   nroinforme)
       (SELECT sum(r.monto)::VARCHAR as montopago, 
                              idformapagotipos::VARCHAR ,idvalorescaja::VARCHAR, T.nroinforme
	     FROM  ttnroinforme as T NATURAL JOIN informefacturacioncobranza AS ifc
               LEFT JOIN informefacturacioncobranzaunc AS ifcu USING(nroinforme, idcentroinformefacturacion)
               JOIN ', latablapago  , ' as ccp USING(idpago,idcentropago) 			
               JOIN recibocupon as r ON (ifc.idcentropago = r.centro AND 
                                ccp.idcomprobante = r.idrecibo  AND ifc.idformapagocobranza=r.idvalorescaja)
               LEFT JOIN recibocobroacuenta AS rca USING(idrecibo, centro)	
                NATURAL JOIN valorescaja
               GROUP BY  idcentropago, idvalorescaja,idformapagotipos,T.nroinforme)');

/* estas cuentas solo se imputan mal para descuentos de la UNCo y es de forma manual, por eso solo tengo en cuenta la tabla donde se guardan los pagos de los afiliados cuentacorrientepagos */
         INSERT INTO temp_cuentasmalimputadas(monto, "idCuenta" , idcuentadeuda,idcentropago)
          (SELECT sum(ccdp.importeimp) as montopago,mccc.nrocuentac AS ctactepago,  mcccd.nrocuentac AS ctactedeuda,idcentropago
           FROM  ttnroinforme NATURAL JOIN informefacturacioncobranza
       
            NATURAL JOIN cuentacorrientepagos as ccp
           JOIN cuentacorrientedeudapago AS ccdp USING(idpago, idcentropago)
           JOIN cuentacorrientedeuda AS ccd USING(iddeuda, idcentrodeuda)
           JOIN mapeocuentascontablesconcepto AS mccc ON (ccp.idconcepto = mccc.nroconcepto)
           JOIN mapeocuentascontablesconcepto AS mcccd ON (ccd.idconcepto = mcccd.nroconcepto)
           WHERE ccp.idconcepto<>ccd.idconcepto AND ccp.fechamovimiento >='2014-01-01'
          AND not((ccp.idconcepto=360 and ccd.idconcepto=372 ) or (ccp.idconcepto=372 and ccd.idconcepto=360))
         
          GROUP BY mccc.nrocuentac, mcccd.nrocuentac,idcentropago
          HAVING sum(ccdp.importeimp) > 0.01
         );



/*busco las formas de pago en tarjeta*/
 EXECUTE concat('  INSERT INTO temp_formapagotarjeta("nroAutorizacion", barra, "nroDocumento", "nombreCliente", cuotas,
"idTarjeta", importe, "nroCupon","nroTarjeta","fechaEmision",nroinforme)

 (
SELECT rc.autorizacion, cliente.barra, cliente.nrocliente, cliente.denominacion,rc.cuotas, rc.idvalorescaja
,rc.monto, rc.nrocupon, rc.nrotarjeta,r.fecharecibo, if.nroinforme
FROM informefacturacion AS if NATURAL JOIN    ttnroinforme as T NATURAL JOIN informefacturacioncobranza as ifc
    
      NATURAL JOIN cliente  JOIN ', latablapago  , ' as ccp USING(idpago,idcentropago) 			
      JOIN recibo as r 	 ON (ifc.idcentropago = r.centro AND ccp.idcomprobante  = r.idrecibo) 	
        NATURAL JOIN recibocupon AS rc 
       JOIN valorescaja USING(idvalorescaja)
      WHERE    (valorescaja.idformapagotipos=4 OR valorescaja.idformapagotipos=5))');


/*busco las formas de pago en  cheques*/

IF (rexisteninfo.ifcorigenpago=2 ) THEN 					
	 EXECUTE concat(' INSERT INTO temp_formapagocheque("ciudad","provincia","idTipoIva","cuit",barra, "nroDocumento", "nombreCliente", "idValor", "idTipoValor",
	"fechaCobro", "fechaEmision", "idBanco",importe,"nroCheque",nroinforme)
	(
	SELECT idlocalidad,idprovincia,cliente.idcondicioniva,concat(cliente.cuitini,''-'',cliente.cuitmedio,''-'',cliente.cuitfin) as cuit,cliente.barra, cliente.nrocliente,cliente.denominacion, rc.idvalorescaja,valorescaja.idformapagotipos,
	r.fecharecibo,r.fecharecibo,rc.autorizacion,rc.monto, rc.nrocupon, if.nroinforme

	FROM informefacturacion AS if NATURAL JOIN    ttnroinforme as T NATURAL JOIN informefacturacioncobranza as ifc 
	    JOIN ', latablapago  , ' as ccp USING(idpago,idcentropago)

	-- CS 2018-03-08 esta relacion ctactepagocliente con cliente cambia
		left join clientectacte cc on (ccp.idclientectacte=cc.idclientectacte)
		left join cliente on (cc.nrocliente=cliente.nrocliente and cc.barra=cliente.barra)
		--JOIN cliente on (ccp.nrodoc=cliente.nrocliente and ccp.tipodoc=cliente.barra)
	-------------------------------------------------------------------
	    NATURAL JOIN direccion
	      JOIN recibo as r 	 ON (ifc.idcentropago = r.centro AND  ccp.idcomprobante  = r.idrecibo) 		
	      NATURAL JOIN recibocupon AS rc 
	      JOIN valorescaja USING(idvalorescaja)
	     WHERE idvalorescaja=47   )');
ELSE
	EXECUTE concat(' INSERT INTO temp_formapagocheque("ciudad","provincia","idTipoIva","cuit",barra, "nroDocumento", "nombreCliente", "idValor", "idTipoValor",
		"fechaCobro", "fechaEmision", "idBanco",importe,"nroCheque",nroinforme)
		(
		SELECT idlocalidad,idprovincia,cliente.idcondicioniva,concat(cliente.cuitini,''-'',cliente.cuitmedio,''-'',cliente.cuitfin) as cuit,cliente.barra, cliente.nrocliente,cliente.denominacion, rc.idvalorescaja,valorescaja.idformapagotipos,
		r.fecharecibo,r.fecharecibo,rc.autorizacion,rc.monto, rc.nrocupon, if.nroinforme

		FROM informefacturacion AS if NATURAL JOIN    ttnroinforme as T NATURAL JOIN informefacturacioncobranza as ifc 
		    JOIN ', latablapago  , ' as ccp USING(idpago,idcentropago)
		    JOIN cliente on (ccp.nrodoc=cliente.nrocliente and ccp.tipodoc=cliente.barra)
		    NATURAL JOIN direccion
		      JOIN recibo as r 	 ON (ifc.idcentropago = r.centro AND  ccp.idcomprobante  = r.idrecibo) 		
		      NATURAL JOIN recibocupon AS rc 
		      JOIN valorescaja USING(idvalorescaja)
		     WHERE idvalorescaja=47   )');

END IF;


/*Busco las cuentas contables y sus montos */
  EXECUTE concat('INSERT INTO temp_informefacturacioitem( "cuentaImputacion" , "montoImputacion", nroinforme)
       (
        SELECT nrocuentac as  "cuentaImputacion", sum(importe) as "montoImputacion",nroinforme
        FROM informefacturacionitem as ifi NATURAL JOIN ttnroinforme
        WHERE ( ', losnroinfo  , ')         AND ifi.idcentroinformefacturacion=centro()
        GROUP BY nroinforme, nrocuentac,nroinforme) ');



FOR uninforme in 
       
/*Armo la estructura de tipo esperada en la aplicacion */

--       SELECT  concat(T.nroinforme,'-',T.idcentropago) AS "idSiges", 

       SELECT  T.nroinforme AS "idSiges", 
       concat('Inf.Cob.' , T.nroinforme ,'-', T.idcentropago,': ',max(T.denominacion), ' desde '  , min(T.fechadesde )
           , ' hasta ' , max(T.fechahasta) ,'. ',  dartextoinfocob(T.nroinforme,T.idcentropago,rexisteninfo.ifcorigenpago) ) AS descripcion
           ,T.idcentropago as "centroCosto", max(T.fechahasta) AS "fechaCobranza"
/*
CS 2018-02-01 version anterior      
       SELECT  T.nroinforme AS "idSiges", 
       concat('Informe Cobranza ' , T.nroinforme ,'-', T.idcentropago,' desde '  , min(T.fechadesde )
           , ' hasta ' , max(T.fechahasta) ,'. ',  dartextoinfocob(T.nroinforme,T.idcentropago,rexisteninfo.ifcorigenpago) ) AS descripcion
           ,T.idcentropago as "centroCosto", max(T.fechahasta) AS "fechaCobranza"
*/

    FROM  (SELECT nroinforme, ifc.idcentroinformefacturacion,min(ifc.fechadesde) as fechadesde,max(ifc.fechahasta) as fechahasta,ifc.idcentropago
--
          , 'SOSUNC' as denominacion
--
 
          FROM   informefacturacioncobranza as ifc NATURAL JOIN informefacturacioncobranzaunc 
          NATURAL JOIN  informefacturacionestado  NATURAL JOIN ttnroinforme
	  WHERE nullvalue(fechafin) and idinformefacturacionestadotipo <>8
          GROUP BY  nroinforme, idcentroinformefacturacion,idcentropago
    
          UNION 
         SELECT nroinforme, ifc.idcentroinformefacturacion,min(ifc.fechadesde) as fechadesde,max(ifc.fechahasta) as fechahasta,ifc.idcentropago
--
--          ,max(case when not nullvalue(c.denominacion) then c.denominacion else c2.denominacion end) as denominacion
          ,text_concatenar(concat((case when not nullvalue(c.denominacion) then c.denominacion else c2.denominacion end),' | ')) as denominacion
--
          FROM informefacturacioncobranza as ifc NATURAL JOIN ttnroinforme

-- CS 2018-02-01 para que salga el nombre del cliente
          left join ctactepagocliente pc using (idpago,idcentropago)
          left join cuentacorrientepagos pa using (idpago,idcentropago)
          left join cliente c on (pa.idctacte::bigint/10=c.nrocliente and pa.idctacte::bigint%10=barra)
          left join clientectacte cc on (pc.idclientectacte=cc.idclientectacte and pc.idcentroclientectacte=cc.idcentroclientectacte)
          left join cliente c2 on (cc.nrocliente=c2.nrocliente and cc.barra=c2.barra)
-- --------------------------------------------------
         GROUP BY  nroinforme, idcentroinformefacturacion,idcentropago   
  ) as T GROUP BY idcentropago,nroinforme
        loop
return next uninforme;
end loop;

END IF;

END;$function$
