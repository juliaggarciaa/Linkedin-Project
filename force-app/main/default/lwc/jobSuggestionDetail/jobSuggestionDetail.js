import { LightningElement, api, wire } from 'lwc';
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import generateDocs from '@salesforce/apex/TailoredResumeController.generateDocs';

const FIELDS = ['Job_Suggestion__c.Tailored_Resume__c', 'Job_Suggestion__c.Cover_Letter__c', 'Job_Suggestion__c.Outreach_Message__c'];

export default class JobSuggestionDetail extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    job;

    handleGenerate() {
        generateDocs({ suggestionId: this.recordId })
            .then(() => {
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
            })
            .catch(error => console.error(error));
    }

    get record() {
        if (!this.job.data) return {};
        return {
            Tailored_Resume__c: this.job.data.fields.Tailored_Resume__c.value,
            Cover_Letter__c: this.job.data.fields.Cover_Letter__c.value,
            Outreach_Message__c: this.job.data.fields.Outreach_Message__c.value
        };
    }
}