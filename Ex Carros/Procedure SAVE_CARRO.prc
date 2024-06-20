CREATE OR REPLACE PROCEDURE SAVE_CARRO(
  i_Placa IN VARCHAR2,
  i_Marca IN VARCHAR2,
  i_Cor IN VARCHAR2,
  i_Ano IN NUMBER,
  i_Km IN VARCHAR2,
  i_Tipo IN NUMBER,
  O_MSG OUT VARCHAR2
)
IS
  v_count_tp NUMBER;
  e_geral EXCEPTION;
  
BEGIN
  
  -- bloco de validações null
 /*VALIDAÇÃO COR*/
  IF i_Cor IS NULL THEN
    O_MSG := 'A cor do veiculo precisa ser preenchida.';
    RAISE E_GERAL;
  END IF;
    
  /*VALIDAÇÃO MARCA*/
  IF i_Marca IS NULL THEN
    O_MSG := 'A marca do veiculo precisa ser preenchida.';
    RAISE E_GERAL;
  END IF;
    
  /*VALIDAÇÃO ANO*/
  IF i_Ano IS NULL THEN
    O_MSG := 'O ano do veiculo precisa ser preenchido.';
    RAISE E_GERAL;
  END IF;
  
  /*VALIDAÇÃO MODELO*/
    IF i_Tipo IS NULL THEN
      O_MSG := 'O modelo do veiculo precisa ser preenchido.';
      RAISE E_GERAL;
    END IF;
  -- fim do bloco
  
  -- VALIDAÇÃO CASO O ANO SEJA SUPERIOR DO ATUAL 
  IF NVL(i_Ano, 0) > TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) THEN
      O_MSG := 'O ano do carro não pode ser superior ao ano seguinte ao atual!';
      RAISE E_GERAL;
  END IF;

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
  
  -- Se não tem o tipo em registro -> exception
  IF NVL(v_count_tp, 0) = 0 THEN
    O_MSG := 'Tipo não existente. Carro não foi inserido ou atualizado.';
    RAISE e_geral;
  END IF;
  
  -- OPERAÇÃO SAVE
  BEGIN
    -- TENTAR FAZER O INSERT
    INSERT INTO Carro
      (Nr_Placa, Ds_Marca, Ds_Cor, Dt_Ano, Vl_Km, Cd_Tipo)
    VALUES
      (i_Placa, i_Marca, i_Cor, i_Ano, i_Km, i_Tipo);
    
    COMMIT;
    O_MSG := 'Carro inserido com sucesso!';

  -- CASO JÁ EXISTA -> UPDATE  
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      BEGIN
        UPDATE Carro
        SET Ds_Marca =    NVL(i_Marca, Ds_Marca),
            Ds_Cor =      NVL(i_Cor, Ds_Cor),
            Dt_Ano =      NVL(i_Ano, Dt_Ano),
            Vl_Km =       NVL(i_Km, Vl_Km),
            Cd_Tipo =     NVL(i_Tipo, Cd_Tipo)
        WHERE Nr_Placa =  i_Placa;
        
        COMMIT;
        O_MSG := 'Carro atualizado com sucesso!';
        
      -- CASO OCORRA PROBLEMAS NO UPDATE
      EXCEPTION
        WHEN OTHERS THEN
          O_MSG := 'Erro ao atualizar o carro.';
          RAISE e_geral;
      END;
  END;

EXCEPTION
  WHEN e_geral THEN
    ROLLBACK;
    O_MSG := '[SAVE_CARRO]: '|| O_MSG;
    
  WHEN OTHERS THEN
    ROLLBACK;
    O_MSG := '[SAVE_CARRO]: Erro ao inserir ou atualizar o carro - ' || SQLERRM;

END;
/
