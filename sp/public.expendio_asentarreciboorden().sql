CREATE OR REPLACE FUNCTION public.expendio_asentarreciboorden()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE

--cursororden CURSOR FOR SELECT *  FROM temporden;
nuevas CURSOR FOR  SELECT * FROM ttordenesgeneradas;
nueva RECORD;
dato RECORD;
recreciboimporte RECORD;
elidrecibo bigint;
nrorecibo bigint;
imputacion varchar;
total double precision;
respuesta bool;
rcentro integer;
rusuario record; 
rordencbn record;

BEGIN
 
    total = 0;
    imputacion='Pago del coseguro de la/s orden/es: ';
    OPEN nuevas;
    fetch nuevas into nueva;
    while found loop
          imputacion = concat(imputacion , to_char(nueva.centro,'00'),'-',to_char(nueva.nroorden,'00000000'),' ');
          fetch nuevas into nueva;
    end loop;
    close nuevas;
    --open cursororden;
    --FETCH cursororden into dato;
    SELECT INTO dato * FROM temporden;
    
    
    SELECT INTO total SUM(importe) FROM importesorden   NATURAL JOIN ttordenesgeneradas where idformapagotipos<>6;
                      -- KR comente. Lo que quiero son todas las formas de pago diferente a sosunc where idformapagotipos=3 or  idformapagotipos=1;

     --asienta en recibo
    SELECT INTO elidrecibo * FROM getidrecibo();
  
    INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,nroimpreso,importeenletras)
                   VALUES (elidrecibo,total,CURRENT_TIMESTAMP,imputacion,dato.centro,nrorecibo,convertinumeroalenguajenatural(total::numeric) );



/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;
    INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (elidrecibo,dato.centro,rusuario.idusuario) ;


    if (dato.recibo) then
           SELECT max(nroimpreso) into nrorecibo
           from recibo;
           nrorecibo = nrorecibo+1;
           update recibo
                  SET nroimpreso = nrorecibo,
                      importeenletras = dato.importeenletras
                  WHERE idrecibo = elidrecibo and centro=dato.centro;
    end if;
  
  INSERT INTO importesrecibo ( idrecibo , centro  , idformapagotipos,importe)
                (SELECT elidrecibo ,dato.centro ,  idformapagotipos , SUM(importe)
                 FROM importesorden
                 NATURAL JOIN ttordenesgeneradas /*where idformapagotipos=3*/
                 group by  idformapagotipos);
   

   
     INSERT INTO ordenrecibo (idrecibo, nroorden  , centro )
            ( SELECT  elidrecibo , nroorden, centro
              FROM ttordenesgeneradas
            );
               

--    return nrorecibo;	
/*Modifica 22-01-2008 MaLaPi: para que cargue el consumo a la cuenta corriente*/
/*KR 11-11-20 no se genera deuda para las ordenes online de CBN */
-- SL 25/09/23 - Agrego condicion para que filtre las ordenes de tipo 56 y convenio 154 (son generadas desde la app)
-- VAS 100724 NO SE DEBERIAN GENERAR PENDIENTES EN CTA CTE para NADIE testear quitar este bloque de funcionalidad
SELECT INTO rordencbn * 
FROM ordenrecibo   
NATURAL JOIN orden NATURAL 
JOIN ordvalorizada ov 
JOIN prestador p ON (nromatricula = idprestador) 
NATURAL JOIN (SELECT DISTINCT idasocconv, acdecripcion 
              FROM asocconvenio 
              where acactivo and aconline 
) as asocconvenio 
where  (asocconvenio.idasocconv=127 OR asocconvenio.idasocconv= 154 OR asocconvenio.idasocconv= 121
         OR asocconvenio.idasocconv =169  
            -- 2024-11-21 para que no genere el movimiento en la cuenta corriente y quede para que auditoria apruebe la facturacion
        ) 
        AND tipo =56 
        and ordenrecibo.idrecibo =elidrecibo and ordenrecibo.centro=centro();
IF NOT FOUND THEN 
/*KR 24-01-22 si la orden es de reintegros no se genera el movimiento en la cta cte, ya que ahora se hace desde la OT. sp asentarcomprobantefacturacioninformes. TKT 4829*/
  SELECT INTO rordencbn * 
  from orden natural 
  join ordenrecibo 
  where tipo =55 
         and ordenrecibo.idrecibo = elidrecibo 
         and ordenrecibo.centro=centro();
  IF NOT FOUND THEN 
      SELECT INTO respuesta *  FROM asentarconsumoctacteV2(elidrecibo,centro(),null);
  END IF;
END IF;
--MaLaPi 07-04-2020 Mando a generar el Token
PERFORM expendio_solicitar_token_afiliado('');

RETURN elidrecibo;
END;
$function$
