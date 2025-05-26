CREATE OR REPLACE FUNCTION public.actualizarpracticasasociacion(idnomin integer, idcapin integer, idsubcapn integer, idpracin integer, idasocconorigen integer, idasoccondestino integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	alta refcursor; -- FOR SELECT * FROM temppractconvval WHERE nullvalue(temppractconvval.error) ORDER BY temppractconvval.idasocconv;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
	idconvenio bigint;
	verificar RECORD;
	deno_anterior bigint;
	idpracticavalor bigint;
	errores boolean;
BEGIN


 OPEN alta FOR select * from practconvval   where idnomenclador=$1 and practconvval.idcapitulo=$2 and tvvigente=true and practconvval.idasocconv=$5;

FETCH alta INTO elem;
WHILE  found LOOP

/*Si existe la tabla de valores para ese convenio, se da por finalizda la vigencia de un valor y se inserta otro*/
       UPDATE practconvval SET tvvigente = FALSE WHERE practconvval.idasocconv = $6
                                    AND practconvval.idcapitulo = elem.idcapitulo
                                    AND practconvval.idnomenclador = elem.idnomenclador
                                    AND practconvval.idpractica = elem.idpractica
                                    AND practconvval.idsubcapitulo = elem.idsubcapitulo
                                    AND (practconvval.internacion = elem.internacion OR nullvalue(elem.internacion))
                                    AND practconvval.tvvigente;


Select INTO idpracticavalor  * From nextval('practconvval_idpractconvval_seq');

 INSERT INTO practconvval (idpractconvval,idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica,
                                 idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,
                                internacion,tvvigente)
                   VALUES (idpracticavalor,$6,elem.idsubcapitulo,elem.idnomenclador,elem.idcapitulo,elem.idpractica,elem.idtvh1,elem.fijoh1,elem.h1,elem.idtvh2,elem.fijoh2,elem.h2,elem.idtvh3,elem.fijoh3,elem.h3,elem.idtvgs,elem.fijogs,elem.gasto,  elem.internacion,TRUE);



FETCH alta INTO elem;

END LOOP;
CLOSE alta;


return true;

end;$function$
