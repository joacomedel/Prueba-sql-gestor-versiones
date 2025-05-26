CREATE OR REPLACE FUNCTION public.alta_modifica_practicas_conflicto_odonto()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  respuesta BOOLEAN;
  cursoritem CURSOR FOR SELECT * FROM  practicasodontoauditadasconfiguracion;
  elem RECORD;
   
BEGIN

respuesta = true;

DELETE FROM practicasodontoauditadas;


open cursoritem;
FETCH cursoritem INTO elem;
WHILE FOUND LOOP


INSERT INTO practicasodontoauditadas(idnomenclador,idcapitulo,idsubcapitulo,idpractica
,idnomencladorconflicto,idcapituloconflicto,idsubcapituloconflicto,idpracticaconflicto
,idauditoriaodontologiaformula
)
(
SELECT * FROM 
(
SELECT po.*,pc.*,p.idauditoriaodontologiaformula
FROM practicasodontoauditadasconfiguracion p
LEFT JOIN (SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica 
     FROM practica ) as po 
     ON (po.idnomenclador = p.idnomenclador 
     AND (p.idcapitulo = '**' OR po.idcapitulo = p.idcapitulo)
     AND (p.idsubcapitulo = '**' OR po.idsubcapitulo = p.idsubcapitulo)
     AND (p.idpractica = '**' OR po.idpractica = p.idpractica))
LEFT JOIN (SELECT idnomenclador as idnomencladorconflicto,idcapitulo as idcapituloconflicto,idsubcapitulo as idsubcapituloconflicto,idpractica as idpracticaconflicto
     FROM practica ) as pc 
     ON (pc.idnomencladorconflicto = p.idnomencladorconflicto 
     AND (p.idcapituloconflicto = '**' OR pc.idcapituloconflicto = p.idcapituloconflicto)
     AND (p.idsubcapituloconflicto = '**' OR pc.idsubcapituloconflicto = p.idsubcapituloconflicto)
     AND (p.idpracticaconflicto = '**' OR pc.idpracticaconflicto = p.idpracticaconflicto))
WHERE idpracticasodontoauditadasconfiguracion = elem.idpracticasodontoauditadasconfiguracion
) ainsertar
LEFT JOIN practicasodontoauditadas USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica,idnomencladorconflicto,idcapituloconflicto,idsubcapituloconflicto,idpracticaconflicto,idauditoriaodontologiaformula)
WHERE   nullvalue(practicasodontoauditadas.idauditoriaodontologiaformula)
);


FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;


return respuesta;
END;
$function$
