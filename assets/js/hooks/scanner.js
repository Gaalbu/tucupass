// Leitor de QR pela câmera do navegador (html5-qrcode) -> pushEvent("scan").
const LIB = "/assets/vendor/html5-qrcode.min.js"
const REPEAT_MS = 2500

function loadLib() {
  if (window.Html5Qrcode) return Promise.resolve()
  return new Promise((resolve, reject) => {
    const s = document.createElement("script")
    s.src = LIB
    s.onload = resolve
    s.onerror = () => reject(new Error("não foi possível carregar o leitor de QR"))
    document.head.appendChild(s)
  })
}

export const Scanner = {
  async mounted() {
    this.last = {code: null, at: 0}
    this.handleEvent("scan-result", ({status}) => {
      if (navigator.vibrate) navigator.vibrate(status === "ok" ? 80 : [60, 60, 60])
    })

    try {
      await loadLib()
      this.qr = new window.Html5Qrcode(this.el.id)
      await this.qr.start(
        {facingMode: "environment"},
        {fps: 10, qrbox: {width: 240, height: 240}},
        code => this.onCode(code),
        () => {}
      )
    } catch (err) {
      this.pushEvent("camera-error", {message: String(err && err.message ? err.message : err)})
    }
  },

  onCode(code) {
    const now = Date.now()
    if (code === this.last.code && now - this.last.at < REPEAT_MS) return
    this.last = {code, at: now}
    this.pushEvent("scan", {token: code})
  },

  destroyed() {
    if (this.qr) this.qr.stop().then(() => this.qr.clear()).catch(() => {})
  },
}
