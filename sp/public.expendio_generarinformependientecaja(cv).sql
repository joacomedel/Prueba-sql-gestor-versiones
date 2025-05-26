CREATE OR REPLACE FUNCTION public.expendio_generarinformependientecaja(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--record
    rfiltros RECORD;
    regorden RECORD; 
    rplancob RECORD; 
    rimporte RECORD; 
--VARIABLES
    idinforme INTEGER;
    resultado BOOLEAN;
    elnroorden INTEGER;
BEGIN
  
  EXECUTE sys_dar_filtros($1) INTO rfiltros;

  SELECT INTO regorden * FROM temporden NATURAL JOIN persona  JOIN 
          ( SELECT osreci.barra barrareci,idosreci, nrodoc,  tipodoc, nrodoc nrodoctitu, tipodoc tipodoctitu FROM osreci  JOIN afilreci  USING(idosreci,barra) 
             UNION 
             SELECT osreci.barra barrareci,idosreci, benefreci.nrodoc,  benefreci.tipodoc,nrodoctitu   ,tipodoctitu
                FROM osreci  JOIN afilreci  USING(idosreci,barra) JOIN benefreci ON (nrodoctitu = afilreci.nrodoc AND tipodoctitu = afilreci.tipodoc)) AS T USING (nrodoc, tipodoc)
             where persona.barra>100; 

  IF FOUND THEN 
    SELECT INTO rplancob  max(idplancob) as idplancob FROM  tempitems WHERE idplancob=12; 
   RAISE NOTICE 'rplancob  (%)',rplancob  ;
    IF FOUND and (rplancob.idplancob =12 OR rplancob.idplancob =29) THEN
-- ES una persona de reci y el plan de la orden es RECIPROCIDAD o RECIPROCIDAD CON COSEGURO. 
    --creo el informe de facturacion, 2 es el numero que corresponde al tipo de informe de RECIPROCIDAD (ver tabla informefacturaciontipo) 
    --este es el pendiente que hoy necesitamos pero si en filtros viene otro tipo es el que creamos

      elnroorden =  currval('"public"."orden_nroorden_seq"'); 
     --  RAISE NOTICE 'entro al if elnroorden  (%)',elnroorden  ;
   
      SELECT INTO rimporte * FROM  importesorden where nroorden =elnroorden  AND centro=centro();
      SELECT INTO idinforme * FROM crearinformefacturacion(regorden.idosreci::VARCHAR,regorden.barrareci::BIGINT,2);
   
      INSERT INTO informefacturacionreciprocidad(nroinforme,idcentroinformefacturacion,centro,nroorden,idosreci,idprestador, nrodoc,tipodoc,idcomprobantetipos,barra, importe) 
     VALUES(idinforme,centro(),centro(), elnroorden ,regorden.idosreci::INTEGER,regorden.idprestador,regorden.nrodoctitu,regorden.tipodoctitu,regorden.tipo,regorden.barrareci, rimporte.importe);
       SELECT INTO resultado * FROM agregarinformefacturacionreciprocidaditem(idinforme ,centro());
     END IF; 
  
 END IF;
 
return '';
END;$function$
