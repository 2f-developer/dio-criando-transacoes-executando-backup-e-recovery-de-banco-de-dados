# Transações, backup e recovery no MySQL

Desafio "Criando Transações, Executando Backup e Recovery de Banco de Dados", da formação SQL Database Specialist da DIO. Três partes, todas sobre um e-commerce simples (clientes, produtos com estoque, cupons, pedidos e itens):

1. transações executadas direto, com `autocommit` desligado;
2. uma transação dentro de procedure, com tratamento de erro, `ROLLBACK` total e parcial (`SAVEPOINT`);
3. backup e recovery com `mysqldump`, levando procedures, eventos e mais de um banco.

## Parte 1: transações (`sql/02_transacao.sql`)

Com `SET autocommit = 0`, duas transações:

- **uma que vai até o `COMMIT`**: a compra de dois cabos. Trava a linha do produto com `SELECT ... FOR UPDATE`, cria o pedido e o item, baixa o estoque e confirma tudo junto;
- **uma que termina em `ROLLBACK`**: um reajuste de preço errado (+1000%) que é percebido antes de confirmar. Depois do rollback, o preço continua o original.

## Parte 2: transação em procedure (`sql/03_procedure_transacao.sql`)

`registrar_pedido(cliente, produto, quantidade, cupom, OUT pedido, OUT mensagem)` faz o pedido inteiro numa transação e trata três tipos de problema de formas diferentes:

| Situação | O que acontece |
| --- | --- |
| Erro de banco (cliente inexistente, constraint violada...) | o `EXIT HANDLER` faz **`ROLLBACK` total** e repassa o erro com `RESIGNAL` |
| Estoque insuficiente | **`ROLLBACK` total**: nada é gravado, e a mensagem explica |
| Cupom inválido, vencido ou esgotado | **`ROLLBACK TO SAVEPOINT antes_do_cupom`**: só a tentativa de desconto é desfeita; o pedido é confirmado sem desconto |

O rollback parcial é o caso interessante: um cupom ruim não deveria custar uma venda. O `SAVEPOINT` é criado depois de gravar pedido, item e baixa de estoque, então voltar até ele preserva a compra e descarta só o que foi feito com o cupom.

```sql
CALL registrar_pedido(2, 1, 1, 'BEMVINDO10', @id, @msg);  -- pedido com 10% de desconto
CALL registrar_pedido(2, 1, 1, 'VENCIDO20', @id, @msg);   -- pedido sem desconto (rollback parcial)
CALL registrar_pedido(1, 2, 5, NULL, @id, @msg);          -- estoque insuficiente: nada gravado
SELECT @id, @msg;
```

## Parte 3: backup e recovery

`sql/04_recursos_extras.sql` acrescenta o que um backup costuma esquecer:

- um **evento** no e-commerce, que cancela todo dia os pedidos parados há mais de 3 dias;
- um segundo banco, **`relatorios`**, com tabela, view e procedure próprias.

O backup é feito pelo `backup.sh`, com `mysqldump --routines --events --triggers --single-transaction`:

| Arquivo | Conteúdo |
| --- | --- |
| `backup/ecommerce.sql` | só o banco `ecommerce` |
| `backup/ecommerce_relatorios.sql` | os dois bancos, com procedures, evento e view |

O `recovery.sh` apaga os dois bancos e os restaura a partir de `backup/ecommerce_relatorios.sql`. Os arquivos de backup estão versionados aqui, como pede o desafio.

## Rodando

```bash
./testar.sh -u root -p
```

O script executa as três partes, roda `tests/verificacoes.sql` (estoque, preços, descontos e cupons depois de cada transação, inclusive o erro repassado pela procedure), apaga os bancos, restaura o backup versionado e confere com `tests/pos_recovery.sql` se voltaram os dados, as procedures, o evento e a view. O GitHub Actions faz o mesmo num MySQL 8 a cada push.

Para gerar um backup novo a partir do seu banco: `./backup.sh -u root -p`.
