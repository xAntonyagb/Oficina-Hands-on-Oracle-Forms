CREATE OR REPLACE PROCEDURE insertCarro
AS
i_Placa   CARRO.NR_PLACA%TYPE;
i_Marca   CARRO.DS_MARCA%TYPE;
i_Cor     CARRO.DS_COR%TYPE;
i_Ano     CARRO.DT_ANO%TYPE;
i_Km      CARRO.VL_KM%TYPE;
i_Tipo    CARRO.CD_TIPO%TYPE;
v_count   NUMBER;

BEGIN
  i_Placa := 'Teste2';
  i_Marca := 'Teste';
  i_Cor := 'Vermelho';
  i_Ano := 2004;
  i_Km := '5000';
  i_Tipo := 'Novo';

-- POPULANDO V_COUNT
  BEGIN 
    SELECT COUNT(*)
    INTO v_count
         FROM CARRO
         WHERE CARRO.Nr_Placa = i_Placa;
  EXCEPTION
    WHEN OTHERS THEN
         V_COUNT :=0;
  END;
  
-- SE NÃO TEM PLACA INSERE
  IF NVL(V_COUNT,0) = 0 THEN
    INSERT INTO Carro(Nr_Placa,
                      Ds_Marca,
                      Ds_Cor,
                      Dt_Ano,
                      Vl_Km,
                      Cd_Tipo)
    VALUES(i_Placa, 
    i_Marca, 
    i_Cor, 
    i_Ano, 
    i_Km, 
    i_Tipo);
    
    COMMIT;
  
  -- se tem placa -> exception
  ELSE
    RAISE_APPLICATION_ERROR(-20001, 'NÃO FOI INSERIDO');
  END IF;
  
-- bloco exception  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    
END;



BEGIN
  insertCarro;
END;



select * from carro;
