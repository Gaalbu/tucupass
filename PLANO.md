# Tiro ao Alto

Sistema unificado de evento + ticketing + check-in ao vivo para a comunidade
[Devs Norte](https://github.com/devsnorte), pensado para substituir/consolidar
os esforços fragmentados que já existem lá: `cosmopolitan` (gestão de evento),
`ingressos` (embrionário) e o fork parado de `pretix`.

## Por que

A org tem três tentativas paralelas pro mesmo problema e nenhuma consolidada —
sinal de dor real sem solução fechada. A aposta aqui não é só abrir um PR, é
construir algo funcional e **rodar ao vivo num evento presencial deles**,
oferecendo pra operar o check-in na entrada. Reputação em comunidade se
constrói resolvendo problema na frente de todo mundo, não mandando código pra
um repo parado.

## Escopo do MVP

1. **Inscrição** — form público de inscrição no evento (nome, email).
2. **Emissão de ingresso** — geração de ingresso com QR code único por
   inscrito, enviado por email.
3. **Check-in em tempo real** — leitor de QR (câmera do celular do
   organizador, via navegador) que valida e marca check-in instantaneamente.
4. **Dashboard ao vivo** — tela pra organização projetar/acompanhar: total de
   inscritos, quantos já chegaram, taxa de check-in em tempo real, lista dos
   últimos chegando.

Fora de escopo no MVP: pagamento, múltiplos tipos de ingresso, lista de
espera, emissão de certificado.

## Stack

- **Elixir + Phoenix LiveView** — mesmo terreno do `sorteios`, já validado com
  a PR #59 lá (race-safety em fluxo concorrente, i18n).
- **Phoenix.Presence** — pra contagem de "quem está online/no evento" em
  tempo real no dashboard, sem polling.
- **Ecto + Postgres** — persistência de eventos, inscritos, ingressos e
  check-ins.
- **QR**: geração com `eqrcode` (server-side, sem dependência JS pesada);
  leitura via `html5-qrcode` (JS, câmera do navegador) postando pro LiveView
  via `pushEvent`.
- **Deploy**: Fly.io (convenção da comunidade — lubien inclusive trabalha lá),
  reaproveitando `fly.toml` no mesmo estilo do `sorteios`.

## Modelagem inicial

```
events
  id, name, slug, starts_at, location

attendees
  id, event_id, name, email, ticket_token (uuid), checked_in_at (nullable)
```

- `ticket_token` é o valor codificado no QR — único, gerado na inscrição.
- Check-in é idempotente: reprocessar o mesmo QR não duplica, só confirma.
- Race-safety no check-in usa o mesmo padrão aprendido no `sorteios` PR #59:
  lock transacional por `ticket_token` pra evitar dois leitores validando o
  mesmo ingresso ao mesmo tempo.

## Fases

1. **Esqueleto** (este commit) — projeto Phoenix criado, schemas, rotas e
   LiveViews vazias/stub.
2. **Inscrição + emissão de QR** — form público, geração de ticket, envio de
   email (Swoosh, modo dev com preview).
3. **Check-in ao vivo** — LiveView com scanner de QR + validação +
   Presence/PubSub atualizando o dashboard em tempo real.
4. **Dashboard de organização** — visão agregada, pensada pra projetar em
   tela na entrada do evento.
5. **Piloto real** — propor rodar num meetup presencial do Devs Norte,
   validar com dados reais, ajustar UX de scanner (rede ruim, luz baixa,
   celular de organizador).
6. **Proposta formal** — depois do piloto validado, levar pro core do
   Devs Norte como substituto/unificação de `cosmopolitan` + `ingressos`.

## Notas

- Nome "Tiro ao Alto" é provisório — trocar antes de qualquer divulgação
  pública/proposta oficial pra comunidade.
- Repo local por enquanto; decidir depois se vai pra conta pessoal, pro
  `devsnorte/ecossistema` como projeto satélite, ou direto como PR de
  substituição nos repos existentes.
