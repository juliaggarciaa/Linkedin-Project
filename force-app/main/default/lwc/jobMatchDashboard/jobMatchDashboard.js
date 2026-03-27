import { LightningElement, wire, track } from 'lwc';
import getExistingSuggestions from '@salesforce/apex/JobMatchController.getExistingSuggestions';
import findJobs from '@salesforce/apex/JobMatchController.findJobs';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class JobMatchDashboard extends NavigationMixin(LightningElement) {
    @track suggestions;
    @track isLoading = false;
    wiredResult;

    @wire(getExistingSuggestions)
    wiredSuggestions(result) {
        this.wiredResult = result;
        if (result.data) {
            this.suggestions = result.data;
        }
    }

    handleFindJobs() {
        this.isLoading = true;
        findJobs()
            .then(() => refreshApex(this.wiredResult))
            .catch(error => { console.error(error); })
            .finally(() => { this.isLoading = false; });
    }

    handleApply(event) {
        window.open(event.target.dataset.url, '_blank');
    }

    handleView(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                actionName: 'view'
            }
        });
    }

    get badgeClass() {
        return 'slds-badge slds-theme_success'; 
    }
}