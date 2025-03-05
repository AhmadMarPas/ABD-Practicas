--Paso 5. Creación como procedimientos
create or replace procedure pAnularReserva( 
	p_socio varchar,
	p_fecha date,
	p_hora integer, 
	p_pista integer ) 
is

begin
	DELETE FROM reservas 
        WHERE
            trunc(fecha) = trunc(p_fecha) AND
            pista = p_pista AND
            hora = p_hora AND
            socio = p_socio;

	if sql%rowcount = 1 then
		commit;
	else
		rollback;
	end if;

    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
		raise_application_error(-20000, 'Reserva inexistente');
end;
/

create or replace procedure pReservarPista(
        p_socio VARCHAR,
        p_fecha DATE,
        p_hora INTEGER
    ) 
IS

    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas 
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE 
                trunc(fecha) = trunc(p_fecha) AND
                hora = p_hora)
        order by nro;
            
    vPista INTEGER;

BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND
    THEN
        CLOSE vPistasLibres;
	ELSE
        CLOSE vPistasLibres;
        INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
        COMMIT;
    END IF;

    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        CLOSE vPistasLibres;
		raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
end;
/

--
-- Paso 4. Creación del procedimiento.
create or replace procedure TEST_PROCEDURE_TENIS is
    resultado integer;
begin
    -- Reserva
    pReservarPista( 'Socio 1', CURRENT_DATE, 12 );
  
    pReservarPista( 'Socio 2', CURRENT_DATE, 12 );

    pReservarPista( 'Socio 3', CURRENT_DATE, 12 );

    pReservarPista( 'Socio 4', CURRENT_DATE, 12 );

    -- Anulación
	pAnularReserva( 'Socio 1', CURRENT_DATE, 12, 1);
     
    pAnularReserva( 'Socio 1', date '1920-1-1', 12, 1);
end;
/

--1ª forma de ejecutar el procedimiento
begin
    TEST_PROCEDURE_TENIS;
end;
/

--2ª forma de ejecutar el procedimiento
exec TEST_PROCEDURE_TENIS;
/