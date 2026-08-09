import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submitForm() {
    clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      if (this.element.isConnected) this.element.requestSubmit();
    }, 300);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
