import { LightningElement, track } from 'lwc';
import parseResume from '@salesforce/apex/ResumeParserController.parseResume';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ResumeUploader extends LightningElement {
    @track fileName = '';
    @track fileContent = '';
    @track base64PDF = '';
    @track isLoading = false;

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            const isPDF = file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf');
            const reader = new FileReader();
            
            reader.onload = () => {
                if (isPDF) {
                    this.base64PDF = reader.result.split(',')[1];
                    this.fileContent = '';
                } else {
                    this.fileContent = reader.result;
                    this.base64PDF = '';
                }
            };

            if (isPDF) {
                reader.readAsDataURL(file);
            } else {
                reader.readAsText(file);
            }
        }
    }

    handleParse() {
        if (!this.fileContent && !this.base64PDF) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Please select a file first.', variant: 'error' }));
            return;
        }

        this.isLoading = true;
        parseResume({ rawText: this.fileContent, base64PDF: this.base64PDF })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: `Resume "${this.fileName}" has been parsed and skills extracted!`, variant: 'success' }));
                this.fileName = '';
                this.fileContent = '';
                this.base64PDF = '';
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(new ShowToastEvent({ title: 'AI Error', message: error.body ? error.body.message : 'Something went wrong', variant: 'error' }));
            })
            .finally(() => { this.isLoading = false; });
    }
}