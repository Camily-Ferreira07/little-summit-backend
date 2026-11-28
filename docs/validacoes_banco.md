# Validações Preliminares do Banco — Little Summit

Projeto Integrador (3º semestre).

**Responsável:** Sara Alves
**Data da execução:** 27/11/2026 e 28/11/2026
**Ambiente:** MySQL 8.0 local (Máquina 1), schema `little_summit`, dados carregados com `database/seed.sql`, usuários `admin` e `operador` criados pelo backend (`DataInitializer`)
**Script utilizado:** `docs/testes_banco.sql`

## O que este documento é

Validações feitas **diretamente no MySQL**, sem o cliente JavaFX. Elas conferem se o banco aplica corretamente as regras de estoque e de receitas que a aplicação vai usar. As alterações de teste foram feitas dentro de transações e desfeitas com `ROLLBACK`.

**Não substituem** os testes de integração nas 3 máquinas (ver `docs/roteiro_testes.md`), que continuam pendentes.

## Resumo

| Teste | Descrição | Situação |
|---|---|---|
| 0 | Dados carregados | Validado |
| 1 | Simulação de viabilidade | Validado |
| 2 | Bloqueio de saldo negativo | Validado |
| 3 | Abatimento de estoque em produção válida | Validado |
| 4 | Alerta de estoque crítico após produção | Validado |
| Final | Banco restaurado ao estado do seed | Validado |

---

## Teste 0 — Dados carregados

**O que foi feito:** contagem de insumos, produtos e itens de receita.

**Esperado:** 10 insumos, 4 produtos, 14 itens de receita.

**Resultado obtido:** 10 insumos, 4 produtos e 14 itens de receita. **Igual ao esperado.**

**Print:** `docs/evidencias/teste0.png`

---

## Teste 1 — Simulação de viabilidade (equivale ao cenário 3)

**O que foi feito:** consulta que compara o necessário para 100 Suportes Metálicos Padrão com o estoque atual.

**Esperado:** coluna `viavel` = NAO para os 4 insumos, com a quantidade que falta de cada um.

**Resultado obtido:** **igual ao esperado.**

| Insumo | Necessário | Em estoque | Falta | Viável |
|---|---|---|---|---|
| Chapa de Aço | 200 | 50 | 150 | NAO |
| Parafuso Sextavado | 800 | 200 | 600 | NAO |
| Tinta Industrial | 50 | 15 | 35 | NAO |
| Porca Sextavada | 800 | 180 | 620 | NAO |

**Print:** `docs/evidencias/teste1.png`

---

## Teste 2 — Bloqueio de saldo negativo (equivale ao cenário 3)

**O que foi feito:** tentativa de baixar 999 chapas de aço (mais do que o estoque), dentro de uma transação.

**Esperado:** o MySQL recusa a operação com erro de *check constraint* (`chk_mat_current`) e o saldo da Chapa de Aço permanece 50.

**Resultado obtido:** o MySQL retornou `Error Code: 3819. Check constraint 'chk_mat_current' is violated.` e, após o `ROLLBACK`, a Chapa de Aço continuou com 50,00. **Igual ao esperado.**

**Prints:** `docs/evidencias/teste2_erro.png` (mensagem de erro no Output) e `docs/evidencias/teste2_saldo.png` (saldo preservado)

---

## Teste 3 — Abatimento de estoque em produção válida (equivale ao cenário 4)

**O que foi feito:** abatimento dos insumos de 5 Suportes Metálicos Padrão, dentro de uma transação (`START TRANSACTION`, `UPDATE`, `SELECT`, `ROLLBACK`).

**Esperado durante a transação:**

| Insumo | Antes | Depois |
|---|---|---|
| Chapa de Aço | 50 | 40 |
| Parafuso Sextavado | 200 | 160 |
| Tinta Industrial | 15 | 12,5 |
| Porca Sextavada | 180 | 140 |

**Resultado obtido:** Chapa de Aço 40,00, Parafuso Sextavado 160,00, Porca Sextavada 140,00 e Tinta Industrial 12,50. O `UPDATE` alterou 4 linhas. **Igual ao esperado.**

**Observação:** na primeira tentativa foi executado apenas o `SELECT`, sem o `UPDATE`, e o resultado não comprovava o abatimento. O bloco foi reexecutado por inteiro e o print deste teste é da execução completa.

**Print:** `docs/evidencias/teste3.png`

---

## Teste 4 — Alerta de estoque crítico (equivale ao cenário 5)

**O que foi feito:** abatimento dos insumos de 16 Painéis Elétricos Básicos, dentro de uma transação, e consulta dos insumos com estoque abaixo do mínimo, seguida de `ROLLBACK`.

**Esperado:** a consulta lista Borracha Vedante (6, mínimo 8) e Cabo de Cobre (24, mínimo 30).

**Resultado obtido:** Cabo de Cobre 24,00 (mínimo 30,00) e Borracha Vedante 6,00 (mínimo 8,00). O `UPDATE` alterou 3 linhas. **Igual ao esperado.**

**Observação:** na primeira tentativa foi executado apenas o `SELECT`; o bloco foi reexecutado por inteiro, como no Teste 3.

**Print:** `docs/evidencias/teste4.png`

---

## Conferência final

**O que foi feito:** consulta de todos os saldos depois dos testes, para confirmar que os `ROLLBACK` devolveram o banco ao estado do seed.

**Esperado:** Chapa de Aço 50, Parafuso 200, Tinta 15, Barra de Alumínio 80, Cabo de Cobre 120, Rolamento 40, Borracha Vedante 6, Solvente 6, Porca 180, Disjuntor 30.

**Resultado obtido:** todos os saldos iguais aos do seed. **Igual ao esperado.**

**Print:** `docs/evidencias/conferencia_final.png`

---

## O que continua pendente

Estes itens dependem das telas JavaFX e/ou das 3 máquinas em rede e ainda **não foram testados**:

- Cenário 1: login como `operador` e menu de Usuários oculto.
- Cenário 2: cadastro de usuário pelo ADM e senha em BCrypt no MySQL.
- Fluxo completo de produção pelas telas (simulação, confirmação, registros em `stock_movements` e `history`).
- Alerta visual no Dashboard.
- Conexão entre as 3 máquinas na rede local.
