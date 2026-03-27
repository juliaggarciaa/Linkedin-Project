import { LightningElement, track } from 'lwc';
import parseResume from '@salesforce/apex/ResumeParserController.parseResume';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ResumeUploader extends LightningElement {
    @track resumeText = '';
    @track isLoading = false;

    handleTextChange(event) {
        this.resumeText = event.target.value;
    }

    handleParse() {
        if (!this.resumeText) return;
        this.isLoading = true;
        parseResume({ rawText: this.resumeText })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Resume parsed!', variant: 'success' }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body.message, variant: 'error' }));
            })
            .finally(() => { this.isLoading = false; });
    }
}