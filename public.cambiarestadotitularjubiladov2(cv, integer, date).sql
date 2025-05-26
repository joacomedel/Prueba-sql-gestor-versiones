CREATE OR REPLACE FUNCTION public.cambiarestadotitularjubiladov2(character varying, integer, date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* Recibe como parametros el tipo y numero de documento y una fecha para la que se necesita
* determinar el estado.
* Retorna, un boolean que determina si hay o no error
*
* Se determina el estado en el que tiene que estar un titular, segun los datos
* de designacion vigente y sus aportes.
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       pfechaactual alias for $3;
       datoPersona RECORD;
       aportePersona RECORD;
       caru3meses integer;
       nroinforme bigint;
       stipoinforme VARCHAR;
       FechaUltimoAporte DATE;
       rdesVigente RECORD;
       idestado INTEGER;
       mescondesignacionvigente INTEGER;
       cantaportesult3meses INTEGER;
       resultado2 boolean;
begin
idestado = 0;
--pfechaactual = CURRENT_DATE;
/*El nroTipoInforme es el anio*100 + mes*/
nroinforme = cast(date_part('year', pfechaactual) as integer) * 100 + cast(date_part('month', pfechaactual) as integer);

SELECT INTO FechaUltimoAporte * FROM ultimoaporterecibido(pnrodoc,ptipodoc);
/* Buscar una Designacion Vigente para la persona */
IF (nullvalue(FechaUltimoAporte)) THEN
       --Corresponde Pasivo
        idestado = 4;
        --UPDATE afilsosunc SET idestado = 4 WHERE afilsosunc.nrodoc = pnrodoc AND afilsosunc.tipodoc = ptipodoc;
ELSE -- Alguna Vez se recibio un aporte
   SELECT INTO cantaportesult3meses * FROM ultimostresaporterecibido(pnrodoc,ptipodoc);
   IF(cantaportesult3meses >= 4 ) THEN
    --Corresponde Estado ACTIVO
    idestado = 2;
    --UPDATE afilsosunc SET idestado = 2 WHERE afilsosunc.nrodoc = pnrodoc AND afilsosunc.tipodoc = ptipodoc;
   END IF;
   IF(cantaportesult3meses < 4 ) THEN
     idestado = 4;
      stipoinforme = 'PasivoCar';
      SELECT INTO resultado2 *
                       FROM agregareninformev2(stipoinforme,nroinforme,pnrodoc,ptipodoc);
       --UPDATE afilsosunc SET idestado = 4 WHERE afilsosunc.nrodoc = pnrodoc AND afilsosunc.tipodoc = ptipodoc;

   END IF; -- IF(cantaportesult3meses < 4 ) THEN
END IF; -- Alguna Vez se recibio un aporte

return idestado;
end;
$function$
