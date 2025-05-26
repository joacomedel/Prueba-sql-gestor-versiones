CREATE OR REPLACE FUNCTION public.auditoria_verificarconsumo_contemporal(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
      
       cpracticas refcursor;
 --RECORD
       rpracticas RECORD;
       ritem RECORD;
       rparam RECORD;
 --VARIABLES  
       vidusuario INTEGER;

BEGIN
--temp_auditoria_verificarconsumo_contemporal
     vidusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros($1) INTO rparam;
     
     IF iftableexists('temp_auditoria_verificarconsumo_contemporal') THEN
          DELETE FROM temp_auditoria_verificarconsumo_contemporal;
     ELSE 
          CREATE TEMP TABLE temp_auditoria_verificarconsumo_contemporal(
                              descripcion character varying,
                       /*       idplancobertura bigint,
                              iditem bigint,
                              iditemestadotipo integer,
                              idnomenclador character varying,
                              idcapitulo character varying,
                              idsubcapitulo character varying,
                              idpractica character varying,
                              tipodoc integer,
                              idauditoriatipo integer,
                              nroorden bigint,
                              centro integer,
                              cobertura double precision,
                              iicoberturasosuncexpendida double precision,
                              descripcionestado character varying,
                              iicoberturasosuncauditada double precision,
                              idusuario integer,
*/
                              lapractica character varying,
                              nrodoc character varying,
                              cantidad integer DEFAULT 1,
                              fechadesde text,
                              fechahasta text,                             
                              mensaje character varying,
                              elafiliado character varying
           );
       END IF;
       OPEN cpracticas FOR SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica, nrodoc,idplancovertura as idplancobertura 
                           FROM consumo NATURAL JOIN ordvalorizada natural join itemvalorizada NATURAL JOIN item 
                           WHERE consumo.nroorden =rparam.nroorden and consumo.centro=rparam.centro 
                           GROUP BY idnomenclador,idcapitulo,idsubcapitulo,idpractica, nrodoc,idplancovertura ;
       FETCH cpracticas into rpracticas;
       WHILE found LOOP
           SELECT INTO ritem  idnomenclador,idcapitulo,idsubcapitulo,idpractica,  text_concatenar(iierror) as iierror, sum(cantidad) cantidad ,concat(EXTRACT(YEAR FROM now()) ,'-01','-01') AS fechadesde ,now() as fechahasta ,concat(apellido , ' ', nombres) as elafiliado, concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica ) as lapractica , consumo.nrodoc
           FROM orden NATURAL JOIN consumo NATURAL JOIN ordvalorizada NATURAL JOIN itemvalorizada NATURAL JOIN item LEFT JOIN iteminformacion USING(iditem, centro)     
           JOIN persona p ON (consumo.nrodoc=p.nrodoc)
           WHERE consumo.nrodoc =rpracticas.nrodoc  AND (idplancovertura =rpracticas.idplancobertura ) AND fechaemision >= concat(EXTRACT(YEAR FROM now()) ,'-01','-01') AND not anulado and iteminformacion.iditemestadotipo <>3 AND idnomenclador= rpracticas.idnomenclador and idcapitulo= rpracticas.idcapitulo and idsubcapitulo=rpracticas.idsubcapitulo and idpractica= rpracticas.idpractica
           GROUP BY idnomenclador,idcapitulo,idsubcapitulo,idpractica, fechadesde ,fechahasta ,elafiliado,consumo.nrodoc ;
       

--1 - Requiere Auditoria, 2 - Auditada y Aprobada, 3 - Auditada y Rechazada y 4 - No requiere Auditoria
         
       
            INSERT INTO temp_auditoria_verificarconsumo_contemporal(fechadesde ,fechahasta, elafiliado,nrodoc, lapractica,cantidad, mensaje  )
            VALUES(ritem.fechadesde ,ritem.fechahasta,ritem.elafiliado,ritem.nrodoc,ritem.lapractica,ritem.cantidad, ritem.iierror);

		

      FETCH cpracticas into rpracticas;
      END loop;
      close cpracticas;
     
return 'todook';
END;
$function$
