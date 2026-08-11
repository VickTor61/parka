import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["from", "to", "fiscalYear"];

  fiscalYearChanged() {
    if (this.fiscalYearTarget.value) {
      this.fromTarget.value = "";
      this.toTarget.value = "";
    }
  }

  rangeChanged() {
    if (this.fromTarget.value || this.toTarget.value) {
      this.fiscalYearTarget.value = "";
    }
  }
}
