CREATE OR REPLACE PACKAGE PKG_ITEMVENDA IS

  -- Declaração do record e vetor
  TYPE ITEMVENDA_REC IS RECORD (
    CD_VENDA      ITEMVENDA.CD_VENDA%TYPE,
    CD_PRODUTO    ITEMVENDA.CD_PRODUTO%TYPE,
    DS_PRODUTO    PRODUTO.DS_PRODUTO%TYPE,
    VL_UNITPROD   ITEMVENDA.VL_UNITPROD%TYPE,
    QT_ADQUIRIDA  ITEMVENDA.QT_ADQUIRIDA%TYPE,
    VL_SUBTOTAL   NUMBER(15,2),
    DT_RECORD     ITEMVENDA.DT_RECORD%TYPE
  );
  
  TYPE VET_ITEMVENDA IS TABLE OF ITEMVENDA_REC INDEX BY BINARY_INTEGER; 
  
  
  -- Restante dos procedures
  
  PROCEDURE LIMPAR_VET_ITEMVENDA;
    
  PROCEDURE SET_VET_ITEMVENDA(
            I_CD_VENDA  IN ITEMVENDA.CD_VENDA%TYPE,
            O_VET_ITEMVENDA OUT VET_ITEMVENDA,
            O_ERROR_MSG OUT VARCHAR2);

  PROCEDURE SAVE_INTO_VET_ITEMVENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            I_DS_PRODUTO    IN PRODUTO.DS_PRODUTO%TYPE DEFAULT NULL,
            I_VL_UNITPROD   IN ITEMVENDA.VL_UNITPROD%TYPE,
            I_QT_ADQUIRIDA  IN ITEMVENDA.QT_ADQUIRIDA%TYPE,
            I_DT_RECORD     IN DATE DEFAULT TO_DATE(SYSDATE, 'DD/MM/YYYY'),
            O_VET_ITEMVENDA OUT VET_ITEMVENDA,
            O_ERROR_MSG     OUT VARCHAR2);
            
  PROCEDURE DELETE_FROM_VET_ITEMVENDA(
            I_CD_VENDA      IN  ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN  ITEMVENDA.CD_PRODUTO%TYPE,
            O_VET_ITEMVENDA OUT VET_ITEMVENDA,
            O_ERROR_MSG     OUT VARCHAR2);
            
  PROCEDURE PROCESSAR_VETOR_ITEMVENDA(
            I_CD_VENDA  IN VENDA.CD_VENDA%TYPE,
            O_ERROR_MSG OUT VARCHAR2);

  PROCEDURE SAVE_ITEM_VENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            I_VL_UNITPROD   IN ITEMVENDA.VL_UNITPROD%TYPE,
            I_QT_ADQUIRIDA  IN ITEMVENDA.QT_ADQUIRIDA%TYPE,
            I_DT_RECORD     IN ITEMVENDA.DT_RECORD%TYPE DEFAULT SYSDATE,
            O_OPERACAO      OUT CHAR,
            O_ERROR_MSG     OUT VARCHAR2);
            
  PROCEDURE EXCLUIR_ITEM_VENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE, 
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            O_ERROR_MSG     OUT VARCHAR2);
            
  PROCEDURE EXCLUIR_ITEM_VENDA_BY_VENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            O_ERROR_MSG     OUT VARCHAR2);

