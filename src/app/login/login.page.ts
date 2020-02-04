import { Component, OnInit, AfterViewInit } from '@angular/core';
import { PoPageLoginCustomField, PoPageLoginLiterals, PoPageLogin } from '@portinari/portinari-templates';
import { MingleService } from '@totvs/mingle';
import { AuthResponse } from '@totvs/mingle/src/models/authentication-data.model';
import { PoNotificationService } from '@portinari/portinari-ui';
import { LoadingController } from '@ionic/angular';

@Component({
    selector: 'app-login',
    templateUrl: 'login.page.html',
    styleUrls: ['login.page.scss'],
})
export class LoginPage implements AfterViewInit {

    constructor(private mingleService: MingleService,
                private poNotification: PoNotificationService,
                private loadingController: LoadingController) { }

    public alias: PoPageLoginCustomField = {
        property: 'alias',
        placeholder: 'Digite o Alias',
    };

    public literals: PoPageLoginLiterals = {
        rememberUser: 'Lembrar Usuário',
        title: 'Boa tarde! Bem-vindo ao Nome do App'
    };

    async login(formData: any) {
        const loginLoading = await this.loadingController.create({ message: 'Autenticando Usuário' });
        loginLoading.present();

        this.mingleService.auth.login(formData.login, formData.password, formData.alias)
            .subscribe((authResponse: AuthResponse) => {
                this.poNotification.success('Login efetuado com sucesso');
                loginLoading.dismiss();
            }, (error) => {
                this.poNotification.error('Não foi possível efetuar o login, verifique usuário e senha');
                loginLoading.dismiss();
            });
    }

    ngAfterViewInit() {
        this.addAliasLabel();
    }

    addAliasLabel() {
        // const element = document.querySelector('po-input[name=customFieldInput] .po-field-title');
        // element.innerHTML = 'Alias';
    }

}
