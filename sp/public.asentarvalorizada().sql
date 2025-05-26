CREATE OR REPLACE FUNCTION public.asentarvalorizada()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

cursorvalorizada CURSOR FOR
              SELECT *
              FROM ttvalorizada;
/*
malcance           varchar
nromatricula       integer
mespecialidad      varchar
ordenreemitida     bigint
centroreemitida    ingeger
*/

items CURSOR FOR
              SELECT *
              FROM ttitems;
/*
cantidad           integer
importe            double
idnomenclador      varchar
idcapitulo         varchar
idsubcapitulo      varchar
idpractica         varchar
idplancob          varchar
auditada           boolean
*/
nuevas CURSOR FOR
                 SELECT *
                        from ttordenesgeneradas;
nueva RECORD;
identitem int;
unitem RECORD;
dato RECORD;
respuesta boolean;
especialidad varchar;
alcance varchar;
nomenclador varchar;
capitulo varchar;
subcapitulo varchar;
practicaitem varchar;
plan varchar;
norden int;
tipe integer;
pplancobertura varchar;
ppractica varchar;
pconvenio varchar;
nombsprof varchar;
apellprof varchar;
nromat integer;

BEGIN
    respuesta = false;
    open cursorvalorizada;
    FETCH cursorvalorizada into dato;
    especialidad =  dato.mespecialidad ;
	alcance = dato.malcance ;		
	close cursorvalorizada;
    norden = 0;
   /* if nullvalue(dato.nromatricula)  then
     nromat = NULL;
     ELSE
     nromat = dato.nromatricula;

    end if;*/
--  Llama a asentarOrden()
    --  crea la tabla temporal TTOrdenesGeneradas

    CREATE TEMP TABLE ttordenesgeneradas(
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;

	select * into respuesta
           from asentarorden(); --guarda en ttordenesgeneradas
    if (respuesta) then
    OPEN nuevas;
    fetch nuevas into nueva;
    
--  Asienta en ordenvalorizada       	
	INSERT INTO ordvalorizada(centro,nroorden,malcance,nromatricula,mespecialidad,ordenreemitida,centroreemitida)
           VALUES (nueva.centro,nueva.nroorden,alcance,dato.nromatricula,especialidad,null,null);
           
-- Asienta en ItemsValorizada
	open items;
    FETCH items into unitem;
    WHILE found LOOP
			nomenclador = unitem.idnomenclador  ;
			capitulo =  unitem.idcapitulo  ;
			subcapitulo =  unitem.idsubcapitulo  ;
			practicaitem =  unitem.idpractica ;			
			INSERT INTO item (cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,cobertura)
			       VALUES (unitem.cantidad,unitem.importe,nomenclador,capitulo,subcapitulo,practicaitem,unitem.porcentaje);			
			identitem = currval('"public"."item_iditem_seq"');			
			INSERT INTO itemvalorizada (iditem,nroorden,centro,idplancovertura,auditada)
                   VALUES (identitem,nueva.nroorden,nueva.centro,unitem.idplancob,unitem.auditada);									
    FETCH items into unitem;
	END LOOP;
    close items;
    close nuevas;
    end if;
    return true;	
END;
$function$
