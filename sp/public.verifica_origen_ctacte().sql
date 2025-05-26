CREATE OR REPLACE FUNCTION public.verifica_origen_ctacte()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$-- Se asume que existe la siente tabla temporal
-- CREATE TEMP TABLE tempcliente (
--           nrocliente character varying NOT NULL,
--           barra bigint NOT NULL
--           );
--CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
--INSERT INTO tempcliente(nrocliente,barra) VALUES('17627781',1);
--SELECT * FROM verifica_origen_ctacte();

-- Verifica de que tipo de "persona" se trata para saber si su ctacte esta en "prestador" , "cliente", o "afiliado"
DECLARE

 	rcliente RECORD;
  	rtempcliente RECORD;
  	rafil RECORD;
  	--rtitu refcursor;
        respuesta varchar;
        rcuit RECORD;
        
  
BEGIN

     
     SELECT INTO rcliente * FROM tempcliente;
     respuesta = concat('nolose','|'::text,trim(rcliente.nrocliente),'|'::text,trim(rcliente.barra));
    
	
--KR 29-07-21 Agregue el campo  nullvalue(cccborrado) ya que en clientectacte habian afiliados y los movimientos iban a cliente en vez de a afiliado 
-- KR 15-09-21 tenemos que empezar a mirar en la tabla clientectacteestado  x ejemplo se da de baja el empleado de la farma x ejemplo
--KAR 14-12-22 modifico sp para que tome en cuenta la tabla de estados, Cristina x ejemplo se dio de baja pero esta consulta sigue encontrandola como adherente 
     SELECT INTO rtempcliente * FROM cliente NATURAL JOIN clientectacte  LEFT JOIN clientectacteestado ccce USING(nrocliente,barra)
                                WHERE  nrocliente = rcliente.nrocliente
                                  AND barra = rcliente.barra and nullvalue(cccborrado) AND (nullvalue(ccce.nrocliente) OR idestadotipo=8);
    IF FOUND THEN
        -- Esta en clientectacte entonces es un cliente.
 
        respuesta = concat('clientectacte','|'::text,trim(rtempcliente.idclientectacte),'|'::text,trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra),'|'::text,trim(rtempcliente.idcentroclientectacte));
    ELSE 
	 SELECT INTO rtempcliente * FROM cliente 
	          JOIN prestadorctacte ON nrocliente = idprestador 
                  WHERE nrocliente = rcliente.nrocliente and barra = 600;
                                  -- MaLaPi No se con que barra viene desde la ventana, pero se que los prestadores deben ser 600 
                                  -- AND barra = rcliente.barra ;
		 IF FOUND THEN
 
		-- Esta en prestadorctacte entonces es un prestador.
		--idprestadorctacte	idprestador
                --MaLaPi 02-07-2018 El 1 es el centro, que en el caso de los prestadores es Neuquen
			respuesta = concat('prestadorctacte','|'::text,trim(rtempcliente.idprestadorctacte),'|'::text,trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra),'|'::text,trim('1'));

		ELSE 
		    -- En este punto, puede ser un Afiliado, o puede ser un Cliente o un Prestador que no este guardado en la tabla correspondiente
 
		    -- Verifico primero si es un afiliado
--KR 17-07-21 MODIFico para que tome a los afiliados de reci como afiliados y vaya ahi su cta cte
			SELECT INTO rtempcliente c.* ,centro() as idcentroclientectacte
			FROM cliente  as c
			JOIN (select nrodoc, tipodoc,barra  from afilsosunc UNION select nrodoc, tipodoc,barra  from afilreci) as aso ON aso.nrodoc = nrocliente AND aso.tipodoc = c.barra
                        WHERE  c.nrocliente = rcliente.nrocliente
                                  AND c.barra = rcliente.barra AND (aso.barra <> 35 AND aso.barra <> 36);
			IF FOUND THEN
 
				respuesta = concat('afiliadoctacte','|'::text,trim(rtempcliente.nrocliente),trim(rtempcliente.barra),'|'::text,trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra),'|'::text,trim(rtempcliente.idcentroclientectacte));
			ELSE
			     --En este punto, ya se que no es un afiliado, puede ser un cliente o un prestador, para saberlo verifico el tipocliente en la tabla cliente
                            -- Malapi 04/05/2020 En este punto podria ser un afiliado jubilado o pensionado, en este caso el idtipocliente = 1
			     -- si idtipocliente es 6 (Generico) , 4 (Prestador) , 5 (Farmacia)
				SELECT INTO rtempcliente *, 0::bigint as idprestadorctacte,0::bigint as idclientectacte ,0::bigint as idcentroclientectacte 
						FROM cliente 
						WHERE  nrocliente = rcliente.nrocliente
						  AND barra = rcliente.barra;
RAISE NOTICE ' PASO POR 6  ' ;
				IF FOUND THEN 
RAISE NOTICE ' PASO POR 7  ' ;
					IF rtempcliente.idtipocliente = 6 OR rtempcliente.idtipocliente = 5 THEN
						INSERT INTO clientectacte (nrocliente,barra) VALUES(rcliente.nrocliente,rcliente.barra);
						rtempcliente.idclientectacte = currval('clientectacte_idclientectacte_seq'::regclass);
                                                rtempcliente.idcentroclientectacte = centro();
						respuesta = concat('clientectacte','|'::text,trim(rtempcliente.idclientectacte),'|'::text,trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra),'|'::text,trim(rtempcliente.idcentroclientectacte));	
					 END IF;
                                         IF rtempcliente.idtipocliente = 1  THEN
                                          -- Se trata de un afiliado pensionado o jubilado
						INSERT INTO clientectacte (nrocliente,barra) VALUES(rcliente.nrocliente,rcliente.barra);
						rtempcliente.idclientectacte = currval('clientectacte_idclientectacte_seq'::regclass);
                                                rtempcliente.idcentroclientectacte = centro();
						respuesta = concat('clientectacte','|'::text,trim(rtempcliente.idclientectacte),'|'::text,trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra),'|'::text,trim(rtempcliente.idcentroclientectacte));	
					 END IF;
					IF rtempcliente.idtipocliente = 4 THEN
						INSERT INTO prestadorctacte (idprestador,idprestadorctacte) VALUES(rcliente.nrocliente::bigint,rcliente.nrocliente::bigint);
						--Malapi 06-08-2021 lo comento pues me da un error, puesto que en la tabla ya no se usa la secuencia
                                                --rtempcliente.idprestadorctacte = currval('prestadorctacte_idprestadorctacte_seq'::regclass);
                                                 rtempcliente.idprestadorctacte = rcliente.nrocliente::bigint;
						respuesta = concat('prestadorctacte','|'::text,trim(rtempcliente.idprestadorctacte),'|'::text,trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra),'|'::text,trim(rtempcliente.idcentroprestadorctacte));
					 END IF;
				END IF;
			END IF;
		END IF;
	END IF;

RETURN respuesta;
END;
$function$
