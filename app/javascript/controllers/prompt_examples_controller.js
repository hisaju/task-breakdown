import { Controller } from "@hotwired/stimulus"

// 入力例のチップをクリックすると入力欄に反映する
export default class extends Controller {
  fill(event) {
    const input = document.querySelector("[data-prompt-target='input']")
    if (!input) return
    input.value = event.currentTarget.dataset.text
    // 入力欄の検証（空白だけの入力の判定）を例文に合わせて更新する
    input.dispatchEvent(new Event("input", { bubbles: true }))
    input.focus()
  }
}
