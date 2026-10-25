import { Controller } from "@hotwired/stimulus"

// モック：完了チェックの見た目だけを切り替える（保存はしない）
export default class extends Controller {
  static targets = ["check", "title"]
  static classes = ["done"]

  toggle() {
    const done = this.element.classList.toggle(this.doneClass)
    this.checkTarget.textContent = done ? "✓" : ""
    this.checkTarget.classList.toggle("bg-brand", done)
    this.checkTarget.classList.toggle("border-brand", done)
    this.titleTarget.classList.toggle("line-through", done)
  }
}
