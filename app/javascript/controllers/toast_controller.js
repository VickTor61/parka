import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  #DURATION = 2000;

  connect() {
    this.show();
  }

  show() {
    this.element.classList.add("-translate-y-full", "opacity-0");
    this.element.classList.remove("translate-y-0", "opacity-100");

    this.element.offsetHeight;

    requestAnimationFrame(() => {
      this.element.classList.remove("-translate-y-full", "opacity-0");
      this.element.classList.add("translate-y-0", "opacity-100");
    });

    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.#DURATION);
  }

  dismiss() {
    this.element.classList.remove("translate-y-0", "opacity-100");
    this.element.classList.add("-translate-y-full", "opacity-0");

    setTimeout(() => this.element.remove(), 300);
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }
}
