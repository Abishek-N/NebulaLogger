import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import loggerStaticResources from '@salesforce/resourceUrl/LoggerResources';

export default class LoggerCodeViewer extends LightningElement {
    @api code;
    @api language;
    @api startingLineNumber;
    @api targetLineNumber;

    isLoaded = false;

    renderedCallback() {
        if (this.isLoaded) {
            return;
        }

        Promise.all([loadScript(this, loggerStaticResources + '/prism.js'), loadStyle(this, loggerStaticResources + '/prism.css')])
            .then(() => {
                const container = this.template.querySelector('.prism-viewer');

                // eslint-disable-next-line @lwc/lwc/no-inner-html
                container.innerHTML =
                    // data-line and data-line-offset are effectively the same thing within Prism...
                    // but the core Prism code uses data-start for line numbers,
                    // and the line-highlight plugin uses data-line-offset for highlighting a line number
                    // (╯°□°）╯︵ ┻━┻
                    `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
                    `<code class="language-${this.language}">${this.code}</code>` +
                    `</pre>`;

                // eslint-disable-next-line no-undef
                Prism.highlightAll();
                this.isLoaded = true;
            });
    }
}
