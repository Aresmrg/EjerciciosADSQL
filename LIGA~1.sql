CREATE TYPE arbitros_t AS OBJECT (
    codarb NUMBER,
    nomarb VARCHAR2(200)
);

CREATE OR REPLACE TYPE equipos_t AS OBJECT (
    codequipo NUMBER,
    nomequipo VARCHAR2(200),
    ciuequipo VARCHAR2(200),
    pabequipo VARCHAR2(200)
);

CREATE OR REPLACE TYPE partidos_t AS OBJECT (
    nNumPartido NUMBER(10),
    equipolocal REF equipos_t,
    equipovisitante REF equipos_t,
    arbitro REF arbitros_t,
    puntoslocal NUMBER(3),
    puntosvisitante NUMBER(3),
    MEMBER FUNCTION fGanador1 RETURN VARCHAR2,
    MEMBER FUNCTION fGanador2 RETURN VARCHAR2,
    MEMBER FUNCTION fDiferencia RETURN NUMBER,
    MEMBER PROCEDURE spImprimeFichaPartido
);

CREATE OR REPLACE TYPE BODY partidos_t AS 

    MEMBER FUNCTION fGanador1 RETURN VARCHAR2 IS
    ganador VARCHAR(200);
    
    BEGIN
    
        IF fDiferencia() > 0 THEN
            ganador := 'Ha ganado el equipo local';
        ELSIF fDiferencia() < 0 THEN
            ganador := 'Ha ganado el equipo visitante';
        ELSE
            ganador := 'Han empatado';  
        END IF;
        RETURN ganador;
        
    END;
    
    
    MEMBER FUNCTION fGanador2 RETURN VARCHAR2 IS
    
        EL  equipos_t;
    
    BEGIN
        IF fDiferencia() > 0 THEN
            SELECT DEREF(equipolocal) INTO EL FROM DUAL;
            RETURN EL.nomequipo;
        ELSIF fDiferencia() < 0 THEN
            SELECT DEREF(equipovisitante) INTO EL FROM DUAL;
            RETURN EL.nomequipo;
        ELSE
            RETURN 'Han empatao';
        END IF;  
    END;
    
    
    MEMBER FUNCTION fDiferencia RETURN NUMBER IS
    
    BEGIN
        RETURN puntoslocal - puntosvisitante;  
    END;
    
    MEMBER PROCEDURE spImprimeFichaPartido IS
        
        CURSOR c1 IS SELECT DEREF(equipolocal) AS e1, DEREF(equipovisitante) AS e2, 
                  DEREF(arbitro) AS a, puntoslocal, puntosvisitante FROM DUAL;
        
        e1 equipos_t;
        e2 equipos_t;
        a arbitros_t;
        
    BEGIN
        FOR i IN c1 LOOP
            e1 := i.e1;
            e2 := i.e2;
            a := i.a;
            DBMS_OUTPUT.PUT_LINE('Codigo Equipo Local: '|| e1.codequipo ||' Nombre Equipo Local: ' || e1.nomequipo);
            DBMS_OUTPUT.PUT_LINE('Codigo Equipo Visitante: '|| e2.codequipo ||' Nombre Equipo Visitante: ' || e2.nomequipo);
            DBMS_OUTPUT.PUT_LINE('Codigo Arbitro: '|| a.codarb ||' Nombre Arbitro: ' || a.nomarb);
            DBMS_OUTPUT.PUT_LINE('Puntos Equipo Local: '|| i.puntoslocal ||' Puntos Equipo Visitante : ' || i.puntosvisitante);
            DBMS_OUTPUT.PUT_LINE(fGanador2());
        END LOOP;
    END;
    
END;


CREATE TABLE ARBITROS OF arbitros_t (codarb PRIMARY KEY);
CREATE TABLE EQUIPOS OF equipos_t (codequipo PRIMARY KEY);
CREATE TABLE PARTIDOS OF partidos_t;
COMMIT;

DROP TABLE ARBITROS;
DROP TABLE EQUIPOS;
DROP TABLE PARTIDOS;

