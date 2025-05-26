CREATE OR REPLACE FUNCTION public.expendio_generarrecetariotratamientoprolongado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--CURSONRES
consulta CURSOR FOR SELECT * FROM temp_expendioag;
items CURSOR FOR SELECT * FROM tempitems;

-- modifico para usar lo nuevo                 select *                        from ttconsulta;

-- MOdifico, defino referencia para poder usar la temporal siempre y cuando ya no haya guardado las ordnes nuevas generadas --nuevas CURSOR FOR                  SELECT *                  from ttordenesgeneradas;
nuevas refcursor;

--RECORD
nueva RECORD;
dato RECORD;
unitem RECORD;

--VARIABLES
respuesta BOOLEAN;
idrtp INTEGER;
identitem int;

BEGIN
    respuesta = false;
--  Llama a asentarOrden()
    --  crea la tabla temporal TTOrdenesGeneradas

 IF NOT  iftableexists('ttordenesgeneradas') THEN

    CREATE TEMP TABLE ttordenesgeneradas(
           estaenitem BOOLEAN DEFAULT false,          
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;
 END IF;




--	select * into respuesta            from asentarorden(); --guarda en ttordenesgeneradas
/*Cambio y a partir del 30-06 -14 llamo al expendio_asentarorden()*/
   SELECT  * INTO respuesta  FROM expendio_asentarorden(); --guarda en ttordenesgeneradas
   open consulta;
   fetch consulta into dato;

  -- OPEN nuevas;
   OPEN nuevas FOR  SELECT * FROM ttordenesgeneradas WHERE not estaenitem;
                 
   fetch nuevas into nueva;

-- Asienta en RECETARIOS
   WHILE FOUND LOOP
           INSERT INTO recetario (nrorecetario, centro,fechaemision,idplancovertura,asi,gratuito,nrodoc, tipodoc)
          VALUES(nueva.nroorden, centro()
                ,now()
               ,case when nullvalue(dato.idplancobertura) then 1 else dato.idplancobertura end
               ,FALSE
               ,FALSE
               ,dato.nrodoc
               ,dato.tipodoc
              );



     INSERT INTO recetarioestados(nrorecetario,idtipocambioestado,centro,refechamodificacion,redescripcion)
              VALUES(nueva.nroorden, 1, centro()
              ,now()
              ,'Insertado usando el triggers generarrecetariotratamientoprolongado');

     INSERT INTO recetariotp(nrorecetario,centro)
              VALUES(nueva.nroorden
              ,centro()
              );

	     OPEN items;
             FETCH items INTO unitem;
                 WHILE found LOOP
					
			INSERT INTO item (cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,cobertura)
			VALUES (unitem.cantidad,unitem.importe,unitem.idnomenclador,unitem.idcapitulo,unitem.idsubcapitulo,unitem.idpractica,unitem.porcentaje);			
			identitem = currval('"public"."item_iditem_seq"');			
                        INSERT INTO itemvalorizada (iditem,nroorden,centro,idplancovertura,auditada)
                        VALUES (identitem,nueva.nroorden,nueva.centro,unitem.idplancob,unitem.auditada);		
                        			
                        FETCH items into unitem;
                        END LOOP;
             CLOSE items;

/*updateo el campo para saber las ordenes que ya se guardaron. Las ordenes que estan en ttordenesgeneradas se guardan para generar el recibo de esas ordenes
*/
   UPDATE ttordenesgeneradas SET estaenitem=true WHERE nroorden=nueva.nroorden AND centro=nueva.centro;

   FETCH NUEVAS INTO nueva;
   end loop;
   close nuevas;
   close consulta;

RETURN true;

END;
$function$
