import { PoDataTransform } from '@portinari/portinari-sync';

class MyPoDataTransform extends PoDataTransform {
    protected data: any;
    
    getDateFieldName(): string {
        return 'totvs_sync_date';
    }

    getItemsFieldName(): string {
        return 'items';
    }

    getPageParamName(): string {
        return 'page';
    }

    getPageSizeParamName(): string {
        return 'pageSize';
    }

    hasNext(): boolean {
        return this.data.hasNext;
    }
}

export default new MyPoDataTransform();
