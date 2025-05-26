CREATE OR REPLACE FUNCTION public.agregareninforme(character varying, bigint, date, bigint, character varying, character varying, smallint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*agregareninforme('PasivoCar',1,current_date,idLaboral,NroLiquidacion,NroDoc,tipodoc,barra)
$1 TipoInforme
$2 NroInforme
$3 Fecha de Modificacion
$4 IdLaboral
$5 NroLiquidacion
$6 dni
$7 Barra / Barra segun el tpo de informe
*/
DECLARE
    per RECORD;
    verifica RECORD;
    usu varchar;
    tipoinf alias for $1;
	nroinforme alias for $2;
    fecha alias for $3;
	idlab alias for $4;
	nroliq alias for $5;
	dni alias for $6;
	barrafil alias for $7;
BEGIN
     SELECT INTO per * FROM infaporrecibido WHERE infaporrecibido.nrodoc = dni
                                                AND infaporrecibido.tipoinforme = tipoinf
                                                and infaporrecibido.nrotipoinforme = nroinforme
                                                and infaporrecibido.fechmodificacion = fecha
                                                and infaporrecibido.idlaboral = idlab
                                                and infaporrecibido.nroliquidacion = nroliq;
     IF NOT FOUND THEN
        /*IF (nullvalue(nroinforme)) THEN
        INSERT INTO infaporrecibido (tipoinforme,nrotipoinforme,fechmodificacion,idlaboral,nroliquidacion,nrodoc,barra)
                    VALUES (tipoinf,741258963,fecha,idlab,nroliq,dni,barrafil);
        ELSE*/
                INSERT INTO infaporrecibido (tipoinforme,nrotipoinforme,fechmodificacion,idlaboral,nroliquidacion,nrodoc,barra)
                    VALUES (tipoinf,nroinforme,fecha,idlab,nroliq,dni,barrafil);

--        END IF;
     end if;
return true;
END;
$function$
