CREATE OR REPLACE FUNCTION public.sys_eliminarinfoaportecompleta(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD      
runifa RECORD;
raporte RECORD;
rfiltros record; 
--CURSOR
cursorifa REFCURSOR;

--VARIABLES
todook VARCHAR;
respuesta BOOLEAN;
  

BEGIN
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
/*
perform borrarpagojubilado(T.idaporte::bigint,T.idcentroregionaluso::integer,T.tipo::varchar )
from (  select idaporte, idcentroregionaluso,  'aporte' as tipo FROM aporte where   idaporte=1005839 and  idcentroregionaluso=1) as T;
*/
 
DELETE FROM ctactedeudapagocliente WHERE (iddeuda, idcentrodeuda) IN (
select iddeuda, idcentrodeuda  FROM ctactedeudacliente where iddeuda=26337 and idcentrodeuda  =1  ) ;


DELETE FROM ctactedeudacliente WHERE (iddeuda, idcentrodeuda) IN (
select iddeuda, idcentrodeuda  FROM ctactedeudacliente where iddeuda=26337 and idcentrodeuda  =1 ) ;

OPEN cursorifa FOR SELECT * 
                FROM facturaventa 
                 where nrosucursal =1001 and  nrofactura=9620 and tipofactura='FA';
 FETCH cursorifa INTO runifa;
 WHILE FOUND LOOP
       SELECT into respuesta FROM far_eliminarcomprobantenoemitido_arregla_talonario(runifa.nrofactura ,runifa.nrosucursal ,runifa.tipocomprobante ,runifa.tipofactura);

       SELECT into raporte ifa.* FROM informefacturacionaporte ifa natural join informefacturacion natural join facturaventa  
         WHERE nrofactura =runifa.nrofactura  and tipofactura=runifa.tipofactura and tipocomprobante =runifa.tipocomprobante and nrosucursal=runifa.nrosucursal;

       SELECT into respuesta FROM borrarpagojubilado(raporte.idaporte ,raporte.idcentroregionaluso ,'aporte');
       delete from informefacturacion where  nrosucursal =1001 and  nrofactura=9620 and tipofactura='FA';
 FETCH cursorifa INTO runifa;
 END LOOP;
 CLOSE cursorifa;

return '';
END;
$function$
