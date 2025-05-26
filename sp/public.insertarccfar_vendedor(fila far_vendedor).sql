CREATE OR REPLACE FUNCTION public.insertarccfar_vendedor(fila far_vendedor)
 RETURNS far_vendedor
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_vendedorcc:= current_timestamp;
    UPDATE sincro.far_vendedor SET far_vendedorcc= fila.far_vendedorcc, idusuario= fila.idusuario, idvendedor= fila.idvendedor, vactivo= fila.vactivo, vnombre= fila.vnombre, vpassword= fila.vpassword WHERE idvendedor= fila.idvendedor AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_vendedor(far_vendedorcc, idusuario, idvendedor, vactivo, vnombre, vpassword) VALUES (fila.far_vendedorcc, fila.idusuario, fila.idvendedor, fila.vactivo, fila.vnombre, fila.vpassword);
    END IF;
    RETURN fila;
    END;
    $function$
