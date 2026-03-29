import { LightningElement, wire, track } from 'lwc';
import getExistingSuggestions from '@salesforce/apex/JobMatchController.getExistingSuggestions';
import findJobs from '@salesforce/apex/JobMatchController.findJobs';
import createApplication from '@salesforce/apex/JobMatchController.createApplication';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
        const suggestionId = event.target.dataset.id;
        const applyUrl = event.target.dataset.url;

        this.isLoading = true;
        createApplication({ suggestionId: suggestionId })
            .then(() => {
                if (applyUrl) {
                    this.dispatchEvent(new ShowToastEvent({ 
                        title: 'Success', 
                        message: 'Application created! Opening job posting...', 
                        variant: 'success' 
                    }));
                    window.open(applyUrl, '_blank');
                } else {
                    this.dispatchEvent(new ShowToastEvent({ 
                        title: 'Success', 
                        message: 'Application tracked! No direct URL available for this job.', 
                        variant: 'info' 
                    }));
                }
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({ 
                    title: 'Error breaking Apply button', 
                    message: error.body ? error.body.message : 'Unknown error', 
                    variant: 'error' 
                }));
            })
            .finally(() => { this.isLoading = false; });
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