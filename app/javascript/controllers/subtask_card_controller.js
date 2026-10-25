import { Controller } from "@hotwired/stimulus"

// モック：サブタスクの完了チェック（保存はしない）。
// 完了状態はカードの data-done だけで持ち、塗り・打ち消し線は CSS、非表示は completed_filter_controller が担う。
// ここでは data-done を切り替え、チェックの aria-label を状態に合わせる
export default class extends Controller {
  static targets = ["check"]
  static values = { title: String }

  connect() {
    this.render()
  }

  toggle() {
    this.element.dataset.done = String(!this.done)
    this.render()
    // 完了にしたカードは完了フィルタで即座に消える（MutationObserver の処理はこの後のマイクロタスクより先に走る）。
    // フォーカスが失われないよう、次に見えている完了チェック（無ければ「タスクを追加」）へ移す
    queueMicrotask(() => this.keepFocus())
  }

  keepFocus() {
    if (this.element.checkVisibility()) return

    const checks = Array.from(this.element.parentElement.querySelectorAll("[data-subtask-card-target='check']"))
      .filter((check) => check.checkVisibility())
    const next = checks.find((check) => this.element.compareDocumentPosition(check) & Node.DOCUMENT_POSITION_FOLLOWING)
    const fallback = document.querySelector("[data-action~='subtasks#add']")
    ;(next ?? checks.at(-1) ?? fallback)?.focus()
  }

  render() {
    const action = this.done ? "未完了に戻す" : "完了にする"
    this.checkTarget.setAttribute("aria-label", `「${this.titleValue}」を${action}`)
  }

  get done() {
    return this.element.dataset.done === "true"
  }
}
