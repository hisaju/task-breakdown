import { Controller } from "@hotwired/stimulus"

// モック：サブタスクの完了チェック（保存はしない）。
// 完了状態はカードの data-done だけで持ち、塗り・打ち消し線は CSS、非表示は completed_filter_controller が担う。
// ここでは data-done を切り替え、チェックの aria-label を状態に合わせる。
// 「タスクを追加」のカード（タスク名が contenteditable）は、入力したタスク名を完了チェックとメニューの aria-label に反映する
export default class extends Controller {
  static targets = ["check", "title", "description"]
  static values = { title: String, defaultTitle: String }

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

  // タスク名の入力に合わせて読み上げ名を変える（空に戻したら「新しいタスク」）
  rename(event) {
    this.clearIfBlank(event)
    this.titleValue = this.titleTarget.textContent.trim()
    this.render()
  }

  // タスク名は 1 行。Enter では改行せず補足の入力へ移る
  finishTitle(event) {
    if (event.isComposing) return

    event.preventDefault()
    if (this.hasDescriptionTarget) this.descriptionTarget.focus()
  }

  // 文字を消しきったとき、ブラウザが残す <br> を消してプレースホルダ（:empty）を出す
  clearIfBlank(event) {
    const field = event.currentTarget
    if (field.textContent.trim() === "" && field.childNodes.length > 0) field.replaceChildren()
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
    this.checkTarget.setAttribute("aria-label", `「${this.name}」を${action}`)
    // 行メニュー（shared/_menu）のトリガーも同じ名前で読み上げる
    this.element.querySelector("[data-menu-target='trigger']")?.setAttribute("aria-label", `「${this.name}」のメニュー`)
  }

  get name() {
    return this.titleValue || this.defaultTitleValue
  }

  get done() {
    return this.element.dataset.done === "true"
  }
}
