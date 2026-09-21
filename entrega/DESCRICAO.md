# Tucupass

Check-in ao vivo para meetups: a pessoa se inscreve, recebe um ingresso com QR, e na porta a organização escaneia com a câmera do celular e vê cada chegada acontecer no painel, sem recarregar nada.

## Funcionalidades

- Inscrição com nome e e-mail e ingresso com QR (o QR carrega só um UUID)
- Leitor de check-in pela câmera, com campo manual como reserva
- Painel ao vivo: inscritos, chegadas, taxa e leitores online
- Ingresso que muda de estado sozinho quando o check-in acontece
- Check-in idempotente e seguro contra corrida: o mesmo QR lido por 8 leitores ao mesmo tempo dá 1 entrada e 7 "já entrou"
- Modo projetor em tela cheia para a organização

## Como funciona por dentro

Phoenix LiveView + PubSub por evento para o tempo real, Presence para contar leitores online, Postgres com `SELECT … FOR UPDATE` para o check-in atômico.

## Experimente

Não há hospedagem pública por enquanto. Rode local com Docker, sem instalar Elixir:

```bash
./bin-mix setup
docker compose up dev   # http://localhost:4000
```

A home abre num painel com um evento de demonstração alimentado por gente fictícia. Inscreva-se e faça check-in você mesmo: aparece na hora.

## Stack

Elixir · Phoenix 1.8 · LiveView · Ecto/Postgres · Swoosh · eqrcode · html5-qrcode
