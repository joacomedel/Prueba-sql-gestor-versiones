CREATE OR REPLACE FUNCTION public.expendio_fechadesde_hasta(bigint, character varying, integer)
 RETURNS SETOF type_fechasdesdehasta
 LANGUAGE sql
AS $function$
/*DECLARE
        pidconfiguracion alias for $1;
        pnrodoc alias for $2;
        ptipodoc alias for $3;
BEGIN
*/
SELECT
CASE WHEN serepite THEN
     CASE WHEN ppcperiodo = 'a'
            THEN date_trunc('YEAR', CURRENT_DATE)::DATE
            WHEN ppcperiodo = 'm'
            THEN date_trunc('MONTH', CURRENT_DATE)::DATE
            ELSE CURRENT_DATE
            END
ELSE
    CASE WHEN ppcperiodo = 'a'
            THEN date_trunc('YEAR', pcpfechaingreso)::DATE + (concat(ppcperiodoinicial -1 , ' YEAR'))::interval
            WHEN ppcperiodo = 'm'
            THEN date_trunc('MONTH', pcpfechaingreso)::DATE + (concat(ppcperiodoinicial -1 , ' MONTH'))::interval
            ELSE pcpfechaingreso
            END
END::date as fechadesde,
CASE WHEN serepite THEN
     CASE WHEN ppcperiodo = 'a'
            THEN (date_trunc('YEAR', CURRENT_DATE)::DATE + ('1 YEAR')::interval )::date - 1
            WHEN ppcperiodo = 'm'
            THEN (date_trunc('MONTH', CURRENT_DATE)::DATE + ('1 MONTH')::interval )::date - 1
            ELSE CURRENT_DATE
            END
ELSE
    CASE WHEN ppcperiodo = 'a'
            THEN date_trunc('YEAR', pcpfechaingreso)::DATE + (concat(ppcperiodofinal  , ' YEAR'))::interval
            WHEN ppcperiodo = 'm'
            THEN date_trunc('MONTH', pcpfechaingreso)::DATE + (concat(ppcperiodofinal , ' MONTH'))::interval
            ELSE pcpfechaingreso
            END
END::date as fechahasta
FROM practicaplan
NATURAL JOIN plancobpersona
WHERE  idconfiguracion = $1
       AND nrodoc = $2
ORDER BY idnomenclador,idcapitulo,idsubcapitulo,idpractica,ppcprioridad;
$function$
