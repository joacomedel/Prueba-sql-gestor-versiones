CREATE OR REPLACE FUNCTION public.asentarrecibopago()
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
/*Se utuliza para asentar el pago por caja de entrada de los aportes*/
aportes CURSOR FOR
              SELECT *
              FROM tempaportejubpen;
asientos CURSOR FOR
                SELECT *
                FROM tempasiento;
/*temasiento --> centro,amuc,cuentacorriente,debito,credito,efectivo,total,importeletras
tempaportejubpen --> nrodoc,importe,mes,anio,barra*/
raportes RECORD;
rasientos RECORD;
resp bigint;
nrorecibo bigint;
imputacion varchar;
total double precision;
vnrodoc varchar;

BEGIN
    resp = 0;
    total = 0;
    imputacion='Pago Por Caja ';
    OPEN aportes;
    fetch aportes into raportes;
    while found loop
          imputacion =concat( imputacion , to_char(raportes.mes,'00'),'-',to_char(raportes.anio,'0000'),' ');
          vnrodoc = raportes.nrodoc;
          fetch aportes into raportes;
    end loop;
    close aportes;
    imputacion = concat(imputacion , vnrodoc , ' ' , to_char(CURRENT_DATE,'yyyy-MM-dd'));
    open asientos;
    FETCH asientos into rasientos;
    total = total + rasientos.efectivo + rasientos.credito + rasientos.debito + rasientos.amuc + rasientos.cuentacorriente;
    --asienta en recibo
    			SELECT INTO resp * FROM getidrecibo();
        	INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,nroimpreso)
                   VALUES (resp,total,CURRENT_TIMESTAMP,imputacion,rasientos.centro,nrorecibo);
            
           SELECT max(nroimpreso) into nrorecibo
           from recibo;
           nrorecibo = nrorecibo+1;
           update recibo
                  SET nroimpreso = nrorecibo,
                      importeenletras = rasientos.importeletras
                  WHERE idrecibo = resp;

    --asienta en importesrecibo
            if (not nullvalue(rasientos.amuc)) AND (rasientos.amuc > 0) then
              INSERT INTO importesrecibo
                        VALUES (resp,1,rasientos.amuc,rasientos.centro);
              end if;

              if (not nullvalue(rasientos.efectivo)) AND (rasientos.efectivo > 0) then
              INSERT INTO importesrecibo
                     VALUES (resp,2,rasientos.efectivo,rasientos.centro);
              end if;

              if (not nullvalue(rasientos.cuentacorriente)) AND (rasientos.cuentacorriente > 0)  then
                 INSERT INTO importesrecibo
                        VALUES (resp,3,rasientos.cuentacorriente,rasientos.centro);
              end if;

              if (not nullvalue(rasientos.debito))  AND (rasientos.debito > 0) then
                 INSERT INTO importesrecibo
                        VALUES (resp,4,rasientos.debito,rasientos.centro);
              end if;
              if (not nullvalue(rasientos.credito))  AND (rasientos.credito > 0) then
                 INSERT INTO importesrecibo
                        VALUES (resp,5,rasientos.credito,rasientos.centro);
              end if;
              
close asientos;
--    return nrorecibo;	
RETURN resp;
END;
$function$
