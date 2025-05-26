CREATE OR REPLACE FUNCTION public.generarminutapagoexpendioreintegro(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	elreintegro RECORD;
	laotp RECORD;
        rcuentacontable RECORD;
--variables 
	idnroop INTEGER;
        elnroinforme alias for $1;
        elcentroinforme alias for $2;
BEGIN


	SELECT INTO laotp concat(if.tipofactura , ' ' , to_char(if.nrosucursal, '0000') , ' - ' ,  to_char(if.nrofactura, '00000000')) AS nrofacturaconformato,  * 
	FROM informefacturacion as if NATURAL 
        JOIN informefacturacionexpendioreintegro 
        JOIN reintegro USING(nroreintegro, anio, idcentroregional)
        JOIN persona USING (tipodoc, nrodoc)  
        JOIN tiposdoc USING (tipodoc)
        JOIN mapeoformapagotipostipoformapago USING(idformapagotipos)
       /*agrego hector left join en ves del join para las personas que no tienen cuentas. que quieren el pago efectivo*/
        LEFT JOIN cuentas  USING (tipodoc, nrodoc)   
	WHERE nroinforme = elnroinforme AND idcentroinformefacturacion=elcentroinforme ;

        SELECT INTO rcuentacontable * FROM ordenpagotipo WHERE idordenpagotipo=2;

        CREATE TEMP TABLE tempordenpago ( nroordenpago BIGINT NOT NULL,
				  fechaingreso DATE, 
				  beneficiario VARCHAR, 
				  concepto VARCHAR, 
				  asiento VARCHAR,
				  importetotal DOUBLE PRECISION,
                                  idordenpagotipo INTEGER,
                                  nrocuentachaber VARCHAR
				 ) WITHOUT OIDS;  
	
	CREATE TEMP TABLE tempordenpagoimputacion (
				  codigo INTEGER, 
				  nroordenpago BIGINT NOT NULL,
				  debe FLOAT,
				  haber FLOAT
				  ) WITHOUT OIDS;
	
	CREATE TEMP TABLE tempreintegro (
				  nroreintegro INTEGER NOT NULL,
				  anio INTEGER NOT NULL,
				  tipodoc SMALLINT NOT NULL, 
				  nrodoc VARCHAR(8) NOT NULL, 
				  tipocuenta SMALLINT,
				  nrocuenta BIGINT,
				  tipoformapago INTEGER,
				  nroordenpago BIGINT,
				  centroregional INTEGER
				  ) WITHOUT OIDS;
        SELECT INTO idnroop nextval('ordenpago_seq');
--MaLaPi 22-02-2018 Modifico para que la minuta tenga como fecha de ingreso, la fecha en la que se genero el reintegro. 
-- VAS 13-04-2018 Modifico para que la minuta se genere con la fecha actual
	INSERT INTO tempordenpago (nroordenpago,fechaingreso,beneficiario,concepto,importetotal, idordenpagotipo, nrocuentachaber) 
		VALUES (idnroop ,now() ,concat(laotp.descrip,' ',laotp.nrodoc,'',laotp.apellido, ' ' , laotp.nombres),
		concat('Minuta de pago vinculada a ', laotp.nrofacturaconformato,' del reintegro ' , laotp.nroreintegro,'-',laotp.anio,'-',
		laotp.idcentroregional), laotp.rimporte, 2, rcuentacontable.nrocuentachaber);

	
	INSERT INTO tempordenpagoimputacion (codigo,nroordenpago,debe,haber)
--KR saco las cuentas contables del reintegro 10-10-17
        SELECT nrocuentac::integer, idnroop, SUM(case when nullvalue(importe)  THEN 0 ELSE importe END), 0
	FROM reintegroprestacion NATURAL JOIN tipoprestacion NATURAL JOIN cuentascontables
	WHERE nroreintegro = laotp.nroreintegro AND anio=laotp.anio AND idcentroregional=laotp.idcentroregional
	GROUP BY nrocuentac, idnroop;


/*  KR hasta el 21-08-17
	SELECT nrocuentac::integer, idnroop, SUM(importe), 0
	FROM informefacturacionitem NATURAL JOIN informefacturacionexpendioreintegro
	WHERE nroinforme = elnroinforme AND idcentroinformefacturacion=elcentroinforme 
	GROUP BY nrocuentac, idnroop;
*/
-- CS 2017-09-08
-- Las cuentas contables ahora las obtiene de la tabla cuentascontablesreintegros
      /* KR comenta el 10-10-17
        SELECT nrocuentacreintegro::integer, idnroop, SUM(importe), 0
	FROM informefacturacionitem NATURAL JOIN informefacturacionexpendioreintegro
             JOIN cuentascontablesreintegros cc on (informefacturacionitem.nrocuentac=cc.nrocuentac) 
	WHERE nroinforme = elnroinforme AND idcentroinformefacturacion=elcentroinforme 
	GROUP BY nrocuentacreintegro, idnroop;
*/
	INSERT INTO tempreintegro (nroreintegro,anio,tipodoc,nrodoc,tipocuenta,nrocuenta,tipoformapago,nroordenpago,centroregional) 
		VALUES (laotp.nroreintegro,laotp.anio,laotp.tipodoc, laotp.nrodoc,laotp.tipocuenta, laotp.nrocuenta, laotp.tipoformapago,idnroop,laotp.idcentroregional);
		
        
	PERFORM generarordenpagoreintegro();

        


	
return true;   

END;
$function$
