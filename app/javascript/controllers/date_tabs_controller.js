import { Controller } from "@hotwired/stimulus"

// S-4 の日付タブ。選んだタブと期限の日付（data-due-key）が一致しないカードに data-hidden-by-tab を付ける（非表示は CSS）。
// 「すべて」は全カードを表示し、期限なし（none）のカードは「すべて」でだけ表示される。
// 選択状態はタブの aria-selected だけで持ち、下線・文字色は CSS（aria-selected:）が描く。
// 完了フィルタ（data-hidden-by-done）とは独立で、両方の属性が外れたカードだけが見える。
// 絞り込みで見えるカードが 0 件になったら empty ターゲット（「この日のサブタスクはありません」）を出す。
// ただし全カードが完了済みとして隠れているときは、完了フィルタ側の全完了の空状態だけを出す
export default class extends Controller {
  static targets = ["tab", "panel", "list", "empty"]

  connect() {
    this.apply()
    // 完了・完了フィルタ・カードの追加で見えるカードが変わるので追随する（自分が付ける data-hidden-by-tab は監視しない）
    this.observer = new MutationObserver(() => this.apply())
    this.observer.observe(this.listTarget, {
      subtree: true, childList: true, attributes: true, attributeFilter: ["data-done", "data-hidden-by-done"]
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  select(event) {
    this.choose(event.currentTarget)
  }

  // カードを追加したら「すべて」に戻す（追加したカードが絞り込みで隠れないように）
  showAll() {
    this.choose(this.tabTargets[0], { focus: false })
  }

  // ←→ で前後のタブへ（端で折り返す）、Home / End で先頭・末尾へ。移った先のタブをそのまま選ぶ
  navigate(event) {
    const tabs = this.tabTargets
    const index = tabs.indexOf(event.currentTarget)
    const next = {
      ArrowRight: (index + 1) % tabs.length,
      ArrowLeft: (index - 1 + tabs.length) % tabs.length,
      Home: 0,
      End: tabs.length - 1
    }[event.key]
    if (next === undefined) return

    event.preventDefault()
    this.choose(tabs[next])
  }

  choose(selected, { focus = true } = {}) {
    this.tabTargets.forEach((tab) => {
      const isSelected = tab === selected
      tab.setAttribute("aria-selected", String(isSelected))
      tab.tabIndex = isSelected ? 0 : -1
    })
    this.panelTarget.setAttribute("aria-labelledby", selected.id)
    if (focus) selected.focus()
    this.apply()
  }

  apply() {
    const key = this.selectedKey
    const cards = this.cards
    cards.forEach((card) => {
      card.toggleAttribute("data-hidden-by-tab", key !== "all" && card.dataset.dueKey !== key)
    })

    const allHiddenByDone = cards.length > 0 && cards.every((card) => card.hasAttribute("data-hidden-by-done"))
    const anyVisible = cards.some((card) => !card.hasAttribute("data-hidden-by-tab") && !card.hasAttribute("data-hidden-by-done"))
    this.emptyTarget.hidden = key === "all" || anyVisible || allHiddenByDone
  }

  get selectedKey() {
    return this.tabTargets.find((tab) => tab.getAttribute("aria-selected") === "true")?.dataset.dueKey ?? "all"
  }

  get cards() {
    return Array.from(this.listTarget.querySelectorAll(":scope > [data-due-key]"))
  }
}
