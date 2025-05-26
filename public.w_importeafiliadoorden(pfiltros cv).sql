CREATE OR REPLACE FUNCTION public.w_importeafiliadoorden(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--CURSORES
cursoritem refcursor;

--RECORD    
ritem RECORD; 
runiteminfo RECORD; 
rladeuda RECORD;
roocbn  RECORD;

--VARIABLES
elnroorden BIGINT;
elcentro INTEGER;
vimpafiliado DOUBLE PRECISION;
totalafiliado  DOUBLE PRECISION;
respuesta varchar;
 
BEGIN

  SELECT INTO elnroorden split_part(pfiltros, '-',1);
  SELECT INTO elcentro split_part(pfiltros, '-',2);
  vimpafiliado = 0;
  OPEN cursoritem FOR SELECT *  FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion 
		      WHERE nroorden = elnroorden AND centro= elcentro;
  FETCH cursoritem INTO ritem;
  WHILE FOUND LOOP
        vimpafiliado = case when nullvalue(ritem.iicoberturasosuncauditada) then 0 else ritem.iiimporteunitario* (1-ritem.iicoberturasosuncauditada) end; 
	SELECT INTO runiteminfo * FROM iteminformacionimporteafiliado WHERE iditem= ritem.iditem AND centro=ritem.centro;
        IF NOT FOUND THEN 

             INSERT INTO iteminformacionimporteafiliado(iditem,centro,iiiaimportesinauditoria,iiiaimporteconauditoria)                                            
 VALUES(ritem.iditem,ritem.centro,round((case when(ritem.iditemestadotipo=4) then ritem.iiimporteafiliadounitario else 0 end)::numeric,2),round((case when(ritem.iditemestadotipo=2) then vimpafiliado else 0 end)::numeric,2));

       ELSE 

           
 
           UPDATE iteminformacionimporteafiliado SET iiiaimportesinauditoria = case when(ritem.iditemestadotipo=4) then vimpafiliado else 0 end
                                                     ,iiiaimporteconauditoria = case when(ritem.iditemestadotipo=2) then vimpafiliado else 0 end
                                                     
                 WHERE  iditem= ritem.iditem AND centro=ritem.centro;
       END IF;
           UPDATE iteminformacionimporteafiliado SET iiiaimportetotal = (iiiaimportesinauditoria+iiiaimporteconauditoria)
                   WHERE  iditem= ritem.iditem AND centro=ritem.centro;

FETCH cursoritem INTO ritem;
END LOOP;
CLOSE cursoritem;

/* KR 1-7-21 comento pq ya no se genera la deuda aqui sino con el comprobante. 

--KR 21-07-20 Modifico el importe de la deuda del afiliado acorde a lo que se audito
SELECT INTO totalafiliado sum(iiiaimporteconauditoria) from itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion  NATURAL JOIN iteminformacionimporteafiliado
		                                 WHERE nroorden = elnroorden AND centro= elcentro;  
/* KR 11-11-20 La deuda ahora se genera cuando se audita la orden para CBN*/

select into roocbn * FROM orden NATURAL JOIN ordvalorizada ov JOIN prestador p ON (nromatricula = idprestador) NATURAL JOIN (SELECT DISTINCT idasocconv, acdecripcion FROM asocconvenio where acactivo and aconline ) as asocconvenio 
                         where  asocconvenio.idasocconv=127 AND tipo =56 and orden.centro=elcentro and orden.nroorden =  elnroorden ;
if not found then 

  select into rladeuda * from cuentacorrientedeuda join ordenrecibo on idcomprobante=nroorden * 100 + centro where nroorden=elnroorden and centro= elcentro;
  if found then --la deuda existe, actualizo el importe 
    UPDATE cuentacorrientedeuda SET importe = round((importe +totalafiliado)::numeric, 2) , saldo =  round((saldo+totalafiliado)::numeric, 2)  
               where iddeuda=rladeuda.iddeuda and idcentrodeuda= rladeuda.idcentrodeuda;
  else 
   --genero la deuda
    SELECT INTO respuesta *  FROM asentarconsumoctacteV2(rladeuda.idrecibo,rladeuda.centro,null);
  end if;
end if;*/
return '';

END;
$function$
