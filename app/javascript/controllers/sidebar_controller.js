import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "backdrop", "dialog"];

  open() {
    const sidebar = this.panelTarget;
    const backdrop = this.backdropTarget;

    sidebar.classList.remove("hidden");
    backdrop.classList.remove("hidden");

    backdrop.offsetHeight;

    requestAnimationFrame(() => {
      backdrop.classList.remove("opacity-0");
      backdrop.classList.add("opacity-100");
      backdrop.classList.add("transition-opacity", "ease-in", "duration-100");

      sidebar.classList.remove("-translate-x-full");
      sidebar.classList.add("translate-x-0");
      sidebar.classList.add(
        "transition-transform",
        "ease-in-out",
        "duration-300"
      );
    });
  }

  close() {
    const sidebar = this.panelTarget;
    const backdrop = this.backdropTarget;

    backdrop.classList.remove("opacity-100");
    backdrop.classList.add("opacity-0");

    sidebar.classList.remove("translate-x-0");
    sidebar.classList.add("-translate-x-full");

    setTimeout(() => {
      sidebar.classList.add("hidden");
      backdrop.classList.add("hidden");
    }, 300);
  }

  openModal() {
    this.dialogTarget.showModal();
  }
  closeModal() {
    this.dialogTarget.close();
  }
}
