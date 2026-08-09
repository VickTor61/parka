import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";
import monthSelectPlugin from "flatpickr/month-select";

export default class extends Controller {
  connect() {
    this.picker = flatpickr(this.element, {
      allowInput: true,
      plugins: [
        new monthSelectPlugin({
          shorthand: true,
          dateFormat: "Y-m",
          altFormat: "F Y",
        }),
      ],
    });
  }

  disconnect() {
    this.picker?.destroy();
    this.picker = null;
  }
}
