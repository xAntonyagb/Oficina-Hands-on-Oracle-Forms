CREATE OR REPLACE PACKAGE PKG_PRODUTO IS

  PROCEDURE SAVE_PRODUTO(
            I_CD_PRODUTO      IN PRODUTO.CD_PRODUTO%TYPE, 
            I_DS_PRODUTO      IN PRODUTO.DS_PRODUTO%TYPE, 
            I_VL_UNITARIO     IN PRODUTO.VL_UNITARIO%TYPE,
            O_OPERACAO         OUT CHAR,
            O_ERROR_MSG       OUT VARCHAR2);
            
  PROCEDURE EXCLUIR_PRODUTO(
            I_CD_PRODUTO      IN PRODUTO.CD_PRODUTO%TYPE, 
            I_FORCE_DELETE    IN CHAR DEFAULT 'S',
            O_ERROR_MSG       OUT VARCHAR2);
    
END PKG_PRODUTO;
/
create or replace package body PKG_PRODUTO is

  /* Auxiliares */
  V_COUNT   NUMBER;
  E_GERAL   EXCEPTION;

  /* Para inserir e fazer update em produtos */
  PROCEDURE SAVE_PRODUTO(
            I_CD_PRODUTO      IN PRODUTO.CD_PRODUTO%TYPE, 
            I_DS_PRODUTO      IN PRODUTO.DS_PRODUTO%TYPE, 
            I_VL_UNITARIO     IN PRODUTO.VL_UNITARIO%TYPE,
            O_OPERACAO         OUT CHAR,
            O_ERROR_MSG       OUT VARCHAR2)
  IS
  BEGIN
    
    -- VALIDA��ES
    /* VALIDA��O CD_PRODUTO */
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'C�digo do produto n�o informado';
      RAISE e_geral;
    END IF;
    
    BEGIN
      SELECT 
        COUNT(*)
      INTO 
        V_COUNT
      FROM 
        PRODUTO
      WHERE 
        CD_PRODUTO = I_CD_PRODUTO
        AND ST_ATIVO = 'N';

      IF V_COUNT > 0 THEN
        O_ERROR_MSG := 'Esse produto foi exclu�do e n�o pode ser modificado';
        RAISE E_GERAL;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao verificar o produto: ' || SQLERRM;
        RAISE E_GERAL;
    END;

    /* VALIDA��O DESCRI��O */
    IF I_DS_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'Descri��o do produto n�o informada';
      RAISE e_geral;
    END IF;
    
    IF LENGTH(I_DS_PRODUTO) > 100 THEN
      O_ERROR_MSG := 'Informe uma descri��o com menos de 100 caracteres';
      RAISE e_geral;
    END IF;

    /* VALIDA��O VALOR UNIT�RIO */
    IF I_VL_UNITARIO IS NULL THEN
      O_ERROR_MSG := 'Valor unit�rio do produto n�o informado';
      RAISE e_geral;
    END IF;
    
    IF I_VL_UNITARIO <= 0 THEN
        O_ERROR_MSG := 'Valor unit�rio inv�lido. Informe um valor maior que zero';
        RAISE E_GERAL;
    END IF;


    -- OPERA��O SAVE
    BEGIN
      O_OPERACAO := 'I';
      
      -- TENTAR FAZER O INSERT
      INSERT INTO PRODUTO
        (CD_PRODUTO,DS_PRODUTO,VL_UNITARIO)
      VALUES
        (I_CD_PRODUTO,I_DS_PRODUTO,I_VL_UNITARIO);
      COMMIT;
      
    EXCEPTION
      -- CASO J� EXISTA -> UPDATE  
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          O_OPERACAO := 'U';
          
          UPDATE 
            PRODUTO
          SET 
            DS_PRODUTO =    I_DS_PRODUTO,
            VL_UNITARIO = I_VL_UNITARIO
          WHERE 
            CD_PRODUTO = I_CD_PRODUTO;
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
  BEGIN

    -- VALIDA��O CD_PRODUTO
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'C�digo do produto n�o informado';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE O PRODUTO EXISTE
    BEGIN 
      SELECT 
        COUNT(*)
      INTO   
        V_COUNT
      FROM   
        PRODUTO
      WHERE  
        CD_PRODUTO = I_CD_PRODUTO;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;

    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'Esse produto n�o existe';
      RAISE E_GERAL; 
    END IF;

    -- VERIFICAR SE DEVE FAZER VALIDA��O DE FK
    IF I_FORCE_DELETE != 'S' THEN
      -- VERIFICANDO SE O PRODUTO EST� PRESENTE EM ALGUMA VENDA 
      BEGIN 
        SELECT 
          COUNT(*)
        INTO   
          V_COUNT
        FROM   
          ITEMVENDA
        WHERE  
          CD_PRODUTO = I_CD_PRODUTO;
        
      EXCEPTION
        WHEN OTHERS THEN
          V_COUNT := 0;
      END;

      IF V_COUNT > 0 THEN
        O_ERROR_MSG := 'Esse produto est� presente em uma ou mais vendas';
        RAISE e_geral;
      END IF;
    END IF;


    -- DESATIVAR O PRODUTO
    BEGIN
      UPDATE 
        PRODUTO
      SET 
        ST_ATIVO = 'N'
      WHERE 
        CD_PRODUTO = I_CD_PRODUTO;
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
