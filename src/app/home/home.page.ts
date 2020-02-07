import { OnInit } from '@angular/core/core';
import { Component } from '@angular/core';
import { MingleService } from '@totvs/mingle';
import { LoadingController } from '@ionic/angular';
import { PoSyncService, PoResponseApi, PoSyncConfig, PoNetworkType } from '@portinari/portinari-sync';
import { taskSchema } from '../sync/schemas';
import MyPoDataTransform from '../sync/data-transform';

@Component({
    selector: 'app-home',
    templateUrl: 'home.page.html',
    styleUrls: ['home.page.scss'],
})
export class HomePage implements OnInit {

    public items = [];
    public tasks = [];
    public page = 0;

    constructor(private mingleService: MingleService,
                private loadingController: LoadingController,
                private poSync: PoSyncService) { }

    ngOnInit() {
        this.initializeSync();
    }

    getTasks() {
        this.page = this.page + 1;
        this.poSync.getModel('Task')
            .find()
            .page(this.page)
            .pageSize(20)
            .exec().then((response: PoResponseApi) => {
                this.tasks = [this.tasks, ...response.items];
                console.log('this.tasks', this.tasks);
                console.log('response.items', response.items);
            });
    }

    async initializeSync() {
        const schemas = [taskSchema];

        const config: PoSyncConfig = {
            dataTransform: MyPoDataTransform,
            type: [PoNetworkType.ethernet, PoNetworkType.wifi, PoNetworkType._3g, PoNetworkType._4g],
            period: 300
        };

        await this.poSync.prepare(schemas, config);

        const syncLoading = await this.loadingController.create({ message: 'Executando carga inicial' });
        syncLoading.present();

        this.poSync.loadData().subscribe(() => { // this.poSync.sync(); FIXME: Controlar o primeiro login
            syncLoading.dismiss();
            this.getTasks();
        }, error => syncLoading.dismiss());
    }

    async sync() {
        await this.poSync.sync();
        this.page = 0;
        this.getTasks();
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
