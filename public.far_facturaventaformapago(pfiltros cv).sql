CREATE OR REPLACE FUNCTION public.far_facturaventaformapago(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
      coviifp CURSOR FOR SELECT  *
                        FROM  tempoviiformapago;
                       
      corden REFCURSOR;
      citemimportes REFCURSOR;
      roviifp RECORD;
      runiimmporte RECORD;
      eltipocomprobante  integer;
      eltipofactura VARCHAR;
      elnrosucursal integer;
      elnrofactura bigint;

BEGIN
SELECT INTO eltipocomprobante split_part(pfiltros,'|',1);
SELECT INTO eltipofactura split_part(pfiltros, '|',2);
SELECT INTO elnrosucursal split_part(pfiltros,'|',3);
SELECT INTO elnrofactura split_part(pfiltros, '|',4); 

OPEN coviifp;
FETCH coviifp INTO roviifp;
WHILE FOUND LOOP
   OPEN citemimportes FOR SELECT *
                        FROM far_ordenventaitemimportes
                        NATURAL JOIN far_ordenventaitem
                        WHERE idordenventa =roviifp.idordenventa and idcentroordenventa = roviifp.idcentroordenventa AND  idvalorescaja = 0;

   FETCH citemimportes INTO runiimmporte;
   WHILE FOUND LOOP 
	 INSERT INTO far_oviiformapago(idvalorescaja,idordenventaitemimporte,idcentroordenventaitemimporte,oviifpmonto,oviifpmontodto,oviifpporcentajedto,oviifpcantcuotas,oviifpmontocuota,oviifpporcentajeinteres,tipocomprobante,nrosucursal,nrofactura,tipofactura)
         VALUES (roviifp.idvalorescaja,runiimmporte.idordenventaitemimporte,runiimmporte.idcentroordenventaitemimporte,roviifp.oviifpmonto,roviifp.oviifpmontodto,roviifp.oviifpporcentajedto,roviifp.oviifpcantcuotas,roviifp.oviifpmontocuota,roviifp.oviifpporcentajeinteres,eltipocomprobante,elnrosucursal,elnrofactura,eltipofactura); 
	
	 
   FETCH citemimportes INTO runiimmporte;
   END LOOP;
   CLOSE citemimportes;

FETCH coviifp INTO roviifp;
END LOOP;
CLOSE coviifp;




return '';
END;
$function$
