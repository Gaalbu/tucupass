# Tucupass

Evento + ticketing + check-in ao vivo. Plano completo em `PLANO.md`.

Phoenix 1.8 · LiveView · Ecto/Postgres · Presence · Swoosh · `eqrcode` · `html5-qrcode`.

## Rodando (sem Elixir local, via Docker)

```bash
./bin-mix setup            # deps, banco, seeds (evento demo: demo)
docker compose up dev      # http://localhost:4000
./bin-mix test
./bin-mix precommit
```

| Rota | Quem | O quê |
| --- | --- | --- |
| `/` | público | landing + painel ao vivo da demo |
| `/demo` | público | painel em tela cheia (modo projetor) |
| `/demo/checkin` | público | leitor do evento demo |
| `/e/:slug` | público | inscrição (nome, e-mail) |
| `/t/:token` | inscrito | ingresso com QR (atualiza ao vivo no check-in) |
| `/e/:slug/checkin?key=…` | organização | scanner pela câmera + digitação manual |
| `/e/:slug/dashboard?key=…` | organização | inscritos, chegadas, taxa, leitores online, últimos |
| `/dev/mailbox` | dev | preview dos e-mails |

`?key=` é o `ORGANIZER_KEY` (dev: `dev-organizer-key`); vira cookie de sessão e sai da URL.

## Vitrine (pivô)

O foco virou uma **vitrine pública** para o Devs Norte: `/` abre direto num painel vivo. O evento `demo`
é alimentado por `Tucupass.Demo`, um simulador com gente fictícia (e-mails `@demo.invalid`, sem
enviar e-mail) que inscreve e faz check-in em ritmo humano e reinicia o ciclo sozinho. Inscrições de
visitantes no `demo` são apagadas após 6 h. `DEMO=false` desliga o simulador em produção.
Identidade: açaí escuro, papel de canhoto, amarelo-tucupi, Big Shoulders Display, cantos retos.

## Decisões

- **Check-in idempotente e race-safe**: `SELECT … FOR UPDATE` por `ticket_token` numa transação
  (`Events.check_in/2`); teste com 8 leitores simultâneos → 1 `:checked_in`, 7 `:already_checked_in`.
- **Tempo real**: PubSub por evento (`event:<id>`) para dashboard e ingresso; Presence conta leitores online.
- **QR**: payload é só o UUID. E-mail leva o PNG inline; a página do ingresso renderiza SVG.
- **Câmera exige HTTPS** (Fly já força). Se falhar, há campo manual.

## Deploy (Fly.io)

```bash
fly launch --no-deploy --copy-config
fly postgres create && fly postgres attach <app>
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret) ORGANIZER_KEY=<forte> RESEND_API_KEY=<key>
fly deploy
```

Sem `RESEND_API_KEY` os e-mails não saem em produção (adapter Local).

## Fases do plano

1–4 (esqueleto, inscrição + QR + e-mail, check-in ao vivo, dashboard): **feitas e testadas**.
5 (piloto real) e 6 (proposta) dependem de pessoas: roteiro em `PILOTO.md`, rascunho em `PROPOSTA.md`. Checklist resumido:

- [x] Nome definido: Tucupass
- [x] Material de entrega para o Devs Norte em `entrega/` (campos do formulário, descrição e prints)
- [x] Repositório publicado: https://github.com/Gaalbu/tucupass
- [ ] Deploy no Fly + domínio de remetente no Resend (só se decidir hospedar; hoje sem custo)
- [ ] Testar scanner em celular real, luz baixa e rede ruim (sem modo offline ainda)
- [ ] Combinar com a organização do meetup e operar a entrada
