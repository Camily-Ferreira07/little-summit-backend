-- =====================================================================
-- Little Summit - Validações preliminares direto no banco (MySQL)
-- =====================================================================
-- Estes testes NÃO usam o backend nem o JavaFX: validam, no próprio
-- MySQL, a lógica de estoque e receitas que a aplicação vai usar.
-- Todas as alterações são desfeitas com ROLLBACK ao final de cada teste.
--
-- PRÉ-REQUISITO: seed.sql já carregado (insumos, produtos e receitas).
-- COMO RODAR: selecione UM bloco por vez (de "TESTE" até o ROLLBACK ou
-- o SELECT final) e clique no raio. Tire print de cada resultado.
-- =====================================================================

USE little_summit;
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- TESTE 0: Conferência dos dados carregados
-- Esperado: 10 insumos, 4 produtos, 14 itens de receita
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM materials)         AS insumos,
  (SELECT COUNT(*) FROM products)          AS produtos,
  (SELECT COUNT(*) FROM product_materials) AS itens_de_receita;

-- ---------------------------------------------------------------------
-- TESTE 1 (equivale ao cenário 3): Simulação de viabilidade
-- Produzir 100 Suportes Metálicos Padrão.
-- Esperado: coluna "viavel" = NAO em chapa, parafuso e porca
-- (o estoque só permite 22 unidades, limitado pelas porcas).
-- ---------------------------------------------------------------------
SELECT
  m.name                                   AS insumo,
  pm.quantity_per_unit * 100               AS necessario,
  m.current_quantity                       AS em_estoque,
  GREATEST(pm.quantity_per_unit * 100 - m.current_quantity, 0) AS falta,
  IF(m.current_quantity >= pm.quantity_per_unit * 100, 'SIM', 'NAO') AS viavel
FROM product_materials pm
JOIN products  p ON p.id = pm.product_id
JOIN materials m ON m.id = pm.material_id
WHERE p.name = 'Suporte Metálico Padrão';

-- ---------------------------------------------------------------------
-- TESTE 2 (equivale ao cenário 3, parte do bloqueio):
-- Tentar baixar 999 chapas de aço (mais do que existe).
-- Esperado: ERRO 3819 "Check constraint 'chk_mat_current' is violated".
-- O banco recusa saldo negativo, então nada é alterado.
-- ---------------------------------------------------------------------
START TRANSACTION;
UPDATE materials SET current_quantity = current_quantity - 999
WHERE name = 'Chapa de Aço';
ROLLBACK;

-- Confere que o saldo continuou igual (esperado: 50.00)
SELECT name, current_quantity FROM materials WHERE name = 'Chapa de Aço';

-- ---------------------------------------------------------------------
-- TESTE 3 (equivale ao cenário 4): Produção válida abate o estoque
-- Produzir 5 Suportes Metálicos Padrão.
-- Esperado depois do abatimento:
--   Chapa de Aço 40 | Parafuso 160 | Tinta 12.50 | Porca 140
-- Selecione do START TRANSACTION até o ROLLBACK de uma vez.
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE materials m
JOIN product_materials pm ON pm.material_id = m.id
JOIN products p ON p.id = pm.product_id
SET m.current_quantity = m.current_quantity - pm.quantity_per_unit * 5
WHERE p.name = 'Suporte Metálico Padrão';

SELECT name, current_quantity
FROM materials
WHERE name IN ('Chapa de Aço', 'Parafuso Sextavado', 'Tinta Industrial', 'Porca Sextavada');

ROLLBACK;

-- ---------------------------------------------------------------------
-- TESTE 4 (equivale ao cenário 5): Alerta de estoque crítico
-- Produzir 16 Painéis Elétricos Básicos derruba o Cabo de Cobre
-- de 120 para 24 (abaixo do mínimo de 30).
-- Esperado: a consulta lista Borracha Vedante (6 < 8, já em alerta
-- desde o seed) e Cabo de Cobre (24 < 30).
-- Selecione do START TRANSACTION até o ROLLBACK de uma vez.
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE materials m
JOIN product_materials pm ON pm.material_id = m.id
JOIN products p ON p.id = pm.product_id
SET m.current_quantity = m.current_quantity - pm.quantity_per_unit * 16
WHERE p.name = 'Painel Elétrico Básico';

SELECT name, current_quantity, minimum_quantity
FROM materials
WHERE current_quantity < minimum_quantity;

ROLLBACK;

-- ---------------------------------------------------------------------
-- CONFERÊNCIA FINAL: tudo deve ter voltado ao estado do seed
-- Esperado: Chapa 50, Parafuso 200, Tinta 15, Cabo 120, Porca 180
-- ---------------------------------------------------------------------
SELECT name, current_quantity FROM materials ORDER BY id;
