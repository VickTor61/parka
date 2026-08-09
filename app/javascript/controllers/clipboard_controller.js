import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "copyIcon", "checkIcon"];
  static values = { text: String };

  async copy() {
    const text = this.hasTextValue ? this.textValue : this.sourceTarget.textContent.trim();

    try {
      await navigator.clipboard.writeText(text);
    } catch {
      return;
    }

    this.copyIconTarget.classList.add("hidden");
    this.checkIconTarget.classList.remove("hidden");

    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.copyIconTarget.classList.remove("hidden");
      this.checkIconTarget.classList.add("hidden");
    }, 1500);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
