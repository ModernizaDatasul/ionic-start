import { PoSyncSchema } from '@portinari/portinari-sync';

export const taskSchema: PoSyncSchema = {
    getUrlApi: 'dts/datasul-rest/resources/prg/crl/v1/task',
    diffUrlApi: 'dts/datasul-rest/resources/prg/crl/v1/task/diff',
    deletedField: 'isDeleted',
    fields: ['id', 'phone', 'actionId', 'actionName', 'campaignId', 'campaignName'],
    idField: 'id',
    name: 'Task',
    pageSize: 50
};
