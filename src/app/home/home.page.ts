import { OnInit } from '@angular/core/core';
import { Component } from '@angular/core';
import { MingleService } from '@totvs/mingle';
import { LoadingController } from '@ionic/angular';
// import { PoTableColumn } from '@portinari/portinari-ui';
import { taskSchema } from '../sync/schemas';
import { PoSyncService, PoSyncConfig, PoNetworkType, PoResponseApi } from '@portinari/portinari-sync';
import MyPoDataTransform from '../sync/data-transform';

@Component({
    selector: 'app-home',
    templateUrl: 'home.page.html',
    styleUrls: ['home.page.scss'],
})
export class HomePage implements OnInit {

    public items = [];
    public tasks = [];

    constructor(private mingleService: MingleService,
                private loadingController: LoadingController,
                private poSync: PoSyncService) { }

    ngOnInit() {
        this.initializeSync();
        this.getTasks();
    }

    async getTasks() {
        this.poSync.getModel('Task').find().exec().then((response: PoResponseApi) => {
            this.tasks = response.items;
            console.log('Tarefas', this.tasks);
        });
    }
    async initializeSync() {
        const schemas = [taskSchema];

        const config: PoSyncConfig = {
            dataTransform: MyPoDataTransform,
            type: [PoNetworkType.ethernet, PoNetworkType.wifi, PoNetworkType._3g, PoNetworkType._4g],
            period: 30
        };

        await this.poSync.prepare(schemas, config);
        // this.poSync.sync(); FIXME: Controlar o primeiro login
        this.poSync.loadData();
    }

    async sync() {
        await this.poSync.sync();
    }

    async executeRequest() {
        const styleLoading = await this.loadingController.create({ message: 'Buscando registros no ERP' });
        styleLoading.present();

        this.items = [];

        this.mingleService.gateway.get('dts/datasul-rest/resources/prg/cgc/v1/style')
            .subscribe((response: any) => {
                this.items = [...response.items];
                styleLoading.dismiss();
            }, (error) => {
                styleLoading.dismiss();
            });
    }

}
