// Standard imports
import { LightningElement, api } from 'lwc';

const SECTION_ICON_EXPANDED = 'utility:chevrondown';
const SECTION_ICON_COLLAPSED = 'utility:chevronright';

export default class LoggerPageSection extends LightningElement {
    @api
    section;
    @api
    sectionTitle;

    showSectionContent = true;

    get sectionToggleIcon() {
        if (this.showSectionContent) {
            return SECTION_ICON_EXPANDED;
        } else {
            return SECTION_ICON_COLLAPSED;
        }
    }

    toggleSection() {
        this.showSectionContent = !this.showSectionContent;
    }
}
