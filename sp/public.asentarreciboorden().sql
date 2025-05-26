CREATE OR REPLACE FUNCTION public.asentarreciboorden()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE

cursororden CURSOR FOR
              SELECT *
              FROM ttorden;
/*
nrodoc        varchar
centro        integer
idsocconv     bigint
recibo        boolean   
tipo          varchar
cantordenes   integer   en este SP no se usa
amuc       -> double - puede ser null
efectivo   -> double - puede ser null
debito     -> double - puede ser null
credito    -> double - puede ser null
ctacte     -> double - puede ser null
sosunc     -> double
importeenletras varchar      puede ser null (se usa para cuando se debe imprimir el recibo)
*/

nuevas CURSOR FOR
                 SELECT *
                        FROM ttordenesgeneradas;
nueva RECORD;
dato RECORD;
recreciboimporte RECORD;
resp bigint;
nrorecibo bigint;
imputacion varchar;
total double precision;
respuesta bool;
rcentro integer;
rusuario record;
  elidusuario INTEGER; 
BEGIN
    resp = 0;
    total = 0;
    imputacion='Pago del coseguro de la/s orden/es: ';
    OPEN nuevas;
    fetch nuevas into nueva;
    while found loop
          imputacion =concat( imputacion , to_char(nueva.centro,'00'),'-',to_char(nueva.nroorden,'00000000'),' ');
          fetch nuevas into nueva;
    end loop;
    close nuevas;
	open cursororden;
    FETCH cursororden into dato;
    total = total + dato.efectivo + dato.credito + dato.debito + dato.amuc + dato.cuentacorriente;
    --asienta en recibo
         SELECT INTO resp * FROM getidrecibo();
         rcentro = dato.centro;
        	INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,nroimpreso,importeenletras)
                   VALUES (resp,total,CURRENT_TIMESTAMP,imputacion,dato.centro,nrorecibo,dato.importeenletras);
            
    /* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF not found THEN
                   elidusuario = 25;
                ELSE
                    elidusuario = rusuario.idusuario;
                END IF;
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (resp,dato.centro,elidusuario) ;



    if (dato.recibo) then
           SELECT max(nroimpreso) into nrorecibo
           from recibo;
           nrorecibo = nrorecibo+1;
           update recibo
                  SET nroimpreso = nrorecibo,
                      importeenletras = dato.importeenletras
                  WHERE idrecibo = resp and centro=dato.centro;
    end if;
    --asienta en importesrecibo
    /*Lo Agrego MaLaPi 14-12-2007 para el caso de la emision de recetarios gratuitos*/
              IF dato.amuc is null
                 AND dato.efectivo is null
                 AND dato.cuentacorriente is null
                 AND dato.debito is null
                 AND dato.credito is null
                 AND dato.sosunc is null THEN
                 SELECT INTO recreciboimporte * FROM importesrecibo WHERE idrecibo = resp;
                 IF NOT FOUND THEN
                 INSERT INTO importesrecibo
                        VALUES (resp,10,0,dato.centro);
                 END IF;
              END IF;
            if not dato.amuc is null then
              INSERT INTO importesrecibo
                        VALUES (resp,1,dato.amuc,dato.centro);
              end if;

              if not dato.efectivo is null then
              INSERT INTO importesrecibo
                     VALUES (resp,2,dato.efectivo,dato.centro);
              end if;

              if not dato.cuentacorriente is null then
                 INSERT INTO importesrecibo
                        VALUES (resp,3,dato.cuentacorriente,dato.centro);
              end if;

              if not dato.debito is null then
                 INSERT INTO importesrecibo
                        VALUES (resp,4,dato.debito,dato.centro);
              end if;
              if not dato.credito is null then
                 INSERT INTO importesrecibo
                        VALUES (resp,5,dato.credito,dato.centro);
              end if;
              if not dato.sosunc is null then
                 INSERT INTO importesrecibo
                        VALUES (resp,6,dato.sosunc,dato.centro);
              end if;
    OPEN nuevas;
    fetch nuevas into nueva;
    while found loop
          INSERT INTO ordenrecibo
                 values (resp,nueva.centro,nueva.nroorden);
          fetch nuevas into nueva;
    end loop;
    close nuevas;
    close cursororden;
--    return nrorecibo;	
/*Modifica 22-01-2008 MaLaPi: para que cargue el consumo a la cuenta corriente*/
SELECT INTO respuesta *  FROM asentarconsumoctacteV2(resp,rcentro,null);

--MaLaPi 07-04-2020 Mando a generar el Token
PERFORM expendio_solicitar_token_afiliado('');

RETURN resp;
END;
$function$
