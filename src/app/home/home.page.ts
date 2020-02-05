import { Component } from '@angular/core';
import { MingleService } from '@totvs/mingle';
import { LoadingController } from '@ionic/angular';
import { PoTableColumn } from '@portinari/portinari-ui';

@Component({
    selector: 'app-home',
    templateUrl: 'home.page.html',
    styleUrls: ['home.page.scss'],
})
export class HomePage {

    public items = [];

    public columns: Array<PoTableColumn> = [{
        property: 'id',
        label: 'Código'
    }, {
        property: 'name',
        label: 'Nome'
    }];

    constructor(private mingleService: MingleService, private loadingController: LoadingController) { }

    async executeRequest() {
        const styleLoading = await this.loadingController.create({ message: 'Buscando registros no ERP' })
        styleLoading.present();

        this.items = [];

        this.mingleService.gateway.get('/dts/datasul-rest/resources/prg/cgc/v1/style')
            .subscribe((response: any) => {
                this.items = [...response.items];
                styleLoading.dismiss();
            }, (error) => {
                styleLoading.dismiss();
            });
    }

}
