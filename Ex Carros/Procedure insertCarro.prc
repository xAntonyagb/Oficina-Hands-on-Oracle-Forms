CREATE OR REPLACE PROCEDURE insertCarro(
  i_Placa IN VARCHAR2,
  i_Marca IN VARCHAR2,
  i_Cor IN VARCHAR2,
  i_Ano IN NUMBER,
  i_Km IN VARCHAR2,
  i_Tipo IN NUMBER,
  O_MSG OUT VARCHAR2
)
IS
  v_count NUMBER;
  v_count_tp NUMBER;
  e_geral EXCEPTION;
  
BEGIN
  O_MSG := 'Carro inserido com sucesso!';


  -- POPULANDO V_COUNT
  BEGIN 
    SELECT COUNT(*)
    INTO v_count
    FROM CARRO
    WHERE CARRO.Nr_Placa = i_Placa;
  EXCEPTION
    WHEN OTHERS THEN
      v_count := 0;
  END;
  
  
    -- POPULANDO V_COUNT_TP
  BEGIN 
    SELECT COUNT(*)
    INTO v_count_tp
    FROM TIPO_VEICULO tv
    WHERE tv.nr_codigo = i_Tipo;
  EXCEPTION
    WHEN OTHERS THEN
      v_count_tp := 0;
  END;
  
  
  -- Se não tem o tipo -> exception
  IF NVL(v_count_tp, 0) = 0 THEN
    O_MSG := 'Tipo não existente. Carro não foi inserido.';
    RAISE e_geral;
  END IF;
  
  
  -- SE NÃO TEM PLACA INSERE
  IF NVL(v_count, 0) = 0 THEN
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
    O_MSG := 'Placa já existente. Carro não foi inserido.';
    RAISE e_geral;
  END IF;

EXCEPTION
  WHEN e_geral THEN
    O_MSG := '[InsertCarro]: '|| O_MSG;
    ROLLBACK;
  WHEN OTHERS THEN
    O_MSG := '[InsertCarro]: Erro ao inserir o carro. ' || SQLERRM;
    ROLLBACK;
END;
/
