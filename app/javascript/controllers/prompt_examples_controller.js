import { Controller } from "@hotwired/stimulus"

// 入力例のチップをクリックすると入力欄に反映する
export default class extends Controller {
  fill(event) {
    const input = document.querySelector("[data-prompt-target='input']")
    if (!input) return
    input.value = event.currentTarget.dataset.text
    input.focus()
  }
}
