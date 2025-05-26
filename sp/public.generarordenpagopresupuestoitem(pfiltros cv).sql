CREATE OR REPLACE FUNCTION public.generarordenpagopresupuestoitem(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
/*Genera una orden para pagar un conjunto de presupuesto items, realizando el cambio de estados para los
mismos.*/


DECLARE
--RECORD 
  rlaminuta RECORD; 
  rcuentacontable RECORD; 
  rpresitem RECORD;

--CURSOR
  cpresuitem refcursor;

--VARIABLES
  resultado boolean;
 -- idnroop BIGINT;

BEGIN
    SELECT INTO rlaminuta DISTINCT ON(temp.idpresupuesto) temp.idpresupuesto AS elidpresupuesto, case when nullvalue(nroordenpago) then nextval('ordenpago_seq') else nroordenpago end as nroordenpago,(sum(piimportetotalconiva)) as importetotal, pdescripcion as beneficiario,text_concatenar(concat(idpresupuestoitem,'-',idcentropresupuestoitem)) as eliditempre FROM temppresitem  temp JOIN presupuestoitem using(idpresupuestoitem, idcentropresupuestoitem) JOIN presupuesto p ON(temp.idpresupuesto=p.idpresupuesto AND temp.idcentropresupuesto=p.idcentropresupuesto) NATURAL JOIN prestador
    GROUP BY temp.idpresupuesto,nroordenpago,pdescripcion;

    CREATE TEMP TABLE tempordenpago ( nroordenpago BIGINT NOT NULL,
				  fechaingreso DATE, 
				  beneficiario VARCHAR, 
				  concepto VARCHAR, 
				  asiento VARCHAR,
				  importetotal DOUBLE PRECISION,
                                  idordenpagotipo INTEGER,
                                  nrocuentachaber VARCHAR
				 ) WITHOUT OIDS;  
   CREATE TEMP TABLE tempordenpagoimputacion (
				  codigo INTEGER, 
				  nroordenpago BIGINT NOT NULL,
				  debe FLOAT,
				  haber FLOAT
				  ) WITHOUT OIDS;

   SELECT INTO rcuentacontable * FROM ordenpagotipo WHERE idordenpagotipo=8;
-- KR 11-02-20 EL Nro. OP viene de la ventana
  -- SELECT INTO idnroop nextval('ordenpago_seq'); 
   INSERT INTO tempordenpago (nroordenpago,fechaingreso,beneficiario,concepto,importetotal,idordenpagotipo, nrocuentachaber) 
	VALUES (rlaminuta.nroordenpago ,now() , rlaminuta.beneficiario,
		concat('Minuta de pago vinculada al presupuesto #', rlaminuta.elidpresupuesto, ' del item ', rlaminuta.eliditempre ), rlaminuta.importetotal, 8, rcuentacontable.nrocuentachaber);
	
   INSERT INTO tempordenpagoimputacion (codigo,nroordenpago,debe,haber)
   
  SELECT CASE WHEN t.pidiscriminante ILIKE '%monodroga%' THEN '50335'  --Farmacia
                    WHEN t.pidiscriminante ILIKE '%practica%' THEN practica.nrocuentac   
                    WHEN t.pidiscriminante ILIKE '%articulo%' THEN articulo.nrocuentac   END::integer,  
                   	rlaminuta.nroordenpago,piimportetotalconiva, 0
        
        FROM temppresitem t JOIN presupuestoitem using(idpresupuestoitem, idcentropresupuestoitem)  LEFT JOIN articulo ON(t.picoditem=idarticulo) 
        LEFT JOIN practica ON(idnomenclador =  trim(split_part(t.picoditem, '.', 1))::varchar AND idcapitulo=  trim(split_part(t.picoditem, '.', 2))::varchar AND  idsubcapitulo=  trim(split_part(t.picoditem, '.', 3))::varchar AND idpractica=  trim(split_part(t.picoditem, '.', 4))::varchar)
	GROUP BY t.pidiscriminante,nroordenpago, piimportetotalconiva ,articulo.nrocuentac, practica.nrocuentac,t.picantidad;

  	

   SELECT INTO resultado * FROM generarordenpago();

   IF resultado THEN 
      INSERT INTO presupuestoitemordenpago (idpresupuestoitem,idcentropresupuestoitem,nroordenpago,idcentroordenpago,ctopimportepagado)
      SELECT idpresupuestoitem,idcentropresupuestoitem,rlaminuta.nroordenpago,centro(), piimporte FROM temppresitem;
  
      
      /*El item se coloca en estado 3 - Liquidado*/
      UPDATE presupuestoitemestado SET pifechahasta=NOW()
      FROM ( SELECT idpresupuestoitem, idcentropresupuestoitem
             FROM temppresitem) AS T
      WHERE presupuestoitemestado.idpresupuestoitem=T.idpresupuestoitem AND presupuestoitemestado.idcentropresupuestoitem=T.idcentropresupuestoitem  AND nullvalue(presupuestoitemestado.pifechahasta);

      INSERT INTO presupuestoitemestado (pifechadesde,idpresupuestoitem, idcentropresupuestoitem, idpresupuestoitemestadotipo)
      SELECT CURRENT_DATE,idpresupuestoitem,idcentropresupuestoitem,3 FROM temppresitem;
   
     
   END IF; 



return concat(rlaminuta.nroordenpago,'-',centro());
END;
$function$
