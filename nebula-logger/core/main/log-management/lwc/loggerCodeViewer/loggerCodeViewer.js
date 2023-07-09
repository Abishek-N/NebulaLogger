import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
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
                const container = this.template.querySelector('.container');

                // eslint-disable-next-line @lwc/lwc/no-inner-html
                container.innerHTML =
                    `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
                    `<code class="language-${this.language}">${this.code}</code>` +
                    `</pre>`;

                // eslint-disable-next-line no-undef
                Prism.highlightAll();
                this.isLoaded = true;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: error.message,
                        title: 'Error loading code viewer',
                        variant: 'error'
                    })
                );
            });
    }
}
