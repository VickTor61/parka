import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

// A form inside the modal frame must keep validation errors in the frame, so it cannot
// target _top. Success then needs to leave the frame explicitly, which Turbo has no
// built-in action for
Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target)
}

import "chartkick"
import "Chart.bundle"
