CREATE OR REPLACE FUNCTION public.eliminarreciboautomaticodesdectactedeuda()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE 
  rrecibo RECORD;

  crrecibo refcursor;

BEGIN 

  OPEN crrecibo FOR  SELECT  * FROM recibo WHERE imputacionrecibo ILIKE '%Asiento de compensacion%' and ( idrecibo=1000093092 or idrecibo=1000093093);

  FETCH crrecibo INTO rrecibo;
  WHILE FOUND LOOP

      
       DELETE FROM reciboautomatico WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro; 
 
       DELETE FROM importesrecibo WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro; 

       DELETE FROM recibocupon WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro; 
    
       DELETE FROM recibousuario WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro; 

       DELETE FROM pagosafiliado WHERE (idpagos,centro)  in (SELECT idpagos,centro FROM pagos 
                             WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro);  

       DELETE FROM pagos WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro;  

       DELETE FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = rrecibo.centro; 

  FETCH crrecibo INTO rrecibo;
  END LOOP;
  CLOSE crrecibo;

/*
delete from cuentacorrientedeudapagocompensacion where (iddeudagenerada=263023 or iddeudagenerada=263024 ) and idcentrodeudagenerada=1;
delete from cuentacorrientedeudapago where (iddeuda=263024 or iddeuda=263023) and idcentrodeuda=1;
delete from cuentacorrientepagos where (idcomprobante=1000093088 or idcomprobante=1000093089) and idcentropago=1;
delete from cuentacorrientedeuda where (iddeuda=263023 or iddeuda=263024) and idcentrodeuda=1;

*/
      RETURN TRUE;
END;
    $function$
