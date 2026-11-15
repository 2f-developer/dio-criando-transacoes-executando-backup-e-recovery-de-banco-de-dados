-- Confere o que voltou do backup: dados, procedures, evento, view e o segundo banco.
SELECT IF(
  (SELECT COUNT(*) FROM ecommerce.pedido) = 3
  AND (SELECT COUNT(*) FROM ecommerce.item_pedido) = 3
  AND (SELECT estoque FROM ecommerce.produto WHERE id = 3) = 98
  AND (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'ecommerce' AND routine_name = 'registrar_pedido') = 1
  AND (SELECT COUNT(*) FROM information_schema.events WHERE event_schema = 'ecommerce' AND event_name = 'ev_cancelar_pedidos_parados') = 1
  AND (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'relatorios' AND routine_name = 'gerar_fechamento') = 1
  AND (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'relatorios' AND table_name = 'vw_vendas_por_produto') = 1
  AND (SELECT COUNT(*) FROM relatorios.fechamento_diario) = 1,
  'ok  backup restaurado com dados, procedures, evento e view',
  'FALHOU: o recovery não trouxe tudo de volta') AS resultado;
