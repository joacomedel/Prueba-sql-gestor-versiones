CREATE OR REPLACE FUNCTION public.verificaingresacliente()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE

 	rcliente RECORD;
  	rtempcliente RECORD;
  	rafil RECORD;
  	--rtitu refcursor;
        respuesta varchar;
        rcuit RECORD;
        
  
BEGIN
   
     SELECT INTO rcliente * FROM tempcliente;
     -- 1 : Verifico si es el cliente ya existe
     SELECT INTO rtempcliente * FROM cliente
     WHERE  nrocliente = rcliente.nrocliente;
    IF FOUND THEN
        respuesta = concat(trim(rtempcliente.nrocliente),'|'::text,trim(rtempcliente.barra));

    ELSE 
        -- 2:  Verifico si es afiliado benef, pues si es titutlar ya lo habria encuentrado en cliente
        SELECT INTO rafil c.* 
	FROM cliente  as c
	LEFT JOIN benefsosunc as bs ON bs.nrodoctitu = nrocliente AND bs.tipodoctitu = c.barra AND bs.nrodoc = rcliente.nrocliente
	LEFT JOIN benefreci as br ON br.nrodoctitu = nrocliente AND br.tipodoctitu = c.barra AND br.nrodoc = rcliente.nrocliente
        WHERE ( not nullvalue(bs.nrodoctitu) OR not nullvalue(br.nrodoctitu)) 
        LIMIT 1;

	IF FOUND THEN
		respuesta = concat(trim(rafil.nrocliente),'|'::text,trim(rafil.barra));

	ELSE
        --* No esta en cliente y hay que daro de alta. 
		INSERT INTO direccion (barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
	        VALUES ('','A Completar',10,'','','',1,1);
		INSERT INTO cliente (nrocliente , barra , idtipocliente, 
                      idcondicioniva, cuitmedio, iddireccion, idcentrodireccion, denominacion )
                      VALUES (rcliente.nrocliente , rcliente.barra , rcliente.idtipocliente, rcliente.idcondicioniva
                      ,rcliente.nrocliente,currval('direccion_iddireccion_seq'), centro(), rcliente.denominacion);

                IF length(rcliente.nrocliente) > 8 THEN 
			SELECT INTO rcuit trim(left(rcliente.nrocliente, 2)) as cuitini,trim(right(rcliente.nrocliente, 1)) as cuitfin,trim(right(trim(left(rcliente.nrocliente, -1)),8)) as cuitmedio;
		        UPDATE cliente SET cuitini = rcuit.cuitini
				,cuitmedio=rcuit.cuitmedio
				,cuitfin=rcuit.cuitfin
				,nrocliente = rcuit.cuitmedio
				WHERE nrocliente = rcliente.nrocliente 
				AND barra = rcliente.barra;
				respuesta = concat(trim(rcuit.cuitmedio),'|',trim(rcliente.barra));
		ELSE
				respuesta = concat(trim(rcliente.nrocliente),'|',trim(rcliente.barra));
		END IF;
		
        END IF;
     END IF ;
     

RETURN respuesta;
END;
$function$
