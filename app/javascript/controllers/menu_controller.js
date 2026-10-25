import { Controller } from "@hotwired/stimulus"

// メニュー「…」の開閉。開いたら最初の項目へフォーカスし、外側クリック・Esc・Tab でメニューの外へ出たとき・
// 見た目のみの項目を押したときに閉じる。
// 開閉状態はトリガーの aria-expanded とメニューの hidden 属性だけで表す
export default class extends Controller {
  static targets = ["trigger", "menu"]

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.menuTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.items[0]?.focus()
  }

  close() {
    this.menuTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  closeAndFocus() {
    if (!this.isOpen) return
    this.close()
    this.triggerTarget.focus()
  }

  closeOnOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  // Tab などでフォーカスがメニューの外へ移ったら閉じる（フォーカスは移った先のまま）
  closeOnFocusOut(event) {
    if (this.isOpen && event.relatedTarget && !this.element.contains(event.relatedTarget)) this.close()
  }

  // ↑↓ で項目間を移動（端で折り返す）、Home / End で先頭・末尾へ
  navigate(event) {
    const items = this.items
    if (items.length === 0) return

    const index = items.indexOf(document.activeElement)
    const next = {
      ArrowDown: (index + 1) % items.length,
      ArrowUp: (index - 1 + items.length) % items.length,
      Home: 0,
      End: items.length - 1
    }[event.key]
    if (next === undefined) return

    event.preventDefault()
    items[next].focus()
  }

  get isOpen() {
    return !this.menuTarget.hidden
  }

  get items() {
    return Array.from(this.menuTarget.querySelectorAll("[role='menuitem']"))
  }
}
