CREATE OR REPLACE FUNCTION public.expendio_verificar_consumo(character varying, character varying, character varying, character varying, bigint, character varying, integer, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
       
        pidnomenclador alias for $1;
          pidcapitulo alias for $2;
        pidsubcapitulo alias for $3;
        pidpractica alias for $4;
        pidplancoberturas alias for $5;
       
        pnrodoc alias for $6;
       ptipodoc alias for $7;
        pidasociacion alias for $8;


--RECORD 
        rtemporal RECORD;
        rconfiguracion RECORD;
        rfechas RECORD;
        cantidadrespuesta RECORD;
--VARIABLES
        cantidadconsumida BIGINT;
        cantidadrestante BIGINT;
        i integer;
        resp boolean;
        tieneamuc BOOLEAN;
        
        
  --CURSOR      
        --  cconfiguraciones refcursor;
       
        
        cconfiguraciones CURSOR FOR SELECT pp.*,
                         CASE WHEN pp.idcapitulo = '**' THEN 0
                         WHEN pp.idsubcapitulo = '**' THEN 1
                         WHEN pp.idpractica = '**' THEN 2
                         ELSE 3
                         END as nivel
                         FROM practicaplan as pp
                         NATURAL JOIN plancobpersona
                         WHERE (nrodoc = pnrodoc)
                           AND (pp.idplancoberturas = pidplancoberturas)
                           AND (pp.idnomenclador = pidnomenclador)
                           AND (pp.idcapitulo = pidcapitulo or pp.idcapitulo = '**')
                           AND (pp.idsubcapitulo = pidsubcapitulo or pp.idsubcapitulo = '**')
                           AND (pp.idpractica = pidpractica or pp.idpractica = '**')
                         /*ORDER BY pp.idnomenclador,pp.idcapitulo,pp.idsubcapitulo
                         ,pp.idpractica,pp.ppcprioridad;*/
                         ORDER BY auditoria asc ,nivel DESC,pp.idnomenclador,pp.idcapitulo,pp.idsubcapitulo,pp.idpractica,pp.ppcprioridad ASC;

BEGIN
    --MaLaPi 13-06-2019 Lo saco afuera del while, pues borra las otras configuraciones
   --KR 08-0-17 recupero el valor que inserte por defecto para esreintegro
      INSERT INTO esposibleelconsumo DEFAULT VALUES;
      SELECT INTO rtemporal  * FROM esposibleelconsumo;
      DELETE FROM esposibleelconsumo;


i=0;
 --DELETE FROM esposibleelconsumo;
 OPEN cconfiguraciones;
    FETCH cconfiguraciones INTO rconfiguracion;
    WHILE  found LOOP
           i = i+1;
           SELECT INTO rfechas * FROM expendio_fechadesde_hasta(rconfiguracion.idconfiguracion,pnrodoc,ptipodoc);

           SELECT INTO cantidadconsumida CASE WHEN nullvalue(sum(cantidad)) THEN 0 ELSE sum(cantidad) END
                  FROM expendio_consumo_fechadesde_hastaV1(rconfiguracion.idplancoberturas,pnrodoc,1,rfechas.fechadesde,rfechas.fechahasta)
                  WHERE idnomenclador = pidnomenclador
                        AND idcapitulo = pidcapitulo
                        AND idsubcapitulo = pidsubcapitulo
                        AND idpractica = pidpractica;
           cantidadrestante = rconfiguracion.ppccantpractica - cantidadconsumida;
--cobertura cuanto cubre sosunc
--  amuc y sosunc 100 primero se cubre amuc
 
--KR 05-08-19 me fijo si el afiliado tiene cobertura amuc
           SELECT INTO tieneamuc expendio_tiene_amuc(pnrodoc,ptipodoc);
  
           INSERT INTO esposibleelconsumo (idesposibleelconsumo , idpractica,idplancobertura,idnomenclador,auditoria,cobertura,coberturaamuc,idcapitulo,idsubcapitulo,idplancoberturas,ppccantpractica,ppcperiodo,
           ppccantperiodos,ppclongperiodo,ppcprioridad,idconfiguracion,serepite,ppcperiodoinicial,       ppcperiodofinal,rcantidadconsumida,rcantidadrestante,nivel,fechadesde,fechahasta,coberturasosunc)
           VALUES(i , rconfiguracion.idpractica,rconfiguracion.idplancobertura,rconfiguracion.idnomenclador,rconfiguracion.auditoria,
          (case when not nullvalue(rtemporal.esreintegro) and rtemporal.esreintegro then  (100-rconfiguracion.cobertura) ELSE rconfiguracion.cobertura END),
         -- (case when not nullvalue(rtemporal.esreintegro) and rtemporal.esreintegro then  0 ELSE rconfiguracion.ppcoberturaamuc END), 
          (CASE WHEN NOT nullvalue(rtemporal.esreintegro) AND rtemporal.esreintegro THEN 0 
                 WHEN tieneamuc THEN rconfiguracion.ppcoberturaamuc
                 ELSE 0 END),
           rconfiguracion.idcapitulo,rconfiguracion.idsubcapitulo,rconfiguracion.idplancoberturas,rconfiguracion.ppccantpractica,rconfiguracion.ppcperiodo,
           rconfiguracion.ppccantperiodos,rconfiguracion.ppclongperiodo,rconfiguracion.ppcprioridad,rconfiguracion.idconfiguracion,rconfiguracion.serepite,rconfiguracion.ppcperiodoinicial,
           rconfiguracion.ppcperiodofinal,cantidadconsumida,cantidadrestante,rconfiguracion.nivel,rfechas.fechadesde,rfechas.fechahasta
,rconfiguracion.ppcoberturasosunc);

         
           IF existecolumtemp('esposibleelconsumo', 'idconfiguracion') THEN 
               UPDATE esposibleelconsumo SET idconfiguracion = rconfiguracion.idconfiguracion WHERE idesposibleelconsumo = i;
           END IF;
   

    FETCH cconfiguraciones INTO rconfiguracion;
    END LOOP;
    CLOSE cconfiguraciones ;
 

   SELECT into resp  expendio_calcular_importes( pidnomenclador, pidcapitulo,pidsubcapitulo,pidpractica , pidplancoberturas,pnrodoc,ptipodoc,pidasociacion);
  
 --  SELECT into cantidadrespuesta   *  from esposibleelconsumo ;

return resp ;
END;$function$
