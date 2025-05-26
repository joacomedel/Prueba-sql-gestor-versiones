CREATE OR REPLACE FUNCTION public.dardatoscuentaproveedor_ineficiente_()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	ctempcuentas refcursor;
--RECORD
	unacuenta RECORD;
	aux RECORD;
	minutareintegro RECORD;
	rcuentanrodoc RECORD;
	rminutaafil RECORD;
--VARIABLES
	resultado BOOLEAN;
	elcuil varchar;
	laobsmodificada varchar;
BEGIN
    elcuil ='';
    laobsmodificada='';
    OPEN ctempcuentas FOR  SELECT * FROM tempcuentaproveedor;
    FETCH ctempcuentas into unacuenta;
    WHILE FOUND LOOP
--KR 04-06-19 busco los datos de las MP que generaron movimientos para los afiliados 
	SELECT INTO rminutaafil * 
        FROM  ordenpagocontableordenpago AS opcop NATURAL JOIN ordenpagocontable AS opc NATURAL JOIN ordenpagoafiliado NATURAL JOIN cambioestadoordenpago 
	WHERE idordenpagocontable =unacuenta.idcomprobante AND nullvalue(ceopfechafin) AND idtipoestadoordenpago <> 4;

	IF FOUND THEN 



        SELECT INTO rcuentanrodoc  p.nrodoc,rpad('',11,' ')::varchar AS nrocuit, p.tipodoc, concat(p.apellido,' ',p.nombres)::text AS p_razonsocial
        FROM ordenpagoafiliado AS opa NATURAL JOIN persona p
        WHERE opa.nroordenpago= rminutaafil.nroordenpago AND opa.idcentroordenpago= rminutaafil.idcentroordenpago; 
       

        SELECT INTO aux *  FROM cuentas  WHERE cuentas.nrodoc  = rcuentanrodoc.nrodoc AND cuentas.tipodoc =  rcuentanrodoc.tipodoc;  
        --KR 04-06-19 copio comentario Y sentencias de ML 
        IF FOUND AND aux.nrobanco = 191 THEN --MaLaPi 12-10-2017 Cuando el banco es credicoop no es obligatorio el CUIL, como no siempre esta bien cargado no lo pongo
            SELECT INTO elcuil rpad('',11,' ')::varchar;
        ELSE --MaLaPi 12-10-2017 Cuando el banco es otro, el cuil es obligatorio por lo que lo tengo que poner si o si, si no lo tengo lo genero. 
            SELECT INTO elcuil CASE WHEN length(concat(nrocuilini,nrocuildni,nrocuilfin)::varchar)<11 THEN '' ELSE concat('1',nrocuilini,nrocuildni,nrocuilfin) END
            FROM afilsosunc 
            WHERE nrodoc  = rcuentanrodoc.nrodoc AND tipodoc =  rcuentanrodoc.tipodoc; 
            IF elcuil = '' THEN 
                     SELECT INTO aux * FROM arreglarcuil(rcuentanrodoc.nrodoc,rcuentanrodoc.tipodoc);
                     SELECT INTO elcuil CASE WHEN length(concat(nrocuilini,nrocuildni,nrocuilfin)::varchar)<11 THEN '' 
                                     ELSE    concat('1',nrocuilini,nrocuildni,nrocuilfin) END
                     FROM afilsosunc 
                     WHERE nrodoc  = rcuentanrodoc.nrodoc AND tipodoc =  rcuentanrodoc.tipodoc; 
            END IF;
         
        END IF;

	SELECT INTO laobsmodificada CONCAT('*#*MP',rminutaafil.nroordenpago,'-',rminutaafil.idcentroordenpago, '*#*',unacuenta.nroopago);
       




