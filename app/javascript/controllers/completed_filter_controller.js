import { Controller } from "@hotwired/stimulus"

// 「完了済みを表示／隠す」。トグルの aria-pressed を唯一の状態とし、
// data-done="true" の要素に data-hidden-by-done を付け外しする（非表示は CSS が担う）。
// 完了状態（data-done）や日付タブの絞り込み（data-hidden-by-tab）が後から変わっても追随し、
// 表示対象が 0 件になったら empty ターゲットを表示する
export default class extends Controller {
  static targets = ["toggle", "empty"]

  connect() {
    this.apply()
    this.observer = new MutationObserver(() => this.apply())
    this.observer.observe(this.element, {
      subtree: true, childList: true, attributes: true, attributeFilter: ["data-done", "data-hidden-by-tab"]
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  toggle() {
    this.toggleTarget.setAttribute("aria-pressed", String(!this.showing))
    this.apply()
  }

  apply() {
    // 同じ文字列でも代入すると childList の変化になり observer が再発火するため、変わるときだけ書き換える
    const label = this.showing ? "完了済みを隠す" : "完了済みを表示"
    if (this.toggleTarget.textContent !== label) this.toggleTarget.textContent = label

    const items = this.items
    items.forEach((item) => {
      item.toggleAttribute("data-hidden-by-done", !this.showing && item.dataset.done === "true")
    })

    // 項目がそもそも無い画面（分解失敗など）では空状態を出さない
    const hidden = (item) => item.hasAttribute("data-hidden-by-done") || item.hasAttribute("data-hidden-by-tab")
    const visible = items.length === 0 || items.some((item) => !hidden(item))
    this.emptyTargets.forEach((empty) => { empty.hidden = visible })
  }

  get showing() {
    return this.toggleTarget.getAttribute("aria-pressed") === "true"
  }

  get items() {
    return Array.from(this.element.querySelectorAll("[data-done]"))
  }
}
