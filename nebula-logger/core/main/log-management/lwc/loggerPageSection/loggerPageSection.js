// Standard imports
import { LightningElement, api } from 'lwc';

const SECTION_ICON_EXPANDED = 'utility:chevrondown';
const SECTION_ICON_COLLAPSED = 'utility:chevronright';

export default class LoggerPageSection extends LightningElement {
    @api title;
    @api content;

    showContent = true;

    get sectionToggleIcon() {
        return this.showContent ? SECTION_ICON_EXPANDED : SECTION_ICON_COLLAPSED;
    }

    toggleSection() {
        this.showContent = !this.showContent;
    }
}
