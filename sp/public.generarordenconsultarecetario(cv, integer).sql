CREATE OR REPLACE FUNCTION public.generarordenconsultarecetario(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

BEGIN

        IF NOT  iftableexists('ttorden') THEN 
             CREATE TEMP TABLE ttorden(nrodoc varchar(8),tipodoc int  NOT NULL,numorden bigint, ctroorden integer, centro int4 NOT NULL,idasocconv BIGINT,
	recibo boolean,cantordenes int4     ,tipo int8,amuc float ,efectivo float ,debito float ,credito float ,cuentacorriente float ,sosunc float ,
	importeenletras varchar);
        ELSE  DELETE FROM ttorden;
        END IF;

        
	INSERT INTO ttorden(nrodoc,tipodoc,centro,idasocconv,recibo,cantordenes,tipo,amuc,efectivo,debito,credito,cuentacorriente,sosunc,importeenletras) 
	VALUES($1,$2,centro(),95,false,null,4,0,0,0,0,0,0,'');

        IF NOT  iftableexists('ttconsulta') THEN 
             CREATE TEMP TABLE ttconsulta(idplancobertura varchar);
        ELSE  DELETE FROM ttconsulta;
        END IF;
       
        INSERT INTO ttconsulta VALUES('15');
        
        PERFORM asentarconsultarecibo();
    
return 	true;
END;
$function$
