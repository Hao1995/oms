import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Flash controller connected", this.element.dataset.key);

    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.style.transition = 'opacity 0.5s ease-out';
      this.element.style.opacity = '0';
      this.timeout = setTimeout(() => this.element.remove(), 500);
    }, 2000);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
