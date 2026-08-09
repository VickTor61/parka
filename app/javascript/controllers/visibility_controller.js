import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["password", "showIcon", "hideIcon"];

  toggle(event) {
    const isHidden = this.passwordTarget.type === "password";

    this.passwordTarget.type = isHidden ? "text" : "password";

    this.showIconTarget.classList.toggle("hidden", isHidden);
    this.hideIconTarget.classList.toggle("hidden", !isHidden);

    event.currentTarget.setAttribute("aria-pressed", isHidden.toString());
  }
}
