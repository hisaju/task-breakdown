import { Controller } from "@hotwired/stimulus"

// モック：「タスクを追加」でカードを末尾に追加する（保存はしない）
export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const number = String(this.listTarget.children.length + 1).padStart(2, "0")
    const html = this.templateTarget.innerHTML.replace("__NUMBER__", number)
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }
}
