import { LightningElement, track } from 'lwc';
import parseResume from '@salesforce/apex/ResumeParserController.parseResume';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ResumeUploader extends LightningElement {
    @track fileName = '';
    @track fileContent = '';
    @track isLoading = false;

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            const reader = new FileReader();
            reader.onload = () => {
                this.fileContent = reader.result;
            };
            reader.readAsText(file); // Currently supports text-based files
        }
    }

    handleParse() {
        if (!this.fileContent) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Please select a file first.', variant: 'error' }));
            return;
        }

        this.isLoading = true;
        parseResume({ rawText: this.fileContent })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: `Resume "${this.fileName}" has been parsed and skills extracted!`, variant: 'success' }));
                this.fileName = '';
                this.fileContent = '';
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(new ShowToastEvent({ title: 'AI Error', message: error.body ? error.body.message : 'Something went wrong', variant: 'error' }));
            })
            .finally(() => { this.isLoading = false; });
    }
}