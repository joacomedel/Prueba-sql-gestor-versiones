CREATE OR REPLACE FUNCTION public.modificarestadoaporte(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD
        rfiltros RECORD;
        relaporte  RECORD;
--VARIABLES
       vimportelimite DOUBLE PRECISION;
       vtoodok BOOLEAN;
BEGIN
--KR 30-8-22 MODIFIco el limite, lo tomo de la tabla aporteimportelimite tkt 5327
--vimportelimite = 600.00;
SELECT INTO vimportelimite ailimporte FROM aporteimportelimite WHERE nullvalue(ailfechafin);
 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 
--IF (rfiltros.origendeuda ILIKE 'noafiliado') THEN
/*KR 03-11-21 comento ya que la tabla aporteconfiguracioninformefacturacion hay aportes que no estan, quizas es un caso aislado que tocamos manualmente pq no deberia pasar pero la realidad es que no se necesita la tabla. Ej(iddeuda, idcentrodeuda) = (30068,1) */
   SELECT INTO relaporte * 
      FROM ctactedeudacliente 
/*JOIN aporteconfiguracioninformefacturacion*/ 
        JOIN informefacturacion ON idcomprobante = nroinforme*100+idcentroinformefacturacion /* NATURAL JOIN informefacturacion */
                          NATURAL JOIN informefacturacionaporte 
                          WHERE iddeuda =rfiltros.iddeuda AND idcentrodeuda=rfiltros.idcentrodeuda;
IF FOUND THEN 
--KR 12-09-22 Creo esta tabla pq no encuentro aun el error de que no se actualice el estado de un adherente
   UPDATE ctacteadherenteestado SET ccaedescripcion=concat('Se modifico el estado en la tabla aporteestado ' ) 
 ,idclientectacte=relaporte.idclientectacte,importe=relaporte.importe,saldo=relaporte.saldo,nrocliente=relaporte.nrocliente,barra=relaporte.barra,idaporte=relaporte.idaporte,idcentroregionaluso= relaporte.idcentroregionaluso 
   WHERE iddeuda =relaporte.iddeuda and idcentrodeuda = relaporte.idcentrodeuda;
       
  
   IF (abs(relaporte.saldo) <= vimportelimite ) THEN -- SE imputo toda la deuda y es de un aporte KR 11-05 por diferencia de redondeo dejamos hasta 600 centavos y se considera pagado el aporte
RAISE NOTICE 'saldo (%)',abs(relaporte.saldo);
       UPDATE aporteestado SET aefechafin=now() WHERE idaporte = relaporte.idaporte AND idcentroregionaluso = relaporte.idcentroregionaluso AND nullvalue(aefechafin);
       INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,idcentroregionaluso) VALUES(relaporte.idaporte, 'Se cancela la deuda del aporte. SP sys_modificarestadoaporte',7,relaporte.idcentroregionaluso);
     
       UPDATE ctacteadherenteestado SET ccaedescripcion=concat('Se modifico el estado en la tabla aporteestado, nuevo id: ', currval('aporteestado_idaporteestado_seq'), '-',centro() ) WHERE iddeuda =relaporte.iddeuda and idcentrodeuda = relaporte.idcentrodeuda;
       --KR 20-05-20 MODIFICO EL ESTADo del afiliado 
       SELECT INTO vtoodok cambiarestadoconfechafinos(concat('nrodoc =''',persona.nrodoc,'''')) 
                FROM persona join clientectacte on nrodoc = nrocliente natural join ctactedeudacliente
                WHERE iddeuda =rfiltros.iddeuda AND idcentrodeuda=rfiltros.idcentrodeuda;

      
   END IF;
 END IF;
 return '';

END;$function$
