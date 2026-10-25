import { Controller } from "@hotwired/stimulus"

// 入力欄：⌘(Ctrl) + Enter で送信
export default class extends Controller {
  static targets = ["input"]

  submitOnShortcut(event) {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}
