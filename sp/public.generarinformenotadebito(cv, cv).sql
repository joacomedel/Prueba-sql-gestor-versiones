CREATE OR REPLACE FUNCTION public.generarinformenotadebito(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    --idprestadorfac INTEGER;
    elem RECORD;
    regfactura RECORD;
    resultado BOOLEAN;
    regdebito RECORD;
    idinforme integer;
    indiceestado integer;
    importedebito DOUBLE PRECISION;
    resp BOOLEAN;
    cursordebito CURSOR FOR
                SELECT  debitofacturaprestador.iddebitofacturaprestador, debitofacturaprestador.idcentrodebitofacturaprestador,debitofacturaprestador.importe
                FROM debitofacturaprestador
                WHERE debitofacturaprestador.nroregistro = $1 	AND debitofacturaprestador.anio= $2;
	
BEGIN

    -- SELECT INTO idprestadorfac idprestador FROM factura WHERE nroregistro= $1 and anio =$2;
    SELECT INTO regfactura
		concat(r.clase,r.puntodeventa,' ',r.numero) as nrocomprobante,
        f.idprestador::text as idprestador,
        concat(f.nroregistro::text,'/',f.anio::text) as nroregistro,
        case when (not nullvalue(f.nroordenpago)) then f.nroordenpago::text else '' end as nroordenpago,
        case when (not nullvalue(c.pdescripcion)) then c.pdescripcion else 'Ninguno' end as colegio
	from factura as f
		 join reclibrofact as r on (f.nroregistro=r.numeroregistro)
		 join prestador as p on (f.idprestador=p.idprestador)
		 left join prestador as c on (p.idcolegio=c.idprestador)
	WHERE f.nroregistro= $1 and f.anio =$2;

     SELECT INTO elem cliente.nrocliente, cliente.barra FROM cliente JOIN prestador ON (cliente.nrocliente=prestador.idprestador)
     WHERE prestador.idprestador=regfactura.idprestador AND cliente.barra=600;

  /*creo el informe de facturacion, 5 es el numero que corresponde al tipo de informe de NOTA DE DEBITO (ver tabla informefacturaciontipo)
     le modifico el estado FACTURABLE*/
    SELECT INTO idinforme * FROM crearinformefacturacion(elem.nrocliente,elem.barra,5);

  -- Actualizo el Informe para que sea para Nota de Debitos
  UPDATE informefacturacion SET idtipofactura = 'DI'
  WHERE informefacturacion.nroinforme = idinforme
  AND informefacturacion.idcentroinformefacturacion = centro();
  -- Cambio el estado del informe de facturacion 3=facturable

     FOR indiceestado IN 1..3 LOOP

          SELECT INTO resp * FROM cambiarestadoinformefacturacion(idinforme,centro(),indiceestado,'Generado Automaticamente desde generarinformenotadebito');

      END LOOP;



    OPEN cursordebito;
    FETCH cursordebito INTO regdebito;
    importedebito = 0;
    WHILE FOUND LOOP

     /*creo el informe de facturacion de nota de debito */
    INSERT INTO informefacturacionnotadebito(nroinforme,idcentroinformefacturacion,iddebitofacturaprestador,idcentrodebitofacturaprestador)
    VALUES(idinforme,centro(),regdebito.iddebitofacturaprestador,regdebito.idcentrodebitofacturaprestador);
    importedebito = importedebito + regdebito.importe;
    FETCH cursordebito INTO regdebito;

    END LOOP;

    CLOSE cursordebito;

   -- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
   -- el numero de cuenta contable para los debitos es la 40716

    INSERT INTO ttinformefacturacionitem(nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
    VALUES (idinforme,'40716',1,importedebito,	concat('Concepto: Deducción por Auditoría (Comp.: ' ,regfactura. nrocomprobante,')',E'\n',
												'Registro: ', regfactura.nroregistro,E'\n',
												'Minuta: ',regfactura.nroordenpago, E'\n',
												'Agrupador: ',regfactura.colegio));

   SELECT INTO resultado * FROM insertarinformefacturacionitem();

   DELETE from ttinformefacturacionitem;

return resultado;
END;
$function$
