import { Controller } from "@hotwired/stimulus";

const MOBILE_BREAKPOINT = 640;

export default class extends Controller {
  static targets = ["menu", "button"];

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this);
    this.closeOnEscape = this.closeOnEscape.bind(this);
    this.reposition = this.reposition.bind(this);

    document.addEventListener("click", this.closeOnOutsideClick);
    document.addEventListener("keydown", this.closeOnEscape);
    window.addEventListener("resize", this.reposition);
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick);
    document.removeEventListener("keydown", this.closeOnEscape);
    window.removeEventListener("resize", this.reposition);
  }

  toggle(event) {
    event.stopPropagation();
    this.menuTarget.classList.toggle("hidden");
    this.reposition();
  }

  close() {
    this.menuTarget.classList.add("hidden");
  }

  reposition() {
    if (this.menuTarget.classList.contains("hidden")) return;

    if (window.innerWidth < MOBILE_BREAKPOINT) {
      const trigger = this.hasButtonTarget ? this.buttonTarget : this.element;
      this.menuTarget.style.top = `${Math.round(trigger.getBoundingClientRect().bottom + 6)}px`;
    } else {
      this.menuTarget.style.top = "";
    }
  }

  closeOnOutsideClick(event) {
    if (this.element.contains(event.target)) return;
    if (event.target.closest(".flatpickr-calendar")) return;

    this.close();
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close();
  }
}
