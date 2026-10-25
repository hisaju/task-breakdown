import { Controller } from "@hotwired/stimulus"

// S-3 の入力フォーム
// - ⌘(Ctrl) + Enter で送信（フォーム内のどの入力欄からでも）。送信前にブラウザの入力チェックを通す
// - 空白だけの入力は空欄と同じく送信させない（required は空白だけの値を通してしまうため）
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.validate()
  }

  validate() {
    const input = this.inputTarget
    const blankOnly = input.value !== "" && input.value.trim() === ""
    input.setCustomValidity(blankOnly ? "取り組みたいことを入力してください" : "")
  }

  submitOnShortcut(event) {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.validate()
      this.element.requestSubmit()
    }
  }
}