ELSE 
    SELECT INTO minutareintegro * FROM (
	--Malapi 13/10/2017 Determina si es un reintegro sin OTP 
	SELECT  nroreintegro, anio,idcentroregional 
                FROM ordenpagocontableordenpago AS opcop
                NATURAL JOIN ordenpagocontable AS opc
                NATURAL JOIN reintegro 
                WHERE idordenpagocontable =  unacuenta.idcomprobante
                      AND trim(split_part(trim(substring(opcobservacion from '%Pago Reintegro #"_________________#"%' for '#')), '-',1)) = nroreintegro
	and trim(split_part(trim(substring(opcobservacion from '%Pago Reintegro #"_________________#"%' for '#')), '-',2)) = anio
	and trim(split_part(trim(substring(opcobservacion from '%Pago Reintegro #"_________________#"%' for '#')), '-',3)) = idcentroregional 
	UNION 
	--Malapi 13/10/2017 Determina si es un reintegro de una OTP
	SELECT nroreintegro,anio,idcentroregional 
		FROM  ordenpagocontablereintegro AS opcr
     
                NATURAL JOIN ordenpagocontableordenpago AS opc
		WHERE idordenpagocontable =  unacuenta.idcomprobante
	) as t ;


		IF FOUND THEN
    	-- es una orden de pago contable asociada a un reintegro, entonces busco al beneficiario del reintegro

         --KR 23-10-17 busco los datos de la MP y de la OTP en caso de existir

           SELECT INTO laobsmodificada CONCAT('*#*MP',nroordenpago,'-',idcentroordenpago,
                 text_concatenar( CASE WHEN NOT nullvalue(if.nrofactura) THEN  CONCAT('*#*',if.tipofactura , '-' , if.nrosucursal, '-' ,  if.nrofactura) END) )
                 FROM ordenpagocontablereintegro NATURAL JOIN ordenpagocontableordenpago 
                 LEFT JOIN  informefacturacionexpendioreintegro AS ifex USING ( nroreintegro,anio,idcentroregional) 
                 LEFT JOIN  informefacturacion AS if USING (nroinforme, idcentroinformefacturacion)
                 LEFT JOIN tipocomprobanteventa ON(tipocomprobante=idtipo)
                 WHERE idordenpagocontable =  unacuenta.idcomprobante
                           -- AND idcentroordenpagocontable= 1
                  GROUP BY nroordenpago,idcentroordenpago;
                         SELECT INTO rcuentanrodoc
                         CASE WHEN nullvalue(nrodoctitu) THEN p.nrodoc ELSE bs.nrodoctitu END AS nrodoc,rpad('',11,' ')::varchar AS nrocuit
                         ,CASE WHEN nullvalue(nrodoctitu) THEN p.tipodoc  ELSE bs.tipodoctitu END::integer  AS tipodoc,
                         CASE WHEN nullvalue(nrodoctitu) THEN concat(p.apellido,' ',p.nombres) ELSE concat(ptitu.apellido,' ',ptitu.nombres) END::text AS p_razonsocial
                 FROM reintegrobenef AS rb 
                 --NATURAL JOIN persona AS p --ON (rb.nrodocbenef = p.nrodoc AND rb.tipodocbenef=p.tipodoc)			
                  LEFT JOIN persona AS p USING(nrodoc) --MaLapi 10-10-2017 En reintegrobenef esta solo la barra, y la barra puede cambiar en el 
		  LEFT JOIN benefsosunc AS bs USING(nrodoc, tipodoc)
                  LEFT JOIN persona AS ptitu ON(nrodoctitu=ptitu.nrodoc AND tipodoctitu=ptitu.tipodoc)
		  WHERE rb.nroreintegro= minutareintegro.nroreintegro AND rb.anio= minutareintegro.anio
                       AND rb.idcentroregional=minutareintegro.idcentroregional;
	
             SELECT INTO aux *  FROM cuentas  WHERE cuentas.nrodoc  = rcuentanrodoc.nrodoc AND cuentas.tipodoc =  rcuentanrodoc.tipodoc;  
             IF FOUND AND aux.nrobanco = 191 THEN --MaLaPi 12-10-2017 Cuando el banco es credicoop no es obligatorio el CUIL, como no siempre esta bien cargado no lo pongo
                 SELECT INTO elcuil rpad('',11,' ')::varchar;
             ELSE --MaLaPi 12-10-2017 Cuando el banco es otro, el cuil es obligatorio por lo que lo tengo que poner si o si, si no lo tengo lo genero. 
                    SELECT INTO elcuil CASE WHEN length(concat(nrocuilini,nrocuildni,nrocuilfin)::varchar)<11 THEN '' ELSE    
                                        concat('1',nrocuilini,nrocuildni,nrocuilfin) END
                                       FROM afilsosunc 
                                       WHERE nrodoc  = rcuentanrodoc.nrodoc AND tipodoc =  rcuentanrodoc.tipodoc; 
             IF elcuil = '' THEN 
                     SELECT INTO aux * FROM arreglarcuil(rcuentanrodoc.nrodoc,rcuentanrodoc.tipodoc);
                     SELECT INTO elcuil CASE WHEN length(concat(nrocuilini,nrocuildni,nrocuilfin)::varchar)<11 THEN '' 
                                     ELSE    concat('1',nrocuilini,nrocuildni,nrocuilfin) END
                     FROM afilsosunc 
                     WHERE nrodoc  = rcuentanrodoc.nrodoc AND tipodoc =  rcuentanrodoc.tipodoc; 
             END IF;
         
       END IF;

             
    	ELSE
             SELECT INTO rcuentanrodoc unacuenta.nrocuit as nrocuit,unacuenta.nrocuit as nrodoc, 12 AS tipodoc, unacuenta.p_razonsocial;
			
        END IF;
   END IF;             
		SELECT INTO aux *  FROM cuentas  WHERE cuentas.nrodoc  = rcuentanrodoc.nrodoc AND cuentas.tipodoc =  rcuentanrodoc.tipodoc;  

		UPDATE tempcuentaproveedor SET tipocuenta= aux.tipocuenta, nrobanco= aux.nrobanco, nrosucursal= aux.nrosucursal,
			nrocuenta= aux.nrocuenta, digitoverificador = aux.digitoverificador, cemail = aux.cemail,
                        nrocuit= CASE WHEN (elcuil='') THEN rcuentanrodoc.nrocuit ELSE elcuil END,
                        cbuini= aux.cbuini, cbufin= aux.cbufin,
                        p_razonsocial= rcuentanrodoc.p_razonsocial,
                      ---  tiponrodoc =  (trim(rpad( CASE WHEN rcuentanrodoc.tipodoc=12 THEN concat('12', rcuentanrodoc.nrodoc) ELSE elcuil END , 22, ' ')))
                       observacionmodificada = laobsmodificada, 
                       tiponrodoc =  CASE WHEN (elcuil='') 
                                     THEN (trim(rpad( concat(CASE WHEN rcuentanrodoc.tipodoc=12 THEN 1 ELSE rcuentanrodoc.tipodoc END ,rcuentanrodoc.nrodoc), 22, ' ')))  ELSE elcuil END

                        


		WHERE idcomprobante = unacuenta.idcomprobante;
     
		FETCH ctempcuentas into unacuenta;
	END LOOP;
     	CLOSE ctempcuentas;
return 'true';
END;
$function$
