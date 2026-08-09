import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["backdrop", "panel"];

  connect() {
    this.closeWithEscapeKey = this.closeWithEscapeKey.bind(this);
    document.addEventListener("keydown", this.closeWithEscapeKey);
    this.stopBackgroundScroll();
    this.show();
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeWithEscapeKey);
    const frame = document.querySelector("turbo-frame[id='modal']");
    if (frame) frame.src = null;
    this.continueBackgroundScroll();
  }

  show() {
    requestAnimationFrame(() => {
      this.backdropTarget.classList.replace("opacity-0", "opacity-100");
      this.panelTarget.classList.remove("opacity-0", "scale-95");
      this.panelTarget.classList.add("opacity-100", "scale-100");
    });
  }

  closeModal(event) {
    event?.preventDefault();
    this.hide();
  }

  closeWithEscapeKey(event) {
    if (event.key === "Escape") this.hide();
  }

  hide() {
    this.backdropTarget.classList.replace("opacity-100", "opacity-0");
    this.panelTarget.classList.remove("opacity-100", "scale-100");
    this.panelTarget.classList.add("opacity-0", "scale-95");

    setTimeout(() => this.element?.remove(), 300);
  }

  stopBackgroundScroll() {
    const scrollY = window.scrollY;
    document.body.dataset.scrollY = scrollY;
    document.body.style.position = "fixed";
    document.body.style.top = `-${scrollY}px`;
    document.body.style.width = "100%";
    document.body.style.overflow = "hidden";
  }

  continueBackgroundScroll() {
    const scrollY = parseInt(document.body.dataset.scrollY || "0", 10);
    document.body.style.position = "";
    document.body.style.top = "";
    document.body.style.width = "";
    document.body.style.overflow = "";
    window.scrollTo(0, scrollY);
  }
}
