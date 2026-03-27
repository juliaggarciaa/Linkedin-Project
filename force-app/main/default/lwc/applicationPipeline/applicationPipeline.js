import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPipelineData from '@salesforce/apex/JobMatchController.getPipelineData';

export default class ApplicationPipeline extends NavigationMixin(LightningElement) {
    @track stages = [];

    @wire(getPipelineData)
    wiredData({ error, data }) {
        if (data) {
            this.stages = data;
        } else if (error) {
            console.error(error);
        }
    }

    handleNavigate(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                actionName: 'view'
            }
        });
    }
}
