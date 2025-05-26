CREATE OR REPLACE FUNCTION public.far_abmafiliado_2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

cursorafiliado refcursor;
rafiliado RECORD;
rartexistente record;
rprecioventa record;
rpersona record;
rafil record;
elafiliado varchar;
ladireccion bigint;
existeidmutual INTEGER;
resp boolean;
rbenef RECORD;
vnrocliente VARCHAR;
vbarracliente INTEGER;
rcliente RECORD;
esmutu RECORD;
tieneorden RECORD; 
elidafiliado RECORD;

BEGIN

IF NOT existecolumtemp('tfar_afiliado', 'conidafiliado') THEN
    ALTER TABLE tfar_afiliado ADD COLUMN conidafiliado boolean DEFAULT FALSE;

END IF;

OPEN cursorafiliado FOR SELECT * FROM tfar_afiliado;
FETCH cursorafiliado into rafiliado;
WHILE  found LOOP

    IF rafiliado.conidafiliado THEN --30-05-2018 MaLaPi Se llama desde la gestion (Farmacia.Transacciones.TArreglarOrdenVenta) de afiliados que necesitan cambiar los datos de un afiliado usando el idafiliado
         SELECT INTO rafil * FROM far_afiliado WHERE idafiliado = rafiliado.idafiliado AND idcentroafiliado = rafiliado.idcentroafiliado;
        IF FOUND THEN --Tiene que existir, puedo solo se pueden modificar datos desde el gestor de afiliados. 
            --Verifico que el cliente existe, sino lo creo
            SELECT INTO rcliente * FROM cliente where nrocliente = rafiliado.nrocliente;
            IF NOT FOUND THEN
                INSERT INTO cliente(nrocliente,barra,idtipocliente,idcondicioniva,cuitini,cuitmedio,cuitfin,iddireccion,telefono,email,denominacion,idcentrodireccion)
                VALUES (rafiliado.nrocliente,1,5,afiliado.condicionIva,null,rafiliado.nrocliente,null,rafil.iddireccion,rafil.telefono,rafil.email,rafiliado.denominacion,rafil.idcentrodireccion);
            ELSE
                UPDATE cliente SET nrocliente = rafiliado.nrocliente,barra = 1,denominacion = rafiliado.denominacion 
                    WHERE nrocliente = rafiliado.nrocliente;
            END IF;
            -- BelenA 19-09-24 quito del set en el update los datos clave y agrego los datos clave en el WHERE
            UPDATE far_afiliado SET aidafiliadoobrasocial= rafiliado.nroAfiliado
                            ,nrocliente = rafiliado.nrocliente,barra = rafiliado.tipoDoc
                            ,aapellidoynombre = rafiliado.nombreapellido 

            WHERE idafiliado = rafiliado.idafiliado AND idcentroafiliado = rafiliado.idcentroafiliado;
                        elafiliado = concat(rafiliado.idafiliado,'-',rafiliado.idcentroafiliado) AND
                        nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc AND idobrasocial=rafiliado.idobrasocial;
        END IF;
    ELSE 
        IF rafiliado.eliminar THEN -- el afiliado ya no tiene esa obra social
                SELECT INTO elidafiliado * FROM far_afiliado WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.idobrasocial;
                IF FOUND THEN 
                 -- BelenA 19-09-24 cambio para que me filtre por el idafiliado y por el número de documento y tipo ya que el idafiliado se puede llegar a repetir
                 -- Cuando se inserta en far_afiliado con distintos centros
                    SELECT INTO tieneorden * 
                    FROM far_ordenventaitemimportes  
                    WHERE oviiidafiliadocobertura=elidafiliado.idafiliado AND 
                    oviinrodoc=elidafiliado.nrodoc AND oviitipodoc = elidafiliado.tipodoc; 
                    
                    -- BelenA 19-09-24 agrego que me filtre en el WHERE con las claves de la tabla
                    IF NOT FOUND THEN
                      DELETE FROM far_afiliado WHERE idafiliado= elidafiliado.idafiliado AND
                            nrodoc = rafiliado.nroDoc AND 
                            tipodoc = rafiliado.tipoDoc and 
                            idobrasocial=rafiliado.idobrasocial; 
                    END IF;

                END IF; 
        ELSE -- solo recupero el idafiliado
                SELECT INTO esmutu * FROM far_obrasocialmutual WHERE idmutual=rafiliado.idobrasocial limit 1;
                    IF FOUND THEN
                        SELECT INTO existeidmutual *  FROM expendio_tiene_mutual(rafiliado.nroDoc, rafiliado.tipoDoc);
                        IF existeidmutual=0 THEN
                            INSERT INTO mutualpadron(nrodoc,tipodoc,mpidafiliado,idobrasocial,mpdenominacion)
                            VALUES(rafiliado.nrodoc,rafiliado.tipodoc,rafiliado.nroafiliado,rafiliado.idobrasocial,rafiliado.nombreapellido);
                        END IF;
                    END IF;
                --KR 08-02-18 verifico que la persona este activa ya que como no se borra de persona y a veces tampoco de benefsosunc me sigue poniendo al que era titular como cliente 
                SELECT INTO rpersona * FROM persona WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc AND fechafinos>=current_date ;
                IF FOUND THEN
                    -- Es Afiliado de SOSUNC
                    -- Malapi 23-10-2013 Puede ser un afiliado beneficiario en sosunc, en cuyo caso se coloca como cliente el titular
                    SELECT INTO rbenef * FROM benefsosunc WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
                         IF FOUND THEN --ES un beneficiario
                           vnrocliente = rbenef.nrodoctitu;
                           vbarracliente = rbenef.tipodoctitu;
                         ELSE
                            vnrocliente = rpersona.nrodoc;
                            vbarracliente = rpersona.tipodoc;
                         END IF;
                    SELECT into rafil * from far_afiliado WHERE nrodoc = rafiliado.nroDoc 
                            AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.idobrasocial;
                    IF NOT FOUND THEN
                        -- NO está cargado en far_afiliado con otra Obra Social
                        INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,tipodoc,nrodoc,nrocliente,barra,aapellidoynombre,iddireccion)
                        VALUES(rafiliado.idobrasocial,rafiliado.nroAfiliado,rafiliado.tipoDoc,rafiliado.nroDoc,vnrocliente,vbarracliente,rafiliado.nombreapellido,rpersona.iddireccion);
                        elafiliado = concat(currval('far_afiliado_idafiliado_seq'),'-',centro());
                        --Malapi 11-12-2013 Puede ser el caso en el que fue un benef por lo que no estaba en cliente pero ya no esta en benefsosunc pues esta desafiliado
                        SELECT INTO rcliente * FROM cliente where nrocliente = rafiliado.nroDoc;
                        IF NOT FOUND THEN
                            INSERT INTO  cliente(nrocliente,barra,idtipocliente,idcondicioniva,cuitini,cuitmedio,cuitfin,iddireccion,telefono,email,denominacion,idcentrodireccion)
                            VALUES (rafiliado.nroDoc,rafiliado.tipoDoc,5,rafiliado.condicionIva,rafiliado.cuitini,rafiliado.cuitmedio,rafiliado.cuitfin,rpersona.iddireccion,rafiliado.telefono,rafiliado.email,rafiliado.nombreapellido,rpersona.idcentrodireccion);
                        END IF;
                    ELSE
                    -- BelenA 19-09-24 quito del set en el update los datos clave
                        elafiliado = concat(rafil.idafiliado,'-',rafil.idcentroafiliado);
                        UPDATE far_afiliado 
                        SET aidafiliadoobrasocial= rafiliado.nroAfiliado,
                            nrocliente = vnrocliente,barra = vbarracliente,
                            aapellidoynombre = rafiliado.nombreapellido ,
                            iddireccion = rpersona.iddireccion
                        WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.idobrasocial;
                    END IF;
                ELSE
                    -- No es Afiliado de SOSUNC
                    SELECT into rafil * from far_afiliado WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.idobrasocial;
                    IF NOT FOUND THEN
                    -- NO está cargado en far_afiliado con otra Obra Social

                        INSERT INTO direccion (barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
                        VALUES (rafiliado.barrio,rafiliado.calle,rafiliado.nro,rafiliado.tira,rafiliado.piso,rafiliado.dpto,rafiliado.provincia,rafiliado.localidad);
                        ladireccion = currval('direccion_iddireccion_seq');
                        INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,tipodoc,nrodoc,nrocliente,barra,aapellidoynombre,iddireccion)
                        VALUES(rafiliado.idobrasocial,rafiliado.nroAfiliado,rafiliado.tipoDoc,rafiliado.nroDoc,rafiliado.nroDoc,rafiliado.tipoDoc,rafiliado.nombreapellido,ladireccion);
                        elafiliado = concat(currval('far_afiliado_idafiliado_seq'),'-',centro());

                        SELECT INTO rcliente * FROM cliente where nrocliente = rafiliado.nroDoc;
                        IF NOT FOUND THEN
                            INSERT INTO cliente(nrocliente,barra,idtipocliente,idcondicioniva,cuitini,cuitmedio,cuitfin,iddireccion,telefono,email,denominacion,idcentrodireccion)
                            VALUES (rafiliado.nroDoc,rafiliado.tipoDoc,5,rafiliado.condicionIva,rafiliado.cuitini,rafiliado.cuitmedio,rafiliado.cuitfin,ladireccion,
                            rafiliado.telefono,rafiliado.email,rafiliado.denominacion,centro());
                        END IF;

                    ELSE -- solo recupero el idafiliado
                        -- BelenA 19-09-24 quito del set en el update los datos clave
                        elafiliado = concat(rafil.idafiliado,'-',rafil.idcentroafiliado);
                        UPDATE far_afiliado SET aidafiliadoobrasocial= rafiliado.nroAfiliado,
                                barra = rafiliado.tipoDoc,aapellidoynombre = rafiliado.nombreapellido ,
                                iddireccion = rpersona.iddireccion
                        WHERE nrodoc = rafiliado.nroDoc AND tipodoc = rafiliado.tipoDoc and idobrasocial=rafiliado.idobrasocial;
                        SELECT INTO rcliente * FROM cliente where nrocliente = rafiliado.nroDoc;
                        IF NOT FOUND THEN
                            INSERT INTO cliente(nrocliente,barra,idtipocliente,idcondicioniva,cuitini,cuitmedio,cuitfin,iddireccion,telefono,email,denominacion,idcentrodireccion)
                            VALUES (rafiliado.nroDoc,rafiliado.tipoDoc,5,rafiliado.condicionIva,rafiliado.cuitini,rafiliado.cuitmedio,rafiliado.cuitfin,ladireccion,
                            rafiliado.telefono,rafiliado.email,rafiliado.denominacion,centro());
                        ELSE
                            UPDATE cliente SET nrocliente = rafiliado.nroDoc,barra = rafiliado.tipoDoc,
                            idtipocliente = 5,idcondicioniva = rafiliado.condicionIva,cuitini = rafiliado.cuitini,
                            cuitmedio = rafiliado.cuitmedio,cuitfin = rafiliado.cuitfin,telefono = rafiliado.telefono,
                            email = rafiliado.email,denominacion = rafiliado.denominacion WHERE nrocliente = rafiliado.nroDoc;
                        END IF;
                    END IF;
            END IF;
        END IF; -- Fin de IF rafiliado.eliminar THEN
    END IF; -- Fin IF rafiliado.conidafiliado THEN

FETCH cursorafiliado into rafiliado;

END LOOP;

close cursorafiliado;

return elafiliado;

END;
$function$
