-- Parte 2: transação dentro de procedure, com verificação de erro, ROLLBACK
-- total e ROLLBACK parcial com SAVEPOINT.
USE ecommerce;

DROP PROCEDURE IF EXISTS registrar_pedido;

DELIMITER $$

-- Registra um pedido de um produto e tenta aplicar um cupom.
-- * Qualquer erro de banco (cliente inexistente, constraint...) desfaz tudo e
--   repassa o erro (ROLLBACK total).
-- * Estoque insuficiente também desfaz tudo.
-- * Cupom inválido, vencido ou esgotado não cancela a compra: volta só até o
--   SAVEPOINT anterior ao cupom e confirma o pedido sem desconto (ROLLBACK parcial).
CREATE PROCEDURE registrar_pedido(
  IN p_cliente_id INT UNSIGNED,
  IN p_produto_id INT UNSIGNED,
  IN p_quantidade INT UNSIGNED,
  IN p_cupom VARCHAR(20),
  OUT p_pedido_id INT UNSIGNED,
  OUT p_mensagem VARCHAR(200)
)
BEGIN
  DECLARE v_estoque INT UNSIGNED;
  DECLARE v_preco DECIMAL(10, 2);
  DECLARE v_percentual TINYINT UNSIGNED;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_pedido_id = NULL;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estoque, preco INTO v_estoque, v_preco FROM produto WHERE id = p_produto_id FOR UPDATE;
  IF v_estoque IS NULL OR v_estoque < p_quantidade THEN
    ROLLBACK;
    SET p_pedido_id = NULL, p_mensagem = 'Estoque insuficiente: nada foi gravado.';
  ELSE
    INSERT INTO pedido (cliente_id) VALUES (p_cliente_id);
    SET p_pedido_id = LAST_INSERT_ID();
    INSERT INTO item_pedido VALUES (p_pedido_id, p_produto_id, p_quantidade, v_preco);
    UPDATE produto SET estoque = estoque - p_quantidade WHERE id = p_produto_id;

    SAVEPOINT antes_do_cupom;
    SET p_mensagem = 'Pedido registrado.';

    IF p_cupom IS NOT NULL THEN
      UPDATE cupom SET usos_restantes = usos_restantes - 1
      WHERE codigo = p_cupom AND validade >= CURDATE() AND usos_restantes > 0;
      IF ROW_COUNT() = 1 THEN
        SELECT percentual INTO v_percentual FROM cupom WHERE codigo = p_cupom;
        UPDATE pedido
        SET cupom = p_cupom, desconto = ROUND(v_preco * p_quantidade * v_percentual / 100, 2)
        WHERE id = p_pedido_id;
        SET p_mensagem = CONCAT('Pedido registrado com ', v_percentual, '% de desconto.');
      ELSE
        ROLLBACK TO SAVEPOINT antes_do_cupom;
        SET p_mensagem = 'Pedido registrado sem desconto: cupom inválido, vencido ou esgotado.';
      END IF;
    END IF;

    COMMIT;
  END IF;
END$$

DELIMITER ;

-- Exemplos
CALL registrar_pedido(2, 1, 1, 'BEMVINDO10', @id, @msg);  SELECT @id AS pedido, @msg AS resultado;
CALL registrar_pedido(2, 1, 1, 'VENCIDO20', @id, @msg);   SELECT @id AS pedido, @msg AS resultado;
CALL registrar_pedido(1, 2, 5, NULL, @id, @msg);          SELECT @id AS pedido, @msg AS resultado;
