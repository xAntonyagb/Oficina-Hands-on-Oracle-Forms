CREATE OR REPLACE package PKG_PRODUTO IS

  PROCEDURE SAVE_PRODUTO(
            I_CD_PRODUTO      IN PRODUTO.CD_PRODUTO%TYPE, 
            I_DS_PRODUTO      IN PRODUTO.DS_PRODUTO%TYPE, 
            I_VL_UNITARIO     IN PRODUTO.VL_UNITARIO%TYPE,
            O_OERACAO         OUT CHAR,
            O_ERROR_MSG       OUT VARCHAR2);
            
  PROCEDURE EXCLUIR_PRODUTO(
            I_CD_PRODUTO    IN PRODUTO.CD_PRODUTO%TYPE, 
            I_FORCE_DELETE  IN CHAR DEFAULT 'S',
            O_ERROR_MSG     OUT VARCHAR2);
    
END PKG_PRODUTO;
/
create or replace package body PKG_PRODUTO is

  /* Para inserir e fazer update em produtos */
  PROCEDURE SAVE_PRODUTO(
            I_CD_PRODUTO      IN PRODUTO.CD_PRODUTO%TYPE, 
            I_DS_PRODUTO      IN PRODUTO.DS_PRODUTO%TYPE, 
            I_VL_UNITARIO     IN PRODUTO.VL_UNITARIO%TYPE,
            O_OERACAO         OUT CHAR,
            O_ERROR_MSG       OUT VARCHAR2)
  IS
    E_GERAL EXCEPTION;
  BEGIN
    
    -- VALIDAÇÕES
    /* VALIDAÇÃO CD_PRODUTO */
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'Código do produto não informado';
      RAISE e_geral;
    END IF;

    /* VALIDAÇÃO DESCRIÇÃO */
    IF I_DS_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'Descrição do produto não informada';
      RAISE e_geral;
    END IF;
    
    IF LENGTH(I_DS_PRODUTO) > 100 THEN
      O_ERROR_MSG := 'Informe uma descrição com menos de 100 caracteres';
      RAISE e_geral;
    END IF;

    /* VALIDAÇÃO VALOR UNITÁRIO */
    IF I_VL_UNITARIO IS NULL THEN
      O_ERROR_MSG := 'Valor unitário do produto não informado';
      RAISE e_geral;
    END IF;
    
    IF I_VL_UNITARIO <= 0 THEN
        O_ERROR_MSG := 'Valor unitário inválido. Informe um valor maior que zero';
        RAISE E_GERAL;
    END IF;


    -- OPERAÇÃO SAVE
    BEGIN
      O_OERACAO := 'I';
      -- TENTAR FAZER O INSERT
      INSERT INTO PRODUTO
        (CD_PRODUTO,DS_PRODUTO,VL_UNITARIO)
      VALUES
        (I_CD_PRODUTO,I_DS_PRODUTO,I_VL_UNITARIO);
      
      COMMIT;
    
    EXCEPTION
      -- CASO JÁ EXISTA -> UPDATE  
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          O_OERACAO := 'U';
          UPDATE PRODUTO
          SET 
              DS_PRODUTO =    I_DS_PRODUTO,
              VL_UNITARIO = I_VL_UNITARIO
          WHERE CD_PRODUTO = I_CD_PRODUTO;
          
          COMMIT;
          
        -- CASO OCORRA PROBLEMAS NO UPDATE
        EXCEPTION
          WHEN OTHERS THEN
            O_ERROR_MSG := 'Erro ao atualizar o produto: ' || SQLERRM;
            RAISE e_geral;
        END;

      -- OUTROS ERROS DE INSERT
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao inserir o produto: ' || SQLERRM;
        RAISE e_geral;
    END;

  EXCEPTION
    WHEN e_geral THEN
      O_ERROR_MSG := '[SAVE_PRODUTO] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[SAVE_PRODUTO] Erro ao salvar o produto: ' || SQLERRM;
      ROLLBACK;
  END SAVE_PRODUTO;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Para excluir produtos */
  PROCEDURE EXCLUIR_PRODUTO(
            I_CD_PRODUTO    IN PRODUTO.CD_PRODUTO%TYPE, 
            I_FORCE_DELETE  IN CHAR DEFAULT 'S',
            O_ERROR_MSG     OUT VARCHAR2) 
  IS
    V_COUNT   NUMBER;
    E_GERAL   EXCEPTION;
  
  BEGIN

    -- VALIDAÇÃO CD_PRODUTO
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'Código do produto não informado';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE O PRODUTO EXISTE
    BEGIN 
      SELECT COUNT(*)
      INTO   V_COUNT
      FROM   PRODUTO
      WHERE  CD_PRODUTO = I_CD_PRODUTO;
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;

    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'Esse produto não existe';
      RAISE E_GERAL; 
    END IF;

    -- VERIFICAR SE DEVE FAZER VALIDAÇÃO DE FK
    IF I_FORCE_DELETE != 'S' THEN
      -- VERIFICANDO SE O PRODUTO ESTÁ PRESENTE EM ALGUMA VENDA 
      BEGIN 
        SELECT COUNT(*)
        INTO   V_COUNT
        FROM   ITEMVENDA
        WHERE  CD_PRODUTO = I_CD_PRODUTO;
      EXCEPTION
        WHEN OTHERS THEN
          V_COUNT := 0;
      END;

      IF V_COUNT > 0 THEN
        O_ERROR_MSG := 'Esse produto está presente em uma ou mais vendas';
        RAISE e_geral;
      END IF;
    END IF;


    -- DESATIVAR O PRODUTO
    BEGIN
      UPDATE PRODUTO
        SET ST_ATIVO = 'N'
        WHERE CD_PRODUTO = I_CD_PRODUTO;
      
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir o produto: ' || SQLERRM;
        RAISE e_geral;
    END;

  EXCEPTION
    WHEN e_geral THEN
      O_ERROR_MSG := '[EXCLUIR_PRODUTO] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_PRODUTO] Erro ao excluir o produto: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_PRODUTO;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
end PKG_PRODUTO;
/
