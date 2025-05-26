CREATE OR REPLACE FUNCTION public.actualizarproveedores(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    curproveedor REFCURSOR;
    unproveedor RECORD;
    salida varchar;
    rprovmap RECORD;
    rconiva RECORD;
BEGIN
     	OPEN  curproveedor for
        	SELECT substring(cuit from 1 for 2) as inicio,substring(cuit from 4 for 8) as medio,substring(cuit from 10 for 2) as fin,tempproveedormulivac.*
            FROM tempproveedormulivac;

        FETCH curproveedor INTO unproveedor;
	    WHILE FOUND LOOP
                    salida = 'Migrado Correctamente ';
                    SELECT  INTO rprovmap * FROM multivac.mapeoprestadores
                           WHERE idprestadormultivac = unproveedor.idproveedor;
                     IF FOUND THEN
                                SELECT  INTO rconiva * FROM multivac.mapeotiposiva
                                     WHERE idtipoivamultivac=unproveedor.idtipoiva;
                                IF FOUND THEN
                                   --rprovmap.idprestadorsiges
                                          /* ACTUALIZAR PROVEEDORES*/
                                          UPDATE prestador SET
                                          pdireccion = unproveedor.direccionreal,
                                          ptelefono =unproveedor.tel,
                                          pdomiciliolegal = unproveedor.direccion,
                                          pcuit = unproveedor.cuit,
                                          piva = rconiva.idcondicioniva,
                                          pdescripcion =unproveedor.razonsocial
                                          WHERE idprestador = rprovmap.idprestadorsiges;

                                          /* ACTUALIZA cliente */
                                          UPDATE cliente SET
                                                 cuitini = unproveedor.inicio,
                                                 cuitmedio =unproveedor.medio,
                                                 cuitfin =unproveedor.fin,
                                                 telefono = unproveedor.tel,
                                                 email =unproveedor.email,
                                                 idcondicioniva = rconiva.idcondicioniva
                                          WHERE
                                          nrocliente = rprovmap.idprestadorsiges and barra = 600;
                                          /* ACTUALIZA  personajuridicabis*/
                                          UPDATE personajuridicabis SET
                                                 cuitini = unproveedor.inicio,
                                                 cuitmedio =unproveedor.medio ,
                                                 cuitfin =unproveedor.fin
                                          WHERE nrocliente = rprovmap.idprestadorsiges and barra = 600;


                                ELSE
                                    salida = 'Condicion IVA no encontrada mapeoprestadores';
                                END IF;
                    	
                     ELSE
                         salida = 'Porveedor no encontrado en mapeoprestadores';
                     END IF;
                     UPDATE tempproveedormulivac
                     SET observacion =salida
                     WHERE idproveedor = unproveedor.idproveedor;
               FETCH curproveedor INTO unproveedor;
        END LOOP;
        CLOSE curproveedor;

  return 'true';
end;
$function$
