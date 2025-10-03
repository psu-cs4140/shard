// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and import them using relative paths:
//     import "../vendor/some-package.js"
// Or install packages into assets with npm and import by name:
//     import "some-package"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

import topbar from "../vendor/topbar"

// ---------------- LiveView Hooks ----------------
const Hooks = {
  // Background music via <audio phx-hook="Bgm" data-src="..." data-fallback="...">
  Bgm: {
    mounted() {
      this.fallback = this.el.dataset.fallback || ""
      this.el.addEventListener("error", () => {
        if (this.fallback && !this.el.src.endsWith(this.fallback)) {
          this.el.src = this.fallback
          this.el.play?.().catch(() => {})
        }
      })
      this.swap()
    },
    updated() { this.swap() },
    swap() {
      const desired = this.el.dataset.src || ""
      if (!this.el.src.endsWith(desired)) {
        this.el.src = desired
        this.el.play?.().catch(() => {})
      }
    }
  },

  // Room music controlled by server events:
  //   push_event("play-room-music", %{src, volume, loop})
  //   push_event("stop-room-music", %{})
  RoomMusic: {
    mounted() {
      this.handleEvent("play-room-music", ({ src, volume, loop }) => {
        if (!this.audio) this.audio = new Audio()
        this.audio.pause()
        this.audio.src = src
        this.audio.loop = !!loop
        this.audio.volume = Math.max(0, Math.min(1, (volume ?? 70) / 100))
        this.audio.play().catch(() => { /* user gesture may be required */ })
      })
      this.handleEvent("stop-room-music", () => {
        if (this.audio) this.audio.pause()
      })
    },
    destroyed() {
      if (this.audio) { this.audio.pause(); this.audio = null }
    }
  }
}
// ------------------------------------------------------------------------

// CSRF + LiveSocket
const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Prevent arrow keys from scrolling the page during game movement
let keysPressed = new Set()

document.addEventListener("keydown", function (event) {
  keysPressed.add(event.key)

  if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(event.key)) {
    event.preventDefault()

    if (keysPressed.has("ArrowUp") && keysPressed.has("ArrowRight")) {
      window.liveSocket.pushEventTo("#character-index", "diagonal_move", { direction: "northeast" })
    } else if (keysPressed.has("ArrowUp") && keysPressed.has("ArrowLeft")) {
      window.liveSocket.pushEventTo("#character-index", "diagonal_move", { direction: "northwest" })
    } else if (keysPressed.has("ArrowDown") && keysPressed.has("ArrowRight")) {
      window.liveSocket.pushEventTo("#character-index", "diagonal_move", { direction: "southeast" })
    } else if (keysPressed.has("ArrowDown") && keysPressed.has("ArrowLeft")) {
      window.liveSocket.pushEventTo("#character-index", "diagonal_move", { direction: "southwest" })
    } else {
      window.liveSocket.pushEventTo("#character-index", "keydown", { key: event.key })
    }
  }
})

document.addEventListener("keyup", function (event) {
  keysPressed.delete(event.key)
})

// The lines below enable quality-of-life phoenix_live_reload dev features:
//   1. stream server logs to the browser console
//   2. click on elements to jump to their definitions in your code editor
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    reloader.enableServerLogs()

    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
