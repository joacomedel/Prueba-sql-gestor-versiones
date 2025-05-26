CREATE OR REPLACE FUNCTION public.far_abmafiliado()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$/* New function body */

DECLARE

cursorafiliado CURSOR FOR SELECT *

                           FROM tfar_afiliado;

    	rafiliado RECORD;

	rartexistente record;

	rprecioventa record;

	rpersona record;

	rafil record;

	elafiliado bigint;

	ladireccion bigint;

	rprecioventavalor double precision;

        elidajuste bigint;

        resp boolean;

        existelote record;
        rbenef RECORD;
        vnrocliente VARCHAR;
        vbarracliente INTEGER;
        rcliente RECORD;


BEGIN

OPEN cursorafiliado;

FETCH cursorafiliado into rafiliado;

WHILE  found LOOP

       SELECT INTO rpersona * FROM persona WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc;

       IF FOUND THEN

       -- Es Afiliado de SOSUNC
          -- Malapi 23-10-2013 Puede ser un afiliado beneficiario en sosunc, en cuyo caso se coloca como cliente el titular
             SELECT INTO rbenef * FROM benefsosunc WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc;
             IF FOUND THEN --ES un beneficiario
                   vnrocliente = rbenef.nrodoctitu;
                   vbarracliente = rbenef.tipodoctitu;
             ELSE
                    vnrocliente = rpersona.nrodoc;
                    vbarracliente = rpersona.tipodoc;
             END IF;

          SELECT into rafil * from far_afiliado WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.obraSocial;

          IF NOT FOUND then

          -- NO está cargado en far_afiliado con otra Obra Social

          	INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,tipodoc,nrodoc,nrocliente,barra,aapellidoynombre,iddireccion)

           	VALUES(rafiliado.obraSocial,rafiliado.nroAfiliado,rafiliado.tipoDoc,rafiliado.nroDoc,vnrocliente,vbarracliente,rafiliado.denominacion,rpersona.iddireccion);

            elafiliado = currval('far_afiliado_idafiliado_seq');
 

           /* Malapi 22/10/2013 Comento pues ya no se usan mas estas tablas.*/	
          --INSERT INTO far_plancoberturaafiliado(idafiliado,idplancobertura) VALUES (elafiliado,rafiliado.planCobertura);

          ELSE

          -- Ya está cargado, solo recupero el idafiliado

              elafiliado = rafil.idafiliado;

          END IF;

       ELSE

       -- No es Afiliado de SOSUNC

          SELECT into rafil * from far_afiliado WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.obraSocial;

          IF NOT FOUND then

          -- NO está cargado en far_afiliado con otra Obra Social

            INSERT INTO direccion (barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)

	        VALUES (rafiliado.barrio,rafiliado.calle,rafiliado.nro,rafiliado.tira,rafiliado.piso,rafiliado.dpto,rafiliado.provincia,rafiliado.localidad);

            ladireccion = currval('direccion_iddireccion_seq');

           	INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,tipodoc,nrodoc,nrocliente,barra,aapellidoynombre,iddireccion)

           	VALUES(rafiliado.obraSocial,rafiliado.nroAfiliado,rafiliado.tipoDoc,rafiliado.nroDoc,rafiliado.nroDoc,rafiliado.tipoDoc,rafiliado.denominacion,ladireccion);

            elafiliado = currval('far_afiliado_idafiliado_seq');
            SELECT INTO rcliente * FROM cliente where nrocliente = rafiliado.nroDoc;
            IF NOT FOUND THEN         
            INSERT INTO cliente(nrocliente,barra,idtipocliente,idcondicioniva,cuitini,cuitmedio,cuitfin,iddireccion,telefono,email,denominacion,idcentrodireccion)

            VALUES (rafiliado.nroDoc,rafiliado.tipoDoc,5,rafiliado.condicionIva,rafiliado.cuitini,rafiliado.cuitmedio,rafiliado.cuitfin,ladireccion,

                   rafiliado.telefono,rafiliado.email,rafiliado.denominacion,centro());
END IF;

          ELSE

          -- Ya está cargado, solo recupero el idafiliado

              elafiliado = rafil.idafiliado;

          END IF;

       END IF;

FETCH cursorafiliado into rafiliado;

END LOOP;

close cursorafiliado;

return elafiliado;

END;

$function$
