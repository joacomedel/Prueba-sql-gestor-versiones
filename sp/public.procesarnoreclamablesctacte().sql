CREATE OR REPLACE FUNCTION public.procesarnoreclamablesctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*/
DECLARE
    --registros
      rreclctacte RECORD;
      perctacte RECORD;

    --cursor
      cursorreclctacte CURSOR FOR SELECT * FROM tempnoreclamables;

    --variables
      movimientoconcepto VARCHAR;
      idcomprobantedeuda INTEGER;
BEGIN
CREATE TEMP TABLE tempnoreclamables ( mesingreso INTEGER NOT NULL, anioingreso INTEGER NOT NULL, nroliquidacion INTEGER NOT NULL, nrolegajo INTEGER NOT NULL, nrocargo INTEGER NOT NULL, nroconcepto INTEGER NOT NULL, mesretroactivo INTEGER NOT NULL, anioretroactivo INTEGER NOT NULL, importe double precision, tipoconcepto character varying(1), novedad1 INTEGER , novedad2 INTEGER , ordenimpresion INTEGER , tipoescalafon character varying(1), nroescalafon INTEGER , codigoescalafon character varying, regional character varying, unidadacademica character varying, dependencia INTEGER , subdependencia INTEGER , fuentefinanciamiento INTEGER , programa INTEGER , subprograma INTEGER , proyecto INTEGER , actividad INTEGER , obra INTEGER , finalidad INTEGER , funcion INTEGER , detalle character varying);
INSERT INTO tempnoreclamables(mesingreso,anioingreso,nroliquidacion,nrolegajo,nrocargo,nroconcepto,mesretroactivo,anioretroactivo,importe,tipoconcepto,novedad1,novedad2,ordenimpresion,tipoescalafon,nroescalafon,codigoescalafon,regional,unidadacademica,dependencia,subdependencia,fuentefinanciamiento,programa,subprograma,proyecto,actividad,obra,finalidad,funcion,detalle) VALUES(6,2012,416,2457,60986,-51,0,0,174.50,'A',0,0,911,'D',2,'DOCE','NCAP','FAIF',29,0,11,29,0,0,1,0,3,4,NULL);

     OPEN cursorreclctacte;
     FETCH cursorreclctacte INTO rreclctacte;
     WHILE  found LOOP
           
             INSERT INTO dh21noreclamable( mesingreso, anioingreso, nroliquidacion, nrolegajo,nrocargo, nroconcepto,
                                           importe,tipoconcepto,novedad1,novedad2, ordenimpresion,
                                  tipoescalafon,
    nroescalafon,
    codigoescalafon,
    regional,
    unidadacademica,
    dependencia,
    subdependencia,
    fuentefinanciamiento,
    programa,
    subprograma,
    proyecto,
    actividad,
    obra,
    finalidad,
    funcion,
    mesretroactivo,
    anioretroactivo,
    detalle)
             VALUES (rreclctacte.mesingreso, rreclctacte.anioingreso, rreclctacte.nroliquidacion, rreclctacte.nrolegajo,rreclctacte.nrocargo, rreclctacte.nroconcepto,
                                           rreclctacte.importe,rreclctacte.tipoconcepto,rreclctacte.novedad1,rreclctacte.novedad2, rreclctacte.ordenimpresion,
                                  rreclctacte.tipoescalafon,
    rreclctacte.nroescalafon,
    rreclctacte.codigoescalafon,
    rreclctacte.regional,
    rreclctacte.unidadacademica,
    rreclctacte.dependencia,
    rreclctacte.subdependencia,
    rreclctacte.fuentefinanciamiento,
    rreclctacte.programa,
    rreclctacte.subprograma,
    rreclctacte.proyecto,
    rreclctacte.actividad,
    rreclctacte.obra,
    rreclctacte.finalidad,
    rreclctacte.funcion,
    rreclctacte.mesretroactivo,
    rreclctacte.anioretroactivo,
    rreclctacte.detalle);


    SELECT INTO perctacte t.*
           FROM (SELECT legajosiu,nrodoc,tipodoc FROM afilidoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilinodoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afiliauto
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilirecurprop
                      ) as t

          WHERE t.legajosiu=rreclctacte.nrolegajo;

    idcomprobantedeuda=currval('dh21noreclamable_iddh21noreclamable_seq');
    movimientoconcepto = concat('Corresponde a NO reclamable liq ' , rreclctacte.nroliquidacion , ' cargo ' , rreclctacte.nrocargo , ' ' , rreclctacte.mesingreso , '/' , rreclctacte.anioingreso);
   
/*ver si nrocuentac es correcto, lo tome del sp agregardescuentosconceptos */ 
      INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
        VALUES (25,rreclctacte.tipodoc,to_number(rreclctacte.nrodoc,'99999999')*10+rreclctacte.tipodoc,now(),movimientoconcepto,10311,rreclctacte.importe,idcomprobantedeuda,rreclctacte.importe,rreclctacte.nroconcepto,rreclctacte.nrodoc);


      
          DELETE FROM dh21 
          WHERE mesingreso= rreclctacte.mesingreso
                AND anioingreso= rreclctacte.anioingreso
                AND nroliquidacion= rreclctacte.nroliquidacion
                AND nrolegajo= rreclctacte.nrolegajo
                AND nrocargo= rreclctacte.nrocargo
                AND nroconcepto = rreclctacte.nroconcepto
                AND mesretroactivo =rreclctacte.mesretroactivo
                AND anioretroactivo =    rreclctacte.anioretroactivo
                AND importe = rreclctacte.importe;


      FETCH cursorreclctacte INTO rreclctacte;
     END LOOP;
     CLOSE cursorreclctacte;

     RETURN TRUE;
END;
$function$