INSERT INTO EQUIPOS VALUES(1,'RM','MADRID','P MA');
INSERT INTO EQUIPOS VALUES(2,'UNI','MALAGA','MARTIN CARPENA');
INSERT INTO EQUIPOS VALUES(3,'JOV','BADALONA','P BADA');

INSERT INTO ARBITROS VALUES(1, 'SERGIO GRASO');
INSERT INTO ARBITROS VALUES(2, 'JOSE GARRIDO');
INSERT INTO ARBITROS VALUES(3, 'MARIO RODRIGUEZ');

INSERT INTO PARTIDOS VALUES(1, 
    (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 1), (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 2), 
    (SELECT REF(E) FROM ARBITROS E WHERE codarb = 1), 50, 70);
INSERT INTO PARTIDOS VALUES(2, 
    (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 2), (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 3), 
    (SELECT REF(E) FROM ARBITROS E WHERE codarb = 2), 84, 70);
INSERT INTO PARTIDOS VALUES(3, 
    (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 1), (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 3), 
    (SELECT REF(E) FROM ARBITROS E WHERE codarb = 3), 33, 33);

SELECT * FROM EQUIPOS E;
SELECT * FROM PARTIDOS P;

SELECT P.*, P.fDiferencia() FROM PARTIDOS P;

SELECT P.*, P.fGanador2() FROM PARTIDOS P;

SELECT P.*, P.fDiferencia(), P.fGanador1(), P.fGanador2() FROM PARTIDOS P;

-- PROCEDIMIENTO ALMACENADO PARA IMPRIMIR Y ANONIMO PARA LLAMAR A spImprime -- 

CREATE OR REPLACE PROCEDURE sp_Imprime (numero NUMBER) IS
    P1 partidos_t;
BEGIN
    SELECT VALUE(p) INTO P1 FROM PARTIDOS p WHERE p.nNumpartido = numero;
    p1.spImprimeFichaPartido;
END;

SET SERVEROUTPUT ON;
DECLARE

BEGIN
    sp_Imprime(1);
END;

-- IMPRESION DE TODOS LOS PARTIDOS QUE HAY --

CREATE OR REPLACE PROCEDURE sp_ImprimeTodos IS
    P1 partidos_t;
    CURSOR c2 IS SELECT VALUE(P) FROM PARTIDOS P;
BEGIN
    OPEN c2;
        LOOP
            FETCH c2 INTO p1;
            EXIT WHEN c2%NOTFOUND;
            p1.spImprimeFichaPartido;
        END LOOP;
    CLOSE c2;
END;

SET SERVEROUTPUT ON;
DECLARE

BEGIN
    sp_ImprimeTodos();
END;

-- CREAR UNA NUEVA TABLA LLAMADA MARIO CON UN CAMPO NUMPARTIDOSJUGADOS DE TIPO NUMBER Y UN TRIGGER QUE MODIFIQUE ESE REGISTRO --
-- CADA VEZ QUE SE INSERTE UN PARTIDO EN LA TABLA PARTIDOS.

CREATE TABLE MARIO(
    NUMPARTJUGADOS NUMBER(10)
);

CREATE OR REPLACE TRIGGER tPartidos
AFTER INSERT ON PARTIDOS FOR EACH ROW
BEGIN

    INSERT INTO MARIO VALUES(:NEW.NNUMPARTIDO);

END;

INSERT INTO PARTIDOS VALUES(4, 
    (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 2), (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 3), 
    (SELECT REF(E) FROM ARBITROS E WHERE codarb = 3), 46, 54);
INSERT INTO PARTIDOS VALUES(5, 
    (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 3), (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 2), 
    (SELECT REF(E) FROM ARBITROS E WHERE codarb = 1), 50, 50);
INSERT INTO PARTIDOS VALUES(6, 
    (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 31), (SELECT REF(E) FROM EQUIPOS E WHERE codequipo = 2), 
    (SELECT REF(E) FROM ARBITROS E WHERE codarb = 1), 50, 50);

SELECT * FROM MARIO;

