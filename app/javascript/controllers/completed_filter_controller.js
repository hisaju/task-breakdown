import { Controller } from "@hotwired/stimulus"

// 「完了済みを表示／隠す」。トグルの aria-pressed を唯一の状態とし、
// data-done="true" の要素に data-hidden-by-done を付け外しする（非表示は CSS が担う）。
// 完了状態（data-done）や日付タブの絞り込み（data-hidden-by-tab）が後から変わっても追随し、
// すべての項目が完了済みとして隠れたら empty ターゲットを表示する
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

    // 空状態は「すべての項目が完了済みとして隠れた」ときだけ出す。
    // 日付タブなど別の理由で 0 件になったときは出さない（その理由の空状態は絞り込み側が持つ）。
    // 項目がそもそも無い画面（分解失敗など）でも出さない
    const allHiddenByDone = items.length > 0 && items.every((item) => item.hasAttribute("data-hidden-by-done"))
    this.emptyTargets.forEach((empty) => { empty.hidden = !allHiddenByDone })
  }

  get showing() {
    return this.toggleTarget.getAttribute("aria-pressed") === "true"
  }

  get items() {
    return Array.from(this.element.querySelectorAll("[data-done]"))
  }
}
