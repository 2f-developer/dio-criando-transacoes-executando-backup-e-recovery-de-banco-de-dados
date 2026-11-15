-- Parte 1: transações sem procedure.
USE ecommerce;

SET autocommit = 0;

-- Transação confirmada: a Ana compra dois cabos. Consulta, grava o pedido,
-- baixa o estoque e só então confirma tudo de uma vez.
START TRANSACTION;
  SELECT estoque FROM produto WHERE id = 3 FOR UPDATE;   -- trava a linha até o COMMIT
  INSERT INTO pedido (cliente_id) VALUES (1);
  SET @pedido = LAST_INSERT_ID();
  INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unitario)
  SELECT @pedido, id, 2, preco FROM produto WHERE id = 3;
  UPDATE produto SET estoque = estoque - 2 WHERE id = 3;
  SELECT p.id, SUM(i.quantidade * i.preco_unitario) AS total
  FROM pedido p JOIN item_pedido i ON i.pedido_id = p.id
  WHERE p.id = @pedido GROUP BY p.id;
COMMIT;

-- Transação desfeita: um reajuste de preço errado (+1000%) é percebido antes de
-- confirmar e volta atrás com ROLLBACK. Nada do que foi feito dentro dela fica.
START TRANSACTION;
  UPDATE produto SET preco = preco * 11 WHERE id = 1;
  SELECT nome, preco FROM produto WHERE id = 1;
ROLLBACK;
SELECT nome, preco AS preco_depois_do_rollback FROM produto WHERE id = 1;

SET autocommit = 1;