END PKG_ITEMVENDA;
/
CREATE OR REPLACE PACKAGE BODY PKG_ITEMVENDA IS

  /* Auxiliares */
  V_COUNT   NUMBER;
  E_GERAL   EXCEPTION;
  V_VET_ITEMVENDA VET_ITEMVENDA;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  PROCEDURE SET_VET_ITEMVENDA(
            I_CD_VENDA  IN ITEMVENDA.CD_VENDA%TYPE,
            O_VET_ITEMVENDA OUT VET_ITEMVENDA,
            O_ERROR_MSG OUT VARCHAR2)
  IS
    V_INDICE BINARY_INTEGER := 0;
  BEGIN
    -- Limpar a variável global antes de popular
    V_VET_ITEMVENDA.DELETE;
    
    /* Para cada record dentro do select inserir no vetor  */
    FOR REC IN (
      SELECT 
        IV.CD_VENDA, 
        IV.CD_PRODUTO, 
        P.DS_PRODUTO, 
        IV.VL_UNITPROD, 
        IV.QT_ADQUIRIDA, 
        IV.VL_UNITPROD * IV.QT_ADQUIRIDA AS VL_SUBTOTAL, 
        IV.DT_RECORD
      FROM 
        ITEMVENDA IV
      JOIN PRODUTO P ON IV.CD_PRODUTO = P.CD_PRODUTO
      WHERE 
        IV.CD_VENDA = I_CD_VENDA)
    LOOP
      V_INDICE := V_INDICE + 1;
      V_VET_ITEMVENDA(V_INDICE).CD_VENDA     := REC.CD_VENDA;
      V_VET_ITEMVENDA(V_INDICE).CD_PRODUTO   := REC.CD_PRODUTO;
      V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO   := REC.DS_PRODUTO;
      V_VET_ITEMVENDA(V_INDICE).VL_UNITPROD  := REC.VL_UNITPROD;
      V_VET_ITEMVENDA(V_INDICE).QT_ADQUIRIDA := REC.QT_ADQUIRIDA;
      V_VET_ITEMVENDA(V_INDICE).VL_SUBTOTAL  := REC.VL_SUBTOTAL;
      V_VET_ITEMVENDA(V_INDICE).DT_RECORD    := REC.DT_RECORD;
    END LOOP;
    
    O_VET_ITEMVENDA := V_VET_ITEMVENDA;
    
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := '[SET_VET_ITEMVENDA] Erro ao carregar listagem de itens de venda: ' || SQLERRM;
  END SET_VET_ITEMVENDA;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para zerar o vetor */
  PROCEDURE LIMPAR_VET_ITEMVENDA IS
  BEGIN
    -- Limpar
    V_VET_ITEMVENDA.DELETE;
  END LIMPAR_VET_ITEMVENDA;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para inserir um item venda no vetor */
  PROCEDURE SAVE_INTO_VET_ITEMVENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            I_DS_PRODUTO    IN PRODUTO.DS_PRODUTO%TYPE DEFAULT NULL,
            I_VL_UNITPROD   IN ITEMVENDA.VL_UNITPROD%TYPE,
            I_QT_ADQUIRIDA  IN ITEMVENDA.QT_ADQUIRIDA%TYPE,
            I_DT_RECORD     IN DATE DEFAULT TO_DATE(SYSDATE, 'DD/MM/YYYY'),
            O_VET_ITEMVENDA OUT VET_ITEMVENDA,
            O_ERROR_MSG     OUT VARCHAR2)
  IS
    V_INDICE NUMBER;
    V_ENCONTRADO BOOLEAN := FALSE;
  BEGIN
    -- Verificar se já tem algum item venda no vetor
    IF NVL(V_VET_ITEMVENDA.COUNT, 0) != 0 THEN
      -- Se tiver, procura para dar update
      FOR V_INDICE IN 1 .. V_VET_ITEMVENDA.LAST LOOP
        IF V_VET_ITEMVENDA(V_INDICE).CD_VENDA = I_CD_VENDA AND V_VET_ITEMVENDA(V_INDICE).CD_PRODUTO = I_CD_PRODUTO THEN
          -- Atualizar
          V_VET_ITEMVENDA(V_INDICE).VL_UNITPROD := I_VL_UNITPROD;
          V_VET_ITEMVENDA(V_INDICE).QT_ADQUIRIDA := I_QT_ADQUIRIDA;
          V_VET_ITEMVENDA(V_INDICE).DT_RECORD := I_DT_RECORD;
          V_VET_ITEMVENDA(V_INDICE).VL_SUBTOTAL := (I_VL_UNITPROD * I_QT_ADQUIRIDA);
          
          /* Preencher DS_PRODUTO */
          IF I_DS_PRODUTO IS NOT NULL THEN
            V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO := I_DS_PRODUTO;
          ELSE 
            BEGIN 
              SELECT 
                P.DS_PRODUTO 
              INTO
                V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO
              FROM 
                PRODUTO P
              WHERE 
                P.CD_PRODUTO = I_CD_PRODUTO
                AND P.ST_ATIVO = 'S';
            EXCEPTION
              WHEN OTHERS THEN
                V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO := 'Produto sem nome';
            END;
          END IF;
    
          -- Marcar encontrado no indice e sai do loop
          V_ENCONTRADO := TRUE;
          EXIT;
        END IF;
      END LOOP;
    END IF;

    -- Se não tiver registro, adiciona um novo
    IF NOT V_ENCONTRADO THEN
      V_INDICE := V_VET_ITEMVENDA.COUNT + 1;
      
      V_VET_ITEMVENDA(V_INDICE).CD_VENDA := I_CD_VENDA;
      V_VET_ITEMVENDA(V_INDICE).CD_PRODUTO := I_CD_PRODUTO;
      V_VET_ITEMVENDA(V_INDICE).VL_UNITPROD := I_VL_UNITPROD;
      V_VET_ITEMVENDA(V_INDICE).QT_ADQUIRIDA := I_QT_ADQUIRIDA;
      V_VET_ITEMVENDA(V_INDICE).DT_RECORD := I_DT_RECORD;
      V_VET_ITEMVENDA(V_INDICE).VL_SUBTOTAL := (I_VL_UNITPROD * I_QT_ADQUIRIDA);
      
      /* Preencher DS_PRODUTO */
      IF I_DS_PRODUTO IS NOT NULL THEN
        V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO := I_DS_PRODUTO;
      ELSE 
        BEGIN 
          SELECT 
            P.DS_PRODUTO 
          INTO
            V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO
          FROM 
            PRODUTO P
          WHERE 
            P.CD_PRODUTO = I_CD_PRODUTO
            AND P.ST_ATIVO = 'S';
        EXCEPTION
          WHEN OTHERS THEN
            V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO := 'Produto sem nome';
        END;
      END IF;
    END IF;
    
    /* Retornar o vetor atualizado */
    O_VET_ITEMVENDA := V_VET_ITEMVENDA;
    
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := '[SAVE_INTO_VET_ITEMVENDA] Erro ao salvar item venda na listagem: ' || SQLERRM;
    
  END SAVE_INTO_VET_ITEMVENDA;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para deletar o item venda do vetor */
  PROCEDURE DELETE_FROM_VET_ITEMVENDA(
            I_CD_VENDA      IN  ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN  ITEMVENDA.CD_PRODUTO%TYPE,
            O_VET_ITEMVENDA OUT VET_ITEMVENDA,
            O_ERROR_MSG     OUT VARCHAR2) 
  IS
    V_INDICE BINARY_INTEGER := 0;
  BEGIN
    IF NVL(V_VET_ITEMVENDA.COUNT, 0) = 0 THEN
      O_ERROR_MSG := 'Nenhum item de venda foi adicionado a listagem';
      RAISE E_GERAL;
    END IF;  
  
    -- Tratativa caso não tenha o item venda no vetor
    O_ERROR_MSG := 'Este item de venda não foi encontrado ou não foi adicionado';
  
    -- loopar V_VET_ITEMVENDA para achar e deletar
    FOR V_INDICE IN 1 .. V_VET_ITEMVENDA.LAST LOOP
      IF V_VET_ITEMVENDA(V_INDICE).CD_VENDA = I_CD_VENDA AND V_VET_ITEMVENDA(V_INDICE).CD_PRODUTO = I_CD_PRODUTO THEN
        V_VET_ITEMVENDA.DELETE(V_INDICE);
        O_ERROR_MSG := NULL;
        EXIT;
      END IF;
    END LOOP;
    
    IF O_ERROR_MSG IS NOT NULL THEN
      RAISE E_GERAL;
    END IF;
    
    /* Retornar o vetor atualizado */
    O_VET_ITEMVENDA := V_VET_ITEMVENDA;
    
  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[DELETE_FROM_VET_ITEMVENDA] ' || O_ERROR_MSG;
  
    WHEN OTHERS THEN
      O_ERROR_MSG := '[DELETE_FROM_VET_ITEMVENDA] Erro ao remover item venda da listagem: ' || SQLERRM;
    
  END DELETE_FROM_VET_ITEMVENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para enviar os itens venda para o banco */
  PROCEDURE PROCESSAR_VETOR_ITEMVENDA(
            I_CD_VENDA  IN VENDA.CD_VENDA%TYPE,
            O_ERROR_MSG OUT VARCHAR2)
  IS
    V_OPERACAO      CHAR;
    V_ERROR_MSG     VARCHAR2(3200);
    V_INDICE        BINARY_INTEGER := 0;
  BEGIN
    IF NVL(V_VET_ITEMVENDA.COUNT, 0) = 0 THEN
      O_ERROR_MSG := 'Nenhum item de venda foi adicionado a listagem';
      RAISE E_GERAL;
    END IF;  
  
    -- Percorre o vetor
    FOR V_INDICE IN V_VET_ITEMVENDA.FIRST .. V_VET_ITEMVENDA.LAST LOOP
      -- salvar o item venda
      SAVE_ITEM_VENDA(
        I_CD_VENDA,
        V_VET_ITEMVENDA(V_INDICE).CD_PRODUTO,
        V_VET_ITEMVENDA(V_INDICE).VL_UNITPROD,
        V_VET_ITEMVENDA(V_INDICE).QT_ADQUIRIDA,
        V_VET_ITEMVENDA(V_INDICE).DT_RECORD,
        V_OPERACAO,
        V_ERROR_MSG
      );

      -- Verificar se deu erro
      IF V_ERROR_MSG IS NOT NULL THEN
        O_ERROR_MSG := 'Erro ao processar o item [' || V_VET_ITEMVENDA(V_INDICE).DS_PRODUTO || ']: ' || V_ERROR_MSG;
        RAISE E_GERAL;
      END IF;
      
    END LOOP;
    
    /* Enviar para o banco e limpar o vetor ao fim */
    COMMIT;
    V_VET_ITEMVENDA.DELETE;

  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[PROCESSAR_VETOR_ITEMVENDA] ' || O_ERROR_MSG;
  
    WHEN OTHERS THEN
      O_ERROR_MSG := '[PROCESSAR_VETOR_ITEMVENDA] Erro ao processar lista de itens de venda: ' || SQLERRM;
      
  END PROCESSAR_VETOR_ITEMVENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Para inserir e fazer update em itens de venda */
  PROCEDURE SAVE_ITEM_VENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            I_VL_UNITPROD   IN ITEMVENDA.VL_UNITPROD%TYPE,
            I_QT_ADQUIRIDA  IN ITEMVENDA.QT_ADQUIRIDA%TYPE,
            I_DT_RECORD     IN ITEMVENDA.DT_RECORD%TYPE DEFAULT SYSDATE,
            O_OPERACAO      OUT CHAR,
            O_ERROR_MSG     OUT VARCHAR2)
  IS
    V_POS   NUMBER;
  BEGIN
    
    -- VALIDAÇÕES
    /* VALIDAÇÃO VENDA */
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'Código da venda não informado';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(I_CD_VENDA)) > 15 THEN
      O_ERROR_MSG := 'Código da venda não pode exceder 15 dígitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICAR SE A VENDA EXISTE
    BEGIN 
      SELECT 
        COUNT(*)
      INTO   
        V_COUNT
      FROM   
        VENDA
      WHERE  
        CD_VENDA = I_CD_VENDA;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;
      
    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'A venda informada não existe';
      RAISE E_GERAL;
    END IF;

    /* VALIDAÇÃO PRODUTO */
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'Código do produto não informado';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(I_CD_PRODUTO)) > 10 THEN
      O_ERROR_MSG := 'Código do produto não pode exceder 10 dígitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICAR SE O PRODUTO EXISTE
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
      O_ERROR_MSG := 'O produto informado não existe';
      RAISE E_GERAL;
    END IF;

    /* VALIDAÇÃO VALOR UNIT */
    IF I_VL_UNITPROD IS NULL THEN
      O_ERROR_MSG := 'Valor unitário do produto não informado';
      RAISE E_GERAL;
    END IF;
    
    IF I_VL_UNITPROD <= 0 THEN
      O_ERROR_MSG := 'Valor unitário inválido. Informe um valor maior que zero';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(TRUNC(I_VL_UNITPROD))) > 15 THEN
      O_ERROR_MSG := 'Valor unitário inválido. Informe um valor com até 15 casas inteiras';
      RAISE E_GERAL;
    END IF;

    -- Verificar o tamanho da parte decimal
    V_POS := INSTR(TO_CHAR(I_VL_UNITPROD), ','); -- Retorna pos da virgula
    IF V_POS > 0 THEN
      -- Corta a string a partir da virgula utilizando V_POS para verificar o tamanho
      IF LENGTH(SUBSTR(TO_CHAR(I_VL_UNITPROD), V_POS + 1)) > 2 THEN
        O_ERROR_MSG := 'Valor unitário inválido. Informe um valor com até 2 casas decimais';
        RAISE E_GERAL;
      END IF;
    END IF;

    /* VALIDAÇÃO QUANTIDADE ADQUIRIDA */
    IF I_QT_ADQUIRIDA IS NULL THEN
      O_ERROR_MSG := 'Quantidade adquirida não informada';
      RAISE E_GERAL;
    END IF;

    IF I_QT_ADQUIRIDA <= 0 THEN
      O_ERROR_MSG := 'Quantidade adquirida inválida. Informe um valor maior que zero';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(TRUNC(I_QT_ADQUIRIDA))) > 15 THEN
      O_ERROR_MSG := 'Quantidade adquirida inválida. Informe uma quantidade com no máximo 15 casas inteiras';
      RAISE E_GERAL;
    END IF;

    -- Verificar o tamanho da parte decimal
    V_POS := INSTR(TO_CHAR(I_QT_ADQUIRIDA), ','); -- Retorna pos da virgula
    IF V_POS > 0 THEN
      -- Corta a string a partir da virgula utilizando V_POS para verificar o tamanho
      IF LENGTH(SUBSTR(TO_CHAR(I_QT_ADQUIRIDA), V_POS + 1)) > 2 THEN
        O_ERROR_MSG := 'Quantidade adquirida inválida. Informe uma quantidade com até 2 casas decimais';
        RAISE E_GERAL;
      END IF;
    END IF;

    /* VALIDAÇÃO DATA */
    IF I_DT_RECORD IS NULL THEN
      O_ERROR_MSG := 'DT_RECORD não informada';
      RAISE E_GERAL;
    END IF;

    -- Verificar se a data está no formato errado ou é futura
    DECLARE
      V_VALIDACAO_DATE DATE;
    BEGIN
      V_VALIDACAO_DATE := TO_DATE(TO_CHAR(I_DT_RECORD, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      
      IF V_VALIDACAO_DATE > SYSDATE THEN
        O_ERROR_MSG := 'DT_RECORD não pode ser uma data futura';
        RAISE E_GERAL;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'DT_RECORD inválida. Informe no formato DD/MM/YYYY';
        RAISE E_GERAL;
    END;

    /* OPERAÇÃO SAVE */
    BEGIN
      O_OPERACAO := 'I';
      -- TENTAR FAZER O INSERT
      INSERT INTO ITEMVENDA
        (CD_VENDA, CD_PRODUTO, VL_UNITPROD, QT_ADQUIRIDA, DT_RECORD)
      VALUES
        (I_CD_VENDA, I_CD_PRODUTO, I_VL_UNITPROD, I_QT_ADQUIRIDA, I_DT_RECORD);
    
    EXCEPTION
      -- CASO JÁ EXISTA -> UPDATE  
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          O_OPERACAO := 'U';
          
          UPDATE 
            ITEMVENDA
          SET 
            VL_UNITPROD  = I_VL_UNITPROD,
            QT_ADQUIRIDA = I_QT_ADQUIRIDA,
            DT_RECORD    = I_DT_RECORD
          WHERE 
            CD_VENDA = I_CD_VENDA 
            AND CD_PRODUTO = I_CD_PRODUTO;
          
        -- CASO OCORRA PROBLEMAS NO UPDATE
        EXCEPTION
          WHEN OTHERS THEN
            O_ERROR_MSG := 'Erro ao atualizar o item de venda: ' || SQLERRM;
            RAISE E_GERAL;
        END;

      -- OUTROS ERROS DE INSERT
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao inserir o item de venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[SAVE_ITEM_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[SAVE_ITEM_VENDA] Erro ao salvar o item de venda: ' || SQLERRM;
      ROLLBACK;
  END SAVE_ITEM_VENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Para excluir itens de venda */
  PROCEDURE EXCLUIR_ITEM_VENDA(
            I_CD_VENDA    IN ITEMVENDA.CD_VENDA%TYPE, 
            I_CD_PRODUTO  IN ITEMVENDA.CD_PRODUTO%TYPE,
            O_ERROR_MSG   OUT VARCHAR2) 
  IS
  BEGIN

    -- VALIDAÇÃO CD_VENDA
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'Código da venda não informado';
      RAISE E_GERAL;
    END IF;
    
    IF LENGTH(TO_CHAR(I_CD_VENDA)) > 15 THEN
      O_ERROR_MSG := 'Código da venda não pode exceder 15 dígitos';
      RAISE E_GERAL;
    END IF;

    -- VALIDAÇÃO CD_PRODUTO
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'Código do produto não informado';
      RAISE E_GERAL;
    END IF;
    
    IF LENGTH(TO_CHAR(I_CD_PRODUTO)) > 10 THEN
      O_ERROR_MSG := 'Código do produto não pode exceder 10 dígitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE O ITEM DE VENDA EXISTE
    BEGIN 
      SELECT 
        COUNT(*)
      INTO   
        V_COUNT
      FROM   
        ITEMVENDA
      WHERE  
        CD_VENDA = I_CD_VENDA 
        AND CD_PRODUTO = I_CD_PRODUTO;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;
      
    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'O item de venda informado não existe';
      RAISE E_GERAL; 
    END IF;
      
    -- EXCLUINDO O ITEM DE VENDA
    BEGIN
      DELETE FROM 
        ITEMVENDA
      WHERE 
        CD_VENDA = I_CD_VENDA 
        AND CD_PRODUTO = I_CD_PRODUTO;
      
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir o item de venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;
    
  EXCEPTION
    WHEN e_geral THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA] Erro ao excluir a venda: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_ITEM_VENDA;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para excluir todos os itens de venda de uma venda específica */
  PROCEDURE EXCLUIR_ITEM_VENDA_BY_VENDA(
            I_CD_VENDA    IN ITEMVENDA.CD_VENDA%TYPE,
            O_ERROR_MSG   OUT VARCHAR2)
  IS
  BEGIN

    -- VALIDAÇÃO CD_VENDA
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'Código da venda não informado';
      RAISE E_GERAL;
    END IF;
    
    IF LENGTH(TO_CHAR(I_CD_VENDA)) > 15 THEN
      O_ERROR_MSG := 'Código da venda não pode exceder 15 dígitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE A VENDA EXISTE
    BEGIN 
      SELECT 
        COUNT(*)
      INTO   
        V_COUNT
      FROM   
        VENDA
      WHERE  
        CD_VENDA = I_CD_VENDA;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;
      
    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'A venda informada não existe';
      RAISE E_GERAL;
    END IF;
      
    -- EXCLUINDO OS ITENS DE VENDA DA VENDA ESPECÍFICA
    BEGIN 
      DELETE FROM 
        ITEMVENDA
      WHERE 
        CD_VENDA = I_CD_VENDA;
      
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir os itens de venda da venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;
    
  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA_BY_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA_BY_VENDA] Erro ao excluir os itens de venda pela venda: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_ITEM_VENDA_BY_VENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
END PKG_ITEMVENDA;
/
