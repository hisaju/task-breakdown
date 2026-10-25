import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// モック：分解中の S-4 を、一定時間後に分解完了の S-4 へ切り替える（実際の分解は行わない）。
// 履歴は置き換えるので、ブラウザの「戻る」で分解中の画面には戻らない。autoplay が false なら何もしない
export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 3000 }, autoplay: { type: Boolean, default: true } }

  connect() {
    if (!this.autoplayValue) return

    this.timer = setTimeout(() => Turbo.visit(this.urlValue, { action: "replace" }), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
