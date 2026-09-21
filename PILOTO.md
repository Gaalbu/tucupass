# Fase 5 — Roteiro do piloto (meetup presencial)

Status: **preparado, não executado** (depende de acordo com a organização do Devs Norte).

## Antes de propor
- [x] Nome definido: Tucupass
- [ ] Deploy no Fly com Postgres; `fly secrets set SECRET_KEY_BASE ORGANIZER_KEY RESEND_API_KEY`
- [ ] Domínio/remetente verificado no Resend (senão o e-mail cai em spam ou não sai)
- [ ] Criar o evento em produção (`Events.create_event/1` via `bin/tucupass rpc`)

## Oferta à organização
"Opero o check-in na entrada do próximo meetup, sem custo. Vocês só compartilham o link de inscrição."
Risco zero para eles: manter a lista/planilha atual como plano B na porta.

## Ensaio (1 semana antes)
- [ ] 10 inscrições de teste; abrir os e-mails em Gmail, Outlook e celular
- [ ] Scanner em pelo menos 2 celulares (Android + iOS), luz baixa, tela do ingresso com brilho baixo
- [ ] Testar com 4G ruim: o que acontece se a rede cair no meio do scan? (hoje não há modo offline)
- [ ] Dois leitores simultâneos no mesmo ingresso

## No dia
- [ ] Dashboard projetado; 2 celulares com `/e/:slug/checkin`
- [ ] Lista impressa como plano B
- [ ] Anotar: tempo médio por pessoa na fila, falhas de leitura, ingressos não recebidos, quem chegou sem inscrição

## Depois
- [ ] Números: inscritos, comparecimento, taxa de falha, tempo de fila
- [ ] Ajustes de UX a partir das anotações; decidir se modo offline é necessário
- [ ] Feedback direto da organização (3 perguntas: o que travou, o que faltou, usariam de novo?)

## Lacunas conhecidas antes do piloto
- Sem modo offline no scanner
- Sem inscrição na hora (walk-in) nem cancelamento
- Sem exportação de lista (CSV)
