import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// モック：分解中の S-4 を、一定時間後に分解完了の S-4 へ切り替える（実際の分解は行わない）。
// 履歴は置き換えるので、ブラウザの「戻る」で分解中の画面には戻らない。autoplay が false なら何もしない。
// delay・autoplay の値が後から変わったときは、その時点から数え直す（system spec で待ち時間を短くするため）
export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 3000 }, autoplay: { type: Boolean, default: true } }

  // 値の変更コールバックは接続時にも呼ばれるので、タイマーの開始はここで行う
  delayValueChanged() {
    this.schedule()
  }

  autoplayValueChanged() {
    this.schedule()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  schedule() {
    clearTimeout(this.timer)
    if (!this.autoplayValue) return

    this.timer = setTimeout(() => Turbo.visit(this.urlValue, { action: "replace" }), this.delayValue)
  }
}
