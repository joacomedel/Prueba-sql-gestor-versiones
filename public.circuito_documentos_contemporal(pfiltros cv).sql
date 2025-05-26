CREATE OR REPLACE FUNCTION public.circuito_documentos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
        rfiltros record;
        
        
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_circuito_documentos_contemporal
        AS (
                SELECT iddocumento, idcentrodocumento, idpase, idcentropase,
                dotitulo, docontenido ,
                pafechaenvio, pafecharecepcion, pacantfolios, pamotivo, 
                nombreorigen,  usuarioorigen, idpersonaorigen, nombredestino, usuariodestino, idpersonadestino,
                sectori, idsectororigen, sectdes, idsectordestino

                ,'1-Nro.Documento#iddocumento@2-Centro Documento#idcentrodocumento@3-Nro. Pase.#idpase@4-Centro Pase#idcentropase@5-Titulo Documento#dotitulo@6-Contenido Documento#docontenido@7-Envio Pase#pafechaenvio@8-Recepcion Pase#pafecharecepcion@9-Cantidad Folios#pacantfolios@10-Motivo Pase#pamotivo@11-Usuario Origen#nombreorigen@12-ID Usuario Origen#usuarioorigen@13-Usuario Destino#nombredestino@14-ID Usuario Destino#usuariodestino@15-Sector Origen#sectori@16-ID Sector Origen#idsectororigen@17-Sector Destino#sectdes@18-ID Sector Destino#idsectordestino'::text as mapeocampocolumna
                FROM documento
                NATURAL JOIN pase

                LEFT JOIN (
                        SELECT concat (apellido,' ',nombre) as nombreorigen, idusuario as usuarioorigen, idpersona as idpersonaor
                        FROM "ca"."persona"
                        LEFT JOIN usuario ON (penrodoc=dni)
                        ) as persorigen ON (idpersonaorigen=persorigen.idpersonaor) 
                LEFT JOIN (
                        SELECT concat (apellido,' ',nombre) as nombredestino, idusuario as usuariodestino, idpersona as idpersonades
                        FROM "ca"."persona"
                        LEFT JOIN usuario ON (penrodoc=dni)
                        ) as persdestino ON (idpersonadestino=persdestino.idpersonades)
                LEFT JOIN (
                        SELECT sedescripcion as sectori, idsector as idsectori
                        FROM "ca"."sector"
                        ) as sectororigen ON (idsectororigen=sectororigen.idsectori)
                LEFT JOIN (
                        SELECT sedescripcion as sectdes, idsector as idsectdes
                        FROM "ca"."sector"
                        ) as sectordestino ON (idsectordestino=sectordestino.idsectdes)

                WHERE dofechacreacion>=rfiltros.fechadesde AND dofechacreacion<=rfiltros.fechahasta 
                AND CASE WHEN nullvalue(rfiltros.usuorigen) THEN TRUE ELSE nombreorigen ilike concat('%',rfiltros.usuorigen, '%') END

                AND CASE WHEN nullvalue(rfiltros.sectorig) THEN TRUE ELSE sectori ilike concat('%',rfiltros.sectorig, '%') END

                GROUP BY 

                iddocumento, idcentrodocumento, idpase, idcentropase,
                dotitulo, docontenido ,
                pafechaenvio, pafecharecepcion, pacantfolios, pamotivo, 
                nombreorigen,  usuarioorigen, idpersonaorigen, nombredestino, usuariodestino, idpersonadestino,
                sectori, idsectororigen, sectdes, idsectordestino

                order by iddocumento asc

        );
  

return true;
END;
$function$
